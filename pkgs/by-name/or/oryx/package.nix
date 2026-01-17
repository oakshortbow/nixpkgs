{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "oryx";
  version = "0.7.2";

  src = fetchFromGitHub {
    owner = "pythops";
    repo = "oryx";
    rev = "v${version}";
    hash = "sha256-f3bKfc1M2LBLrFv5gHhNP8PmIDIQi8WcJZ01z7MEnq8=";
  };

  cargoHash = "sha256-u4Hu924dEBGzSZ2ywISxzuh4PK5LX8O/mEFgMBtYnf0=";
  # Oryx depends on trivial_bounds unstable feature
  env.RUSTC_BOOTSTRAP = 1;
  buildPhase = ''
    cargo xtask build --release
  '';
  meta = {
    description = "Interactive find and replace in the terminal";
    homepage = "https://github.com/pythops/oryx";
    changelog = "https://github.com/pythops/oryx/commits/v${version}";
    license = lib.licenses.fdl13Plus;
    maintainers = with lib.maintainers; [ oakshortbow ];
    mainProgram = "oryx";
  };
}
