-- Regenerate lua/nodezero/treesitter/sources.lua from nvim-treesitter's registry.
--
-- Reads the languages the profiles declare, resolves them (plus their query
-- `requires` closure) against nvim-treesitter's parsers.lua, and writes the
-- pinned table the installer consumes.
--
--   make treesitter-sync
--
-- Fails loudly rather than silently dropping a language, on either:
--   * a declared language with no upstream registry entry
--   * a grammar that needs `tree-sitter generate` (we only support grammars
--     shipping a pre-generated src/parser.c, so no Node/Rust toolchain is needed)

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

-- Grammar pins and queries are both taken from this repo at a single resolved
-- revision. They must come from the same commit: nvim-treesitter's queries are
-- written against the grammar revisions its own registry pins, and mixing the
-- two produces queries that reference node types the grammar does not have
-- ("Invalid node type" at load).
--
-- The org fork, consistent with how the rest of the plugins are sourced. Sync
-- the fork with upstream to pick up newer grammars.
local SOURCE_URL = "https://github.com/nodezeroio/nvim-treesitter"
local SOURCE_BRANCH = "main"
local SOURCE_RAW = "https://raw.githubusercontent.com/nodezeroio/nvim-treesitter"

-- Parsers Nvim ships itself; excluded from sources.lua entirely.
local BUNDLED = {
  c = true,
  lua = true,
  markdown = true,
  markdown_inline = true,
  query = true,
  vim = true,
  vimdoc = true,
}

local function die(msg)
  io.stderr:write("sync-treesitter-sources: " .. msg .. "\n")
  vim.cmd("cquit 1")
end

local function run(cmd)
  local result = vim.system(cmd, { text = true }):wait()
  if result.code ~= 0 then
    die(table.concat(cmd, " ") .. " failed: " .. vim.trim(result.stderr or ""))
  end
  return vim.trim(result.stdout or "")
end

-- 1. Collect what the profiles declare. The treesitter module is stubbed so
--    requiring a profile file records its languages without registering
--    filetypes or creating autocmds.
local declared = {}
package.loaded["nodezero.treesitter"] = {
  setup = function(spec)
    for _, lang in ipairs(spec.languages or {}) do
      declared[lang] = true
    end
  end,
}

local profile_files = vim.fn.glob(root .. "/lua/nodezero/profiles/*/config/treesitter.lua", false, true)
if #profile_files == 0 then
  die("no profile config/treesitter.lua files found under " .. root)
end
for _, file in ipairs(profile_files) do
  local chunk, err = loadfile(file)
  if not chunk then
    die("could not load " .. file .. ": " .. tostring(err))
  end
  chunk()
end

local wanted = vim.tbl_keys(declared)
table.sort(wanted)
print(("declared by %d profiles: %d languages"):format(#profile_files, #wanted))

-- 2. Resolve the single revision that both the registry and the queries come from.
local ls_remote = run({ "git", "ls-remote", SOURCE_URL, SOURCE_BRANCH })
local source_revision = ls_remote:match("^(%w+)")
if not source_revision or #source_revision ~= 40 then
  die("could not resolve " .. SOURCE_URL .. " " .. SOURCE_BRANCH)
end
print("source revision: " .. source_revision)

-- 3. Pull the registry from that same revision.
local tmp = vim.fn.tempname() .. ".lua"
run({ "curl", "-sSL", "--fail", "-o", tmp, SOURCE_RAW .. "/" .. source_revision .. "/lua/nvim-treesitter/parsers.lua" })
local registry = dofile(tmp)
vim.fn.delete(tmp)
print(("registry: %d languages"):format(vim.tbl_count(registry)))

-- 4. Expand over `requires` and classify.
local entries, missing, needs_generate = {}, {}, {}
local seen, queue = {}, vim.deepcopy(wanted)

while #queue > 0 do
  local lang = table.remove(queue)
  if not seen[lang] then
    seen[lang] = true
    if not BUNDLED[lang] then
      local upstream = registry[lang]
      if not upstream then
        table.insert(missing, lang)
      else
        local info = upstream.install_info
        if not info then
          -- No grammar: a query-only module such as ecma, jsx or html_tags,
          -- pulled in by an `; inherits:` modeline.
          entries[lang] = { queries_only = true }
        elseif info.generate or info.generate_from_json then
          table.insert(needs_generate, lang)
        else
          entries[lang] = {
            url = info.url,
            revision = info.revision,
            location = info.location,
          }
        end
        for _, req in ipairs(upstream.requires or {}) do
          table.insert(queue, req)
          if entries[lang] then
            entries[lang].requires = entries[lang].requires or {}
            table.insert(entries[lang].requires, req)
          end
        end
      end
    end
  end
end

table.sort(missing)
table.sort(needs_generate)

if #missing > 0 then
  die(
    "declared but absent from the upstream registry: "
      .. table.concat(missing, ", ")
      .. "\n  These can never resolve. Drop them from the profile, or map the filetype to a\n"
      .. "  parser that does exist via the `filetypes` option, e.g.\n"
      .. '    filetypes = { json = { "jsonc" } }'
  )
end

if #needs_generate > 0 then
  die(
    "these grammars need `tree-sitter generate`, which the installer does not support: "
      .. table.concat(needs_generate, ", ")
  )
end

-- 5. Emit sources.lua.
local langs = vim.tbl_keys(entries)
table.sort(langs)

local out = {}
local function put(line)
  table.insert(out, line)
end

put("-- Pinned treesitter grammar sources. GENERATED FILE - do not edit by hand.")
put("--")
put("-- Regenerate with `make treesitter-sync`, which rewrites this from the")
put("-- languages the profiles declare plus their query `requires` closure.")
put("--")
put("-- Grammar pins and queries both come from queries_revision below; they must")
put("-- stay on the same commit. Queries are from nvim-treesitter (Apache-2.0);")
put("-- each grammar carries its own licence. Parsers bundled with Nvim (c, lua,")
put("-- markdown, markdown_inline, query, vim, vimdoc) are intentionally absent.")
put("")
put("return {")
put(("  queries_url = %q,"):format(SOURCE_URL))
put(("  queries_revision = %q,"):format(source_revision))
put("  parsers = {")

for _, lang in ipairs(langs) do
  local entry = entries[lang]
  put(("    [%q] = {"):format(lang))
  if entry.queries_only then
    put("      queries_only = true,")
  else
    put(("      url = %q,"):format(entry.url))
    put(("      revision = %q,"):format(entry.revision))
    if entry.location then
      put(("      location = %q,"):format(entry.location))
    end
  end
  if entry.requires then
    table.sort(entry.requires)
    local quoted = vim.tbl_map(function(r)
      return string.format("%q", r)
    end, entry.requires)
    put(("      requires = { %s },"):format(table.concat(quoted, ", ")))
  end
  put("    },")
end

put("  },")
put("}")
put("")

local target = root .. "/lua/nodezero/treesitter/sources.lua"
local fd = assert(io.open(target, "w"))
fd:write(table.concat(out, "\n"))
fd:close()

local build_count = 0
for _, lang in ipairs(langs) do
  if not entries[lang].queries_only then
    build_count = build_count + 1
  end
end
print(("wrote %s: %d languages (%d built, %d queries-only)"):format(
  target:gsub(root .. "/", ""),
  #langs,
  build_count,
  #langs - build_count
))
