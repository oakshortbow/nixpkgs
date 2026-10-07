{
  lib,

  buildGo127Module, # go.mod requires go >= 1.27.1
  fetchFromGitHub,
  versionCheckHook,

  callPackage,

  nixosTests,
  nix-update-script,

  withUI ? true,
}:

buildGo127Module (finalAttrs: {
  pname = "llama-swap";
  version = "262";

  outputs = [
    "out"
    "wol" # wake on lan proxy
  ];

  # Git fetch (rather than the default tarball) so postFetch can record the
  # rev's commit and date; these are injected into the -version banner in
  # preBuild. The hash is of the checkout after postFetch has run.
  src = fetchFromGitHub {
    owner = "mostlygeek";
    repo = "llama-swap";
    # main HEAD (2026-10-03) rather than the v262 tag: main is v262 plus the
    # capcompat default prober (#1198), which detects OpenAI-compatible
    # upstreams the v262 probers don't cover (ninfer-serve among them).
    # Re-pin to the first release tag containing the prober once it cuts.
    rev = "783c3232fbe5e7588d3e667e2933579f11538d3d";
    forceFetchGit = true;
    leaveDotGit = true;
    postFetch = ''
      cd "$out"
      git rev-parse HEAD > $out/COMMIT
      date -u -d "@$(git log -1 --pretty=%ct)" '+%Y-%m-%dT%H:%M:%SZ' > $out/SOURCE_DATE_EPOCH
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
    hash = "sha256-RJqShI9z/Q3p+oaFgTwPUP3omRbZvsubpUkgRkHILG8=";
  };

  vendorHash = "sha256-yelob7FlaGymASUP0DAUkALQm5vnXZnN5ThbnSkH2Ak=";

  # Upstream only embeds the UI when this build tag is set.
  tags = lib.optionals withUI [ "embed_ui" ];

  passthru.ui = callPackage ./ui.nix { llama-swap = finalAttrs.finalPackage; };

  nativeBuildInputs = [
    versionCheckHook
  ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  preBuild = ''
    # ldflags from the commit and date recorded by src's postFetch
    ldflags+=" -X main.commit=$(cat COMMIT)"
    ldflags+=" -X main.date=$(cat SOURCE_DATE_EPOCH)"

    ${lib.optionalString withUI ''
      # copy for go:embed in internal/server/embed.go
      cp -r ${finalAttrs.passthru.ui}/ui_dist internal/server/
    ''}
  '';

  excludedPackages = [
    # test and dev tools (see cmd/); wol-proxy is kept for the `wol` output
    "cmd/fake-model"
    "cmd/kubeswap"
    "cmd/misc"
    "cmd/monitor-test"
    "cmd/simple-responder"
    "cmd/test-concurrency"
    "cmd/vllm-wrapper"
  ];

  # The upstream test suite needs cmd/simple-responder and network access;
  # upstream runs it in CI.
  doCheck = false;

  postInstall = ''
    install -Dm444 -t "$out/share/llama-swap" config.example.yaml
    mkdir -p "$wol/bin"
    mv "$out/bin/wol-proxy" "$wol/bin/"
  '';

  doInstallCheck = true;
  versionCheckProgramArg = "-version";

  passthru.tests.nixos = if withUI then nixosTests.llama-swap.full else nixosTests.llama-swap.minimal;
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--subpackage"
      "ui"
    ];
  };

  __structuredAttrs = true;

  meta = {
    homepage = "https://github.com/mostlygeek/llama-swap";
    changelog = "https://github.com/mostlygeek/llama-swap/releases/tag/v${finalAttrs.version}";
    description = "Model swapping for llama.cpp (or any local OpenAPI compatible server)";
    longDescription = ''
      llama-swap is a light weight, transparent proxy server that provides
      automatic model swapping to llama.cpp's server.

      When a request is made to an OpenAI compatible endpoint, llama-swap will
      extract the `model` value and load the appropriate server configuration to
      serve it. If the wrong upstream server is running, it will be replaced
      with the correct one. This is where the "swap" part comes in. The upstream
      server is automatically swapped to the correct one to serve the request.

      In the most basic configuration llama-swap handles one model at a time.
      For more advanced use cases, the `groups` feature allows multiple models
      to be loaded at the same time. You have complete control over how your
      system resources are used.
    '';
    license = lib.licenses.mit;
    mainProgram = "llama-swap";
    maintainers = with lib.maintainers; [
      jk
      podium868909
    ];
  };
})
