class RadarLoveCli < Formula
  desc "CLI toolkit for simulating secret leaks and triggering GitHub PR scans"
  homepage "https://github.com/raymonepping/radar_love_cli"
  url      "https://github.com/raymonepping/radar_love_cli/archive/refs/tags/v1.0.0.tar.gz"
  sha256   "9731be25ab825ed6ddfc97ef5601dc4add17462714bddcfbf71b71acd6a6e3e1"
  license "MIT"
  version  "1.0.0"

  depends_on "bash"

  def install
    bin.install "bin/radar_love"
    prefix.install Dir["core", "templates", "README.md"]
  end

  test do
    system "#{bin}/radar_love", "--version"
  end
end
