describe("nodezero.nvim utils unit tests", function()
  before_each(function()
    package.loaded["utils.global"] = nil

    -- Require fresh module instance
    require("utils.global")
  end)
  after_each(function()
    package.loaded["utils.global"] = nil
  end)

  describe("ensurePath", function()
    local test_base_dir
    local ensure_path_utils

    before_each(function()
      -- Create a temporary test directory in the XDG test structure
      test_base_dir = vim.fn.expand("tests/xdg/local/test_paths")
      ensure_path_utils = NodeZeroVim.utils

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
        local result = ensure_path_utils.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should return true for existing directory when create is false", function()
        -- Arrange: Create the directory first
        local test_path = test_base_dir .. "/existing_dir"
        vim.fn.mkdir(test_path, "p")

        -- Act
        local result = ensure_path_utils.ensurePath(test_path, false)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should return true for existing directory when create is nil", function()
        -- Arrange: Create the directory first
        local test_path = test_base_dir .. "/existing_dir"
        vim.fn.mkdir(test_path, "p")

        -- Act
        local result = ensure_path_utils.ensurePath(test_path, nil)

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
        local result = ensure_path_utils.ensurePath(test_file, false)

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
        local result = ensure_path_utils.ensurePath(test_path, true)

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
          ensure_path_utils.ensurePath(test_path, false)
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
          ensure_path_utils.ensurePath(test_path, nil)
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
        local result = ensure_path_utils.ensurePath(test_path, true)

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
          ensure_path_utils.ensurePath("", true)
        end, "Path cannot be empty")
      end)

      it("should throw error for nil path", function()
        -- Act & Assert
        assert.has_error(function()
          ensure_path_utils.ensurePath(nil, true)
        end, "Path cannot be nil or empty")
      end)

      it("should handle path with tilde expansion", function()
        -- Arrange
        local test_path = "~/test_ensure_path_dir"
        local expanded_path = vim.fn.expand(test_path)

        -- Clean up in case it exists
        vim.fn.system("rm -rf " .. expanded_path)

        -- Act
        local result = ensure_path_utils.ensurePath(test_path, true)

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
        local result = ensure_path_utils.ensurePath(test_path, true)

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
        local result = ensure_path_utils.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should handle very long paths", function()
        -- Arrange
        local long_segment = string.rep("a", 50)
        local test_path = test_base_dir .. "/" .. long_segment .. "/" .. long_segment

        -- Act
        local result = ensure_path_utils.ensurePath(test_path, true)

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
          ensure_path_utils.ensurePath(test_path, true)
        end) -- Error message will depend on the actual failure reason
      end)

      it("should be consistent across multiple calls", function()
        -- Arrange
        local test_path = test_base_dir .. "/consistent_test"

        -- Act: Call multiple times
        local result1 = ensure_path_utils.ensurePath(test_path, true)
        local result2 = ensure_path_utils.ensurePath(test_path, true)
        local result3 = ensure_path_utils.ensurePath(test_path, false)

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
        ensure_path_utils.ensurePath(existing_path, true)

        -- Act & Assert: Should still throw error for nonexistent path
        assert.has_error(function()
          ensure_path_utils.ensurePath(nonexistent_path, false)
        end, "Path does not exist: " .. nonexistent_path)
      end)
    end)

    describe("path normalization", function()
      it("should handle paths with trailing slashes", function()
        -- Arrange
        local test_path = test_base_dir .. "/trailing_slash/"

        -- Act
        local result = ensure_path_utils.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should handle paths with multiple consecutive slashes", function()
        -- Arrange
        local test_path = test_base_dir .. "//multiple///slashes"

        -- Act
        local result = ensure_path_utils.ensurePath(test_path, true)

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
        local result = ensure_path_utils.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))

        -- Clean up: Restore original directory
        vim.cmd("cd " .. original_cwd)
      end)
    end)
  end)
  describe("profiles.utils", function()
    local profile_utils
    local original_env

    before_each(function()
      -- Store original environment
      original_env = vim.env.NODEZERO_NVIM_PROFILES_PATH
      -- Clear any existing cache of the module
      package.loaded["utils.global"] = nil

      -- Require fresh module instance
      require("utils.global")
      profile_utils = NodeZeroVim.utils.profiles
    end)

    after_each(function()
      -- Restore original environment
      vim.env.NODEZERO_NVIM_PROFILES_PATH = original_env
    end)

    describe("getProfilesPath", function()
      it("should return default path when NODEZERO_NVIM_PROFILES_PATH is not set", function()
        -- Arrange: Clear the environment variable
        vim.env.NODEZERO_NVIM_PROFILES_PATH = nil

        -- Act
        local result = profile_utils.getProfilesPath()

        -- Assert
        local expected = vim.fn.expand("$XDG_DATA_HOME/nodezero.nvim/profiles")
        assert.are.equal(expected, result)
      end)

      it("should return default path when NODEZERO_NVIM_PROFILES_PATH is empty string", function()
        -- Arrange: Set environment variable to empty string
        vim.env.NODEZERO_NVIM_PROFILES_PATH = ""

        -- Act
        local result = profile_utils.getProfilesPath()

        -- Assert
        local expected = vim.fn.expand("$XDG_DATA_HOME/nodezero.nvim/profiles")
        assert.are.equal(expected, result)
      end)

      it("should return custom path when NODEZERO_NVIM_PROFILES_PATH is set", function()
        -- Arrange: Set custom environment variable
        local custom_path = "/custom/profiles/path"
        vim.env.NODEZERO_NVIM_PROFILES_PATH = custom_path

        -- Act
        local result = profile_utils.getProfilesPath()

        -- Assert
        assert.are.equal(custom_path, result)
      end)

      it("should return custom path with tilde expansion when set", function()
        -- Arrange: Set custom environment variable with tilde
        local custom_path = "~/my-custom-profiles"
        vim.env.NODEZERO_NVIM_PROFILES_PATH = custom_path

        -- Act
        local result = profile_utils.getProfilesPath()

        -- Assert
        assert.are.equal(custom_path, result)
      end)

      it("should return custom absolute path when set", function()
        -- Arrange: Set custom absolute path
        local custom_path = "/home/user/projects/nvim-profiles"
        vim.env.NODEZERO_NVIM_PROFILES_PATH = custom_path

        -- Act
        local result = profile_utils.getProfilesPath()

        -- Assert
        assert.are.equal(custom_path, result)
      end)

      it("should handle paths with trailing slashes", function()
        -- Arrange: Set custom path with trailing slash
        local custom_path = "/custom/profiles/path/"
        vim.env.NODEZERO_NVIM_PROFILES_PATH = custom_path

        -- Act
        local result = profile_utils.getProfilesPath()

        -- Assert
        assert.are.equal(custom_path, result)
      end)

      it("should be consistent across multiple calls when env var is not set", function()
        -- Arrange: Clear environment variable
        vim.env.NODEZERO_NVIM_PROFILES_PATH = nil

        -- Act
        local result1 = profile_utils.getProfilesPath()
        local result2 = profile_utils.getProfilesPath()

        -- Assert
        assert.are.equal(result1, result2)
        local expected = vim.fn.expand("$XDG_DATA_HOME/nodezero.nvim/profiles")
        assert.are.equal(expected, result1)
      end)

      it("should be consistent across multiple calls when env var is set", function()
        -- Arrange: Set custom environment variable
        local custom_path = "/consistent/custom/path"
        vim.env.NODEZERO_NVIM_PROFILES_PATH = custom_path

        -- Act
        local result1 = profile_utils.getProfilesPath()
        local result2 = profile_utils.getProfilesPath()

        -- Assert
        assert.are.equal(result1, result2)
        assert.are.equal(custom_path, result1)
      end)

      describe("edge cases", function()
        it("should handle whitespace-only environment variable", function()
          -- Arrange: Set environment variable to whitespace
          vim.env.NODEZERO_NVIM_PROFILES_PATH = "   "

          -- Act
          local result = profile_utils.getProfilesPath()

          -- Assert: Should return the whitespace as-is (let the caller handle validation)
          assert.are.equal("   ", result)
        end)

        it("should handle very long custom paths", function()
          -- Arrange: Set a very long custom path
          local custom_path = "/very/long/path/that/goes/on/and/on/and/on/profiles"
          vim.env.NODEZERO_NVIM_PROFILES_PATH = custom_path

          -- Act
          local result = profile_utils.getProfilesPath()

          -- Assert
          assert.are.equal(custom_path, result)
        end)
      end)
    end)
  end)
end)
