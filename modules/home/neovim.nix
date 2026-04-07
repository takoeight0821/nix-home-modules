{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.takoeight0821.programs.neovim;
in
{
  options.takoeight0821.programs.neovim = {
    enable = lib.mkEnableOption "Neovim configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.tree-sitter ];

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };

    xdg.configFile = {
      "nvim/init.lua".text = ''
        if vim.g.vscode then
          -- VSCode extension
          -- https://github.com/vscode-neovim/vscode-neovim/issues/298
          vim.opt.clipboard:append("unnamedplus")
          return
        end

        -- Bootstrap lazy.nvim
        require("config.lazy")

        -- Load core configuration
        require("config.options")
        require("config.keymaps")
        require("config.autocmds")
      '';

      "nvim/lua/config/lazy.lua".text = ''
        -- Bootstrap lazy.nvim
        local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
        if not (vim.uv or vim.loop).fs_stat(lazypath) then
          local lazyrepo = "https://github.com/folke/lazy.nvim.git"
          local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
          if vim.v.shell_error ~= 0 then
            vim.api.nvim_echo({
              { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
              { out, "WarningMsg" },
              { "\nPress any key to exit..." },
            }, true, {})
            vim.fn.getchar()
            os.exit(1)
          end
        end
        vim.opt.rtp:prepend(lazypath)

        -- Make sure to setup `mapleader` and `maplocalleader` before
        -- loading lazy.nvim so that mappings are correct.
        vim.g.mapleader = " "
        vim.g.maplocalleader = "\\"

        -- Setup lazy.nvim
        require("lazy").setup({
          spec = {
            -- import your plugins
            { import = "plugins" },
          },
          -- Configure any other settings here. See the documentation for more details.
          -- colorscheme that will be used when installing plugins.
          install = { colorscheme = { "habamax" } },
          -- automatically check for plugin updates
          checker = { enabled = true },
        })
      '';

      "nvim/lua/config/options.lua".text = ''
        -- Set options
        local opt = vim.opt

        -- Line numbers
        opt.number = true
        opt.relativenumber = false

        -- Tabs and indentation
        opt.tabstop = 2
        opt.shiftwidth = 2
        opt.expandtab = true
        opt.autoindent = true

        -- Line wrapping
        opt.wrap = true
        opt.linebreak = true
        opt.breakindent = true

        -- Search settings
        opt.ignorecase = true
        opt.smartcase = true

        -- Cursor line
        opt.cursorline = true

        -- Appearance
        opt.termguicolors = true
        opt.signcolumn = "yes"

        -- Backspace
        opt.backspace = "indent,eol,start"

        -- Clipboard
        opt.clipboard:append("unnamedplus")

        -- Split windows
        opt.splitright = true
        opt.splitbelow = true

        -- Consider - as part of word
        opt.iskeyword:append("-")

        -- Disable swapfile
        opt.swapfile = false

        -- Enable mouse
        opt.mouse = "a"

        -- Set completeopt for better completion experience
        opt.completeopt = "menu,menuone,noselect"

        -- Persistent undo
        opt.undofile = true

        -- Interval for writing swap file to disk, also used by gitsigns
        opt.updatetime = 250

        -- Set timeout for mapped sequences
        opt.timeoutlen = 300
      '';

      "nvim/lua/config/keymaps.lua".text = ''
        -- Set keymaps
        local keymap = vim.keymap

        -- Clear search highlights
        keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

        -- Delete without yanking
        keymap.set("n", "x", '"_x')

        -- Increment/decrement numbers
        keymap.set("n", "+", "<C-a>")
        keymap.set("n", "-", "<C-x>")

        -- Window management
        keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
        keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
        keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
        keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

        -- Tab management
        keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
        keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
        keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
        keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
        keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

        -- Navigate buffers
        keymap.set("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
        keymap.set("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })

        -- Stay in indent mode
        keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
        keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

        -- Move text up and down
        keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text down" })
        keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text up" })

        -- Better paste
        keymap.set("v", "p", '"_dP', { desc = "Paste without yanking" })

        -- Diagnostic keymaps
        keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
        keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
        keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic error messages" })
        keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
      '';

      "nvim/lua/config/autocmds.lua".text = ''
        -- Autocmds are automatically loaded on the VeryLazy event

        local autocmd = vim.api.nvim_create_autocmd
        local augroup = vim.api.nvim_create_augroup

        -- Highlight on yank
        autocmd("TextYankPost", {
          group = augroup("highlight_yank", { clear = true }),
          callback = function()
            vim.highlight.on_yank()
          end,
        })

        -- Resize splits if window got resized
        autocmd({ "VimResized" }, {
          group = augroup("resize_splits", { clear = true }),
          callback = function()
            local current_tab = vim.fn.tabpagenr()
            vim.cmd("tabdo wincmd =")
            vim.cmd("tabnext " .. current_tab)
          end,
        })

        -- Close some filetypes with <q>
        autocmd("FileType", {
          group = augroup("close_with_q", { clear = true }),
          pattern = {
            "help",
            "lspinfo",
            "man",
            "notify",
            "qf",
            "checkhealth",
          },
          callback = function(event)
            vim.bo[event.buf].buflisted = false
            vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
          end,
        })

        -- Auto create dir when saving a file, in case some intermediate directory does not exist
        autocmd({ "BufWritePre" }, {
          group = augroup("auto_create_dir", { clear = true }),
          callback = function(event)
            if event.match:match("^%w%w+://") then
              return
            end
            local file = vim.loop.fs_realpath(event.match) or event.match
            vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
          end,
        })

        -- Disable line numbers for certain filetypes
        autocmd("FileType", {
          group = augroup("disable_line_numbers", { clear = true }),
          pattern = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason", "notify", "toggleterm" },
          callback = function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
          end,
        })
      '';

      "nvim/lua/plugins/init.lua".text = ''
        return {
          {
            "Mofiqul/vscode.nvim",
            lazy = false,
            priority = 1000,
            config = function()
              vim.cmd([[colorscheme vscode]])
            end,
          },

          -- which-key for better keybinding discovery
          {
            "folke/which-key.nvim",
            event = "VeryLazy",
            init = function()
              vim.o.timeout = true
              vim.o.timeoutlen = 300
            end,
            opts = {
              delay = 1000,
            },
          },

          -- treesitter for better syntax highlighting
          {
            "nvim-treesitter/nvim-treesitter",
            branch = "main",
            lazy = false,
            build = ":TSUpdate",
            config = function()
              require("nvim-treesitter").setup {}
              require("nvim-treesitter").install {
                "lua", "vim", "vimdoc", "query",
                "markdown", "markdown_inline",
                "bash", "c", "cpp", "go",
                "javascript", "typescript", "tsx", "json",
                "python", "rust", "yaml", "toml",
                "html", "css", "dockerfile", "gitignore",
                "make", "regex", "fsharp", "nix",
              }
              vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                  pcall(vim.treesitter.start)
                end,
              })
            end,
          },

          -- telescope for fuzzy finding
          {
            "nvim-telescope/telescope.nvim",
            branch = "0.1.x",
            dependencies = { "nvim-lua/plenary.nvim" },
            keys = {
              { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
              { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
              { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
              { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
            },
          },

          -- neo-tree for file explorer
          {
            "nvim-neo-tree/neo-tree.nvim",
            branch = "v3.x",
            dependencies = {
              "nvim-lua/plenary.nvim",
              "nvim-tree/nvim-web-devicons",
              "MunifTanjim/nui.nvim",
            },
            keys = {
              { "<leader>fe", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
            },
          },

          -- Trouble for better diagnostics
          {
            "folke/trouble.nvim",
            dependencies = { "nvim-tree/nvim-web-devicons" },
            opts = {},
            cmd = "Trouble",
            keys = {
              { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
              { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
              { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
              {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
              },
              { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
              { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
            },
          },

          -- F# support with Ionide-vim
          {
            "ionide/Ionide-vim",
            ft = { "fsharp", "fs", "fsx", "fsi" },
            dependencies = {
              "neovim/nvim-lspconfig",
            },
            config = function()
              -- Disable Ionide's built-in LSP since we're using fsautocomplete directly
              vim.g["fsharp#lsp_auto_setup"] = 0
              vim.g["fsharp#lsp_recommended_colorscheme"] = 0
              vim.g["fsharp#fsi_command"] = "dotnet fsi"
              vim.g["fsharp#fsi_keymap"] = "custom"

              -- F# Interactive keybindings
              vim.api.nvim_create_autocmd("FileType", {
                pattern = { "fsharp", "fs", "fsx", "fsi" },
                callback = function()
                  local opts = { buffer = true, silent = true }
                  -- Send current line to FSI
                  vim.keymap.set("n", "<leader>fi", "<Plug>(fsharp-send-line)", opts)
                  -- Send selection to FSI
                  vim.keymap.set("v", "<leader>fi", "<Plug>(fsharp-send-selection)", opts)
                  -- Toggle FSI window
                  vim.keymap.set(
                    "n",
                    "<leader>ft",
                    "<cmd>FsiShow<cr>",
                    { buffer = true, desc = "Toggle F# Interactive" }
                  )
                  -- Reset FSI
                  vim.keymap.set(
                    "n",
                    "<leader>fr",
                    "<cmd>FsiReset<cr>",
                    { buffer = true, desc = "Reset F# Interactive" }
                  )
                end,
              })
            end,
          },
        }
      '';

      "nvim/lua/plugins/lsp.lua".text = ''
        return {
          -- LSP Configuration & Plugins
          {
            "neovim/nvim-lspconfig",
            dependencies = {
              -- Automatically install LSPs and related tools to stdpath for Neovim
              { "williamboman/mason.nvim", config = true },
              "williamboman/mason-lspconfig.nvim",
              "WhoIsSethDaniel/mason-tool-installer.nvim",

              -- Useful status updates for LSP.
              { "j-hui/fidget.nvim", opts = {} },

              -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
              { "folke/neodev.nvim", opts = {} },
            },
            config = function()
              vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
                callback = function(event)
                  local map = function(keys, func, desc)
                    vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                  end

                  -- Jump to the definition of the word under your cursor.
                  map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

                  -- Find references for the word under your cursor.
                  map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

                  -- Jump to the implementation of the word under your cursor.
                  map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

                  -- Jump to the type of the word under your cursor.
                  map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

                  -- Fuzzy find all the symbols in your current document.
                  map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

                  -- Fuzzy find all the symbols in your current workspace.
                  map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

                  -- Rename the variable under your cursor.
                  map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

                  -- Execute a code action
                  map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

                  -- Opens a popup that displays documentation about the word under your cursor
                  map("K", vim.lsp.buf.hover, "Hover Documentation")

                  -- Goto Declaration
                  map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

                  -- Highlight references of the word under cursor
                  local client = vim.lsp.get_client_by_id(event.data.client_id)
                  if client and client.server_capabilities.documentHighlightProvider then
                    local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
                    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                      buffer = event.buf,
                      group = highlight_augroup,
                      callback = vim.lsp.buf.document_highlight,
                    })

                    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                      buffer = event.buf,
                      group = highlight_augroup,
                      callback = vim.lsp.buf.clear_references,
                    })

                    vim.api.nvim_create_autocmd("LspDetach", {
                      group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
                      callback = function(event2)
                        vim.lsp.buf.clear_references()
                        vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
                      end,
                    })
                  end

                  -- Toggle inlay hints
                  if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
                    map("<leader>th", function()
                      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
                    end, "[T]oggle Inlay [H]ints")
                  end
                end,
              })

              local capabilities = vim.lsp.protocol.make_client_capabilities()
              capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

              local servers = {
                lua_ls = {
                  settings = {
                    Lua = {
                      completion = {
                        callSnippet = "Replace",
                      },
                    },
                  },
                },

                fsautocomplete = {
                  cmd = { "fsautocomplete", "--adaptive-lsp-server-enabled" },
                  filetypes = { "fsharp", "fs", "fsx", "fsi" },
                  settings = {
                    FSharp = {
                      keywordsAutocomplete = true,
                      ExternalAutocomplete = false,
                      Linter = true,
                      UnionCaseStubGeneration = true,
                      UnionCaseStubGenerationBody = "failwith \"Not Implemented\"",
                      RecordStubGeneration = true,
                      RecordStubGenerationBody = "failwith \"Not Implemented\"",
                      InterfaceStubGeneration = true,
                      InterfaceStubGenerationObjectIdentifier = "this",
                      InterfaceStubGenerationMethodBody = "failwith \"Not Implemented\"",
                      UnusedOpensAnalyzer = true,
                      UnusedDeclarationsAnalyzer = true,
                      UseSdkScripts = true,
                      SimplifyNameAnalyzer = true,
                      ResolveNamespaces = true,
                      EnableReferenceCodeLens = true,
                    },
                  },
                },
              };

              require("mason").setup()

              local ensure_installed = vim.tbl_keys(servers or {})
              vim.list_extend(ensure_installed, {
                "stylua",
              })
              require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

              require("mason-lspconfig").setup({
                handlers = {
                  function(server_name)
                    local server = servers[server_name] or {}
                    server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                    require("lspconfig")[server_name].setup(server)
                  end,
                },
              })
            end,
          },

          -- Autoformat
          {
            "stevearc/conform.nvim",
            lazy = false,
            keys = {
              {
                "<leader>f",
                function()
                  require("conform").format({ async = true, lsp_fallback = true })
                end,
                mode = "",
                desc = "[F]ormat buffer",
              },
            },
            opts = {
              notify_on_error = false,
              format_on_save = function(bufnr)
                local disable_filetypes = { c = true, cpp = true }
                return {
                  timeout_ms = 500,
                  lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
                }
              end,
              formatters_by_ft = {
                lua = { "stylua" },
              },
            },
          },
        }
      '';

      "nvim/lua/plugins/cmp.lua".text = ''
        return {
          -- Autocompletion
          {
            "hrsh7th/nvim-cmp",
            event = "InsertEnter",
            dependencies = {
              -- Snippet Engine & its associated nvim-cmp source
              {
                "L3MON4D3/LuaSnip",
                build = (function()
                  if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
                    return
                  end
                  return "make install_jsregexp"
                end)(),
                dependencies = {
                  {
                    "rafamadriz/friendly-snippets",
                    config = function()
                      require("luasnip.loaders.from_vscode").lazy_load()
                    end,
                  },
                },
              },
              "saadparwaiz1/cmp_luasnip",

              -- Adds other completion capabilities.
              "hrsh7th/cmp-nvim-lsp",
              "hrsh7th/cmp-path",
              "hrsh7th/cmp-buffer",
            },
            config = function()
              local cmp = require("cmp")
              local luasnip = require("luasnip")
              luasnip.config.setup({})

              cmp.setup({
                snippet = {
                  expand = function(args)
                    luasnip.lsp_expand(args.body)
                  end,
                },
                completion = { completeopt = "menu,menuone,noinsert" },

                mapping = cmp.mapping.preset.insert({
                  -- Select the [n]ext item
                  ["<C-n>"] = cmp.mapping.select_next_item(),
                  -- Select the [p]revious item
                  ["<C-p>"] = cmp.mapping.select_prev_item(),

                  -- Scroll the documentation window [b]ack / [f]orward
                  ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                  ["<C-f>"] = cmp.mapping.scroll_docs(4),

                  -- Accept ([y]es) the completion.
                  ["<C-y>"] = cmp.mapping.confirm({ select = true }),

                  -- Traditional completion keymaps
                  ["<CR>"] = cmp.mapping.confirm({ select = true }),
                  ["<Tab>"] = cmp.mapping.select_next_item(),
                  ["<S-Tab>"] = cmp.mapping.select_prev_item(),

                  -- Manually trigger a completion from nvim-cmp.
                  ["<C-Space>"] = cmp.mapping.complete({}),

                  -- Jump within snippets
                  ["<C-l>"] = cmp.mapping(function()
                    if luasnip.expand_or_locally_jumpable() then
                      luasnip.expand_or_jump()
                    end
                  end, { "i", "s" }),
                  ["<C-h>"] = cmp.mapping(function()
                    if luasnip.locally_jumpable(-1) then
                      luasnip.jump(-1)
                    end
                  end, { "i", "s" }),
                }),
                sources = {
                  { name = "nvim_lsp" },
                  { name = "luasnip" },
                  { name = "path" },
                  { name = "buffer" },
                },
              })
            end,
          },
        }
      '';
    };
  };
}
