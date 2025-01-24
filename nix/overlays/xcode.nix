final: prev: {
  darwin = prev.darwin.overrideScope (
    final: prev: {
      xcode_16_2 = prev.xcode.overrideAttrs (prev: {
        outputHash = "sha256-hMxBGFyF3CvP+HjAbwMeIxOjA+HkA+HVe8uVHs/2PNc=";
      });
      xcode = final.xcode_16_2;
    }
  );
}
