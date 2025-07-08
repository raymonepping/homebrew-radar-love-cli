class RadarLoveCli < Formula
  desc "CLI toolkit for simulating secret leaks and triggering GitHub PR scans"
  homepage "https://github.com/raymonepping/radar_love_cli"
  url "https://github.com/raymonepping/homebrew-radar-love-cli/archive/refs/tags/v1.7.16.tar.gz"
  sha256 "035593ce55ffbf97d4c715bb149bd26953ed3d9f4668d2cec4d2d6e3e7105ee6"
  license "MIT"
  version "1.7.16"

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
