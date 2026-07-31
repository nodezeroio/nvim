return {
  {
    "stevearc/conform.nvim",
    url = "git@github.com:nodezeroio/conform.nvim.git",
    opts = {
      log_level = vim.log.levels.DEBUG,
      formatters_by_ft = {
        cue = {
          meta = {
            url = "https://cuelang.org",
            description = "Format CUE Files using `cue fmt` command",
          },
          command = "cue",
          args = { "fmt", "-" },
          stdin = true,
        },
      },
    },
  },
}
