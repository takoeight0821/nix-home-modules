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

    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
    "[nix]" = {
      "editor.formatOnSave" = false;
    };

    "go.useLanguageServer" = true;
    "go.toolsManagement.autoUpdate" = true;

    "[markdown]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = false;
    };

    "markdown.marp.themes" = [
      "https://cunhapaulo.github.io/style/socrates.css"
    ];

    "git.autofetch" = true;
    "git.confirmSync" = false;
    "githubPullRequests.pullBranch" = "never";

    "vim.useSystemClipboard" = true;

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

      extensions =
        with pkgs.vscode-extensions;
        [
          github.copilot
          github.copilot-chat

          vscodevim.vim
          editorconfig.editorconfig

          jnoortheen.nix-ide
          mkhl.direnv

          golang.go

          hashicorp.terraform
          hashicorp.hcl
          ms-azuretools.vscode-docker

          esbenp.prettier-vscode

          redhat.vscode-yaml
          github.vscode-github-actions
          github.vscode-pull-request-github

          marp-team.marp-vscode
        ]
        ++ (with pkgs.vscode-utils; [
          (extensionFromVscodeMarketplace {
            name = "vscode-speech";
            publisher = "ms-vscode";
            version = "0.16.0";
            sha256 = "sha256-JhZWNlGXljsjmT3/xDi9Z7I4a2vsi/9EkWYbnlteE98=";
          })
        ]);

      mutableExtensionsDir = true;
    };
  };
}
