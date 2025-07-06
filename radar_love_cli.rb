class RadarLoveCli < Formula
  desc "CLI toolkit for simulating secret leaks and triggering GitHub PR scans"
  homepage "https://github.com/raymonepping/radar_love_cli"
  url "https://github.com/raymonepping/radar_love_cli/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "<TO_BE_FILLED_AFTER_RELEASE>"
  license "MIT"
  version "1.2.0"

  depends_on "bash"

  def install
    bin.install "bin/radar_love"
    prefix.install Dir["core", "templates", "README.md"]
  end

  test do
    system "#{bin}/radar_love", "--version"
  end
end
