{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.iterm2;
  nordColorScheme = ./iterm2-nord.itermcolors;
in
{
  options.takoeight0821.programs.iterm2 = {
    enable = lib.mkEnableOption "iTerm2 configuration";
  };

  config = lib.mkIf cfg.enable {
    home.activation.iterm2Defaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      /usr/bin/defaults write com.googlecode.iterm2 TabViewType -int 2
      /usr/bin/defaults write com.googlecode.iterm2 EnableAPIServer -bool true

      PLIST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
      if [ -f "$PLIST" ]; then
        /usr/libexec/PlistBuddy -c "Delete ':Custom Color Presets:Nord'" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add ':Custom Color Presets:Nord' dict" "$PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Merge '${nordColorScheme}' ':Custom Color Presets:Nord'" "$PLIST"
        /usr/libexec/PlistBuddy -c "Merge '${nordColorScheme}' ':New Bookmarks:0'" "$PLIST"
      fi
    '';
  };
}
