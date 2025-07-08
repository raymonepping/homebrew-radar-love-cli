class RadarLoveCli < Formula
  desc "CLI toolkit for simulating secret leaks and triggering GitHub PR scans"
  homepage "https://github.com/raymonepping/radar_love_cli"
  url "https://github.com/raymonepping/homebrew-radar-love-cli/archive/refs/tags/v2.0.2.tar.gz"
  sha256 "f9b170cf1a7962f4dda68b6b4db32191b3b3354f9d7393985e7463d3eb790ce2"
  license "MIT"
  version "2.0.2"

  depends_on "bash"

  def install
    bin.install "bin/radar_love" => "radar_love"
    pkgshare.install "core", "templates"
    doc.install "README.md"
  end

  def caveats
    <<~EOS
      To get started, run:
        radar_love --help

      The core scripts and templates are located in:
        #{opt_pkgshare}

      If you need to reference them directly in your scripts, use:
        export RADAR_LOVE_HOME=#{opt_pkgshare}
    EOS
  end

  test do
    assert_match "radar_love", shell_output("#{bin}/radar_love --version")
  end
end
