vim.filetype.add({
  extension = {
    cls = "apex",
  },
})

vim.lsp.config("apex_ls", {
  cmd = function(dispatchers, config)
    ---@diagnostic disable: undefined-field
    local local_cmd = {
      "java",
      "-cp",
      config.apex_jar_path,
      "-Ddebug.internal.errors=true",
      "-Ddebug.semantic.errors=" .. tostring(config.apex_enable_semantic_errors or false),
      "-Ddebug.completion.statistics=" .. tostring(config.apex_enable_completion_statistics or false),
      "-Dlwc.typegeneration.disabled=true",
    }
    if config.apex_jvm_max_heap then
      table.insert(local_cmd, "-Xmx" .. config.apex_jvm_max_heap)
    end
    ---@diagnostic enable: undefined-field
    table.insert(local_cmd, "apex.jorje.lsp.ApexLanguageServerLauncher")

    return vim.lsp.rpc.start(local_cmd, dispatchers)
  end,
  apex_jar_path = vim.env.JAVA_HOME .. "/apex-jorje-lsp.jar",
  filetypes = { "apex", "apexcode" },
  root_markers = {
    ".git",
  },
})
vim.lsp.enable("apex_ls")
