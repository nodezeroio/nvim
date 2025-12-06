return {
  {
    "yetone/avante.nvim",
    url = "git@github.com:nodezeroio/avante.nvim.git",
    opts = {
      provider = "codex",
      acp_providers = {
        ["codex"] = {
          command = "codex-acp",
          env = {
            NODE_NO_WARNINGS = "1",
            OPENAI_API_KEY = os.getenv("AVANTE_OPENAI_API_KEY"),
          },
        },
      },
    },
  },
}
