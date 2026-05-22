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
    "githubPullRequests.pullBranch" = "never";

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
    home.file.".vscode/extensions/local.toml-syntax-1.0.0" = {
      source = ./extensions/toml-syntax;
      recursive = true;
    };

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
          version = "latest";
        };

      profiles.default.extensions =
        with pkgs.vscode-extensions;
        [
          github.copilot
          github.copilot-chat

          ms-azuretools.vscode-docker

          github.vscode-github-actions
          github.vscode-pull-request-github
        ]
        ++ (with pkgs.vscode-utils; [
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
