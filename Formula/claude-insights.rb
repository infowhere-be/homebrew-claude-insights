# Homebrew formula template for claude-insights.
# Auto-updated by the release workflow via update-homebrew-formula.sh.
# Do not edit manually — changes will be overwritten on next release.
#
# Live formula: https://github.com/infowhere-be/homebrew-claude-insights

class ClaudeInsights < Formula
  desc "Real-time dashboard for Claude Code sessions"
  homepage "https://github.com/infowhere-be/claude-monitor"
  version "1.0.0b1"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/infowhere-be/claude-monitor/releases/download/v1.0.0b1/claude-insights-macos-arm64"
      sha256 "5f8b366f9bcd79b972478da74b499fb9e541fa9f519c3d768dad01c7eb2d1c88"
    end
  end

  def install
    bin.install "claude-insights-macos-arm64" => "claude-insights"
  end

  def caveats
    <<~EOS
      To install the Claude Code hook, run:
        claude-insights install

      To start the dashboard:
        claude-insights start

      The dashboard will be available at http://localhost:4000
    EOS
  end

  test do
    assert_match "claude-insights", shell_output("#{bin}/claude-insights --version")
  end
end
