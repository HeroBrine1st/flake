{ spotify, stdenv, rustPlatform, pkgs }: spotify.overrideAttrs (
    old: {
      postInstall =
        (old.postInstall or "")
        + ''
          mkdir spotify-xpui
          mv $out/share/spotify/Apps/xpui.spa .
          ${pkgs.unzip}/bin/unzip -qq xpui.spa -d spotify-xpui/
          
          cd spotify-xpui/
          ${pkgs.perl}/bin/perl -pi -w -e 's|adsEnabled:!0|adsEnabled:!1|' xpui.js
          #${pkgs.perl}/bin/perl -pi -w -e 's|allSponsorships||' xpui.js
          #${pkgs.perl}/bin/perl -pi -w -e 's/(return|.=.=>)"free"===(.+?)(return|.=.=>)"premium"===/$1"premium"===$2$3"free"===/g' xpui.js
          #${pkgs.perl}/bin/perl -pi -w -e 's/(case .:|async enable\(.\)\{)(this.enabled=.+?\(.{1,3},"audio"\),|return this.enabled=...+?\(.{1,3},"audio"\))((;case 4:)?this.subscription=this.audioApi).+?this.onAdMessage\)/$1$3.cosmosConnector.increaseStreamTime(-100000000000)/' xpui.js
          #${pkgs.perl}/bin/perl -pi -w -e 's|(Enables quicksilver in-app messaging modal",default:)(!0)|$1false|' xpui.js
          #${pkgs.perl}/bin/perl -pi -w -e 's/(\.WiPggcPDzbwGxoxwLWFf\s*{)/$1 height: 0;/;' home-hpto.css

          ${pkgs.zip}/bin/zip -qq -r xpui.spa .
          mv xpui.spa $out/share/spotify/Apps/xpui.spa
          cd ..
          rm xpui.spa

          sed -i 's/Exec=spotify %U/Exec=spotify --uri=%U/g' "$out/share/applications/spotify.desktop"
        '';
    }
  )
