describe("nodezero.plugins.loader", function()
  local loader
  local mock_utils
  local original_require
  local mock_requires
  local snapshot
  before_each(function()
    snapshot = assert:snapshot()
    -- Clear all loaded modules
    package.loaded["nodezero.plugins.loader"] = nil
    package.loaded["nodezero"] = nil
    stub(_G.vim, "notify")
    vim.env.NODEZERO_NVIM_PLUGINS_DIRECTORY = "/test/plugins"
    -- Create mocks for dependencies
    mock_utils = require("nodezero.utils")
    stub(mock_utils, "updatePackagePath").returns(true)
    stub(mock_utils.vcs, "cloneRepo").returns(true)
    -- {
    --   updatePackagePath = spy.new(function(path)
    --     return true
    --   end),
    --   fs = {
    --     ensurePath = spy.new(function(path, create)
    --       if path:match("should_fail") then
    --         error("Failed to create directory: " .. path)
    --       end
    --       if not create then
    --         error("Path does not exist: " .. path)
    --       end
    --       return true
    --     end),
    --   },
    --   vcs = {
    --     cloneRepo = spy.new(function(repoDetails)
    --       if repoDetails.repo:match("failing%-repo") then
    --         return false
    --       end
    --       return true
    --     end),
    --   },
    --   debug = {
    --     log = spy.new(function(message)
    --         return message
    --     end)
    --   }
    -- }

    -- Store original functions
    original_require = require

    -- Mock require function to control what modules return
    mock_requires = {}
    _G.require = function(module_name)
      if mock_requires[module_name] then
        return mock_requires[module_name]
      end
      return original_require(module_name)
    end

    -- Set up module mocks
    mock_requires["nodezero.utils"] = mock_utils

    -- Load the module under test
    loader = require("nodezero.plugins.loader")
  end)

  after_each(function()
    -- Restore original require function and vim
    _G.require = original_require
    snapshot:revert()
    package.loaded["nodezero.utils"] = nil
    package.loaded["nodezero.plugins.loader"] = nil
    package.loaded["nodezero"] = nil
    vim.env.NODEZERO_NVIM_PLUGINS_DIRECTORY = nil
  end)

  describe("setup", function()
    describe("basic functionality", function()
      it("should return the loader module when called", function()
        -- Arrange
        local plugins = {}
        local hooks = {}
        stub(mock_utils.fs, "ensurePath").returns(true).on_call_with(vim.env.NODEZERO_NVIM_PLUGINS_DIRECTORY)

        -- Act
        local result = loader.setup(plugins, hooks)

        -- Assert
        assert.are.equal(loader, result)
      end)

      it("should ensure plugin directory exists", function()
        -- Arrange
        local plugins = {}
        local hooks = {}
        stub(mock_utils.fs, "ensurePath").returns(true).on_call_with(vim.env.NODEZERO_NVIM_PLUGINS_DIRECTORY)

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(mock_utils.fs.ensurePath).was_called_with("/test/plugins", true)
      end)

      it("should throw error when plugin directory creation fails", function()
        -- Arrange
        local plugins = {}
        local hooks = {}
        vim.env.NODEZERO_NVIM_PLUGINS_DIRECTORY = "/test/notexist"
        stub(mock_utils.fs, "ensurePath")
          .invokes(function(path)
            error("Failed to create directory: " .. path)
          end)
          .on_call_with(vim.env.NODEZER_NVIM_PLUGINS_DIRECTORY)

        -- Act & Assert
        assert.has_error(function()
          loader.setup(plugins, hooks)
        end, "Failed to create directory: /test/notexist")
      end)
    end)

    describe("plugin existence checking", function()
      before_each(function()
        stub(mock_utils.fs, "ensurePath").returns(true)
      end)
      it("should check if plugin directory exists for each plugin", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "catppuccin" },
            options = { flavour = "mocha" },
          },
          {
            "nvim-treesitter/nvim-treesitter",
            spec = { name = "nvim-treesitter" },
            options = { highlight = { enable = true } },
          },
        }
        local hooks = {}

        stub(vim.fn, "isdirectory").invokes(function(path) --luacheck: ignore 212
          return 0 -- Plugins don't exist
        end)

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(vim.fn.isdirectory).was_called_with("/test/plugins/catppuccin")
        assert.spy(vim.fn.isdirectory).was_called_with("/test/plugins/nvim-treesitter")
      end)

      it("should skip cloning for existing plugins", function()
        -- Arrange
        local plugins = {
          {
            "existing-plugin/nvim",
            spec = { name = "existing-plugin" },
            options = {},
          },
        }
        local hooks = {}

        stub(vim.fn, "isdirectory").invokes(spy.new(function(path)
          if path:match("existing%-plugin") then
            return 1 -- Plugin exists
          end
          return 0
        end))

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(mock_utils.vcs.cloneRepo).was_not_called()
      end)
    end)
    describe("plugin cloning", function()
      local cloneRepoSpy

      before_each(function()
        cloneRepoSpy = spy.new(function(repoDetails) --luacheck: ignore 212
          return true
        end)
        stub(mock_utils.fs, "ensurePath").returns(true)
        stub(mock_utils.vcs, "cloneRepo").invokes(cloneRepoSpy)
      end)
      it("should clone missing plugins", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "catppuccin" },
            options = { flavour = "mocha" },
          },
        }

        local hooks = {}

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(mock_utils.vcs.cloneRepo).was_called_with({
          repo = "https://github.com/catppuccin/nvim",
          path = "/test/plugins/catppuccin",
        })
      end)

      it("should use custom repository URL when specified in plugin", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = {
              name = "catppuccin",
              url = "https://custom.git/catppuccin/nvim",
            },
            options = { flavour = "mocha" },
          },
        }
        local hooks = {}
        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(mock_utils.vcs.cloneRepo).was_called_with({
          repo = "https://custom.git/catppuccin/nvim",
          path = "/test/plugins/catppuccin",
        })
      end)

      it("should throw error when cloning fails", function()
        -- Arrange
        local plugins = {
          {
            "failing-repo/nvim",
            spec = { name = "failing-repo" },
            options = {},
          },
        }
        local hooks = {}
        stub(mock_utils.vcs, "cloneRepo")
          .invokes(function()
            error("Failed to clone plugin failing-repo/nvim")
          end)
          .on_call_with(plugins[1].spec.name)
        -- Act & Assert
        assert.has_error(function()
          loader.setup(plugins, hooks)
        end, "Failed to clone plugin failing-repo/nvim")
      end)

      it("should show notification during plugin installation", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "catppuccin" },
            options = { flavour = "mocha" },
          },
        }
        local hooks = {}
        stub(mock_utils.fs, "ensurePath").returns(true)
        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(vim.notify).was_called()
      end)
    end)
    describe("runtime path management", function()
      it("should add plugin directory to runtime path", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "catppuccin" },
            options = { flavour = "mocha" },
          },
        }
        local hooks = {}
        local updatePackagePathSpy = spy.new(function(path) --luacheck: ignore 212
          return
        end)
        stub(mock_utils.fs, "ensurePath").returns(true)

        stub(mock_utils, "updatePackagePath").invokes(updatePackagePathSpy)
        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(mock_utils.updatePackagePath).was_called_with("/test/plugins/catppuccin")
      end)

      it("should add runtime path for existing plugins too", function()
        -- Arrange
        local plugins = {
          {
            "existing-plugin/nvim",
            spec = { name = "existing-plugin" },
            options = {},
          },
        }
        local hooks = {}

        stub(vim.fn, "isdirectory").invokes(spy.new(function()
          return 1 -- Plugin exists
        end))

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(mock_utils.updatePackagePath).was_called_with("/test/plugins/existing-plugin")
      end)
    end)
    describe("plugin loading and hooks", function()
      it("should call preSetup hook when defined", function()
        -- Arrange
        local preSetup_spy = spy.new(function() end)
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "catppuccin" },
            options = { flavour = "mocha" },
          },
        }
        local hooks = {
          ["catppuccin/nvim"] = {
            preSetup = preSetup_spy,
          },
        }
        stub(mock_utils.fs, "ensurePath").returns(true)
        stub(mock_utils.vcs, "cloneRepo").returns(true)

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(preSetup_spy).was_called_with(plugins[1])
      end)

      it("should call custom config hook when defined", function()
        -- Arrange
        local config_spy = spy.new(function() end)
        local plugins = {
          {
            "nvim-treesitter/nvim-treesitter",
            spec = { name = "nvim-treesitter" },
            options = { highlight = { enable = true } },
          },
        }
        local hooks = {
          ["nvim-treesitter/nvim-treesitter"] = {
            config = config_spy,
          },
        }
        stub(mock_utils.fs, "ensurePath").returns(true)
        stub(mock_utils.vcs, "cloneRepo").returns(true)

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(config_spy).was_called_with(plugins[1])
      end)

      it("should call default setup when no config hook defined", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "catppuccin" },
            options = { flavour = "mocha" },
          },
        }

        local setupCalled = false
        local mock_plugin_setup = function(options)
          assert.is.same(options, plugins[1].options)
          setupCalled = true
        end

        local hooks = {}

        -- Mock the plugin module
        mock_requires["catppuccin"] = {
          setup = mock_plugin_setup,
        }
        stub(mock_utils.fs, "ensurePath").returns(false)
        stub(mock_utils, "cloneRepo").returns(true)

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.is_true(setupCalled)
      end)

      it("should call postSetup hook when defined", function()
        -- Arrange
        local postSetup_spy = spy.new(function() end)
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "catppuccin" },
            options = { flavour = "mocha" },
          },
        }
        local hooks = {
          ["catppuccin/nvim"] = {
            postSetup = postSetup_spy,
          },
        }

        -- Mock the plugin module
        mock_requires["catppuccin"] = {
          setup = function() end,
        }
        stub(mock_utils.fs, "ensurePath").returns(true)
        stub(mock_utils.vcs, "cloneRepo").returns(true)
        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(postSetup_spy).was_called_with(plugins[1])
      end)

      it("should execute hooks in correct order", function()
        -- Arrange
        local call_order = {}
        local preSetup_spy = spy.new(function()
          table.insert(call_order, "preSetup")
        end)
        local config_spy = spy.new(function()
          table.insert(call_order, "config")
        end)
        local postSetup_spy = spy.new(function()
          table.insert(call_order, "postSetup")
        end)

        local plugins = {
          {
            "test/plugin",
            spec = { name = "test-plugin" },
            options = { test = true },
          },
        }
        local hooks = {
          ["test/plugin"] = {
            preSetup = preSetup_spy,
            config = config_spy,
            postSetup = postSetup_spy,
          },
        }

        stub(mock_utils.fs, "ensurePath").returns(true)
        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.are.same({ "preSetup", "config", "postSetup" }, call_order)
      end)

      it("should continue loading if preSetup hook fails", function()
        -- Arrange
        local config_spy = spy.new(function() end)
        local plugins = {
          {
            "test/plugin",
            spec = { name = "test-plugin" },
            options = { test = true },
          },
        }
        local hooks = {
          ["test/plugin"] = {
            preSetup = function()
              error("preSetup failed")
            end,
            config = config_spy,
          },
        }

        stub(mock_utils.fs, "ensurePath").returns(true)
        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(config_spy).was_called()
      end)

      it("should continue loading if config hook fails", function()
        -- Arrange
        local postSetup_spy = spy.new(function() end)
        local plugins = {
          {
            "test/plugin",
            spec = { name = "test-plugin" },
            options = { test = true },
          },
        }
        local hooks = {
          ["test/plugin"] = {
            config = function()
              error("config failed")
            end,
            postSetup = postSetup_spy,
          },
        }
        stub(mock_utils.fs, "ensurePath").returns(true)
        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(postSetup_spy).was_called()
      end)
      it("should continue loading if postSetup hook fails", function()
        -- Arrange
        local plugins = {
          {
            "test/plugin1",
            spec = { name = "test-plugin1" },
            options = { test = true },
          },
          {
            "test/plugin2",
            spec = { name = "test-plugin2" },
            options = { test = true },
          },
        }
        local hooks = {
          ["test/plugin1"] = {
            postSetup = function()
              error("postSetup failed")
            end,
          },
        }
        stub(mock_utils.fs, "ensurePath").returns(false)
        stub(mock_utils, "cloneRepo").returns(true)
        local setupPlugin1Called = false
        local setupPlugin2Called = false

        mock_requires["test-plugin1"] = {
          setup = function()
            setupPlugin1Called = true
          end,
        }
        mock_requires["test-plugin2"] = {
          setup = function()
            setupPlugin2Called = true
          end,
        }
        -- Act & Assert
        assert.has_no.errors(function()
          loader.setup(plugins, hooks)
        end)

        -- Both plugins should have been processed
        assert.is_true(setupPlugin1Called)
        assert.is_true(setupPlugin2Called)
      end)
      it("should handle missing plugin module gracefully", function()
        -- Arrange
        local postSetup_spy = spy.new(function() end)
        local plugins = {
          {
            "nonexistent/plugin",
            spec = { name = "nonexistent-plugin" },
            options = { test = true },
          },
        }
        local hooks = {
          ["nonexistent/plugin"] = {
            postSetup = postSetup_spy,
          },
        }
        stub(mock_utils.fs, "ensurePath").returns(false)
        stub(mock_utils, "cloneRepo").returns(true)
        -- Don't mock the plugin module to simulate it not existing

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(postSetup_spy).was_called()
      end)
    end)
    describe("multiple plugins", function()
      it("should process multiple plugins correctly", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "catppuccin" },
            options = { flavour = "mocha" },
          },
          {
            "nvim-treesitter/nvim-treesitter",
            spec = { name = "nvim-treesitter" },
            options = { highlight = { enable = true } },
          },
        }
        local hooks = {}
        local catppuccinSetupCalled = false
        local treeSitterSetupCalled = false
        local catppuccinUpdatePackageCalled = false
        local treeSitterUpdatePackageCalled = false

        mock_requires["catppuccin"] = {
          setup = function()
            catppuccinSetupCalled = true
          end,
        }
        mock_requires["nvim-treesitter"] = {
          setup = function()
            treeSitterSetupCalled = true
          end,
        }
        stub(mock_utils.fs, "ensurePath").returns(true)
        stub(mock_utils.vcs, "cloneRepo").returns(true)
        stub(mock_utils, "updatePackagePath").invokes(function(path)
          if path == "/test/plugins/catppuccin" then
            catppuccinUpdatePackageCalled = true
          end
          if path == "/test/plugins/nvim-treesitter" then
            treeSitterUpdatePackageCalled = true
          end
        end)
        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        -- Both plugins should be cloned
        assert.is_true(catppuccinSetupCalled)
        assert.is_true(treeSitterSetupCalled)

        -- Both plugins should be added to runtime path
        assert.is_true(treeSitterUpdatePackageCalled)
        assert.is_true(catppuccinUpdatePackageCalled)
      end)
    end)

    describe("plugin path normalization", function()
      it("should use spec.name when provided", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "custom-catppuccin-name" },
            options = { flavour = "mocha" },
          },
        }
        local hooks = {}
        local cloneRepoSpy = spy.new(function(repoDetails) --luacheck: ignore 212
          return true
        end)
        stub(mock_utils.fs, "ensurePath").returns(false)
        stub(mock_utils.vcs, "cloneRepo").invokes(cloneRepoSpy)

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(cloneRepoSpy).was_called_with({
          repo = "https://github.com/catppuccin/nvim",
          path = "/test/plugins/custom-catppuccin-name",
        })
      end)

      it("should normalize plugin path when spec.name not provided", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = {},
            options = { flavour = "mocha" },
          },
        }
        local hooks = {}
        local cloneRepoSpy = spy.new(function(repoDetails) --luacheck: ignore 212
          return true
        end)
        stub(mock_utils.fs, "ensurePath").returns(false)
        stub(mock_utils.vcs, "cloneRepo").invokes(cloneRepoSpy)
        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.spy(cloneRepoSpy).was_called_with({
          repo = "https://github.com/catppuccin/nvim",
          path = "/test/plugins/catppuccin-nvim",
        })
      end)
    end)

    describe("edge cases and error handling", function()
      it("should handle plugins with missing options", function()
        -- Arrange
        local plugins = {
          {
            "catppuccin/nvim",
            spec = { name = "catppuccin" },
          },
        }
        local hooks = {}
        local setupCalled = false
        stub(mock_utils.fs, "ensurePath").returns(true)
        mock_requires["catppuccin"] = {
          setup = function(options)
            if options == nil then
              setupCalled = true
            end
          end,
        }

        -- Act
        loader.setup(plugins, hooks)

        -- Assert
        assert.is_true(setupCalled)
      end)
    end)
  end)
end)
