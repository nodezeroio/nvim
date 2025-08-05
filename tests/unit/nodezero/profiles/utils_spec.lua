describe("profiles.utils", function()
  local profile_utils
  local original_env

  before_each(function()
    -- Store original environment
    original_env = vim.env.NODEZERO_NVIM_PROFILES_PATH
    profile_utils = require("nodezero.profiles.utils")
  end)

  after_each(function()
    -- Restore original environment
    vim.env.NODEZERO_NVIM_PROFILES_PATH = original_env
  end)
  describe("profile.utils.sort", function()
    describe("priority-based sorting", function()
      it("should sort by priority in descending order (highest priority first)", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/low-priority",
            spec = {
              priority = 1,
            },
          },
          {
            "nodezero/high-priority",
            spec = {
              priority = 5,
            },
          },
          {
            "nodezero/medium-priority",
            spec = {
              priority = 3,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/high-priority", sorted_profiles[1][1])
        assert.are.equal("nodezero/medium-priority", sorted_profiles[2][1])
        assert.are.equal("nodezero/low-priority", sorted_profiles[3][1])
      end)

      it("should treat priority 0 as lowest priority", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/zero-priority",
            spec = {
              priority = 0,
            },
          },
          {
            "nodezero/one-priority",
            spec = {
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/one-priority", sorted_profiles[1][1])
        assert.are.equal("nodezero/zero-priority", sorted_profiles[2][1])
      end)

      it("should handle negative priorities correctly", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/negative",
            spec = {
              priority = -1,
            },
          },
          {
            "nodezero/zero",
            spec = {
              priority = 0,
            },
          },
          {
            "nodezero/positive",
            spec = {
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/positive", sorted_profiles[1][1])
        assert.are.equal("nodezero/zero", sorted_profiles[2][1])
        assert.are.equal("nodezero/negative", sorted_profiles[3][1])
      end)
    end)

    describe("name-based sorting when priorities are equal", function()
      it("should sort alphabetically by spec.name when priorities are equal", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/zebra",
            spec = {
              name = "zebra",
              priority = 1,
            },
          },
          {
            "nodezero/alpha",
            spec = {
              name = "alpha",
              priority = 1,
            },
          },
          {
            "nodezero/beta",
            spec = {
              name = "beta",
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("alpha", sorted_profiles[1].spec.name)
        assert.are.equal("beta", sorted_profiles[2].spec.name)
        assert.are.equal("zebra", sorted_profiles[3].spec.name)
      end)

      it("should sort alphabetically by spec.name when no priorities are set", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/zebra",
            spec = {
              name = "zebra",
            },
          },
          {
            "nodezero/alpha",
            spec = {
              name = "alpha",
            },
          },
          {
            "nodezero/beta",
            spec = {
              name = "beta",
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("alpha", sorted_profiles[1].spec.name)
        assert.are.equal("beta", sorted_profiles[2].spec.name)
        assert.are.equal("zebra", sorted_profiles[3].spec.name)
      end)

      it("should handle case-insensitive sorting for spec.name", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/zebra",
            spec = {
              name = "Zebra",
              priority = 1,
            },
          },
          {
            "nodezero/alpha",
            spec = {
              name = "alpha",
              priority = 1,
            },
          },
          {
            "nodezero/Beta",
            spec = {
              name = "Beta",
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("alpha", sorted_profiles[1].spec.name)
        assert.are.equal("Beta", sorted_profiles[2].spec.name)
        assert.are.equal("Zebra", sorted_profiles[3].spec.name)
      end)
    end)

    describe("fallback sorting by profile[1]", function()
      it("should sort by profile[1] when no spec.name and same priority", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/zebra",
            spec = {
              priority = 1,
            },
          },
          {
            "nodezero/alpha",
            spec = {
              priority = 1,
            },
          },
          {
            "nodezero/beta",
            spec = {
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/alpha", sorted_profiles[1][1])
        assert.are.equal("nodezero/beta", sorted_profiles[2][1])
        assert.are.equal("nodezero/zebra", sorted_profiles[3][1])
      end)

      it("should sort by profile[1] when no spec exists", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/zebra",
          },
          {
            "nodezero/alpha",
          },
          {
            "nodezero/beta",
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/alpha", sorted_profiles[1][1])
        assert.are.equal("nodezero/beta", sorted_profiles[2][1])
        assert.are.equal("nodezero/zebra", sorted_profiles[3][1])
      end)

      it("should handle case-insensitive sorting for profile[1]", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/Zebra",
          },
          {
            "nodezero/alpha",
          },
          {
            "nodezero/Beta",
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/alpha", sorted_profiles[1][1])
        assert.are.equal("nodezero/Beta", sorted_profiles[2][1])
        assert.are.equal("nodezero/Zebra", sorted_profiles[3][1])
      end)
    end)

    describe("mixed sorting scenarios", function()
      it("should sort complex example from documentation", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/core",
            spec = {
              name = "core",
              vcs = "git",
              priority = 1,
            },
          },
          {
            "nodezero/csharp",
            spec = {
              priority = 0,
            },
          },
          {
            "nodezero/lua",
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/core", sorted_profiles[1][1])
        assert.are.equal("nodezero/csharp", sorted_profiles[2][1])
        assert.are.equal("nodezero/lua", sorted_profiles[3][1])
      end)

      it("should handle mixed priorities with some having names", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/low-priority-with-name",
            spec = {
              name = "zebra",
              priority = 1,
            },
          },
          {
            "nodezero/high-priority-no-name",
            spec = {
              priority = 5,
            },
          },
          {
            "nodezero/low-priority-alpha-name",
            spec = {
              name = "alpha",
              priority = 1,
            },
          },
          {
            "nodezero/no-priority-no-name",
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        -- Priority 5 comes first
        assert.are.equal("nodezero/high-priority-no-name", sorted_profiles[1][1])
        -- Priority 1 with alpha name comes next
        assert.are.equal("alpha", sorted_profiles[2].spec.name)
        -- Priority 1 with zebra name comes next
        assert.are.equal("zebra", sorted_profiles[3].spec.name)
        -- No priority comes last
        assert.are.equal("nodezero/no-priority-no-name", sorted_profiles[4][1])
      end)

      it("should handle profiles with no spec at all mixed with those that have spec", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/zebra-no-spec",
          },
          {
            "nodezero/alpha-with-spec",
            spec = {
              priority = 1,
            },
          },
          {
            "nodezero/beta-no-spec",
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        -- Priority 1 comes first
        assert.are.equal("nodezero/alpha-with-spec", sorted_profiles[1][1])
        -- Then alphabetical by profile[1]
        assert.are.equal("nodezero/beta-no-spec", sorted_profiles[2][1])
        assert.are.equal("nodezero/zebra-no-spec", sorted_profiles[3][1])
      end)
    end)

    describe("edge cases", function()
      it("should handle empty profile list", function()
        -- Arrange
        local profiles = {}

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal(0, #sorted_profiles)
      end)

      it("should handle single profile", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/single",
            spec = {
              priority = 5,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal(1, #sorted_profiles)
        assert.are.equal("nodezero/single", sorted_profiles[1][1])
      end)

      it("should handle profiles with identical names and priorities", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/duplicate",
            spec = {
              name = "same",
              priority = 1,
            },
          },
          {
            "nodezero/duplicate",
            spec = {
              name = "same",
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal(2, #sorted_profiles)
        -- Order should be preserved or consistent for identical items
        assert.are.equal("nodezero/duplicate", sorted_profiles[1][1])
        assert.are.equal("nodezero/duplicate", sorted_profiles[2][1])
      end)

      it("should handle very large priority values", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/huge-priority",
            spec = {
              priority = 999999,
            },
          },
          {
            "nodezero/normal-priority",
            spec = {
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/huge-priority", sorted_profiles[1][1])
        assert.are.equal("nodezero/normal-priority", sorted_profiles[2][1])
      end)

      it("should handle profiles with nil spec", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/nil-spec",
            spec = nil,
          },
          {
            "nodezero/with-spec",
            spec = {
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/with-spec", sorted_profiles[1][1])
        assert.are.equal("nodezero/nil-spec", sorted_profiles[2][1])
      end)

      it("should handle profiles with empty spec", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/empty-spec",
            spec = {},
          },
          {
            "nodezero/with-priority",
            spec = {
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        assert.are.equal("nodezero/with-priority", sorted_profiles[1][1])
        assert.are.equal("nodezero/empty-spec", sorted_profiles[2][1])
      end)

      it("should not modify the original profiles array", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/zebra",
            spec = {
              priority = 1,
            },
          },
          {
            "nodezero/alpha",
            spec = {
              priority = 2,
            },
          },
        }
        local original_order = { profiles[1][1], profiles[2][1] }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        -- Original array should remain unchanged
        assert.are.equal(original_order[1], profiles[1][1])
        assert.are.equal(original_order[2], profiles[2][1])
        -- But sorted array should be different
        assert.are.equal("nodezero/alpha", sorted_profiles[1][1])
        assert.are.equal("nodezero/zebra", sorted_profiles[2][1])
      end)

      it("should handle profiles with special characters in names", function()
        -- Arrange
        local profiles = {
          {
            "nodezero/special-chars_123",
            spec = {
              name = "special-chars_123",
              priority = 1,
            },
          },
          {
            "nodezero/normal",
            spec = {
              name = "normal",
              priority = 1,
            },
          },
        }

        -- Act
        local sorted_profiles = profile_utils.sort(profiles)

        -- Assert
        -- Should sort alphabetically
        assert.are.equal("normal", sorted_profiles[1].spec.name)
        assert.are.equal("special-chars_123", sorted_profiles[2].spec.name)
      end)
    end)
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
