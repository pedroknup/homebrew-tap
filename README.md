# pedroknup/homebrew-tap

```sh
brew tap pedroknup/tap
brew trust pedroknup/tap
brew install --cask snapdesk
```

SnapDesk needs Accessibility permission: System Settings → Privacy & Security → Accessibility.

Releasing: `scripts/release-snapdesk.sh <version>` (needs the Developer ID cert and a `snapdesk-notary` notarytool profile).
