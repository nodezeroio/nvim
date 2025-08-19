describe("nodezero.profiles.loader", function()
  local loader
  local mock_utils
  local mock_profile_utils
  local mock_git_utils
  local original_require
  local mock_requires

  before_each(function()
    -- Clear all loaded modules
    local original_profile_utils = require("nodezero.profiles.utils")
    package.loaded["nodezero.profiles.loader"] = nil
    package.loaded["nodezero.profiles.profile-configs"] = nil
    package.loaded["nodezero"] = nil

    -- Initialize the global object
    require("nodezero")

    -- Create mocks for dependencies
    mock_utils = {
      updatePackagePath = function(path)
        return path
      end,
      fs = {
        ensurePath = function()
          return true
        end,
      },
      vcs = {
        cloneRepo = function()
          return true
        end,
      },
    }

    mock_profile_utils = {
      getBaseRepositoryURL = function()
        return "https://github.com/"
      end,
      getProfilesPath = function()
        return "/test/profiles/path"
      end,
      normalizeProfileDefinitions = original_profile_utils.normalizeProfileDefinitions,
      normalizePluginDependencies = original_profile_utils.normalizePluginDependencies,
      mergePlugins = original_profile_utils.mergePlugins,
    }

    mock_git_utils = {
      cloneRepo = function()
        return true
      end,
    }

    -- Mock require function to control what modules return
    mock_requires = {}
    original_require = require
    _G.require = function(module_name)
      if mock_requires[module_name] then
        return mock_requires[module_name]
      end
      return original_require(module_name)
    end

    package.loaded["nodezero.profiles.utils"] = nil
    -- Set up module mocks
    mock_requires["nodezero.utils"] = mock_utils
    mock_requires["nodezero.profiles.utils"] = mock_profile_utils
    mock_requires["nodezero.utils.git"] = mock_git_utils

    -- Load the module under test
    loader = require("nodezero.profiles.loader")

    -- Reset loaded state
    loader.loaded = {}
  end)

  after_each(function()
    -- Restore original require function
    _G.require = original_require
    package.loaded["nodezero.profiles.loader"] = nil
    package.loaded["nodezero"] = nil
  end)

  describe("setup", function()
    describe("basic functionality", function()
      it("should return M when called", function()
        -- Arrange
        mock_requires["nodezero.profiles.profile-configs"] = {}

        -- Act
        local result = loader.setup().load()

        -- Assert
        assert.are.equal(loader, result)
      end)
      it("should handle empty profile config", function()
        -- Arrange
        mock_requires["nodezero.profiles.profile-configs"] = {}

        -- Act
        loader.setup().load()

        -- Assert
        assert.are.same({ plugins = {}, profiles = {} }, loader.loaded)
      end)
      it("should set loaded to result of mergePlugins", function()
        -- Arrange
        local expected_merged_plugins = {
          { "test/plugin", spec = { name = "test" } },
        }
        local profile_configs = {
          {
            "test/profile",
          },
        }
        mock_profile_utils.mergePlugins = spy.new(function()
          return expected_merged_plugins
        end)
        mock_requires["nodezero.profiles.profile-configs"] = profile_configs
        mock_requires["test-profile"] = {
          "test/profile",
          plugins = expected_merged_plugins,
        }
        mock_requires["test"] = expected_merged_plugins[1]
        -- Act
        loader.setup().load()
        -- Assert
        assert.spy(mock_profile_utils.mergePlugins).was_called()
        assert.are.same(expected_merged_plugins, loader.loaded.plugins)
      end)
    end)

    describe("profile config loading", function()
      it("should load profiles from nodezero.profiles.profile-configs", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test-profile", spec = { name = "test" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test"] = test_profiles[1]
        mock_profile_utils.normalizeProfileDefinitions = spy.new(function(profiles)
          return profiles
        end)

        -- Act
        loader.setup().load()

        -- Assert
        assert.spy(mock_profile_utils.normalizeProfileDefinitions).was_called_with(test_profiles)
      end)

      it("should handle missing profile-configss gracefully", function()
        -- Arrange
        mock_requires["nodezero.profiles.profile-configss"] = nil

        -- Act & Assert
        assert.has_no.errors(function()
          loader.setup().load()
        end)
        assert.are.same({ plugins = {}, profiles = {} }, loader.loaded)
      end)
    end)

    describe("utility function calls", function()
      it("should call all required utility functions", function()
        -- Arrange
        mock_requires["nodezero.profiles.profile-configs"] = {
          {
            "nodezeroio/nvim-profiles-core",
            spec = {
              name = "core",
            },
          },
        }
        mock_requires["core"] = function() end
        mock_profile_utils.getBaseRepositoryURL = spy.new(function()
          return "https://github.com/"
        end)
        mock_profile_utils.getProfilesPath = spy.new(function()
          return "/test/path"
        end)
        mock_profile_utils.normalizeProfileDefinitions = spy.new(function(profiles)
          return profiles
        end)
        mock_profile_utils.normalizePluginDependencies = spy.new(function(profiles)
          return profiles
        end)
        mock_profile_utils.mergePlugins = spy.new(function()
          return {}
        end)
        -- Act
        loader.setup().load()
        -- Assert
        assert.spy(mock_profile_utils.getBaseRepositoryURL).was_called()
        assert.spy(mock_profile_utils.getProfilesPath).was_called()
        assert.spy(mock_profile_utils.normalizeProfileDefinitions).was_called()
        assert.spy(mock_profile_utils.normalizePluginDependencies).was_called()
        assert.spy(mock_profile_utils.mergePlugins).was_called()
      end)
    end)
    describe("profile directory management", function()
      it("should check if profile path exists using ensurePath", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = test_profiles[1]
        mock_profile_utils.getProfilesPath = function()
          return "/profiles"
        end
        mock_utils.fs.ensurePath = spy.new(function()
          return true
        end)

        -- Act
        loader.setup().load()

        -- Assert
        assert.spy(mock_utils.fs.ensurePath).was_called_with("/profiles/test-profile", false)
      end)

      it("should clone profile when path doesn't exist and vcs is git", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile", vcs = "git" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = {}
        mock_profile_utils.getProfilesPath = function()
          return "/profiles"
        end
        mock_profile_utils.getBaseRepositoryURL = function()
          return "https://github.com/"
        end
        mock_utils.fs.ensurePath = function()
          error("Path does not exist: /profiles/test-profile")
        end
        mock_utils.vcs.cloneRepo = spy.new(function()
          return true
        end)

        -- Act
        loader.setup().load()

        -- Assert
        assert.spy(mock_utils.vcs.cloneRepo).was_called_with({
          repo = "https://github.com/nodezero/test",
          path = "/profiles/test-profile",
        })
      end)

      it("should clone profile when path doesn't exist and vcs is nil (defaults to git)", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = {}
        mock_profile_utils.getProfilesPath = function()
          return "/profiles"
        end
        mock_profile_utils.getBaseRepositoryURL = function()
          return "https://github.com/"
        end
        mock_utils.fs.ensurePath = function()
          error("Path does not exist: /profiles/test-profile")
        end
        mock_utils.vcs.cloneRepo = spy.new(function()
          return true
        end)

        -- Act
        loader.setup().load()

        -- Assert
        assert.spy(mock_utils.vcs.cloneRepo).was_called_with({
          repo = "https://github.com/nodezero/test",
          path = "/profiles/test-profile",
        })
      end)

      it("should throw error when vcs is file and path doesn't exist", function()
        -- Arrange
        local test_profiles = {
          { "local/test", spec = { name = "test-profile", vcs = "file" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_profile_utils.getProfilesPath = function()
          return "/profiles"
        end
        mock_utils.fs.ensurePath = function()
          error("Path does not exist: /profiles/test-profile")
        end

        -- Act & Assert
        assert.has_error(function()
          loader.setup().load()
        end)
      end)

      it("should not clone when profile path already exists", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = {}
        mock_utils.fs.ensurePath = function()
          return true
        end -- Path exists
        mock_utils.vcs.cloneRepo = spy.new(function()
          return true
        end)

        -- Act
        loader.setup().load()

        -- Assert
        assert.spy(mock_utils.vcs.cloneRepo).was_not_called()
      end)
    end)
    describe("vcs validation", function()
      it("should throw error for invalid vcs value", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile", vcs = "invalid" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles

        -- Act & Assert
        assert.has_error(function()
          loader.setup().load()
        end, "Invalid VCS type 'invalid' for profile nodezero/test. Must be nil, 'git', or 'file'")
      end)

      it("should accept nil vcs (defaults to git)", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile", vcs = nil } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = test_profiles[1]
        mock_utils.fs.ensurePath = function()
          return true
        end

        -- Act & Assert
        assert.has_no.errors(function()
          loader.setup().load()
        end)
      end)

      it("should accept git vcs", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile", vcs = "git" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = {}
        mock_utils.fs.ensurePath = function()
          return true
        end

        -- Act & Assert
        assert.has_no.errors(function()
          loader.setup().load()
        end)
      end)

      it("should accept file vcs", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile", vcs = "file" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = {}
        mock_utils.fs.ensurePath = function()
          return true
        end

        -- Act & Assert
        assert.has_no.errors(function()
          loader.setup().load()
        end)
      end)
    end)
    describe("overrides handling", function()
      it("should use override repository when available", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        local overrides = {
          ["nodezero/test"] = "custom/repo",
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = {}
        mock_profile_utils.getProfilesPath = function()
          return "/profiles"
        end
        mock_profile_utils.getBaseRepositoryURL = function()
          return "https://github.com/"
        end
        mock_utils.fs.ensurePath = function()
          error("Path does not exist")
        end
        mock_utils.vcs.cloneRepo = spy.new(function()
          return true
        end)

        -- Act
        loader.setup().load(overrides)

        -- Assert
        assert.spy(mock_utils.vcs.cloneRepo).was_called_with({
          repo = "https://github.com/custom/repo",
          path = "/profiles/test-profile",
        })
      end)

      it("should use original repository when no override available", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        local overrides = {} -- Empty overrides
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = {}
        mock_profile_utils.getProfilesPath = function()
          return "/profiles"
        end
        mock_profile_utils.getBaseRepositoryURL = function()
          return "https://github.com/"
        end
        mock_utils.fs.ensurePath = function()
          error("Path does not exist")
        end
        mock_utils.vcs.cloneRepo = spy.new(function()
          return true
        end)

        -- Act
        loader.setup().load(overrides)

        -- Assert
        assert.spy(mock_utils.vcs.cloneRepo).was_called_with({
          repo = "https://github.com/nodezero/test",
          path = "/profiles/test-profile",
        })
      end)
    end)
    describe("profile config and plugins loading", function()
      it("should load profile plugins when they exist", function()
        -- Arrange
        local test_profiles = {
          {
            "nodezero/test",
            spec = { name = "test-profile" },
            plugins = { { "test/plugin", spec = { name = "test" } } },
          },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = test_profiles[1]
        mock_utils.fs.ensurePath = function()
          return true
        end

        -- Act
        local result = loader.setup().load()
        -- Assert
        assert.are.same(test_profiles[1].plugins, result.loaded.plugins)
      end)
      it("should handle missing config gracefully", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile.config"] = nil
        mock_requires["test-profile"] = {}
        mock_utils.fs.ensurePath = function()
          return true
        end

        -- Act & Assert
        assert.has_no.errors(function()
          loader.setup().load()
        end)
      end)

      it("should handle missing plugins gracefully", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile.plugins"] = nil
        mock_requires["test-profile"] = {}
        mock_utils.fs.ensurePath = function()
          return true
        end

        -- Act & Assert
        assert.has_no.errors(function()
          loader.setup().load()
        end)
      end)

      it("should handle config loading errors gracefully", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = {}
        mock_utils.fs.ensurePath = function()
          return true
        end

        -- Override require to simulate error for config
        local original_mock_require = _G.require
        _G.require = function(module_name)
          if module_name == "test-profile.config" then
            error("Syntax error in config")
          end
          return original_mock_require(module_name)
        end

        -- Act & Assert
        assert.has_no.errors(function()
          loader.setup().load()
        end)
      end)

      it("should handle plugins loading errors gracefully", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["test-profile"] = {}
        mock_utils.fs.ensurePath = function()
          return true
        end

        -- Override require to simulate error for plugins
        local original_mock_require = _G.require
        _G.require = function(module_name)
          if module_name == "test-profile.plugins" then
            error("Syntax error in plugins")
          end
          return original_mock_require(module_name)
        end

        -- Act & Assert
        assert.has_no.errors(function()
          loader.setup().load()
        end)
      end)
    end)
    describe("git clone error handling", function()
      it("should throw error when git clone fails", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/test", spec = { name = "test-profile" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_profile_utils.getProfilesPath = function()
          return "/profiles"
        end
        mock_profile_utils.getBaseRepositoryURL = function()
          return "https://github.com/"
        end
        mock_utils.fs.ensurePath = function()
          error("Path does not exist")
        end
        mock_utils.vcs.cloneRepo = function()
          return false
        end -- Clone fails

        -- Act & Assert
        assert.has_error(function()
          loader.setup().load()
        end, "Failed to clone profile nodezero/test")
      end)
    end)
    describe("multiple profiles handling", function()
      it("should process multiple profiles correctly", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/core", spec = { name = "core" } },
          { "nodezero/ui", spec = { name = "ui", vcs = "file" } },
        }
        local core_plugins = { { "core/plugin", spec = { name = "core" } } }
        local ui_plugins = { { "ui/plugin", spec = { name = "ui" } } }

        mock_requires["core"] = function() end
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["core"] = {
          "nodezero/core",
          plugins = core_plugins,
        }
        mock_requires["ui"] = {
          "nodezero/ui",
          plugins = ui_plugins,
        }
        mock_utils.fs.ensurePath = function()
          return true
        end

        -- Act
        local result = loader.setup().load()

        -- Assert
        assert.are.same(core_plugins[1], result.loaded.plugins[1])
        assert.are.same(ui_plugins[1], result.loaded.plugins[2])
      end)

      it("should continue processing after one profile fails", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/failing", spec = { name = "failing" } },
          { "nodezero/working", spec = { name = "working" } },
        }
        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_profile_utils.getProfilesPath = function()
          return "/profiles"
        end
        mock_profile_utils.getBaseRepositoryURL = function()
          return "https://github.com/"
        end

        -- First profile fails ensurePath, second succeeds
        local call_count = 0
        mock_utils.fs.ensurePath = function(path)
          call_count = call_count + 1
          if call_count == 1 then
            error("Path" .. path .. "does not exist")
          else
            return true
          end
        end

        mock_utils.vcs.cloneRepo = function()
          return false
        end -- Clone fails for first profile

        -- Act & Assert
        assert.has_error(function()
          loader.setup().load()
        end, "Failed to clone profile nodezero/failing")
      end)
    end)

    describe("integration scenarios", function()
      it("should handle complete profile loading workflow", function()
        -- Arrange
        local test_profiles = {
          { "nodezero/complete", spec = { name = "complete-profile" } },
        }
        local test_plugins = {
          { "complete/plugin", spec = { name = "complete" } },
        }

        mock_requires["nodezero.profiles.profile-configs"] = test_profiles
        mock_requires["complete-profile"] = {
          "nodezero/complete",
          plugins = test_plugins,
        }
        mock_utils.fs.ensurePath = function()
          error("Path does not exist")
        end
        mock_utils.vcs.cloneRepo = function()
          return true
        end

        -- Act
        local result = loader.setup().load()
        -- Assert
        assert.are.equal(loader, result)
        assert.are.same(test_plugins, loader.loaded.plugins)
      end)
    end)
  end)
end)
