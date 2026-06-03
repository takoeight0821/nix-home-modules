{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.claude-plugins;

  marketplaceType = lib.types.submodule {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [
          "github"
          "git"
        ];
        description = "Marketplace source type (github or git)";
      };
      repo = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "GitHub repository in owner/name format (for github type)";
      };
      url = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Git URL (for git type)";
      };
      src = lib.mkOption {
        type = lib.types.path;
        description = "Flake input providing the marketplace repository contents";
      };
      pluginsSubdir = lib.mkOption {
        type = lib.types.str;
        default = "plugins";
        description = "Subdirectory within the repository that contains plugin directories";
      };
    };
  };

  pluginType = lib.types.submodule {
    options = {
      marketplace = lib.mkOption {
        type = lib.types.str;
        description = "Name of the marketplace this plugin belongs to";
      };
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable this plugin";
      };
      src = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Override plugin source path. Use when the entire repo is the plugin.";
      };
    };
  };

  homeDir = config.home.homeDirectory;
  pluginsBaseDir = "${homeDir}/.claude/plugins";
  cacheBaseDir = "${pluginsBaseDir}/cache";

  enabledPlugins = lib.filterAttrs (_: p: p.enable) cfg.plugins;

  getPluginSrc =
    name: pluginCfg:
    if pluginCfg.src != null then
      pluginCfg.src
    else
      let
        mkt = cfg.marketplaces.${pluginCfg.marketplace};
      in
      "${mkt.src}/${mkt.pluginsSubdir}/${name}";

  getPluginVersion =
    name: pluginCfg:
    let
      src = getPluginSrc name pluginCfg;
      pluginJsonPath = "${src}/.claude-plugin/plugin.json";
    in
    if builtins.pathExists pluginJsonPath then
      (builtins.fromJSON (builtins.readFile pluginJsonPath)).version or "unknown"
    else
      "unknown";

  getPluginCachePath =
    name: pluginCfg:
    let
      version = getPluginVersion name pluginCfg;
    in
    "${cacheBaseDir}/${pluginCfg.marketplace}/${name}/${version}";

  nixInstalledEntries = lib.mapAttrs' (name: pluginCfg: {
    name = "${name}@${pluginCfg.marketplace}";
    value = [
      {
        scope = "user";
        installPath = getPluginCachePath name pluginCfg;
        version = getPluginVersion name pluginCfg;
        installedAt = "1970-01-01T00:00:00.000Z";
        lastUpdated = "1970-01-01T00:00:00.000Z";
      }
    ];
  }) enabledPlugins;

  nixMarketplaceEntries = lib.mapAttrs (name: mktCfg: {
    source =
      if mktCfg.type == "github" then
        {
          source = "github";
          repo = mktCfg.repo;
        }
      else
        {
          source = "git";
          url = mktCfg.url;
        };
    installLocation = "${pluginsBaseDir}/marketplaces/${name}";
  }) cfg.marketplaces;

  settingsEnabledPlugins = lib.mapAttrs' (name: pluginCfg: {
    name = "${name}@${pluginCfg.marketplace}";
    value = true;
  }) enabledPlugins;

  cachePopulationScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: pluginCfg:
      let
        src = getPluginSrc name pluginCfg;
        target = getPluginCachePath name pluginCfg;
      in
      ''
        mkdir -p "$(dirname "${target}")"
        rm -rf "${target}"
        cp -rL "${src}" "${target}"
        chmod -R u+w "${target}"
      ''
    ) enabledPlugins
  );

  installedPluginsNixJson = builtins.toJSON nixInstalledEntries;
  knownMarketplacesNixJson = builtins.toJSON nixMarketplaceEntries;

  # Copilot CLI helpers
  copilotBaseDir = "${homeDir}/.copilot";
  copilotInstalledPluginsDir = "${copilotBaseDir}/installed-plugins";

  copilotCachePopulationScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: pluginCfg:
      let
        src = getPluginSrc name pluginCfg;
        target = "${copilotInstalledPluginsDir}/${pluginCfg.marketplace}/${name}";
      in
      ''
        mkdir -p "$(dirname "${target}")"
        rm -rf "${target}"
        cp -rL "${src}" "${target}"
        chmod -R u+w "${target}"
      ''
    ) enabledPlugins
  );

  copilotInstalledPluginsNixJson = builtins.toJSON (
    lib.mapAttrsToList (
      name: pluginCfg:
      let
        version = getPluginVersion name pluginCfg;
        installPath = "${copilotInstalledPluginsDir}/${pluginCfg.marketplace}/${name}";
      in
      {
        inherit name version;
        marketplace = pluginCfg.marketplace;
        installed_at = "1970-01-01T00:00:00.000Z";
        enabled = true;
        cache_path = installPath;
      }
    ) enabledPlugins
  );
  copilotMcpServersNixJson = builtins.toJSON {
    mcpServers = cfg.copilotCli.mcpServers;
  };

  # Marketplaces declared in nix-config. In declarative Copilot CLI mode this
  # set is the source of truth: any marketplace directory under
  # ~/.copilot/installed-plugins/ that is not in this list is removed, and
  # plugins within nix-managed marketplaces must be declared in `plugins`.
  nixManagedMarketplacesJson = builtins.toJSON (builtins.attrNames cfg.marketplaces);
in
{
  options.takoeight0821.programs.claude-plugins = {
    enable = lib.mkEnableOption "declarative Claude Code plugin management";

    marketplaces = lib.mkOption {
      type = lib.types.attrsOf marketplaceType;
      default = { };
      description = "Claude Code plugin marketplace definitions";
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf pluginType;
      default = { };
      description = "Claude Code plugins to install and enable";
    };

    copilotCli = {
      enable = lib.mkEnableOption "install plugins to GitHub Copilot CLI (~/.copilot)";
      declarative = lib.mkEnableOption ''
        strict declarative management of GitHub Copilot CLI plugins. When enabled,
        the contents of `~/.copilot/installed-plugins/` and the `installed_plugins`
        array in `~/.copilot/config.json` are kept in exact sync with `plugins`:
        any plugin not declared in nix-config is removed, including plugins from
        marketplaces unknown to nix-config
      '';
      mcpServers = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = { };
        description = ''
          MCP server definitions for GitHub Copilot CLI. These are written to
          `~/.copilot/mcp-config.json`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    takoeight0821.programs.claude-hooks.extraEnabledPlugins = settingsEnabledPlugins;

    home.activation = lib.mkMerge [
      {
        claudePluginsCache = lib.hm.dag.entryAfter [ "writeBoundary" ] cachePopulationScript;

        claudePluginsInstalled = lib.hm.dag.entryAfter [ "claudePluginsCache" ] ''
          installedFile="${pluginsBaseDir}/installed_plugins.json"
          mkdir -p "$(dirname "$installedFile")"
          if [ ! -f "$installedFile" ]; then
            echo '{"version":2,"plugins":{}}' > "$installedFile"
          fi
          ${pkgs.jq}/bin/jq --argjson nix '${installedPluginsNixJson}' \
            '.plugins = (.plugins // {}) + $nix' \
            "$installedFile" > "$installedFile.tmp"
          mv "$installedFile.tmp" "$installedFile"
        '';

        claudePluginsMarketplaces = lib.hm.dag.entryAfter [ "claudePluginsCache" ] ''
          mktFile="${pluginsBaseDir}/known_marketplaces.json"
          mkdir -p "$(dirname "$mktFile")"
          if [ ! -f "$mktFile" ]; then
            echo '{}' > "$mktFile"
          fi
          NOW=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
          nixMkts=$(echo '${knownMarketplacesNixJson}' | ${pkgs.jq}/bin/jq --arg now "$NOW" '
            with_entries(.value.lastUpdated = $now)
          ')
          ${pkgs.jq}/bin/jq --argjson nix "$nixMkts" '. + $nix' \
            "$mktFile" > "$mktFile.tmp"
          mv "$mktFile.tmp" "$mktFile"
        '';
      }
      (lib.mkIf cfg.copilotCli.enable {
        copilotCliPluginsCache = lib.hm.dag.entryAfter [ "writeBoundary" ] copilotCachePopulationScript;

        copilotCliPluginsPrune = lib.mkIf cfg.copilotCli.declarative (
          lib.hm.dag.entryAfter [ "copilotCliPluginsCache" ] ''
            installedDir="${copilotInstalledPluginsDir}"
            [ -d "$installedDir" ] || exit 0
            nixMkts='${nixManagedMarketplacesJson}'

            # Remove marketplace directories not declared in nix-config.
            for mktDir in "$installedDir"/*; do
              [ -d "$mktDir" ] || continue
              mkt=$(basename "$mktDir")
              if ! echo "$nixMkts" | ${pkgs.jq}/bin/jq -e --arg mkt "$mkt" 'index($mkt)' >/dev/null; then
                rm -rf "$mktDir"
              fi
            done

            # Within nix-managed marketplaces, remove plugins not declared in nix-config.
            for mkt in $(echo "$nixMkts" | ${pkgs.jq}/bin/jq -r '.[]'); do
              mktDir="$installedDir/$mkt"
              [ -d "$mktDir" ] || continue
              keep=$(echo '${copilotInstalledPluginsNixJson}' \
                | ${pkgs.jq}/bin/jq -r --arg mkt "$mkt" \
                  '.[] | select(.marketplace == $mkt) | .name')
              for d in "$mktDir"/*; do
                [ -d "$d" ] || continue
                name=$(basename "$d")
                if ! printf '%s\n' "$keep" | grep -qx -- "$name"; then
                  rm -rf "$d"
                fi
              done
            done
          ''
        );

        copilotCliPluginsConfig =
          lib.hm.dag.entryAfter
            [
              "copilotCliPluginsCache"
              "copilotCliPluginsPrune"
            ]
            (
              let
                mergeFilter = ''
                  .installed_plugins = (
                    [(.installed_plugins // [])[] | . as $e | select(
                      ($nix | map(select(.name == $e.name and .marketplace == $e.marketplace)) | length) == 0
                    )]
                    + $nix
                  )
                '';
                declarativeFilter = ''
                  .installed_plugins = $nix
                '';
                jqArgs = "--argjson nix '${copilotInstalledPluginsNixJson}'";
                jqFilter = if cfg.copilotCli.declarative then declarativeFilter else mergeFilter;
              in
              ''
                configFile="${copilotBaseDir}/config.json"
                mkdir -p "$(dirname "$configFile")"
                if [ ! -f "$configFile" ]; then
                  echo '{}' > "$configFile"
                fi
                sed '/^[[:space:]]*\/\//d' "$configFile" \
                  | ${pkgs.jq}/bin/jq ${jqArgs} '${jqFilter}' > "$configFile.tmp"
                mv "$configFile.tmp" "$configFile"
              ''
            );

        copilotCliMcpConfig =
          lib.hm.dag.entryAfter
            [
              "copilotCliPluginsConfig"
            ]
            (
              let
                nixJsonFile = pkgs.writeText "copilot-mcp-servers-nix.json" copilotMcpServersNixJson;
                mergeFilter = ''
                  . + $nix
                '';
                declarativeFilter = ''
                  $nix
                '';
                jqArgs = ''--argjson nix "$(cat ${nixJsonFile})"'';
                jqFilter = if cfg.copilotCli.declarative then declarativeFilter else mergeFilter;
              in
              ''
                mcpConfigFile="${copilotBaseDir}/mcp-config.json"
                mkdir -p "$(dirname "$mcpConfigFile")"
                if [ ! -f "$mcpConfigFile" ]; then
                  echo '{}' > "$mcpConfigFile"
                fi
                sed '/^[[:space:]]*\/\//d' "$mcpConfigFile" \
                  | ${pkgs.jq}/bin/jq ${jqArgs} '${jqFilter}' > "$mcpConfigFile.tmp"
                mv "$mcpConfigFile.tmp" "$mcpConfigFile"
              ''
            );
      })
    ];
  };
}
