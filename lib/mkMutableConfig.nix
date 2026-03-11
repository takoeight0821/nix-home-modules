{ lib }:

pkgs:
{
  name,
  configContent,
  targetPath,
}:
lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  configFile="$HOME/${targetPath}"
  baselineFile="$HOME/${targetPath}.nix-baseline"
  mkdir -p "$(dirname "$configFile")"

  if [ -L "$configFile" ]; then
    rm "$configFile"
  fi

  if [ ! -f "$baselineFile" ] || [ "$(cat "$baselineFile")" != '${configContent}' ]; then
    if [ -f "$configFile" ] && [ -f "$baselineFile" ]; then
      if ! ${pkgs.diffutils}/bin/diff -q "$baselineFile" "$configFile" > /dev/null 2>&1; then
        echo "WARNING [${name}]: runtime changes will be overwritten by updated Nix config:"
        ${pkgs.diffutils}/bin/diff -u "$baselineFile" "$configFile" || true
      fi
    fi
    echo '${configContent}' > "$configFile"
    echo '${configContent}' > "$baselineFile"
  fi
''
