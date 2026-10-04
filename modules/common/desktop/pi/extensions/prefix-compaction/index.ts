/**
 * Prefix-preserving compaction + Kent-style handoff.
 *
 * ## Prefix-preserving compaction
 *
 * Built-in pi compaction serializes the old conversation into a single text
 * blob inside a fresh summarization prompt (dedicated system prompt, new
 * routing session id, cache writes disabled) — so the summarization call
 * never reuses the conversation's KV/prompt cache.
 *
 * This extension instead summarizes only the DISCARDED part of the conversation —
 * the entries from the previous kept boundary up to the cut point (pi's native
 * scoping; the kept tail is never re-summarized) — rendered exactly as the main
 * agent loop sends them (same system prompt, same message rendering, same
 * tools, same thinking settings), with one extra user message appended:
 * pi's own summarization prompt (via ctx.modelRegistry.complete()).
 *
 * With an OpenAI-compatible backend that does automatic prefix/KV-cache
 * reuse (vLLM, SGLang, Ollama per-conversation KV reuse, ...), the summary
 * request is a byte-identical prefix-extension of the previous main request:
 *
 *   main request:  [sys, S_prev, m1 ... mK]                  -> fully cached
 *   summary req:   [sys, S_prev, m1 ... mCut, "summarize"]   -> cache hit up to mCut;
 *                                                            only the instruction prefilled
 *   next main req: [sys, S_new, kept tail ...]               -> ONE full cache miss,
 *                                                            then re-cached
 *
 * (S_prev = previous compaction summary, if any — it is included in the summary
 * request so the LLM consolidates the old checkpoint instead of dropping it.)
 *
 * Net effect: the summary call costs only the uncached tail + the instruction
 * (tokens), and compaction causes exactly one cache invalidation — the new
 * summarized context.
 *
 * For MID-RUN compaction (pi >= 0.84.4 compacts between tool results and the
 * next assistant response, and trigger_handoff below compacts at the same
 * boundary), the summary request additionally contains the last turn's
 * assistant message + part of its tool results, which the last main request
 * did not include yet. The last main request is still a byte-identical prefix
 * of the summary request, so the cache hit covers the whole previous main
 * prompt; only that fresh tail + the instruction prefills.
 *
 * ## Kent-style handoff (trigger_handoff)
 *
 * A `trigger_handoff` tool lets the agent compact at a natural checkpoint,
 * mid-run: right after the tool batch that called it, before the next
 * assistant response (pi >= 0.85). The summarization then uses Kent's
 * handoff prompt instead of pi's checkpoint prompt, the summary is prefixed
 * with Kent's continuation framing ("You are continuing an existing task
 * after a handoff..."), and the tool's `future_agent_message` (if given) is
 * delivered to the next agent as a display:false user message prefixed with
 * "Here's the message from previous agent: ", starting the following turn.
 *
 * Context-usage warnings (default: 80/90/95% of the auto-compaction
 * threshold, i.e. of contextWindow - reserveTokens) are injected as custom
 * messages (pi.sendMessage, never pi.sendUserMessage — that would start a
 * turn). While the agent is running they are queued as
 * steering (delivered before the next assistant response, no new turn); while
 * idle they are appended directly (no turn). They are appended at the TAIL of
 * the context, so they do not disturb prefix identity. They are display:true,
 * rendered in the TUI by the pi-context-warning message renderer as a compact
 * one-liner (remaining-warning count, remaining levels as % of the TOTAL
 * context window, "last warning" for the final level); the agent still
 * receives the full instructional text (count only — no percents, so the
 * levels cannot suggest false headroom).
 * The first warning also ARMS trigger_handoff (Kent's soon-reminder gating);
 * before that the tool refuses with guidance.
 *
 * ## Requirements / caveats
 * - Requires pi >= 0.84.4 for mid-run auto-compaction (trigger_handoff works
 *   on any recent pi, but only 0.84.4+ compacts between tool calls).
 * - The backend must reuse KV across requests for identical prefixes.
 *   Verify via usage.cacheRead (pi parses prompt_tokens_details.cached_tokens)
 *   or server-side metrics.
 * - Do NOT enable the agent-compact extension at the same time (both hook
 *   session_before_compact; the last loaded wins).
 * - Avoid other extensions that mutate per-turn messages (context event) or
 *   the system prompt per turn (before_agent_start) — that breaks prefix identity.
 * - The summary request's transcript head is the previous compaction entry's
 *   stored system message (pi >= 0.86 stores the full prompt + tool state on
 *   every compaction entry; the main loop sends it as the transcript head). The
 *   extension must not additionally pass its own systemPrompt — pi would fold
 *   the stored sections onto the text and render the prompt twice, so only the
 *   first copy would match the KV cache. The first compaction (no stored head)
 *   falls back to the current system prompt + tools.
 * - The summary request is a prefix of the last main request, so it fits in
 *   the window by construction.
 * - reserveTokens is read from pi's settings (project .pi/settings.json
 *   overrides global ~/.pi/agent/settings.json; default 16384), so the
 *   warning thresholds track any user-set value automatically.
 */

import type { ExtensionAPI, ExtensionContext, SessionEntry } from "@earendil-works/pi-coding-agent";
import { CONFIG_DIR_NAME, convertToLlm, getAgentDir, getLatestCompactionEntry, sessionEntryToContextMessages } from "@earendil-works/pi-coding-agent";
import { clampThinkingLevel } from "@earendil-works/pi-ai";
import type { Tool } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import { Text } from "@earendil-works/pi-tui";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// Kent's handoff prompts (verbatim from Kent, except the reference to Kent's
// own "Desired oververbosity" / "analysis channel" settings, which don't
// exist in pi). The summarization prompt replaces pi's prompts for handoff
// compactions; the prefix is prepended to the resulting summary so the next
// agent reads it as a continuation, not a fresh start.
const KENT_COMPACTION_PROMPT = `Create a continuation summary for the next agent that resumes this task after a handoff. Output the summary as your entire next response. Do not continue the task, call tools, address the user, add acknowledgements or formatting.

The continuing agent will receive this summary and share the current workspace, but will not have the earlier conversation context or tool call outputs. Give them enough context to continue toward the original user goal without repeating completed work or asking the user to restate prior decisions. Prefer a well-organized summary that preserves all continuation-critical context. Favor actionable state and decision context over chronology.

Include the following when relevant:
- The original user goal, desired outcome, acceptance criteria.
- Explicit user requests, preferences, corrections, and design decisions that still constrain the work. Preserve relevant decisions from earlier handoffs; newer user guidance takes precedence.
- What is done, what is in progress, what remains, and the exact point where work stopped.
- The architecture, invariants, interfaces, files, symbols, commands, or external systems the next agent needs to understand before acting. Point to source files instead of reproducing information already available there.
- Workspace changes already made and their intent, including important added, modified, or deleted files. Distinguish your changes from pre-existing or user-owned changes when known.
- Verification already performed, its results, known failures, and checks still required.
- Unresolved questions, assumptions, blockers, risks, edge cases, intentional shortcuts, or consequential mistakes that could affect the remaining work.
- Concrete next steps in a sensible order, or a pointer to the location of the plan that tracks overall task progress. Base them on the existing task and current evidence; do not invent scope or speculative work.
- Known issues with, limitations of, and edge cases in your or prior work product the next agent or user might need to know about/address.

Make the continuation state trustworthy:
- Use specific paths, code symbols, commands, and observed results where they help the next agent act.
- Distinguish verified facts and user decisions from assumptions or recommendations.
- Preserve important reasoning behind non-obvious decisions, especially rejected alternatives the next agent might otherwise revisit.
- Do not repeat generic project instructions or documentation that the next agent can read from the environment.
- Omit routine tool history, resolved dead ends, harmless failed commands, apologies, and self-evaluation unless they contain a lesson needed to avoid repeating a problem.
- Do not imply that work is complete when implementation or verification remains. If no work remains, say so and record the final verification state.
- Do not follow verbosity instructions that apply outside of this task; be as verbose or terse as this handoff requires.
- Do not include any overall document headers like "# HANDOFF".
- Your handoff will not be exposed to users; it will only be used as an internal document for the next agent.

A good summary may be short for a simple task or detailed for a complex one. It is complete when the next agent can identify the correct next action, preserve prior decisions, overall goal or task, and completed work, then continue without reconstructing the conversation.

Your response will be directly provided to the next agent. You won't get any messages after your response. If you call a tool, the next agent won't get summary and you won't get tool result. Do not continue task, provide summary only.`;

const KENT_SUMMARY_PREFIX = `You are continuing an existing task after a handoff from the previous agent.

You received a handoff from the previous agent and are continuing their work. Continue the active task from the retained context and shared workspace. Preserve the user's original objective, subsequent corrections, decisions, constraints, and remaining work; the latest message does not automatically replace earlier requests. Reuse completed work and verification unless new evidence makes them stale.

Here is the handoff summary:`;

/**
 * pi's default compaction.reserveTokens (settings-manager: `?? 16384`).
 */
const DEFAULT_RESERVE_TOKENS = 16384;

/**
 * Read pi's effective compaction.reserveTokens the same layered way pi does
 * (settings-manager.js): project <cwd>/.pi/settings.json overrides global
 * <agentDir>/settings.json. Paths come from pi's own getAgentDir()/
 * CONFIG_DIR_NAME; only the file read itself is re-implemented —
 * instantiating a second SettingsManager would take proper-lockfile locks
 * on both files at construction (contention → silently empty settings →
 * wrong default) and would be a stale snapshot relative to pi's live
 * instance. Missing/invalid files or values fall through to the next layer,
 * finally to pi's default.
 */
function getCompactionReserveTokens(cwd: string): number {
	return (
		readCompactionReserve(join(cwd, CONFIG_DIR_NAME, "settings.json")) ??
		readCompactionReserve(join(getAgentDir(), "settings.json")) ??
		DEFAULT_RESERVE_TOKENS
	);
}

function readCompactionReserve(path: string): number | undefined {
	try {
		const parsed: unknown = JSON.parse(readFileSync(path, "utf8").replace(/^\uFEFF/, ""));
		const value = (parsed as { compaction?: { reserveTokens?: unknown } } | null)?.compaction?.reserveTokens;
		return typeof value === "number" && Number.isFinite(value) && value > 0 ? value : undefined;
	} catch {
		return undefined;
	}
}

/**
 * Context-usage warning levels, as fractions of the auto-compaction threshold
 * (contextWindow - reserveTokens). The first level that fires also arms
 * trigger_handoff. Tune as needed.
 */
const WARNING_LEVELS = [0.75, 0.825, 0.875, 0.95];

/** Warning levels still to come after `level` (ascending). */
function remainingLevels(level: number): number[] {
	return WARNING_LEVELS.filter((l) => l > level);
}

/**
 * A warning level as a percent of the TOTAL context window: levels are
 * fractions of the auto-compaction threshold (contextWindow - reserveTokens),
 * so scale by (contextWindow - reserveTokens) / contextWindow for display.
 */
function levelWindowPercent(level: number, contextWindow: number, reserveTokens: number): number {
	return Math.round(level * ((contextWindow - reserveTokens) / contextWindow) * 100);
}

/** "1 more warning" / "2 more warnings". */
function moreWarnings(n: number): string {
	return `${n} more ${n === 1 ? "warning" : "warnings"}`;
}

/**
 * Minimal re-implementation of pi's file-ops extraction, so cumulative file
 * tracking (`details` on the compaction entry) keeps working across compactions.
 *
 * Why this and formatFileOperations() below are copies instead of imports:
 * pi's compaction helpers (extractFileOperations, formatFileOperations, the
 * summarization prompts) are internal — they are not in the package's public
 * index, the extension loader only aliases the package root, and the
 * exports map blocks deep imports. These are verbatim copies of pi's
 * implementation; keep them in sync if pi changes them.
 */
function extractFileDetails(messages: unknown[]): { readFiles: string[]; modifiedFiles: string[] } {
	const read = new Set<string>();
	const modified = new Set<string>();
	for (const msg of messages) {
		if (!msg || (msg as { role?: string }).role !== "assistant") continue;
		const content = (msg as { content?: unknown }).content;
		if (!Array.isArray(content)) continue;
		for (const block of content) {
			if (block?.type !== "toolCall" || typeof block.arguments !== "object" || block.arguments === null) continue;
			const path = (block.arguments as { path?: unknown }).path;
			if (typeof path !== "string") continue;
			if (block.name === "read") read.add(path);
			else if (block.name === "write" || block.name === "edit") modified.add(path);
		}
	}
	const modifiedFiles = [...modified].sort();
	const readFiles = [...read].filter((f) => !modified.has(f)).sort();
	return { readFiles, modifiedFiles };
}

/**
 * Merge this compaction's file ops with the previous checkpoint's, the same way
 * pi's built-in extractFileOperations does (readFiles excludes modifiedFiles).
 */
function mergeFileDetails(
	prev: unknown,
	next: { readFiles: string[]; modifiedFiles: string[] },
): { readFiles: string[]; modifiedFiles: string[] } {
	const p = (prev ?? {}) as { readFiles?: string[]; modifiedFiles?: string[] };
	const read = new Set([...(p.readFiles ?? []), ...next.readFiles]);
	const modified = new Set([...(p.modifiedFiles ?? []), ...next.modifiedFiles]);
	return {
		readFiles: [...read].filter((f) => !modified.has(f)).sort(),
		modifiedFiles: [...modified].sort(),
	};
}

/**
 * Format file operations as XML tags appended to the summary, exactly like pi's
 * built-in compaction does.
 */
function formatFileOperations(readFiles: string[], modifiedFiles: string[]): string {
	const sections: string[] = [];
	if (readFiles.length > 0) {
		sections.push(`<read-files>\n${readFiles.join("\n")}\n</read-files>`);
	}
	if (modifiedFiles.length > 0) {
		sections.push(`<modified-files>\n${modifiedFiles.join("\n")}\n</modified-files>`);
	}
	if (sections.length === 0) return "";
	return `\n\n${sections.join("\n\n")}`;
}

export default function (pi: ExtensionAPI) {
	// Per-session state (the extension is loaded once per session).
	let handoff: {
		summarizerPrompt?: string;
		futureAgentMessage?: string;
		triggered: boolean;
	} | null = null;
	const warnedLevels = new Set<number>();

	/**
	 * Inject a context-usage warning without triggering an agent turn:
	 * custom message, never pi.sendUserMessage (which always starts a turn).
	 * While running: queued as steering (delivered before the next assistant
	 * response). While idle: appended directly. Both land at the tail of the
	 * context, so prefix identity is preserved.
	 */
	const warn = (
		text: string,
		warning: { level: number; pct: number; remainingPcts: number[] },
		ctx: ExtensionContext,
	) => {
		const msg = {
			customType: "pi-context-warning",
			content: [{ type: "text" as const, text: `<SYSTEM_WARNING>\n${text}\n</SYSTEM_WARNING>` }],
			// The agent sees the full content in context; the TUI shows the
			// compact one-liner from the pi-context-warning message renderer
			// (display only affects UI rendering, never the LLM payload).
			display: true,
			// details never reach the LLM (verified); the message renderer
			// reads level/pct/remainingPcts to build the user-facing one-liner.
			details: { extension: "prefix-compaction", ...warning },
		};
		if (ctx.isIdle()) {
			pi.sendMessage(msg, { triggerTurn: false });
		} else {
			pi.sendMessage(msg, { deliverAs: "steer" });
		}
	};

	/**
	 * Current context tokens vs the auto-compaction threshold
	 * (contextWindow - reserveTokens from pi's settings), or null when usage
	 * is unknown (e.g. right after a compaction).
	 */
	const getCompactionThreshold = (ctx: ExtensionContext) => {
		const usage = ctx.getContextUsage();
		if (!usage || usage.tokens === null || usage.contextWindow <= 0) return null;
		const reserveTokens = getCompactionReserveTokens(ctx.cwd);
		const threshold = usage.contextWindow - reserveTokens;
		if (threshold <= 0) return null;
		return { tokens: usage.tokens, contextWindow: usage.contextWindow, reserveTokens, threshold };
	};

	// Warn at 80/90/95% of the auto-compaction threshold (contextWindow -
	// reserveTokens), at most once per level per compaction cycle.
	const checkWarnings = (ctx: ExtensionContext) => {
		const usage = getCompactionThreshold(ctx);
		if (!usage) return;
		const pct = Math.round((usage.tokens / usage.contextWindow) * 100);
		for (const level of WARNING_LEVELS) {
			if (usage.tokens >= usage.threshold * level && !warnedLevels.has(level)) {
				warnedLevels.add(level);
				const first = warnedLevels.size === 1;
				const remaining = remainingLevels(level);
				const last = remaining.length === 0;
				const warning = {
					level,
					pct,
					remainingPcts: remaining.map((l) => levelWindowPercent(l, usage.contextWindow, usage.reserveTokens)),
				};
        let message: string
        if (first) {
          message = `Heads-up: you're approaching your working memory limit and will soon be asked to hand off your work to another agent. This should not change the quality or scope of your work. The \`trigger_handoff\` tool is now armed; use it to trigger a handoff proactively at a time that is convenient for the other agent to continue after you, such as before starting the next chunk of work, after a local checkpoint or commit, or before working on the next user request. Before handoff, consider persisting or updating plans and checklists. If you do not use the tool, the context will still be compacted automatically once it fills up, possibly degrading quality of your work. You will get ${moreWarnings(remaining.length)} more warnings; do not wait until the last one - at that point you will not be able to update plans and checklists.`;
        } else if(last) {
          message = `This is the last warning: you have reached context limit. You MUST hand off NOW by calling \`trigger_handoff\` tool without updating plans and checklists, which can still be done by summarizer guided with \`summarizer_prompt\`.`
        } else {
          message = `Context usage is nearing the limit — the automatic compaction threshold is close. If you have not called \`trigger_handoff\` yet, do so at the next natural checkpoint (after finishing a chunk of work, after a commit, or before starting the next chunk). This is warning ${WARNING_LEVELS.indexOf(level) + 1} of ${WARNING_LEVELS.length}, with ${moreWarnings(remaining.length)} to come.`
        }

				// TODO run only one warn, it might do three at once
				warn(
					message,
					warning,
					ctx,
				);
			}
		}
	};

	// User-facing rendering of the warning messages: the agent keeps the full
	// instructional content, the TUI shows a compact one-liner with the
	// remaining-warning count (remaining levels as % of the TOTAL context
	// window) and "last warning" for the final level.
	// details (never sent to the LLM) carries level, the usage percent, and
	// the remaining levels' percents — all computed at warn time.
	pi.registerMessageRenderer("pi-context-warning", (message, _options, theme) => {
		const details = (message.details ?? undefined) as
			| { level?: number; pct?: number; remainingPcts?: number[] }
			| undefined;
		if (typeof details?.level !== "number") return undefined;
		const pct = typeof details.pct === "number" ? details.pct : Math.round(details.level * 100);
		const remainingPcts = (details.remainingPcts ?? []).filter((p) => typeof p === "number");
		// Pre-remainingPcts messages (reloaded from an older session): count
		// only, no percents.
		const remainingCount = remainingPcts.length > 0 ? remainingPcts.length : remainingLevels(details.level).length;
		let line = `Agent reached ${pct}% context length and got warned`;
		if (remainingCount === 0) {
			line += " — this is the last warning";
		} else if (remainingPcts.length > 0) {
			line += ` — ${moreWarnings(remainingCount)} (${remainingPcts.map((p) => `${p}%`).join(", ")})`;
		} else {
			line += ` — ${moreWarnings(remainingCount)}`;
		}
		if (details.level === WARNING_LEVELS[0]) line += " — trigger_handoff armed";
		return new Text(theme.fg("accent", line), 0, 0);
	});

	pi.registerMessageRenderer("future-agent-message", (message, _options, theme) => {
		return new Text(theme.fg("success", "Handoff completed - sending future agent message to continue work"), 0, 0);
	});

	// Restore warnedLevels after a session reload/resume/fork: warnings fire
	// at every turn_end (pi emits turn_end for aborted and errored turns too,
	// not just completed ones) and usage only grows within a compaction cycle,
	// so at session start every level the current usage has crossed was
	// already warned. (Only gap: a mid-turn process crash never warns; the
	// rebuild then suppresses that one redundant warning — arming stays
	// correct because usage >= level.)
	pi.on("session_start", (event, ctx) => {
		if (event.reason === "new") return;
		warnedLevels.clear();
		const usage = getCompactionThreshold(ctx);
		if (!usage) return;
		for (const level of WARNING_LEVELS) {
			if (usage.tokens >= usage.threshold * level) warnedLevels.add(level);
		}
	});

	// Context-usage warnings + handoff trigger, after every completed turn.
	pi.on("turn_end", (event, ctx) => {
		// Handoff: compact right after this tool batch, before the next
		// assistant response (ctx.compact() aborts the run first, runs the
		// compaction, then the future_agent_message — if any — starts the
		// following turn).
		if (handoff && !handoff.triggered) {
			handoff.triggered = true; // TODO this might not be needed
			const handoffRef = handoff;
			// The future message is delivered from onComplete (not here, not from
			// session_compact): compact() resolves before the triggering run has
			// fully ended, and a message sent earlier would be picked up by the
			// dying run's steering queue and aborted with it.
			ctx.compact({
				customInstructions: handoffRef.summarizerPrompt,
				onComplete: () => {
					warnedLevels.clear();
					// Hidden from the TUI: the next agent sees it as its first user
					// message; the user does not need to read it.
					if (handoffRef.futureAgentMessage) {
						pi.sendMessage(
							{
								customType: "future-agent-message",
								content: [{ type: "text" as const, text: "Here's the message from previous agent:\n\n" + handoffRef.futureAgentMessage }],
								display: false,
								details: { extension: "prefix-compaction" },
							},
							{ triggerTurn: true },
						);
					}
					handoff = null;
				},
			});
		} else {
			checkWarnings(ctx);
		}
	});


	// trigger_handoff tool (Kent's contract).
	pi.registerTool({
		name: "trigger_handoff",
		label: "Trigger handoff",
		description: `Trigger a handoff: immediately after this tool batch, the conversation is compacted and a continuation summary is written for the next agent, which has no memory of this conversation. Use it at a natural checkpoint: after finishing a chunk of work, after a commit or local checkpoint, or before starting the next chunk of work. Only works after a context-usage warning has been issued (the context is filling up). Call it as the only tool in the batch so the run terminates cleanly. Before calling it, make sure plans/checklists and workspace state are up to date.
Parameters:
- summarizer_prompt: extra guidance for the summarizer (optional)
- future_agent_message: a concise message forwarded verbatim to the next agent after compaction (optional)`,
		parameters: Type.Object({
			summarizer_prompt: Type.Optional(Type.String()),
			future_agent_message: Type.Optional(Type.String()),
		}),
		async execute(_toolCallId, params, _signal, _onUpdate) {
			if (handoff) {
				return {
					content: [{ type: "text", text: "Handoff already scheduled; it will run right after this tool batch." }],
					details: { outcome: "already-scheduled" },
				};
			}
			if (warnedLevels.size === 0) {
				return {
					content: [
						{
							type: "text",
							text: "Handoff not armed yet: no context-usage warning has been issued, so the context is not close to the limit. Keep working; the tool arms automatically once context usage crosses the first warning level.",
						},
					],
					details: { outcome: "not-armed" },
					isError: true,
				};
			}
			handoff = {
				summarizerPrompt: params.summarizer_prompt?.trim() || undefined,
				futureAgentMessage: params.future_agent_message?.trim() || undefined,
				triggered: false,
			};
			const parts = ["Handoff scheduled: the conversation will be compacted right after this tool batch, before your next response."];
			if (handoff.futureAgentMessage) {
				parts.push("Your future_agent_message will be forwarded verbatim to the next agent after compaction.");
			}
			parts.push("The next agent has no memory of this conversation and will continue from the handoff summary, so make sure the workspace state and any plans/checklists are up to date.");
			return {
				content: [{ type: "text", text: parts.join(" ") }],
				details: { outcome: "scheduled" },
				// Stop the run after this tool batch: without this, the loop
				// would start a continuation model call that compact()'s abort
				// then kills, leaving an "Error: This operation was aborted"
				// assistant entry in the transcript.
				terminate: true,
			};
		},
		// UI-only rendering (the agent sees only the execute() content above).
		renderCall(args, theme, _ctx) {
			const lines = [theme.fg("toolTitle", theme.bold("trigger_handoff"))];
			if (args.summarizer_prompt) {
				lines.push(theme.fg("toolOutput", `summarizer_prompt: ${args.summarizer_prompt}`));
			}
			if (args.future_agent_message) {
				lines.push(theme.fg("toolOutput", `future_agent_message: ${args.future_agent_message}`));
			}
			return new Text(lines.join("\n"), 0, 0);
		},
		renderResult(result, _options, theme, _ctx) {
			if (result.isError) {
				const text = result.content
					.map((b) => (b.type === "text" ? b.text : ""))
					.join(" ")
					.trim();
				return new Text(theme.fg("warning", text || "Handoff failed"), 0, 0);
			}
			const outcome = (result.details as { outcome?: string } | undefined)?.outcome;
			return new Text(
				theme.fg("success", outcome === "already-scheduled" ? "Handoff already scheduled" : "A handoff has been triggered"),
				0,
				0,
			);
		},
	});

	pi.on("session_before_compact", async (event, ctx) => {
		const { preparation, signal } = event;
		const model = ctx.model;
		if (!model) return; // fall back to built-in summarization

		try {
			// Scope: summarize only the discarded part — entries from the previous
			// kept boundary (or the start) up to the cut point. Same scoping as pi's
			// built-in prepareCompaction(); the kept tail is never re-summarized.
			const branchEntries = event.branchEntries;
			const prev = getLatestCompactionEntry(branchEntries);
			const prevIdx = prev ? branchEntries.findIndex((e) => e.id === prev.id) : -1;
			const boundaryStart = prev
				? (() => {
						const idx = branchEntries.findIndex((e) => e.id === prev.firstKeptEntryId);
						return idx >= 0 ? idx : prevIdx + 1;
					})()
				: 0;
			const firstKeptIdx = branchEntries.findIndex((e) => e.id === preparation.firstKeptEntryId);
			if (firstKeptIdx < 0 || firstKeptIdx <= boundaryStart) return; // nothing to summarize

			// Render exactly the context slice the main loop sends:
			//   [previous compaction summary, if any] + [discarded entries]
			// using pi's own per-entry rendering — a true prefix of the last main
			// request, so the KV cache hits and only the instruction prefills.
			// The slice spans the previous compaction entry itself; it is excluded
			// here because it is already rendered as the first message (pi's
			// buildContextEntries also emits it exactly once — rendering it twice
			// broke prefix identity at ~25K tokens).
			const render = (entries: SessionEntry[]) =>
				convertToLlm(entries.flatMap((e) => sessionEntryToContextMessages(e)));
			const discarded = branchEntries
				.slice(boundaryStart, firstKeptIdx)
				.filter((e) => e.id !== prev?.id);
			const messages = [...(prev ? render([prev]) : []), ...render(discarded)];
			if (messages.length === 0) return;

			// Same tools as the main conversation. Tool definitions are rendered
			// into the prompt by the server, so they must match for prefix identity.
			const active = new Set(pi.getActiveTools());
			const tools: Tool[] = pi
				.getAllTools()
				.filter((t) => active.has(t.name))
				.map((t) => ({ name: t.name, description: t.description, parameters: t.parameters }));

			// Same model, same thinking settings as the main conversation.
			// (For Qwen3 the enable_thinking flag changes the rendered prompt, so it
			// must match the last main request for the prefix to stay valid.)
			const isHandoff = handoff?.triggered === true;
			let instruction: string = KENT_COMPACTION_PROMPT;
      if (prev) {
        instruction +=
          "\n\nA previous handoff summary is provided as the first message, inside <summary> tags: preserve its still-relevant decisions and context, and consolidate the new messages into it.";
      }
      if (event.customInstructions?.trim()) {
        instruction += `\n\nAdditional instructions from the triggering agent:\n${event.customInstructions.trim()}`;
      }

			if (preparation.isSplitTurn && preparation.turnPrefixMessages.length > 0) {
				instruction +=
					"\n\nNote: the conversation above ends mid-turn — its final messages are the prefix of a turn whose remainder is retained verbatim after this summary. Make the retained suffix understandable.";
			}

      let summary;
      let response;

      for(let i = 0; i < 3; i++) {
        response = await ctx.modelRegistry.complete(
          model,
          {
            // system prompt is already in messages
            // systemPrompt: ctx.getSystemPrompt(),
            messages: [...messages, { role: "user", content: [{ type: "text", text: instruction }], timestamp: Date.now() }],
            tools
          },
          {
            // Same output budget as built-in compaction (0.8 * reserveTokens).
            maxTokens: Math.min(
              Math.floor(0.8 * preparation.settings.reserveTokens),
              model.maxTokens > 0 ? model.maxTokens : Number.MAX_SAFE_INTEGER,
            ),
            signal,
            // Full-API options take reasoningEffort (streamSimple's `reasoning`
            // level maps to exactly this), so pass the clamped level.
            reasoningEffort: model.reasoning && ctx.thinkingLevel && ctx.thinkingLevel !== "off" ? clampThinkingLevel(model, ctx.thinkingLevel) : undefined,
            sessionId: ctx.sessionManager.getSessionId(),
            // Deliberately NOT cacheRetention: "none" — we WANT the prefix served
            // from cache and the post-compaction context written back to cache.
          },
        );

        summary = response.content
          .filter((b): b is { type: "text"; text: string } => b.type === "text")
          .map((b) => b.text)
          .join("\n")
          .trim();

        if (!summary || response.stopReason === "error" || response.stopReason === "length") {
          if (ctx.hasUI) ctx.ui.notify("Custom summary failed, retrying", "warning");
          continue;
        }
        break;
      }

      if (!summary) {
        if (ctx.hasUI) ctx.ui.notify("Custom summary failed repeatedly, falling back to built-in compaction", "warning");
        return;
      }

			// Handoff compactions get Kent's continuation framing in front of the
			// summary, so the next agent reads it as a handoff, not a fresh start.
			if (isHandoff) {
				summary = `${KENT_SUMMARY_PREFIX}\n\n${summary}`;
			}

			// Cumulative file tracking (what pi's built-in stores too): merge this
			// compaction's file ops with the previous checkpoint's.
			const details = mergeFileDetails(
				prev?.details,
				extractFileDetails([...preparation.messagesToSummarize, ...preparation.turnPrefixMessages]),
			);
			// Pi appends the file-operation lists to the summary text itself
			// (its prompts do not ask the model for them).
			summary += formatFileOperations(details.readFiles, details.modifiedFiles);

			if (ctx.hasUI)
				ctx.ui.notify(
					`Compaction summary ready (${response.usage.totalTokens.toLocaleString()} tokens, ${response.usage.cacheRead.toLocaleString()} served from cache)`,
					"info",
				);

			return {
				compaction: {
					summary: summary,
					firstKeptEntryId: preparation.firstKeptEntryId,
					tokensBefore: preparation.tokensBefore,
					usage: response.usage,
					details: details,
				},
			};
		} catch (err) {
			if (!signal.aborted && ctx.hasUI)
				ctx.ui.notify(`Prefix-preserving compaction failed, falling back: ${err instanceof Error ? err.message : String(err)}`, "error");
			return; // fall back to built-in summarization
		}
	});

	// Compaction failed: drop the pending handoff (the context is intact; the
	// agent or user can re-trigger once armed again).
	pi.on("session_compact_failed", () => {
		if (handoff?.triggered) handoff = null;
	});
}
