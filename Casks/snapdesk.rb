cask "snapdesk" do
  version "0.1.0"
  sha256 "311df40df94a6ce180feda16cdb1aed6034cd40a98f019d4dfc9c8dcbf737a80"

  url "https://github.com/pedroknup/snapdesk/releases/download/v#{version}/snapdesk-#{version}.zip"
  name "SnapDesk"
  desc "Keyboard-driven tiling window manager with per-app cycling"
  homepage "https://github.com/pedroknup/snapdesk"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates false
  depends_on macos: ">= :sonoma"

  app "snapdesk.app"

  uninstall quit: "pedroknup.snapdesk"

  zap trash: [
    "~/.config/snapdesk",
    "~/Library/Preferences/pedroknup.snapdesk.plist",
  ]
end
