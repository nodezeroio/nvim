-- Pinned treesitter grammar sources. GENERATED FILE - do not edit by hand.
--
-- Regenerate with `make treesitter-sync`, which rewrites this from the
-- languages the profiles declare plus their query `requires` closure.
--
-- Grammar pins and queries both come from queries_revision below; they must
-- stay on the same commit. Queries are from nvim-treesitter (Apache-2.0);
-- each grammar carries its own licence. Parsers bundled with Nvim (c, lua,
-- markdown, markdown_inline, query, vim, vimdoc) are intentionally absent.

return {
  queries_url = "https://github.com/nodezeroio/nvim-treesitter",
  queries_revision = "85ec015f3be42a3c2c04648ff99d617d9609e5f0",
  parsers = {
    ["apex"] = {
      url = "https://github.com/aheber/tree-sitter-sfapex",
      revision = "3597575a429766dd7ecce9f5bb97f6fec4419d5d",
      location = "apex",
    },
    ["bash"] = {
      url = "https://github.com/tree-sitter/tree-sitter-bash",
      revision = "56b54c61fb48bce0c63e3dfa2240b5d274384763",
    },
    ["c_sharp"] = {
      url = "https://github.com/tree-sitter/tree-sitter-c-sharp",
      revision = "3431444351c871dffb32654f1299a00019280f2f",
    },
    ["css"] = {
      url = "https://github.com/tree-sitter/tree-sitter-css",
      revision = "6e327db434fec0ee90f006697782e43ec855adf5",
    },
    ["cue"] = {
      url = "https://github.com/eonpatapon/tree-sitter-cue",
      revision = "770737bcff2c4aa3f624d439e32b07dbb07102d3",
    },
    ["diff"] = {
      url = "https://github.com/the-mikedavis/tree-sitter-diff",
      revision = "e42b8def4f75633568f1aecfe01817bf15164928",
    },
    ["dtd"] = {
      url = "https://github.com/tree-sitter-grammars/tree-sitter-xml",
      revision = "87be254e12169240a0e0214dbee5e208df96fa75",
      location = "dtd",
    },
    ["ecma"] = {
      queries_only = true,
    },
    ["hcl"] = {
      url = "https://github.com/tree-sitter-grammars/tree-sitter-hcl",
      revision = "fad991865fee927dd1de5e172fb3f08ac674d914",
    },
    ["html"] = {
      url = "https://github.com/tree-sitter/tree-sitter-html",
      revision = "cbb91a0ff3621245e890d1c50cc811bffb77a26b",
      requires = { "html_tags" },
    },
    ["html_tags"] = {
      queries_only = true,
    },
    ["javascript"] = {
      url = "https://github.com/tree-sitter/tree-sitter-javascript",
      revision = "6fbef40512dcd9f0a61ce03a4c9ae7597b36ab5c",
      requires = { "ecma", "jsx" },
    },
    ["jinja"] = {
      url = "https://github.com/cathaysia/tree-sitter-jinja",
      revision = "129184fb7bbc2d3e29967002432a869ac3758f2e",
      location = "tree-sitter-jinja",
      requires = { "jinja_inline" },
    },
    ["jinja_inline"] = {
      url = "https://github.com/cathaysia/tree-sitter-jinja",
      revision = "129184fb7bbc2d3e29967002432a869ac3758f2e",
      location = "tree-sitter-jinja_inline",
    },
    ["json"] = {
      url = "https://github.com/tree-sitter/tree-sitter-json",
      revision = "46aa487b3ade14b7b05ef92507fdaa3915a662a3",
    },
    ["json5"] = {
      url = "https://github.com/Joakker/tree-sitter-json5",
      revision = "ab0ba8229d639ec4f3fa5f674c9133477f4b77bd",
    },
    ["jsx"] = {
      queries_only = true,
    },
    ["luadoc"] = {
      url = "https://github.com/tree-sitter-grammars/tree-sitter-luadoc",
      revision = "873612aadd3f684dd4e631bdf42ea8990c57634e",
    },
    ["luap"] = {
      url = "https://github.com/tree-sitter-grammars/tree-sitter-luap",
      revision = "c134aaec6acf4fa95fe4aa0dc9aba3eacdbbe55a",
    },
    ["php"] = {
      url = "https://github.com/tree-sitter/tree-sitter-php",
      revision = "5b5627faaa290d89eb3d01b9bf47c3bb9e797dea",
      location = "php",
      requires = { "php_only" },
    },
    ["php_only"] = {
      url = "https://github.com/tree-sitter/tree-sitter-php",
      revision = "5b5627faaa290d89eb3d01b9bf47c3bb9e797dea",
      location = "php_only",
    },
    ["phpdoc"] = {
      url = "https://github.com/claytonrcarter/tree-sitter-phpdoc",
      revision = "03bb10330704b0b371b044e937d5cc7cd40b4999",
    },
    ["python"] = {
      url = "https://github.com/tree-sitter/tree-sitter-python",
      revision = "710796b8b877a970297106e5bbc8e2afa47f86ec",
    },
    ["toml"] = {
      url = "https://github.com/tree-sitter-grammars/tree-sitter-toml",
      revision = "64b56832c2cffe41758f28e05c756a3a98d16f41",
    },
    ["typescript"] = {
      url = "https://github.com/tree-sitter/tree-sitter-typescript",
      revision = "75b3874edb2dc714fb1fd77a32013d0f8699989f",
      location = "typescript",
      requires = { "ecma" },
    },
    ["xml"] = {
      url = "https://github.com/tree-sitter-grammars/tree-sitter-xml",
      revision = "87be254e12169240a0e0214dbee5e208df96fa75",
      location = "xml",
      requires = { "dtd" },
    },
    ["yaml"] = {
      url = "https://github.com/tree-sitter-grammars/tree-sitter-yaml",
      revision = "3431ec21da1dde751bab55520963cf3a4f1121f3",
    },
  },
}
