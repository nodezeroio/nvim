describe("Busted unit testing framework", function()
  describe("profiles.utils", function()

      local profile_utils
      local original_env
      local mock_env

      before_each(function()
        -- Store original environment
        mock_env = {}
        original_env = vim.env.NODEZERO_NVIM_PROFILES_PATH
        -- _G.vim = {
        --     env = mock_env
        -- }
        -- Clear any existing cache of the module
        package.loaded["utils.global"] = nil

        -- Require fresh module instance
        require("utils.global")
        profile_utils = NodeZeroVim.utils.profiles
      end)

      after_each(function()
        -- Restore original environment
        vim.env.NODEZERO_NVIM_PROFILES_PATH = original_env

        -- Clean up module cache
        package.loaded["utils.global"] = nil
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
