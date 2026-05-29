{ flake, pkgs, ... }: {
  environment.systemPackages = [
    (with flake.pkgs.fenix; combine [
      stable.cargo
      stable.rustc
      stable.rust-src
      targets."riscv32imc-unknown-none-elf".stable.rust-std
    ])
    pkgs.espflash
  ];
}