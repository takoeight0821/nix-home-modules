{ pkgs, lib }:
{
  name,
  pluginRoot,
}:
let
  deployBase = "~/.claude/plugin-files/${name}";

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
          -e 's|\''${CLAUDE_PLUGIN_ROOT}|${deployBase}|g' \
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
          -e 's|\''${CLAUDE_PLUGIN_ROOT}|${deployBase}|g' \
          "$f" > "$out/$fname/SKILL.md"
      done
    fi
  '';

  hooksDir = pluginRoot + "/hooks";
  hooksJsonPath = hooksDir + "/hooks.json";
  hasHooks = builtins.pathExists hooksJsonPath;
  hooksJson = if hasHooks then builtins.fromJSON (builtins.readFile hooksJsonPath) else { };

  scriptsDir = pluginRoot + "/scripts";
  hasScripts = builtins.pathExists scriptsDir;

  replaceRoot = str: builtins.replaceStrings [ "\${CLAUDE_PLUGIN_ROOT}" ] [ deployBase ] str;

  transformHook =
    h: if h.type or "" == "command" then h // { command = replaceRoot h.command; } else h;

  transformEntry = entry: {
    matcher = entry.matcher or "";
    hooks = map transformHook entry.hooks;
  };

  hookEntries = lib.mapAttrs (_event: entries: map transformEntry entries) (hooksJson.hooks or { });

  hookScriptFiles =
    if hasHooks then lib.filterAttrs (n: _: n != "hooks.json") (builtins.readDir hooksDir) else { };

  scriptDirFiles = if hasScripts then builtins.readDir scriptsDir else { };

  hookFiles =
    (lib.mapAttrs' (filename: _: {
      name = ".claude/plugin-files/${name}/hooks/${filename}";
      value = {
        source = hooksDir + "/${filename}";
        executable = true;
      };
    }) hookScriptFiles)
    // (lib.mapAttrs' (filename: _: {
      name = ".claude/plugin-files/${name}/scripts/${filename}";
      value = {
        source = scriptsDir + "/${filename}";
        executable = true;
      };
    }) scriptDirFiles);
in
{
  inherit skills hookFiles hookEntries;
}
