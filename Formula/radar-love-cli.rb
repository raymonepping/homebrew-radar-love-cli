class RadarLoveCli < Formula
  desc "CLI toolkit for simulating secret leaks and triggering GitHub PR scans"
  homepage "https://github.com/raymonepping/radar_love_cli"
  url "https://github.com/raymonepping/homebrew-radar-love-cli/archive/refs/tags/v1.7.12.tar.gz"
  sha256 "f2f65ada932fcca2941f123bbb21fb821cf84f2a6db1ab21789b89e3b77d598e"
  license "MIT"
  version "1.7.12"

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
