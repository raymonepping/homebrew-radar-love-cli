class RadarLoveCli < Formula
  desc "CLI toolkit for simulating secret leaks and triggering GitHub PR scans"
  homepage  "https://github.com/raymonepping/homebrew-radar_love_cli"
  url       "https://github.com/raymonepping/homebrew-radar_love_cli/archive/refs/tags/v1.0.0.tar.gz"
  sha256    "fa5a70a3cc9abab5cd87229f0b4bf32a55c095490cc0021f6f4abe2372334093"

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
