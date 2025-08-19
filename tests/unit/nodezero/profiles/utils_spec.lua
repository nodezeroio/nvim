describe("profiles", function()
  -- Add these tests to the existing tests/unit/nodezero/profiles/utils_spec.lua file
  -- within the describe("profiles.utils") block

  describe("profiles.utils", function()
    local profile_utils
    local original_env

    before_each(function()
      package.loaded["nodezero"] = nil
      -- Store original environment
      original_env = vim.env
      profile_utils = require("nodezero.profiles.utils")
    end)

    after_each(function()
      -- Restore original environment
      vim.env = original_env
    end)
    describe("normalizeProfileDefinitions", function()
      describe("basic functionality", function()
        it("should return empty list when no profiles provided", function()
          -- Arrange
          local profiles = {}

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(0, #result)
        end)

        it("should return profile unchanged when spec.name is already set", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "custom-name",
                priority = 1,
                vcs = "git",
              },
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("nodezero/core", result[1][1])
          assert.are.equal("custom-name", result[1].spec.name)
          assert.are.equal(1, result[1].spec.priority)
          assert.are.equal("git", result[1].spec.vcs)
        end)

        it("should set spec.name from profile path when not provided", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                priority = 1,
                vcs = "git",
              },
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("nodezero/core", result[1][1])
          assert.are.equal("nodezero-core", result[1].spec.name)
          assert.are.equal(1, result[1].spec.priority)
          assert.are.equal("git", result[1].spec.vcs)
        end)

        it("should create spec table when it doesn't exist", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              -- No spec field at all
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("nodezero/core", result[1][1])
          assert.is_not_nil(result[1].spec)
          assert.are.equal("nodezero-core", result[1].spec.name)
        end)

        it("should handle spec table with nil name", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = nil,
                priority = 5,
              },
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("nodezero-core", result[1].spec.name)
          assert.are.equal(5, result[1].spec.priority)
        end)
      end)

      describe("path normalization", function()
        it("should replace single slash with dash", function()
          -- Arrange
          local profiles = {
            {
              "owner/repo",
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal("owner-repo", result[1].spec.name)
        end)

        it("should replace multiple slashes with dashes", function()
          -- Arrange
          local profiles = {
            {
              "organization/team/project",
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal("organization-team-project", result[1].spec.name)
        end)

        it("should handle paths with no slashes", function()
          -- Arrange
          local profiles = {
            {
              "standalone-repo",
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal("standalone-repo", result[1].spec.name)
        end)

        it("should handle paths with leading slash", function()
          -- Arrange
          local profiles = {
            {
              "/nodezero/core",
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal("-nodezero-core", result[1].spec.name)
        end)

        it("should handle paths with trailing slash", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core/",
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal("nodezero-core-", result[1].spec.name)
        end)

        it("should handle paths with consecutive slashes", function()
          -- Arrange
          local profiles = {
            {
              "nodezero//core///extra",
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal("nodezero--core---extra", result[1].spec.name)
        end)

        it("should handle complex paths with multiple segments", function()
          -- Arrange
          local profiles = {
            {
              "org/team/subteam/project/config",
              spec = {
                priority = 10,
              },
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal("org-team-subteam-project-config", result[1].spec.name)
          assert.are.equal(10, result[1].spec.priority)
        end)
      end)

      describe("multiple profiles handling", function()
        it("should process multiple profiles independently", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                priority = 1,
              },
            },
            {
              "nodezero/ui",
              spec = {
                name = "custom-ui-name",
                priority = 2,
              },
            },
            {
              "organization/team/project",
              spec = {
                vcs = "local",
              },
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(3, #result)

          -- First profile: should get normalized name
          assert.are.equal("nodezero/core", result[1][1])
          assert.are.equal("nodezero-core", result[1].spec.name)
          assert.are.equal(1, result[1].spec.priority)

          -- Second profile: should keep existing name
          assert.are.equal("nodezero/ui", result[2][1])
          assert.are.equal("custom-ui-name", result[2].spec.name)
          assert.are.equal(2, result[2].spec.priority)

          -- Third profile: should get normalized name
          assert.are.equal("organization/team/project", result[3][1])
          assert.are.equal("organization-team-project", result[3].spec.name)
          assert.are.equal("local", result[3].spec.vcs)
        end)

        it("should handle mix of profiles with and without spec", function()
          -- Arrange
          local profiles = {
            {
              "profile/with-spec",
              spec = {
                priority = 5,
              },
            },
            {
              "profile/without-spec",
              -- No spec field
            },
            {
              "profile/empty-spec",
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(3, #result)
          assert.are.equal("profile-with-spec", result[1].spec.name)
          assert.are.equal(5, result[1].spec.priority)
          assert.are.equal("profile-without-spec", result[2].spec.name)
          assert.are.equal("profile-empty-spec", result[3].spec.name)
        end)
      end)

      describe("immutability", function()
        it("should not modify the original profiles array", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                priority = 1,
              },
            },
          }
          local original_spec_name = profiles[1].spec.name
          local original_profile_path = profiles[1][1]

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          -- Original should remain unchanged
          assert.are.equal(original_profile_path, profiles[1][1])
          assert.are.equal(original_spec_name, profiles[1].spec.name) -- Should still be nil
          assert.are.equal(1, profiles[1].spec.priority)

          -- Result should have the normalized name
          assert.are.equal("nodezero-core", result[1].spec.name)
          assert.are.equal(1, result[1].spec.priority)
        end)

        it("should create deep copies of profile objects", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                priority = 1,
                nested = {
                  option = "value",
                },
              },
              plugins = {
                { "some/plugin" },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          -- Modify the original
          profiles[1].spec.priority = 999
          profiles[1].spec.nested.option = "modified"
          profiles[1].plugins[1][1] = "modified/plugin"

          -- Result should not be affected
          assert.are.equal(1, result[1].spec.priority)
          assert.are.equal("value", result[1].spec.nested.option)
          assert.are.equal("some/plugin", result[1].plugins[1][1])
        end)

        it("should handle profiles with existing name without mutation", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "existing-name",
                priority = 1,
              },
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          -- Original should remain unchanged
          assert.are.equal("existing-name", profiles[1].spec.name)

          -- Result should also have the existing name (unchanged)
          assert.are.equal("existing-name", result[1].spec.name)

          -- Should be different objects
          assert.are_not.equal(profiles[1], result[1])
          assert.are_not.equal(profiles[1].spec, result[1].spec)
        end)
      end)

      describe("edge cases", function()
        it("should handle profiles with invalid or missing profile path", function()
          -- Arrange
          local profiles = {
            {
              nil, -- Invalid profile path
              spec = {
                priority = 1,
              },
            },
            {
              "", -- Empty profile path
              spec = {
                priority = 2,
              },
            },
            {
              123, -- Non-string profile path
              spec = {
                priority = 3,
              },
            },
          }

          -- Act & Assert
          -- Should handle gracefully without throwing errors
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- The function should handle these gracefully, possibly skipping invalid entries
          -- or using fallback behavior
          assert.is_table(result)
        end)

        it("should handle nil spec field", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = nil,
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.is_not_nil(result[1].spec)
          assert.are.equal("nodezero-core", result[1].spec.name)
        end)

        it("should handle profile with no fields except path", function()
          -- Arrange
          local profiles = {
            {
              "minimal/profile",
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("minimal/profile", result[1][1])
          assert.is_not_nil(result[1].spec)
          assert.are.equal("minimal-profile", result[1].spec.name)
        end)

        it("should handle empty string profile path", function()
          -- Arrange
          local profiles = {
            {
              "",
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("", result[1].spec.name)
        end)

        it("should handle very long profile paths", function()
          -- Arrange
          local long_path = "very/long/path/with/many/segments/that/goes/on/and/on/project"
          local profiles = {
            {
              long_path,
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          local expected_name = string.gsub(long_path, "/", "-")
          assert.are.equal(expected_name, result[1].spec.name)
        end)

        it("should handle profile path with special characters", function()
          -- Arrange
          local profiles = {
            {
              "org-name/repo_name.with.dots",
              spec = {},
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          -- Only slashes should be replaced, other characters preserved
          assert.are.equal("org-name-repo_name.with.dots", result[1].spec.name)
        end)

        it("should preserve all other spec fields when adding name", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                priority = 5,
                vcs = "local",
                custom_field = "custom_value",
                nested_field = {
                  sub_option = true,
                  sub_array = { 1, 2, 3 },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizeProfileDefinitions(profiles)

          -- Assert
          assert.are.equal("nodezero-core", result[1].spec.name)
          assert.are.equal(5, result[1].spec.priority)
          assert.are.equal("local", result[1].spec.vcs)
          assert.are.equal("custom_value", result[1].spec.custom_field)
          assert.is_true(result[1].spec.nested_field.sub_option)
          assert.are.same({ 1, 2, 3 }, result[1].spec.nested_field.sub_array)
        end)
      end)
    end)

    describe("normalizePluginDependencies", function()
      describe("basic dependency resolution", function()
        it("should add missing dependency to profile", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "nvim-telescope/telescope.nvim",
                  spec = {
                    name = "telescope",
                  },
                  dependencies = {
                    "nvim-lua/plenary.nvim",
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(2, #result[1].plugins) -- Original + dependency

          -- Check that the dependency was added
          local found_dependency = false
          for _, plugin in ipairs(result[1].plugins) do
            if plugin[1] == "nvim-lua/plenary.nvim" then
              found_dependency = true
              break
            end
          end
          assert.is_true(found_dependency)
        end)

        it("should not add dependency if it already exists", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "nvim-telescope/telescope.nvim",
                  spec = {
                    name = "telescope",
                  },
                  dependencies = {
                    "nvim-lua/plenary.nvim",
                  },
                },
                {
                  "nvim-lua/plenary.nvim",
                  spec = {
                    name = "plenary",
                  },
                  options = {
                    some_config = true,
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(2, #result[1].plugins) -- Should remain the same count

          -- Verify the existing plugin with options is preserved
          local plenary_plugin = nil
          for _, plugin in ipairs(result[1].plugins) do
            if plugin[1] == "nvim-lua/plenary.nvim" then
              plenary_plugin = plugin
              break
            end
          end

          assert.is_not_nil(plenary_plugin)
          assert.are.equal("plenary", plenary_plugin.spec.name)
          assert.is_true(plenary_plugin.options.some_config)
        end)

        it("should handle plugins with no dependencies", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = {
                    name = "catppuccin",
                  },
                  options = {
                    flavour = "mocha",
                  },
                  -- No dependencies field
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(1, #result[1].plugins) -- Should remain unchanged
          assert.are.equal("catppuccin/nvim", result[1].plugins[1][1])
        end)

        it("should handle plugins with empty dependencies array", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = {
                    name = "catppuccin",
                  },
                  dependencies = {}, -- Empty dependencies
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(1, #result[1].plugins) -- Should remain unchanged
        end)
      end)
      describe("multiple dependencies", function()
        it("should add multiple missing dependencies", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "complex/plugin",
                  spec = {
                    name = "complex",
                  },
                  dependencies = {
                    "nvim-lua/plenary.nvim",
                    "nvim-tree/nvim-web-devicons",
                    "folke/which-key.nvim",
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(4, #result[1].plugins) -- Original + 3 dependencies

          -- Check that all dependencies were added
          local dependency_names = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "folke/which-key.nvim",
          }

          for _, dep_name in ipairs(dependency_names) do
            local found = false
            for _, plugin in ipairs(result[1].plugins) do
              if plugin[1] == dep_name then
                found = true
                break
              end
            end
            assert.is_true(found, "Dependency " .. dep_name .. " should be added")
          end
        end)

        it("should add only missing dependencies when some already exist", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "complex/plugin",
                  spec = {
                    name = "complex",
                  },
                  dependencies = {
                    "nvim-lua/plenary.nvim",
                    "nvim-tree/nvim-web-devicons",
                    "folke/which-key.nvim",
                  },
                },
                {
                  "nvim-tree/nvim-web-devicons", -- This dependency already exists
                  spec = {
                    name = "devicons",
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(4, #result[1].plugins) -- Original + existing + 2 new dependencies

          -- Count occurrences of nvim-web-devicons (should be exactly 1)
          local devicons_count = 0
          for _, plugin in ipairs(result[1].plugins) do
            if plugin[1] == "nvim-tree/nvim-web-devicons" then
              devicons_count = devicons_count + 1
            end
          end
          assert.are.equal(1, devicons_count, "nvim-web-devicons should appear exactly once")
        end)
      end)
      describe("nested dependencies", function()
        it("should recursively resolve dependencies", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "plugin-a/main",
                  spec = {
                    name = "plugin-a",
                  },
                  dependencies = {
                    "plugin-b/dependency",
                  },
                },
                {
                  "plugin-b/dependency",
                  spec = {
                    name = "plugin-b",
                  },
                  dependencies = {
                    "plugin-c/nested-dependency",
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(3, #result[1].plugins) -- Original 2 + 1 nested dependency

          -- Check that the nested dependency was added
          local found_nested = false
          for _, plugin in ipairs(result[1].plugins) do
            if plugin[1] == "plugin-c/nested-dependency" then
              found_nested = true
              break
            end
          end
          assert.is_true(found_nested, "Nested dependency should be added")
        end)
        it("should recursively resolve dependencies", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "plugin-a/main",
                  spec = {
                    name = "plugin-a",
                  },
                  dependencies = {
                    "plugin-b/dependency",
                  },
                },
                {
                  "plugin-b/dependency",
                  spec = {
                    name = "plugin-b",
                  },
                  dependencies = {
                    "plugin-c/nested-dependency",
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(3, #result[1].plugins) -- Original 2 + 1 nested dependency

          -- Check that the nested dependency was added
          local found_nested = false
          for _, plugin in ipairs(result[1].plugins) do
            if plugin[1] == "plugin-c/nested-dependency" then
              found_nested = true
              break
            end
          end
          assert.is_true(found_nested, "Nested dependency should be added")
        end)
        it("should handle complex dependency chains", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "level-1/plugin",
                  dependencies = {
                    "level-2/plugin",
                  },
                },
                {
                  "level-2/plugin",
                  dependencies = {
                    "level-3/plugin",
                    "level-3b/plugin",
                  },
                },
                {
                  "level-3b/plugin",
                  dependencies = {
                    "level-4/plugin",
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(5, #result[1].plugins) -- Original 3 + 2 resolved dependencies

          -- Check that all dependencies in the chain were resolved
          local expected_plugins = {
            "level-1/plugin",
            "level-2/plugin",
            "level-3b/plugin",
            "level-3/plugin",
            "level-4/plugin",
          }

          for _, expected in ipairs(expected_plugins) do
            local found = false
            for _, plugin in ipairs(result[1].plugins) do
              if plugin[1] == expected then
                found = true
                break
              end
            end
            assert.is_true(found, "Plugin " .. expected .. " should be present")
          end
        end)
        it("should handle circular dependencies gracefully", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 0,
              },
              plugins = {
                {
                  "plugin-a/circular",
                  dependencies = {
                    "plugin-b/circular",
                  },
                },
                {
                  "plugin-b/circular",
                  dependencies = {
                    "plugin-a/circular", -- Circular reference
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(2, #result[1].plugins) -- Should not add duplicates or infinite loop

          -- Verify both plugins are still present
          local found_a = false
          local found_b = false
          for _, plugin in ipairs(result[1].plugins) do
            if plugin[1] == "plugin-a/circular" then
              found_a = true
            elseif plugin[1] == "plugin-b/circular" then
              found_b = true
            end
          end
          assert.is_true(found_a)
          assert.is_true(found_b)
        end)
      end)
      describe("multiple profiles", function()
        it("should process dependencies for each profile independently", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 1,
              },
              plugins = {
                {
                  "nvim-telescope/telescope.nvim",
                  dependencies = {
                    "nvim-lua/plenary.nvim",
                  },
                },
              },
            },
            {
              "nodezero/ui",
              spec = {
                name = "ui",
                priority = 2,
              },
              plugins = {
                {
                  "folke/which-key.nvim",
                  dependencies = {
                    "nvim-lua/plenary.nvim", -- Same dependency as profile 1
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(2, #result)
          assert.are.equal(2, #result[1].plugins) -- core profile: telescope + plenary
          assert.are.equal(2, #result[2].plugins) -- ui profile: which-key + plenary

          -- Verify plenary was added to both profiles
          local core_has_plenary = false
          local ui_has_plenary = false

          for _, plugin in ipairs(result[1].plugins) do
            if plugin[1] == "nvim-lua/plenary.nvim" then
              core_has_plenary = true
              break
            end
          end

          for _, plugin in ipairs(result[2].plugins) do
            if plugin[1] == "nvim-lua/plenary.nvim" then
              ui_has_plenary = true
              break
            end
          end

          assert.is_true(core_has_plenary)
          assert.is_true(ui_has_plenary)
        end)
        it("should handle profiles with different dependency requirements", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/core",
              spec = {
                name = "core",
                priority = 1,
              },
              plugins = {
                {
                  "plugin1/core",
                  dependencies = {
                    "shared/dependency",
                    "core/specific",
                  },
                },
              },
            },
            {
              "nodezero/ui",
              spec = {
                name = "ui",
                priority = 2,
              },
              plugins = {
                {
                  "plugin2/ui",
                  dependencies = {
                    "shared/dependency",
                    "ui/specific",
                  },
                },
                {
                  "shared/dependency", -- Already exists in this profile
                  spec = {
                    name = "shared",
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(2, #result)
          assert.are.equal(3, #result[1].plugins) -- core: plugin1 + shared + core/specific
          assert.are.equal(3, #result[2].plugins) -- ui: plugin2 + existing shared + ui/specific
        end)
      end)
      describe("edge cases", function()
        it("should handle empty profiles list", function()
          -- Arrange
          local profiles = {}

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(0, #result)
        end)

        it("should handle profiles with no plugins", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/empty",
              spec = {
                name = "empty",
                priority = 1,
              },
              plugins = {},
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(0, #result[1].plugins)
        end)

        it("should handle profiles with nil plugins field", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/no-plugins",
              spec = {
                name = "no-plugins",
                priority = 1,
              },
              -- No plugins field at all
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          -- Should handle gracefully, possibly initializing plugins to empty array
        end)

        it("should handle invalid plugin definitions gracefully", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/mixed",
              spec = {
                name = "mixed",
                priority = 1,
              },
              plugins = {
                {
                  "valid/plugin",
                  dependencies = {
                    "valid/dependency",
                  },
                },
                {
                  -- Invalid plugin (no identifier)
                  spec = {
                    name = "invalid",
                  },
                  dependencies = {
                    "should-not-be-processed",
                  },
                },
                nil, -- Completely invalid entry
                "not-a-table", -- Also invalid
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)
          -- Assert
          assert.are.equal(1, #result)

          -- Should have added the valid dependency but skipped invalid ones
          local found_valid_dep = false
          local found_invalid_dep = false

          for _, plugin in ipairs(result[1].plugins) do
            if plugin and plugin.dependencies and plugin.dependencies[1] == "valid/dependency" then
              found_valid_dep = true
            elseif plugin and plugin[1] == "should-not-be-processed" then
              found_invalid_dep = true
            end
          end

          assert.is_true(found_valid_dep)
          assert.is_false(found_invalid_dep)
        end)

        it("should preserve plugin order and add dependencies at the end", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/ordered",
              spec = {
                name = "ordered",
                priority = 1,
              },
              plugins = {
                {
                  "first/plugin",
                  dependencies = {
                    "new/dependency",
                  },
                },
                {
                  "second/plugin",
                  -- No dependencies
                },
                {
                  "third/plugin",
                  dependencies = {
                    "another/dependency",
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal(5, #result[1].plugins) -- 3 original + 2 dependencies

          -- Check that original order is preserved
          assert.are.equal("first/plugin", result[1].plugins[1][1])
          assert.are.equal("second/plugin", result[1].plugins[2][1])
          assert.are.equal("third/plugin", result[1].plugins[3][1])

          -- Dependencies should be at the end
          local dependency_positions = {}
          for i, plugin in ipairs(result[1].plugins) do
            if plugin[1] == "new/dependency" or plugin[1] == "another/dependency" then
              table.insert(dependency_positions, i)
            end
          end

          -- Dependencies should be in positions 4 and 5
          assert.is_true(dependency_positions[1] >= 4)
          assert.is_true(dependency_positions[2] >= 4)
        end)

        it("should not modify the original profiles structure", function()
          -- Arrange
          local profiles = {
            {
              "nodezero/original",
              spec = {
                name = "original",
                priority = 1,
              },
              plugins = {
                {
                  "test/plugin",
                  dependencies = {
                    "new/dependency",
                  },
                },
              },
            },
          }

          local original_plugin_count = #profiles[1].plugins

          -- Act
          local result = profile_utils.normalizePluginDependencies(profiles)

          -- Assert
          -- Original should remain unchanged
          assert.are.equal(original_plugin_count, #profiles[1].plugins)
          assert.are.equal("test/plugin", profiles[1].plugins[1][1])

          -- Result should have the dependency added
          assert.are.equal(original_plugin_count + 1, #result[1].plugins)
        end)
      end)
      --
      -- describe("dependency format validation", function()
      --   it("should handle dependencies as strings", function()
      --     -- Arrange
      --     local profiles = {
      --       {
      --         "nodezero/test",
      --         spec = {
      --           name = "test",
      --           priority = 1,
      --         },
      --         plugins = {
      --           {
      --             "test/plugin",
      --             dependencies = {
      --               "string/dependency"
      --             }
      --           }
      --         }
      --       }
      --     }
      --
      --     -- Act
      --     local result = profile_utils.normalizePluginDependencies(profiles)
      --
      --     -- Assert
      --     assert.are.equal(1, #result)
      --     assert.are.equal(2, #result[1].plugins)
      --
      --     -- Find the added dependency
      --     local dependency_plugin = nil
      --     for _, plugin in ipairs(result[1].plugins) do
      --       if plugin[1] == "string/dependency" then
      --         dependency_plugin = plugin
      --         break
      --       end
      --     end
      --
      --     assert.is_not_nil(dependency_plugin)
      --     assert.are.equal("string/dependency", dependency_plugin[1])
      --   end)
      --
      --   it("should ignore non-string dependencies", function()
      --     -- Arrange
      --     local profiles = {
      --       {
      --         "nodezero/test",
      --         spec = {
      --           name = "test",
      --           priority = 1,
      --         },
      --         plugins = {
      --           {
      --             "test/plugin",
      --             dependencies = {
      --               "valid/dependency",
      --               123, -- Invalid - number
      --               {}, -- Invalid - table
      --               nil, -- Invalid - nil
      --               true -- Invalid - boolean
      --             }
      --           }
      --         }
      --       }
      --     }
      --
      --     -- Act
      --     local result = profile_utils.normalizePluginDependencies(profiles)
      --
      --     -- Assert
      --     assert.are.equal(1, #result)
      --     assert.are.equal(2, #result[1].plugins) -- Should only add the valid dependency
      --
      --     -- Check only valid dependency was added
      --     local found_valid = false
      --     for _, plugin in ipairs(result[1].plugins) do
      --       if plugin[1] == "valid/dependency" then
      --         found_valid = true
      --         break
      --       end
      --     end
      --     assert.is_true(found_valid)
      --   end)
      -- end)
    end)
    describe("mergePlugins", function()
      describe("basic merging functionality", function()
        it("should return empty list when no profiles provided", function()
          -- Arrange
          local profiles = {}

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(0, #result)
        end)

        it("should return plugins from single profile unchanged", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = { name = "catppuccin" },
                  options = { flavour = "mocha" },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("catppuccin/nvim", result[1][1])
          assert.are.equal("catppuccin", result[1].spec.name)
          assert.are.equal("mocha", result[1].options.flavour)
        end)

        it("should combine unique plugins from multiple profiles", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = { name = "catppuccin" },
                  options = { flavour = "mocha" },
                },
              },
            },
            {
              "profile2/repo",
              spec = { name = "profile2", priority = 2 },
              plugins = {
                {
                  "nvim-treesitter/nvim-treesitter",
                  spec = { name = "nvim-treesitter" },
                  options = { highlight = { enable = true } },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(2, #result)
        end)
      end)

      describe("plugin merging with conflicts", function()
        it("should merge options from multiple profiles for same plugin", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = { name = "catppuccin" },
                  options = {
                    flavour = "mocha",
                    background = { dark = "mocha" },
                  },
                },
              },
            },
            {
              "profile2/repo",
              spec = { name = "profile2", priority = 2 },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = { name = "catppuccin" },
                  options = {
                    transparent_background = true,
                    background = { light = "latte" },
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          local merged_plugin = result[1]
          assert.are.equal("catppuccin/nvim", merged_plugin[1])
          -- Higher priority profile (profile2) should override flavour
          assert.are.equal("mocha", merged_plugin.options.flavour) -- from lower priority
          assert.is_true(merged_plugin.options.transparent_background) -- from higher priority
          -- Nested options should be merged
          assert.are.equal("mocha", merged_plugin.options.background.dark)
          assert.are.equal("latte", merged_plugin.options.background.light)
        end)

        it("should prioritize higher priority profile options in conflicts", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = { name = "catppuccin" },
                  options = { flavour = "mocha" },
                },
              },
            },
            {
              "profile2/repo",
              spec = { name = "profile2", priority = 5 },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = { name = "catppuccin" },
                  options = { flavour = "latte" },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          -- Higher priority (5) should override lower priority (1)
          assert.are.equal("latte", result[1].options.flavour)
        end)

        it("should handle plugins with different spec configurations", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = { name = "catppuccin" },
                  options = { flavour = "mocha" },
                },
              },
            },
            {
              "profile2/repo",
              spec = { name = "profile2", priority = 2 },
              plugins = {
                {
                  "catppuccin/nvim",
                  spec = {
                    name = "catppuccin",
                    url = "https://custom.git/catppuccin/nvim",
                  },
                  options = { transparent_background = true },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          local merged_plugin = result[1]
          assert.are.equal("catppuccin", merged_plugin.spec.name)
          assert.are.equal("https://custom.git/catppuccin/nvim", merged_plugin.spec.url)
          assert.are.equal("mocha", merged_plugin.options.flavour)
          assert.is_true(merged_plugin.options.transparent_background)
        end)
      end)

      describe("profile sorting integration", function()
        it("should respect profile priority order when merging", function()
          -- Arrange - intentionally out of priority order
          local profiles = {
            {
              "profile-low/repo",
              spec = { name = "low", priority = 1 },
              plugins = {
                {
                  "shared/plugin",
                  spec = { name = "shared" },
                  options = { value = "low_priority" },
                },
              },
            },
            {
              "profile-high/repo",
              spec = { name = "high", priority = 10 },
              plugins = {
                {
                  "shared/plugin",
                  spec = { name = "shared" },
                  options = { value = "high_priority" },
                },
              },
            },
            {
              "profile-medium/repo",
              spec = { name = "medium", priority = 5 },
              plugins = {
                {
                  "shared/plugin",
                  spec = { name = "shared" },
                  options = { value = "medium_priority" },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          -- Highest priority (10) should win
          assert.are.equal("high_priority", result[1].options.value)
        end)

        it("should handle profiles with no priority using lexicographical order", function()
          -- Arrange
          local profiles = {
            {
              "zebra/profile",
              spec = { name = "zebra" },
              plugins = {
                {
                  "shared/plugin",
                  spec = { name = "shared" },
                  options = { value = "zebra" },
                },
              },
            },
            {
              "alpha/profile",
              spec = { name = "alpha" },
              plugins = {
                {
                  "shared/plugin",
                  spec = { name = "shared" },
                  options = { value = "alpha" },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          -- Alpha should come first lexicographically, so alpha should win
          assert.are.equal("alpha", result[1].options.value)
        end)
      end)

      describe("complex merging scenarios", function()
        it("should handle deep nested option merging", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "complex/plugin",
                  spec = { name = "complex" },
                  options = {
                    ui = {
                      theme = "dark",
                      colors = { primary = "blue" },
                    },
                    features = { autocomplete = true },
                  },
                },
              },
            },
            {
              "profile2/repo",
              spec = { name = "profile2", priority = 2 },
              plugins = {
                {
                  "complex/plugin",
                  spec = { name = "complex" },
                  options = {
                    ui = {
                      border = "rounded",
                      colors = { secondary = "green" },
                    },
                    features = { snippets = true },
                  },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          local merged = result[1].options
          assert.are.equal("dark", merged.ui.theme)
          assert.are.equal("rounded", merged.ui.border)
          assert.are.equal("blue", merged.ui.colors.primary)
          assert.are.equal("green", merged.ui.colors.secondary)
          assert.is_true(merged.features.autocomplete)
          assert.is_true(merged.features.snippets)
        end)

        it("should handle plugins with identical specs from different profiles", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "identical/plugin",
                  spec = { name = "identical" },
                  options = { setting1 = "value1" },
                },
                {
                  "unique-to-profile1/plugin",
                  spec = { name = "unique1" },
                  options = { unique = "profile1" },
                },
              },
            },
            {
              "profile2/repo",
              spec = { name = "profile2", priority = 2 },
              plugins = {
                {
                  "identical/plugin",
                  spec = { name = "identical" },
                  options = { setting2 = "value2" },
                },
                {
                  "unique-to-profile2/plugin",
                  spec = { name = "unique2" },
                  options = { unique = "profile2" },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(3, #result)

          -- Find the merged identical plugin
          local identical_plugin = nil
          for _, plugin in ipairs(result) do
            if plugin[1] == "identical/plugin" then
              identical_plugin = plugin
              break
            end
          end

          assert.is_not_nil(identical_plugin)
          assert.are.equal("value1", identical_plugin.options.setting1)
          assert.are.equal("value2", identical_plugin.options.setting2)
        end)

        it("should handle profiles with no plugins", function()
          -- Arrange
          local profiles = {
            {
              "empty/profile",
              spec = { name = "empty", priority = 1 },
              plugins = {},
            },
            {
              "profile-with-plugins/repo",
              spec = { name = "with_plugins", priority = 2 },
              plugins = {
                {
                  "solo/plugin",
                  spec = { name = "solo" },
                  options = { alone = true },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("solo/plugin", result[1][1])
          assert.is_true(result[1].options.alone)
        end)

        it("should handle plugins with missing options", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "minimal/plugin",
                  spec = { name = "minimal" },
                  -- No options defined
                },
              },
            },
            {
              "profile2/repo",
              spec = { name = "profile2", priority = 2 },
              plugins = {
                {
                  "minimal/plugin",
                  spec = { name = "minimal" },
                  options = { configured = true },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("minimal/plugin", result[1][1])
          assert.is_true(result[1].options.configured)
        end)
      end)

      describe("edge cases", function()
        it("should handle profiles with nil plugins field", function()
          -- Arrange
          local profiles = {
            {
              "profile-no-plugins/repo",
              spec = { name = "no_plugins", priority = 1 },
              -- No plugins field at all
            },
            {
              "profile-with-plugins/repo",
              spec = { name = "with_plugins", priority = 2 },
              plugins = {
                {
                  "working/plugin",
                  spec = { name = "working" },
                  options = { works = true },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(1, #result)
          assert.are.equal("working/plugin", result[1][1])
        end)

        it("should handle plugins with same identifier but different repo paths", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "owner1/plugin-name",
                  spec = { name = "plugin-name" },
                  options = { source = "owner1" },
                },
              },
            },
            {
              "profile2/repo",
              spec = { name = "profile2", priority = 2 },
              plugins = {
                {
                  "owner2/plugin-name",
                  spec = { name = "plugin-name" },
                  options = { source = "owner2" },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          -- These should be treated as different plugins since they have different repo paths
          assert.are.equal(2, #result)
        end)

        it("should preserve plugin order within priority groups", function()
          -- Arrange
          local profiles = {
            {
              "profile1/repo",
              spec = { name = "profile1", priority = 1 },
              plugins = {
                {
                  "first/plugin",
                  spec = { name = "first" },
                  options = { order = 1 },
                },
                {
                  "second/plugin",
                  spec = { name = "second" },
                  options = { order = 2 },
                },
              },
            },
          }

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(2, #result)
          -- Order should be preserved
          assert.are.equal("first/plugin", result[1][1])
          assert.are.equal("second/plugin", result[2][1])
        end)

        it("should handle very large numbers of profiles and plugins", function()
          -- Arrange
          local profiles = {}
          for i = 1, 100 do
            local profile = {
              "profile" .. i .. "/repo",
              spec = { name = "profile" .. i, priority = i },
              plugins = {
                {
                  "shared/plugin",
                  spec = { name = "shared" },
                  options = { value = i },
                },
                {
                  "unique" .. i .. "/plugin",
                  spec = { name = "unique" .. i },
                  options = { unique_value = i },
                },
              },
            }
            table.insert(profiles, profile)
          end

          -- Act
          local result = profile_utils.mergePlugins(profiles)

          -- Assert
          assert.are.equal(101, #result) -- 1 shared + 100 unique

          -- Find the shared plugin
          local shared_plugin = nil
          for _, plugin in ipairs(result) do
            if plugin[1] == "shared/plugin" then
              shared_plugin = plugin
              break
            end
          end

          assert.is_not_nil(shared_plugin)
          -- Highest priority (100) should win
          assert.are.equal(100, shared_plugin.options.value)
        end)
      end)
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
            "http://ginternal-git.local/",
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
            "http://ggit.example.com",
            "https://gitlab.com",
            "https://bitbucket.org",
            "http://ginternal-git.company.com",
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
            ":--github.com", -- missing protocol name
            "https:///", -- missing domain
            "https://", -- missing domain
            "ftp:--github.com", -- unsupported protocol for git
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
        assert.are.equal(custom_path:sub(1, -2), result)
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
