describe("nodezero.nvim utils unit tests", function()
  local utils
  before_each(function()
    package.loaded["nodezero.utils"] = nil

    -- Require fresh module instance
    utils = require("nodezero.utils")
  end)
  after_each(function()
    package.loaded["nodezero.utils"] = nil
  end)
  describe("getHooks", function()
    local original_env
    local original_require
    local mock_requires
    local updatePackagePath_spy

    before_each(function()
      -- Store original environment and require
      original_env = vim.env
      original_require = require
      mock_requires = {}

      -- Create spy for updatePackagePath
      updatePackagePath_spy = spy.new(function(path) -- luacheck: ignore 212
        return utils
      end)
      utils.updatePackagePath = updatePackagePath_spy

      -- Mock require function to control what modules return
      _G.require = function(module_name)
        if mock_requires[module_name] then
          return mock_requires[module_name]
        end
        -- If not mocked and it's a hooks module, throw error to simulate not found
        if module_name == "hooks" or module_name == "nodezero.hooks" then
          error("module '" .. module_name .. "' not found")
        end
        return original_require(module_name)
      end
    end)

    after_each(function()
      -- Restore original environment and require
      vim.env = original_env
      _G.require = original_require
    end)

    describe("when NODEZERO_NVIM_HOOKS_PATH is set", function()
      it("should update package path and load hooks from custom path", function()
        -- Arrange
        local custom_hooks_path = "/custom/hooks/path"
        local expected_hooks = {
          ["catppuccin/nvim"] = {
            postSetup = function() end,
          },
        }
        vim.env.NODEZERO_NVIM_HOOKS_PATH = custom_hooks_path
        mock_requires["hooks"] = expected_hooks

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_called_with(custom_hooks_path)
        assert.are.same(expected_hooks, result)
      end)

      it("should handle custom path with trailing slash", function()
        -- Arrange
        local custom_hooks_path = "/custom/hooks/path/"
        local expected_hooks = {
          ["nvim-treesitter/nvim-treesitter"] = {
            config = function() end,
          },
        }
        vim.env.NODEZERO_NVIM_HOOKS_PATH = custom_hooks_path
        mock_requires["hooks"] = expected_hooks

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_called_with(custom_hooks_path)
        assert.are.same(expected_hooks, result)
      end)

      it("should return empty table when custom hooks module not found", function()
        -- Arrange
        local custom_hooks_path = "/custom/hooks/path"
        vim.env.NODEZERO_NVIM_HOOKS_PATH = custom_hooks_path
        -- Don't set mock_requires["hooks"] to simulate module not found

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_called_with(custom_hooks_path)
        assert.are.same({}, result)
      end)

      it("should handle hooks module that returns nil", function()
        -- Arrange
        local custom_hooks_path = "/custom/hooks/path"
        vim.env.NODEZERO_NVIM_HOOKS_PATH = custom_hooks_path
        mock_requires["hooks"] = nil

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_called_with(custom_hooks_path)
        assert.are.same({}, result)
      end)

      it("should handle hooks module that returns non-table value", function()
        -- Arrange
        local custom_hooks_path = "/custom/hooks/path"
        vim.env.NODEZERO_NVIM_HOOKS_PATH = custom_hooks_path
        mock_requires["hooks"] = "not a table"

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_called_with(custom_hooks_path)
        assert.are.same({}, result)
      end)

      it("should handle hooks module that throws error during require", function()
        -- Arrange
        local custom_hooks_path = "/custom/hooks/path"
        vim.env.NODEZERO_NVIM_HOOKS_PATH = custom_hooks_path

        -- Override require to throw error for hooks module
        _G.require = function(module_name)
          if module_name == "hooks" then
            error("Syntax error in hooks module")
          end
          return original_require(module_name)
        end

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_called_with(custom_hooks_path)
        assert.are.same({}, result)
      end)

      it("should handle complex hooks configuration from custom path", function()
        -- Arrange
        local custom_hooks_path = "/custom/hooks/path"
        local complex_hooks = {
          ["catppuccin/nvim"] = {
            preSetup = function() end,
            postSetup = function() end,
          },
          ["nvim-treesitter/nvim-treesitter"] = {
            config = function() end,
          },
          ["telescope.nvim"] = {
            preSetup = function() end,
            config = function() end,
            postSetup = function() end,
          },
        }
        vim.env.NODEZERO_NVIM_HOOKS_PATH = custom_hooks_path
        mock_requires["hooks"] = complex_hooks

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_called_with(custom_hooks_path)
        assert.are.same(complex_hooks, result)
      end)
    end)

    describe("when NODEZERO_NVIM_HOOKS_PATH is not set", function()
      it("should not update package path and load hooks from default location", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = nil
        local expected_hooks = {
          ["catppuccin/nvim"] = {
            postSetup = function() end,
          },
        }
        mock_requires["nodezero.hooks"] = expected_hooks

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_not_called()
        assert.are.same(expected_hooks, result)
      end)

      it("should return empty table when default hooks module not found", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = nil
        -- Don't set mock_requires["nodezero.hooks"] to simulate module not found

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_not_called()
        assert.are.same({}, result)
      end)

      it("should handle default hooks module that returns nil", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = nil
        mock_requires["nodezero.hooks"] = nil

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_not_called()
        assert.are.same({}, result)
      end)

      it("should handle default hooks module that returns non-table value", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = nil
        mock_requires["nodezero.hooks"] = 42

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_not_called()
        assert.are.same({}, result)
      end)

      it("should handle error when loading default hooks module", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = nil

        -- Override require to throw error for default hooks module
        _G.require = function(module_name)
          if module_name == "nodezero.hooks" then
            error("Syntax error in default hooks module")
          end
          return original_require(module_name)
        end

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_not_called()
        assert.are.same({}, result)
      end)

      it("should load complex hooks configuration from default location", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = nil
        local complex_hooks = {
          ["catppuccin/nvim"] = {
            preSetup = function() end,
            postSetup = function() end,
          },
          ["nvim-treesitter/nvim-treesitter"] = {
            config = function() end,
          },
          ["telescope.nvim"] = {
            preSetup = function() end,
            config = function() end,
            postSetup = function() end,
          },
        }
        mock_requires["nodezero.hooks"] = complex_hooks

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_not_called()
        assert.are.same(complex_hooks, result)
      end)
    end)

    describe("when NODEZERO_NVIM_HOOKS_PATH is empty string", function()
      it("should treat empty string as not set and use default behavior", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = ""
        local expected_hooks = {
          ["catppuccin/nvim"] = {
            postSetup = function() end,
          },
        }
        mock_requires["nodezero.hooks"] = expected_hooks

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_not_called()
        assert.are.same(expected_hooks, result)
      end)

      it("should treat whitespace-only string as not set", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = "   \t\n   "
        local expected_hooks = {
          ["catppuccin/nvim"] = {
            postSetup = function() end,
          },
        }
        mock_requires["nodezero.hooks"] = expected_hooks

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_not_called()
        assert.are.same(expected_hooks, result)
      end)
    end)

    describe("consistency and edge cases", function()
      it("should be consistent across multiple calls with custom path", function()
        -- Arrange
        local custom_hooks_path = "/custom/hooks/path"
        local expected_hooks = {
          ["catppuccin/nvim"] = {
            postSetup = function() end,
          },
        }
        vim.env.NODEZERO_NVIM_HOOKS_PATH = custom_hooks_path
        mock_requires["hooks"] = expected_hooks

        -- Act
        local result1 = utils.getHooks()
        local result2 = utils.getHooks()

        -- Assert
        assert.are.same(result1, result2)
        assert.spy(updatePackagePath_spy).was_called(2)
      end)

      it("should be consistent across multiple calls with default path", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = nil
        local expected_hooks = {
          ["catppuccin/nvim"] = {
            postSetup = function() end,
          },
        }
        mock_requires["nodezero.hooks"] = expected_hooks

        -- Act
        local result1 = utils.getHooks()
        local result2 = utils.getHooks()

        -- Assert
        assert.are.same(result1, result2)
        assert.spy(updatePackagePath_spy).was_not_called()
      end)

      it("should handle hooks table with invalid structure gracefully", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = nil
        local malformed_hooks = {
          ["valid/plugin"] = {
            postSetup = function() end,
          },
          ["invalid/plugin"] = "not a table",
          [123] = {
            config = function() end,
          },
          ["another/valid"] = {
            preSetup = function() end,
            invalidHook = function() end, -- Invalid hook type
          },
        }
        mock_requires["nodezero.hooks"] = malformed_hooks

        -- Act
        local result = utils.getHooks()

        -- Assert
        -- Should return the table as-is - validation happens elsewhere
        assert.are.same(malformed_hooks, result)
      end)

      it("should handle custom paths with special characters", function()
        -- Arrange
        local special_path = "/custom/path-with_special.chars/hooks"
        local expected_hooks = {
          ["catppuccin/nvim"] = {
            postSetup = function() end,
          },
        }
        vim.env.NODEZERO_NVIM_HOOKS_PATH = special_path
        mock_requires["hooks"] = expected_hooks

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_called_with(special_path)
        assert.are.same(expected_hooks, result)
      end)

      it("should handle empty hooks table", function()
        -- Arrange
        vim.env.NODEZERO_NVIM_HOOKS_PATH = nil
        mock_requires["nodezero.hooks"] = {}

        -- Act
        local result = utils.getHooks()

        -- Assert
        assert.are.same({}, result)
      end)
    end)

    describe("package path handling", function()
      it("should call updatePackagePath with exact custom path", function()
        -- Arrange
        local custom_hooks_path = "/exact/custom/path"
        vim.env.NODEZERO_NVIM_HOOKS_PATH = custom_hooks_path
        mock_requires["hooks"] = {}

        -- Act
        utils.getHooks()

        -- Assert
        assert.spy(updatePackagePath_spy).was_called_with(custom_hooks_path)
      end)
    end)
  end)
  describe("ensurePath", function()
    local test_base_dir

    before_each(function()
      -- Create a temporary test directory in the XDG test structure
      test_base_dir = vim.fn.expand("tests/xdg/local/test_paths")

      -- Clean up any existing test directories
      vim.fn.system("rm -rf " .. test_base_dir)
    end)

    after_each(function()
      -- Clean up test directories after each test
      if test_base_dir then
        vim.fn.system("rm -rf " .. test_base_dir)
      end
    end)

    describe("when path exists", function()
      it("should return true for existing directory when create is true", function()
        -- Arrange: Create the directory first
        local test_path = test_base_dir .. "/existing_dir"
        vim.fn.mkdir(test_path, "p")

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should return true for existing directory when create is false", function()
        -- Arrange: Create the directory first
        local test_path = test_base_dir .. "/existing_dir"
        vim.fn.mkdir(test_path, "p")

        -- Act
        local result = utils.fs.ensurePath(test_path, false)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should return true for existing directory when create is nil", function()
        -- Arrange: Create the directory first
        local test_path = test_base_dir .. "/existing_dir"
        vim.fn.mkdir(test_path, "p")

        -- Act
        local result = utils.fs.ensurePath(test_path, nil)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should return true for existing file when path points to a file", function()
        -- Arrange: Create a file instead of directory
        local test_dir = test_base_dir .. "/file_test"
        local test_file = test_dir .. "/existing_file.txt"
        vim.fn.mkdir(test_dir, "p")
        vim.fn.writefile({ "test content" }, test_file)

        -- Act
        local result = utils.fs.ensurePath(test_file, false)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.filereadable(test_file))
      end)
    end)

    describe("when path does not exist", function()
      it("should create directory and return true when create is true", function()
        -- Arrange
        local test_path = test_base_dir .. "/new_dir"

        -- Verify path doesn't exist initially
        assert.are.equal(0, vim.fn.isdirectory(test_path))

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should throw error when create is false and path doesn't exist", function()
        -- Arrange
        local test_path = test_base_dir .. "/nonexistent_dir"

        -- Verify path doesn't exist initially
        assert.are.equal(0, vim.fn.isdirectory(test_path))

        -- Act & Assert
        assert.has_error(function()
          utils.fs.ensurePath(test_path, false)
        end, "Path does not exist: " .. test_path)

        -- Verify path was not created
        assert.are.equal(0, vim.fn.isdirectory(test_path))
      end)

      it("should throw error when create is nil and path doesn't exist", function()
        -- Arrange
        local test_path = test_base_dir .. "/nonexistent_dir"

        -- Verify path doesn't exist initially
        assert.are.equal(0, vim.fn.isdirectory(test_path))

        -- Act & Assert
        assert.has_error(function()
          utils.fs.ensurePath(test_path, nil)
        end, "Path does not exist: " .. test_path)

        -- Verify path was not created
        assert.are.equal(0, vim.fn.isdirectory(test_path))
      end)

      it("should create nested directories when create is true", function()
        -- Arrange
        local test_path = test_base_dir .. "/nested/deep/directory/structure"

        -- Verify path doesn't exist initially
        assert.are.equal(0, vim.fn.isdirectory(test_path))

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
        -- Verify intermediate directories were also created
        assert.are.equal(1, vim.fn.isdirectory(test_base_dir .. "/nested"))
        assert.are.equal(1, vim.fn.isdirectory(test_base_dir .. "/nested/deep"))
      end)
    end)

    describe("edge cases", function()
      it("should throw error for empty string path", function()
        -- Act & Assert
        assert.has_error(function()
          utils.fs.ensurePath("", true)
        end, "Path cannot be empty")
      end)

      it("should throw error for nil path", function()
        -- Act & Assert
        assert.has_error(function()
          utils.fs.ensurePath(nil, true)
        end, "Path cannot be nil or empty")
      end)

      it("should handle path with tilde expansion", function()
        -- Arrange
        local test_path = "~/test_ensure_path_dir"
        local expanded_path = vim.fn.expand(test_path)

        -- Clean up in case it exists
        vim.fn.system("rm -rf " .. expanded_path)

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(expanded_path))

        -- Clean up
        vim.fn.system("rm -rf " .. expanded_path)
      end)

      it("should handle paths with environment variables", function()
        -- Arrange
        local test_path = "$XDG_DATA_HOME/test_ensure_path"
        local expanded_path = vim.fn.expand(test_path)

        -- Clean up in case it exists
        vim.fn.system("rm -rf " .. expanded_path)

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(expanded_path))

        -- Clean up
        vim.fn.system("rm -rf " .. expanded_path)
      end)

      it("should handle paths with special characters", function()
        -- Arrange
        local test_path = test_base_dir .. "/dir with spaces & special-chars_123"

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should handle very long paths", function()
        -- Arrange
        local long_segment = string.rep("a", 50)
        local test_path = test_base_dir .. "/" .. long_segment .. "/" .. long_segment

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)
    end)

    describe("permission and error handling", function()
      it("should throw error when creation fails", function()
        -- Arrange: Try to create in a location that might fail (like root)
        local test_path = "/root/should_fail_to_create"

        -- Act & Assert
        assert.has_error(function()
          utils.fs.ensurePath(test_path, true)
        end) -- Error message will depend on the actual failure reason
      end)

      it("should be consistent across multiple calls", function()
        -- Arrange
        local test_path = test_base_dir .. "/consistent_test"

        -- Act: Call multiple times
        local result1 = utils.fs.ensurePath(test_path, true)
        local result2 = utils.fs.ensurePath(test_path, true)
        local result3 = utils.fs.ensurePath(test_path, false)

        -- Assert: All calls should return true once created
        assert.is_true(result1)
        assert.is_true(result2)
        assert.is_true(result3)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should throw error when trying to check nonexistent path with create=false after creation", function()
        -- Arrange
        local existing_path = test_base_dir .. "/existing"
        local nonexistent_path = test_base_dir .. "/nonexistent"

        -- Create one path
        utils.fs.ensurePath(existing_path, true)

        -- Act & Assert: Should still throw error for nonexistent path
        assert.has_error(function()
          utils.fs.ensurePath(nonexistent_path, false)
        end, "Path does not exist: " .. nonexistent_path)
      end)
    end)

    describe("path normalization", function()
      it("should handle paths with trailing slashes", function()
        -- Arrange
        local test_path = test_base_dir .. "/trailing_slash/"

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should handle paths with multiple consecutive slashes", function()
        -- Arrange
        local test_path = test_base_dir .. "//multiple///slashes"

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        -- The directory should exist (vim.fn.mkdir normalizes paths)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should handle relative paths", function()
        -- Arrange: Save current directory and change to test location
        local original_cwd = vim.fn.getcwd()
        vim.fn.mkdir(test_base_dir, "p")
        vim.cmd("cd " .. test_base_dir)

        local test_path = "./relative_test_dir"

        -- Act
        local result = utils.fs.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))

        -- Clean up: Restore original directory
        vim.cmd("cd " .. original_cwd)
      end)
    end)
  end)
end)
