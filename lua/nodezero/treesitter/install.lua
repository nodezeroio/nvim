local M = {}

local uv = vim.uv or vim.loop
local sources = require("nodezero.treesitter.sources")

--- Query files copied out of the nvim-treesitter tree.
--- `indents.scm` is deliberately excluded: built-in treesitter has no indent
--- engine, so those queries would never be read.
local QUERY_FILES = { "highlights", "injections", "folds", "locals" }

--- Parsers Nvim ships itself. Never fetched, never built. :help treesitter-parsers
local BUNDLED = {
  c = true,
  lua = true,
  markdown = true,
  markdown_inline = true,
  query = true,
  vim = true,
  vimdoc = true,
}

local MAX_JOBS = 8

-- Paths ----------------------------------------------------------------------

local function site_dir()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site")
end

local function parser_path(lang)
  return vim.fs.joinpath(site_dir(), "parser", lang .. ".so")
end

local function query_dir(lang)
  return vim.fs.joinpath(site_dir(), "queries", lang)
end

local function manifest_path()
  return vim.fs.joinpath(site_dir(), "nodezero-treesitter.json")
end

local function cache_dir()
  return vim.fs.joinpath(vim.fn.stdpath("cache"), "nodezero-treesitter")
end

local function exists(path)
  return uv.fs_stat(path) ~= nil
end

--- Report progress. vim.notify is swallowed under --headless, which is how
--- `make treesitter` runs, so write to stdout/stderr there instead.
local function report(msg, level)
  if #vim.api.nvim_list_uis() == 0 then
    local stream = level == vim.log.levels.ERROR and io.stderr or io.stdout
    stream:write(msg .. "\n")
  else
    vim.notify(msg, level)
  end
end

-- Manifest -------------------------------------------------------------------

local function read_manifest()
  local fd = io.open(manifest_path(), "r")
  if not fd then
    return { languages = {} }
  end
  local raw = fd:read("*a")
  fd:close()
  local ok, data = pcall(vim.json.decode, raw)
  if not ok or type(data) ~= "table" then
    return { languages = {} }
  end
  data.languages = data.languages or {}
  return data
end

local function write_manifest(manifest)
  vim.fn.mkdir(site_dir(), "p")
  local fd = assert(io.open(manifest_path(), "w"))
  fd:write(vim.json.encode(manifest))
  fd:close()
end

-- Target resolution ----------------------------------------------------------

--- Resolve languages to install: the given list (or everything the active
--- profiles declared), expanded over `requires` and with bundled parsers dropped.
---@param languages string[]?
---@return string[] targets
---@return string[] unknown languages with no entry in sources.lua
function M.targets(languages)
  if not languages or #languages == 0 then
    languages = vim.tbl_keys(require("nodezero.treesitter").declared)
  end

  local seen, queue, targets, unknown = {}, vim.deepcopy(languages), {}, {}
  while #queue > 0 do
    local lang = table.remove(queue)
    if not seen[lang] then
      seen[lang] = true
      if not BUNDLED[lang] then
        local entry = sources.parsers[lang]
        if entry then
          table.insert(targets, lang)
          for _, req in ipairs(entry.requires or {}) do
            table.insert(queue, req)
          end
        else
          table.insert(unknown, lang)
        end
      end
    end
  end

  table.sort(targets)
  table.sort(unknown)
  return targets, unknown
end

--- Installed state of each target: "current", "stale" or "missing".
---@param languages string[]?
---@return table<string, table>
function M.status(languages)
  local manifest = read_manifest()
  local status = {}

  for _, lang in ipairs(M.targets(languages)) do
    local entry = sources.parsers[lang]
    local record = manifest.languages[lang] or {}

    local has_parser = entry.queries_only or exists(parser_path(lang))
    local has_queries = exists(query_dir(lang))
    local parser_current = entry.queries_only or (has_parser and record.revision == entry.revision)
    local queries_current = has_queries and record.queries_revision == sources.queries_revision

    local state
    if parser_current and queries_current then
      state = "current"
    elseif has_parser and has_queries then
      state = "stale"
    else
      state = "missing"
    end

    status[lang] = {
      state = state,
      revision = entry.revision,
      queries_only = entry.queries_only or false,
    }
  end

  return status
end

-- Job plumbing ---------------------------------------------------------------

--- vim.system, with the callback moved back onto the main loop so callers can
--- use the full API rather than being stuck in a fast event context.
local function system(cmd, callback)
  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      callback(result)
    end)
  end)
end

--- Run `worker` over `items` with at most `limit` in flight.
local function pool(items, limit, worker, done)
  local total = #items
  if total == 0 then
    return done({})
  end

  local results, launched, completed = {}, 0, 0

  local function launch()
    launched = launched + 1
    local index = launched
    if index > total then
      return
    end
    worker(items[index], function(result)
      results[index] = result
      completed = completed + 1
      if completed == total then
        return done(results)
      end
      launch()
    end)
  end

  for _ = 1, math.min(limit, total) do
    launch()
  end
end

-- Fetch and build ------------------------------------------------------------

local function archive_dir(entry)
  local name = entry.url:match("([^/]+)$") or "grammar"
  return vim.fs.joinpath(cache_dir(), name .. "-" .. entry.revision)
end

--- Download and extract a grammar tarball. Cached on (url, revision), which
--- matters because several repos supply two languages each (xml/dtd,
--- php/php_only, jinja/jinja_inline).
local function fetch_archive(entry, callback)
  local dest = archive_dir(entry)
  local stamp = vim.fs.joinpath(dest, ".nodezero-ok")
  if exists(stamp) then
    return callback(true)
  end

  vim.fn.mkdir(cache_dir(), "p")
  local tarball = dest .. ".tar.gz"
  local url = entry.url .. "/archive/" .. entry.revision .. ".tar.gz"

  system({ "curl", "-sSL", "--fail", "--retry", "2", "-o", tarball, url }, function(dl)
    if dl.code ~= 0 then
      return callback(false, "download failed: " .. vim.trim(dl.stderr or ""))
    end
    vim.fn.delete(dest, "rf")
    vim.fn.mkdir(dest, "p")
    system({ "tar", "-xzf", tarball, "-C", dest, "--strip-components=1" }, function(untar)
      vim.fn.delete(tarball)
      if untar.code ~= 0 then
        return callback(false, "extract failed: " .. vim.trim(untar.stderr or ""))
      end
      -- The whole repo is extracted on purpose: subdirectory grammars use
      -- relative includes that reach outside their `location` (tree-sitter-php
      -- does #include "../../common/scanner.h").
      io.open(stamp, "w"):close()
      callback(true)
    end)
  end)
end

--- Compile <src>/parser.c plus any scanner into site/parser/<lang>.so.
local function build_parser(lang, entry, callback)
  local root = archive_dir(entry)
  local src = vim.fs.joinpath(root, entry.location or ".", "src")

  if not exists(vim.fs.joinpath(src, "parser.c")) then
    return callback(false, "no parser.c at " .. src)
  end

  local compiler = "cc"
  local files = { vim.fs.joinpath(src, "parser.c") }
  if exists(vim.fs.joinpath(src, "scanner.c")) then
    table.insert(files, vim.fs.joinpath(src, "scanner.c"))
  end
  if exists(vim.fs.joinpath(src, "scanner.cc")) then
    table.insert(files, vim.fs.joinpath(src, "scanner.cc"))
    compiler = "c++"
  end

  vim.fn.mkdir(vim.fs.joinpath(site_dir(), "parser"), "p")
  local out = parser_path(lang)
  local tmp = out .. ".tmp"

  local cmd = { compiler, "-o", tmp, "-shared", "-Os", "-fPIC", "-I" .. src }
  vim.list_extend(cmd, files)

  system(cmd, function(result)
    if result.code ~= 0 then
      vim.fn.delete(tmp)
      return callback(false, vim.trim(result.stderr or "compile failed"))
    end
    -- Rename rather than write in place: a parser already loaded by this Nvim
    -- keeps its inode, so the swap is safe mid-session.
    local ok, err = uv.fs_rename(tmp, out)
    if not ok then
      return callback(false, "install failed: " .. tostring(err))
    end
    callback(true)
  end)
end

--- Download the nvim-treesitter tree once and copy out the query directories.
--- One 450 KB fetch instead of one request per query file.
local function fetch_queries(langs, callback)
  local dest = vim.fs.joinpath(cache_dir(), "queries-" .. sources.queries_revision)
  local stamp = vim.fs.joinpath(dest, ".nodezero-ok")

  local function copy_all()
    local root = vim.fs.joinpath(dest, "runtime", "queries")
    local failures = {}
    for _, lang in ipairs(langs) do
      local from = vim.fs.joinpath(root, lang)
      if not exists(from) then
        table.insert(failures, lang .. ": no queries upstream")
      else
        local to = query_dir(lang)
        vim.fn.delete(to, "rf")
        vim.fn.mkdir(to, "p")
        local copied = 0
        for _, name in ipairs(QUERY_FILES) do
          local file = name .. ".scm"
          if exists(vim.fs.joinpath(from, file)) then
            if uv.fs_copyfile(vim.fs.joinpath(from, file), vim.fs.joinpath(to, file)) then
              copied = copied + 1
            end
          end
        end
        if copied == 0 then
          table.insert(failures, lang .. ": no query files copied")
        end
      end
    end
    callback(#failures == 0, table.concat(failures, "; "))
  end

  if exists(stamp) then
    return copy_all()
  end

  vim.fn.mkdir(cache_dir(), "p")
  local tarball = dest .. ".tar.gz"
  local url = sources.queries_url .. "/archive/" .. sources.queries_revision .. ".tar.gz"

  system({ "curl", "-sSL", "--fail", "--retry", "2", "-o", tarball, url }, function(dl)
    if dl.code ~= 0 then
      return callback(false, "query download failed: " .. vim.trim(dl.stderr or ""))
    end
    vim.fn.delete(dest, "rf")
    vim.fn.mkdir(dest, "p")
    system({ "tar", "-xzf", tarball, "-C", dest, "--strip-components=1" }, function(untar)
      vim.fn.delete(tarball)
      if untar.code ~= 0 then
        return callback(false, "query extract failed: " .. vim.trim(untar.stderr or ""))
      end
      io.open(stamp, "w"):close()
      copy_all()
    end)
  end)
end

-- Public entry point ---------------------------------------------------------

--- Install parsers and queries for the declared languages.
---@param opts table?
---  - languages (string[]?) restrict to these languages
---  - update (boolean?) also rebuild languages whose pinned revision moved
---  - force (boolean?) rebuild everything, ignoring the manifest
---  - wait (boolean?) block until finished (for headless `make treesitter`)
function M.install(opts)
  opts = opts or {}

  if vim.fn.executable("cc") == 0 then
    report("nodezero.treesitter: no C compiler on PATH (need `cc`)", vim.log.levels.ERROR)
    return
  end

  local targets, unknown = M.targets(opts.languages)
  if #unknown > 0 then
    report(
      "nodezero.treesitter: not in sources.lua, skipping: " .. table.concat(unknown, ", ")
        .. "\nRun `make treesitter-sync` if these should be supported.",
      vim.log.levels.WARN
    )
  end

  local status = M.status(opts.languages)
  local todo = {}
  for _, lang in ipairs(targets) do
    local state = status[lang].state
    if opts.force or state == "missing" or (opts.update and state == "stale") then
      table.insert(todo, lang)
    end
  end

  if #todo == 0 then
    report("nodezero.treesitter: everything up to date (" .. #targets .. " languages)")
    return
  end

  local started = uv.now()
  local finished, errors = false, {}

  report("nodezero.treesitter: installing " .. #todo .. " languages...")

  -- Unique archives among the languages that actually need a parser built.
  local builds, archives, seen_archive = {}, {}, {}
  for _, lang in ipairs(todo) do
    local entry = sources.parsers[lang]
    if not entry.queries_only then
      table.insert(builds, { lang = lang, entry = entry })
      local key = entry.url .. "@" .. entry.revision
      if not seen_archive[key] then
        seen_archive[key] = true
        table.insert(archives, entry)
      end
    end
  end

  local function finish()
    local manifest = read_manifest()
    for _, lang in ipairs(todo) do
      if not errors[lang] then
        local entry = sources.parsers[lang]
        manifest.languages[lang] = {
          revision = entry.revision,
          queries_revision = sources.queries_revision,
        }
      end
    end
    write_manifest(manifest)

    local failed = vim.tbl_keys(errors)
    table.sort(failed)
    local elapsed = string.format("%.1fs", (uv.now() - started) / 1000)

    if #failed == 0 then
      report(("nodezero.treesitter: installed %d languages in %s"):format(#todo, elapsed))
    else
      local lines = { ("nodezero.treesitter: %d ok, %d failed in %s"):format(#todo - #failed, #failed, elapsed) }
      for _, lang in ipairs(failed) do
        table.insert(lines, ("  %s: %s"):format(lang, errors[lang]))
      end
      report(table.concat(lines, "\n"), vim.log.levels.ERROR)
    end
    finished = true
  end

  pool(archives, MAX_JOBS, function(entry, done)
    fetch_archive(entry, function(ok, err)
      if not ok then
        for _, build in ipairs(builds) do
          if build.entry.url == entry.url and build.entry.revision == entry.revision then
            errors[build.lang] = err
          end
        end
      end
      done(ok)
    end)
  end, function()
    local buildable = vim.tbl_filter(function(b)
      return not errors[b.lang]
    end, builds)

    pool(buildable, MAX_JOBS, function(build, done)
      build_parser(build.lang, build.entry, function(ok, err)
        if not ok then
          errors[build.lang] = err
        end
        done(ok)
      end)
    end, function()
      local want_queries = vim.tbl_filter(function(lang)
        return not errors[lang]
      end, todo)

      fetch_queries(want_queries, function(ok, err)
        if not ok then
          report("nodezero.treesitter: " .. err, vim.log.levels.WARN)
        end
        finish()
      end)
    end)
  end)

  if opts.wait then
    -- 10 minutes: a cold install of ~24 grammars takes well under one.
    if not vim.wait(600000, function()
      return finished
    end, 100) then
      report("nodezero.treesitter: timed out", vim.log.levels.ERROR)
    end
  end
end

--- Remove parsers and queries no longer declared by any active profile.
function M.clean()
  local keep = {}
  for _, lang in ipairs(M.targets()) do
    keep[lang] = true
  end

  local removed = {}
  local manifest = read_manifest()

  for lang in pairs(manifest.languages) do
    if not keep[lang] then
      vim.fn.delete(parser_path(lang))
      vim.fn.delete(query_dir(lang), "rf")
      manifest.languages[lang] = nil
      table.insert(removed, lang)
    end
  end

  write_manifest(manifest)
  table.sort(removed)
  if #removed == 0 then
    report("nodezero.treesitter: nothing to clean")
  else
    report("nodezero.treesitter: removed " .. table.concat(removed, ", "))
  end
end

return M
