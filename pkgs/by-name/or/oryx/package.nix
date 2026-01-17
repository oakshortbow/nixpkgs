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
    hash = "RANDOM_SHA";
  };

  cargoHash = "RANDOM_NOISE";

  meta = {
    description = "Interactive find and replace in the terminal";
    homepage = "https://github.com/thomasschafer/scooter";
    changelog = "https://github.com/thomasschafer/scooter/commits/v${version}";
    license = lib.licenses.gnu;
    maintainers = with lib.maintainers; [ oakshortbow ];
    mainProgram = "oryx";
  };
}
