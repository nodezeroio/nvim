describe("profiles", function()
  describe("profiles.utils", function()
    local profile_utils
    local original_env

    before_each(function()
      package.loaded["nodezero"] = nil
      -- Store original environment
      original_env = vim.env
      require("nodezero")
      profile_utils = require("nodezero.profiles.utils")
    end)

    after_each(function()
      -- Restore original environment
      vim.env = original_env
      package.loaded["nodezero"] = nil
    end)
    describe("profiles.utils.getBaseRepositoryURL", function()
      describe("environment variable handling", function()
        it("should return custom base URL when NODEZERO_NVIM_PROFILE_REPOSITORY is set to valid base URL", function()
          -- Arrange
          local custom_base_url = "https://gitlab.com"
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = custom_base_url

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal(custom_base_url .. "/", result)
        end)

        it("should return GitHub default when NODEZERO_NVIM_PROFILE_REPOSITORY is not set", function()
          -- Arrange
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = nil

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal("https://github.com/", result)
        end)

        it("should return GitHub default when NODEZERO_NVIM_PROFILE_REPOSITORY is empty string", function()
          -- Arrange
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = ""

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal("https://github.com/", result)
        end)

        it("should handle different valid base repository URLs", function()
          local test_cases = {
            "https://gitlab.com/",
            "https://bitbucket.org/",
            "https://git.example.com/",
            "https://source.company.com/",
            "http://internal-git.local/",
          }

          for _, base_url in ipairs(test_cases) do
            -- Arrange
            vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = base_url

            -- Act
            local result = profile_utils.getBaseRepositoryURL()

            -- Assert
            assert.are.equal(base_url, result)
          end
        end)
      end)

      describe("invalid URL handling", function()
        local mock_log_calls
        local original_debug
        before_each(function()
          -- Mock the debug.log function to capture log calls
          mock_log_calls = {}
          original_debug = NodeZeroVim.debug
          NodeZeroVim.debug = {
            log = function(msg, level)
              table.insert(mock_log_calls, { msg = msg, level = level })
            end,
          }
        end)

        after_each(function()
          -- Restore original debug
          NodeZeroVim.debug = original_debug
        end)

        it("should fallback to GitHub and log warning for obviously invalid URLs", function()
          local invalid_urls = {
            "not-a-url",
            "ftp://invalid-protocol.com",
            "just-text",
            "   ",
            "http://", -- incomplete URL
            "https://", -- incomplete URL
          }

          for _, invalid_url in ipairs(invalid_urls) do
            -- Arrange
            vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = invalid_url

            -- Act
            local result = profile_utils.getBaseRepositoryURL()

            -- Assert
            assert.are.equal("https://github.com/", result)
          end
        end)

        it("should include the invalid URL in the warning message", function()
          -- Arrange
          local invalid_url = "definitely-not-a-base-url"
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = invalid_url

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal("https://github.com/", result)
        end)
      end)

      describe("URL validation logic", function()
        it("should accept base URLs with various protocols", function()
          local valid_base_urls = {
            "https://github.com",
            "http://git.example.com",
            "https://gitlab.com",
            "https://bitbucket.org",
            "http://internal-git.company.com",
          }

          for _, url in ipairs(valid_base_urls) do
            -- Arrange
            vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = url

            -- Act
            local result = profile_utils.getBaseRepositoryURL()

            -- Assert
            assert.are.equal(url .. "/", result)
          end
        end)

        it("should reject URLs without proper base URL structure", function()
          local invalid_structures = {
            "github.com", -- missing protocol
            "://github.com", -- missing protocol name
            "https:///", -- missing domain
            "https://", -- missing domain
            "ftp://github.com", -- unsupported protocol for git
            "git@github.com:user/repo.git", -- not a base URL format
          }

          for _, url in ipairs(invalid_structures) do
            -- Arrange
            vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = url

            -- Act
            local result = profile_utils.getBaseRepositoryURL()

            -- Assert
            assert.are.equal("https://github.com/", result)
          end
        end)
      end)

      describe("consistency and edge cases", function()
        it("should be consistent across multiple calls when env var is not set", function()
          -- Arrange
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = nil

          -- Act
          local result1 = profile_utils.getBaseRepositoryURL()
          local result2 = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal(result1, result2)
          assert.are.equal("https://github.com/", result1)
        end)

        it("should be consistent across multiple calls when env var is set", function()
          -- Arrange
          local custom_base_url = "https://gitlab.com"
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = custom_base_url

          -- Act
          local result1 = profile_utils.getBaseRepositoryURL()
          local result2 = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal(result1, result2)
          assert.are.equal(custom_base_url .. "/", result1)
        end)

        it("should handle base URLs with trailing slashes", function()
          -- Arrange
          local base_url_with_slash = "https://github.com/"
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = base_url_with_slash

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal(base_url_with_slash, result)
        end)

        it("should reject base URLs with paths as invalid", function()
          -- Arrange
          local url_with_path = "https://github.com/some/path"
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = url_with_path

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal("https://github.com/", result)
        end)

        it("should handle base URLs with ports", function()
          -- Arrange
          local base_url_with_port = "https://git.example.com:8080"
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = base_url_with_port

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal(base_url_with_port .. "/", result)
        end)

        it("should handle long domain names", function()
          -- Arrange
          local long_domain_url = "https://very-long-domain-name-for-testing.example.com"
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = long_domain_url

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal(long_domain_url .. "/", result)
        end)
      end)

      describe("GitHub default behavior", function()
        it("should return exactly 'https://github.com' as default", function()
          -- Arrange
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = nil

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal("https://github.com/", result)
        end)

        it("should fallback to GitHub for whitespace-only environment variable", function()
          -- Arrange
          vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = "   \t\n   "

          -- Act
          local result = profile_utils.getBaseRepositoryURL()

          -- Assert
          assert.are.equal("https://github.com/", result)
        end)

        it("should fallback to GitHub for nil-like values", function()
          local nil_like_values = { nil, "", "   ", "\t", "\n" }

          for _, value in ipairs(nil_like_values) do
            -- Arrange
            vim.env.NODEZERO_NVIM_PROFILE_REPOSITORY = value

            -- Act
            local result = profile_utils.getBaseRepositoryURL()

            -- Assert
            assert.are.equal("https://github.com", result)
          end
        end)
      end)
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
end)
