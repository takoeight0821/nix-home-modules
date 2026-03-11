{ pkgs, lib }:
{
  name,
  pluginRoot,
}:
let
  skills = pkgs.runCommand "${name}-skills" { } ''
    mkdir -p $out
    src=${pluginRoot}

    if [ -d "$src/skills" ]; then
      cp -r $src/skills/* $out/ 2>/dev/null || true
    fi

    if [ -d "$src/agents" ]; then
      for f in $src/agents/*.md; do
        [ -f "$f" ] || continue
        fname=$(basename "$f" .md)
        mkdir -p "$out/$fname"
        ${pkgs.gnused}/bin/sed \
          -e 's/^tools: /allowed-tools: /' \
          -e '/^color: /d' \
          "$f" > "$out/$fname/SKILL.md"
      done
    fi

    if [ -d "$src/commands" ]; then
      for f in $src/commands/*.md; do
        [ -f "$f" ] || continue
        fname=$(basename "$f" .md)
        mkdir -p "$out/$fname"
        ${pkgs.gnused}/bin/sed \
          -e '/^argument-hint: /d' \
          "$f" > "$out/$fname/SKILL.md"
      done
    fi
  '';

  hooksDir = pluginRoot + "/hooks";
  hooksJsonPath = hooksDir + "/hooks.json";
  hasHooks = builtins.pathExists hooksJsonPath;
  hooksJson = if hasHooks then builtins.fromJSON (builtins.readFile hooksJsonPath) else { };

  replaceRoot =
    str:
    builtins.replaceStrings [ "\${CLAUDE_PLUGIN_ROOT}/hooks/" ] [ "bash ~/.claude/hooks/${name}/" ] str;

  transformHook =
    h: if h.type or "" == "command" then h // { command = replaceRoot h.command; } else h;

  transformEntry = entry: {
    inherit (entry) matcher;
    hooks = map transformHook entry.hooks;
  };

  hookEntries = lib.mapAttrs (_event: entries: map transformEntry entries) (hooksJson.hooks or { });

  scriptFiles =
    if hasHooks then lib.filterAttrs (n: _: n != "hooks.json") (builtins.readDir hooksDir) else { };

  hookFiles = lib.mapAttrs' (filename: _: {
    name = ".claude/hooks/${name}/${filename}";
    value = {
      source = hooksDir + "/${filename}";
      executable = true;
    };
  }) scriptFiles;
in
{
  inherit skills hookFiles hookEntries;
}
