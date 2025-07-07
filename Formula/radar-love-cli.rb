class RadarLoveCli < Formula
  desc "CLI toolkit for simulating secret leaks and triggering GitHub PR scans"
  homepage "https://github.com/raymonepping/radar_love_cli"
  url "https://github.com/raymonepping/homebrew-radar-love-cli/archive/refs/tags/v1.5.18.tar.gz"
  sha256 "09a8e222879f87548f4c3175fdb30b4583a6cc71c25f24765a49c1692ef3d09e"
  license "MIT"
  version "1.5.18"

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
