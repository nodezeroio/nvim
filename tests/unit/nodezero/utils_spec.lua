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
        local result = utils.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should return true for existing directory when create is false", function()
        -- Arrange: Create the directory first
        local test_path = test_base_dir .. "/existing_dir"
        vim.fn.mkdir(test_path, "p")

        -- Act
        local result = utils.ensurePath(test_path, false)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should return true for existing directory when create is nil", function()
        -- Arrange: Create the directory first
        local test_path = test_base_dir .. "/existing_dir"
        vim.fn.mkdir(test_path, "p")

        -- Act
        local result = utils.ensurePath(test_path, nil)

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
        local result = utils.ensurePath(test_file, false)

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
        local result = utils.ensurePath(test_path, true)

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
          utils.ensurePath(test_path, false)
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
          utils.ensurePath(test_path, nil)
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
        local result = utils.ensurePath(test_path, true)

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
          utils.ensurePath("", true)
        end, "Path cannot be empty")
      end)

      it("should throw error for nil path", function()
        -- Act & Assert
        assert.has_error(function()
          utils.ensurePath(nil, true)
        end, "Path cannot be nil or empty")
      end)

      it("should handle path with tilde expansion", function()
        -- Arrange
        local test_path = "~/test_ensure_path_dir"
        local expanded_path = vim.fn.expand(test_path)

        -- Clean up in case it exists
        vim.fn.system("rm -rf " .. expanded_path)

        -- Act
        local result = utils.ensurePath(test_path, true)

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
        local result = utils.ensurePath(test_path, true)

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
        local result = utils.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should handle very long paths", function()
        -- Arrange
        local long_segment = string.rep("a", 50)
        local test_path = test_base_dir .. "/" .. long_segment .. "/" .. long_segment

        -- Act
        local result = utils.ensurePath(test_path, true)

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
          utils.ensurePath(test_path, true)
        end) -- Error message will depend on the actual failure reason
      end)

      it("should be consistent across multiple calls", function()
        -- Arrange
        local test_path = test_base_dir .. "/consistent_test"

        -- Act: Call multiple times
        local result1 = utils.ensurePath(test_path, true)
        local result2 = utils.ensurePath(test_path, true)
        local result3 = utils.ensurePath(test_path, false)

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
        utils.ensurePath(existing_path, true)

        -- Act & Assert: Should still throw error for nonexistent path
        assert.has_error(function()
          utils.ensurePath(nonexistent_path, false)
        end, "Path does not exist: " .. nonexistent_path)
      end)
    end)

    describe("path normalization", function()
      it("should handle paths with trailing slashes", function()
        -- Arrange
        local test_path = test_base_dir .. "/trailing_slash/"

        -- Act
        local result = utils.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))
      end)

      it("should handle paths with multiple consecutive slashes", function()
        -- Arrange
        local test_path = test_base_dir .. "//multiple///slashes"

        -- Act
        local result = utils.ensurePath(test_path, true)

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
        local result = utils.ensurePath(test_path, true)

        -- Assert
        assert.is_true(result)
        assert.are.equal(1, vim.fn.isdirectory(test_path))

        -- Clean up: Restore original directory
        vim.cmd("cd " .. original_cwd)
      end)
    end)
  end)
end)
