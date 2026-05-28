{
  config,
  lib,
  pkgs,
  nhm-lib,
  ...
}:
let
  cfg = config.takoeight0821.programs.vscode;

  vscodeSettings = {
    "files.autoSave" = "onFocusChange";

    "github.copilot.enable" = {
      "*" = true;
      "plaintext" = false;
      "markdown" = true;
      "scminput" = false;
    };
    "github.copilot.chat.agent.autoApprove" = true;
    "github.copilot.chat.copilotMemory.enabled" = true;

    "[markdown]" = {
      "editor.formatOnSave" = false;
    };

    "[json]" = {
      "editor.defaultFormatter" = "vscode.json-language-features";
    };

    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.replaceTagsWhenPull" = true;
    "githubPullRequests.pullBranch" = "never";

    "workbench.editor.useModal" = "some";

    "claudeCode.preferredLocation" = "panel";
    "claudeCode.useTerminal" = true;

    "chat.mcp.gallery.enabled" = true;
    "chat.tools.urls.autoApprove" = {
      "https://modelcontextprotocol.io" = true;
      "https://github.com" = {
        "approveRequest" = false;
        "approveResponse" = true;
      };
      "https://docs.github.com" = {
        "approveRequest" = false;
        "approveResponse" = true;
      };
      "https://raw.githubusercontent.com" = {
        "approveRequest" = false;
        "approveResponse" = true;
      };
      "https://duckdb.org" = {
        "approveRequest" = true;
        "approveResponse" = false;
      };
      "https://www.npmjs.com" = true;
    };
    "chat.viewSessions.orientation" = "stacked";
    "chat.useClaudeHooks" = true;
    "chat.tools.terminal.autoApprove" = builtins.fromJSON (
      builtins.readFile ./chat-terminal-autoapprove.json
    );

    "accessibility.voice.speechLanguage" = "ja-JP";

    "aws.cloudformation.telemetry.enabled" = false;

    "dev.containers.experimentalMountGitWorktreeCommonDir" = true;

    "haskell.manageHLS" = "PATH";

    "search.followSymlinks" = false;
  };

  settingsJson = builtins.toJSON vscodeSettings;
in
{
  options.takoeight0821.programs.vscode = {
    enable = lib.mkEnableOption "VS Code configuration";
  };

  config = lib.mkIf cfg.enable {
    home.activation.vscodeSettings = nhm-lib.mkMutableConfig {
      name = "vscode";
      configContent = settingsJson;
      targetPath = "Library/Application Support/Code/User/settings.json";
    };

    programs.vscode = {
      enable = true;
      package =
        (pkgs.writeShellScriptBin "code" ''
          exec "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$@"
        '')
        // {
          pname = "vscode";
          # Sentinel version that always passes home-manager's `versionAtLeast`
          # checks (e.g. the >= 1.74.0 gate that controls extensions.json
          # generation). The real VS Code is installed via Homebrew and updates
          # on its own, so we can't track its version from Nix.
          version = "9999.0.0";
        };

      profiles.default.extensions =
        with pkgs.vscode-extensions;
        [
          github.copilot
          github.copilot-chat

          ms-azuretools.vscode-docker
          ms-vscode-remote.remote-containers

          github.vscode-github-actions
          github.vscode-pull-request-github

          golang.go
        ]
        ++ (with pkgs.vscode-utils; [
          (buildVscodeExtension {
            pname = "toml-syntax";
            version = "1.0.0";
            src = ./extensions/toml-syntax;
            sourceRoot = "toml-syntax";
            vscodeExtPublisher = "local";
            vscodeExtName = "toml-syntax";
            vscodeExtVersion = "1.0.0";
            vscodeExtUniqueId = "local.toml-syntax";
          })
          (extensionFromVscodeMarketplace {
            name = "vscode-speech";
            publisher = "ms-vscode";
            version = "0.16.0";
            sha256 = "sha256-JhZWNlGXljsjmT3/xDi9Z7I4a2vsi/9EkWYbnlteE98=";
          })
          (extensionFromVscodeMarketplace {
            name = "vscode-chat-customizations-evaluations";
            publisher = "ms-vscode";
            version = "1.0.3";
            sha256 = "sha256-6m/2+HVEO3lvDbZAS7pcLTcNCBe95PCZGO6Rs/vO54o=";
          })
          (extensionFromVscodeMarketplace {
            name = "vscode-speech-language-pack-ja-jp";
            publisher = "ms-vscode";
            version = "0.5.0";
            sha256 = "sha256-gbesiqyKWPlEPDyAmTgDSbMN9rWRkq1Trsih0gLgPr0=";
          })
        ]);

      mutableExtensionsDir = false;
    };
  };
}
