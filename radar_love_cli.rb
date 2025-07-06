class RadarLoveCli < Formula
  desc "CLI toolkit for simulating secret leaks and triggering GitHub PR scans"
  homepage "https://github.com/raymonepping/radar_love_cli"
  url "https://github.com/raymonepping/radar_love_cli/archive/refs/tags/v1.2.1.tar.gz"
  sha256 "c795641e7562b068e7b8b616eb4768c1421f3551682e567f14d358fce317d984"
  license "MIT"
  version "1.2.1"

  depends_on "bash"

  def install
    bin.install "bin/radar_love"

    # Install folders used by the CLI at runtime
    pkgshare.install "core", "templates"

    # Optionally include README or other docs
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
