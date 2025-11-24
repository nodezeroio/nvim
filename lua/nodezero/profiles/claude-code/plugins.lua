return {
  {
    "yetone/avante.nvim",
    url = "git@github.com:nodezeroio/avante.nvim.git",
    opts = {
      provider = "claude-code",
      providers = {
        claude = {
          endpoint = "https://api.anthropic.com",
          model = "claude-sonnet-4-20250514",
          timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            temperature = 0.75,
            max_tokens = 20480,
          },
        },
      },
      acp_providers = {
        ["claude-code"] = {
          command = "npx",
          args = { "@zed-industries/claude-code-acp" },
          env = {
            NODE_NO_WARNINGS = "1",
            ANTHROPIC_API_KEY = os.getenv("AVANTE_ANTHROPIC_API_KEY"),
          },
        },
      },
    },
  },
}
