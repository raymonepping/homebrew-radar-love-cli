class RadarLoveCli < Formula
  desc "CLI toolkit for simulating secret leaks and triggering GitHub PR scans"
  homepage  "https://github.com/raymonepping/homebrew-radar_love_cli"
  url       "https://github.com/raymonepping/homebrew-radar_love_cli/archive/refs/tags/v1.0.0.tar.gz"
  sha256    "d8623900b69ddaba074b1c4781ca6ad3764319a9826e245882abe5883cf275bd"

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
