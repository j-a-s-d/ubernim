--
-- Ubernim 0.7.0 plugin for Lite XL editor
--
-- NOTE: the following is from language_nim.lua plugin ...
--

-- mod-version:2 -- lite-xl 2.0
local syntax = require "core.syntax"

local patterns = {}

local symbols = {
  ["nil"] = "literal",
  ["true"] = "literal",
  ["false"] = "literal",
}

local number_patterns = {
  "0[bB][01][01_]*",
  "0o[0-7][0-7_]*",
  "0[xX]%x[%x_]*",
  "%d[%d_]*%.%d[%d_]*[eE][-+]?%d[%d_]*",
  "%d[%d_]*%.%d[%d_]*",
  "%d[%d_]*",
}

local type_suffix_patterns = {}

for _, size in ipairs({"", "8", "16", "32", "64"}) do
  table.insert(type_suffix_patterns, "'?[fuiFUI]"..size)
end

for _, pattern in ipairs(number_patterns) do
  for _, suffix in ipairs(type_suffix_patterns) do
    table.insert(patterns, { pattern = pattern..suffix, type = "literal" })
  end
  table.insert(patterns, { pattern = pattern, type = "literal" })
end

local keywords = {
  "addr", "and", "as", "asm",
  "bind", "block", "break",
  "case", "cast", "concept", "const", "continue", "converter",
  "defer", "discard", "distinct", "div", "do",
  "elif", "else", "end", "enum", "except", "export",
  "finally", "for", "from", "func",
  "if", "import", "in", "include", "interface", "is", "isnot", "iterator",
  "let",
  "macro", "method", "mixin", "mod",
  "not", "notin",
  "object", "of", "or", "out",
  "proc", "ptr",
  "raise", "ref", "return",
  "shl", "shr", "static",
  "template", "try", "tuple", "type",
  "using",
  "var",
  "when", "while",
  "xor",
  "yield",
}

for _, keyword in ipairs(keywords) do
  symbols[keyword] = "keyword"
end

local standard_types = {
  "bool", "byte",
  "int", "int8", "int16", "int32", "int64",
  "uint", "uint8", "uint16", "uint32", "uint64",
  "float", "float32", "float64",
  "char", "string", "cstring",
  "pointer",
  "typedesc",
  "void", "auto", "any",
  "untyped", "typed",
  "clong", "culong", "cchar", "cschar", "cshort", "cint", "csize", "csize_t",
  "clonglong", "cfloat", "cdouble", "clongdouble", "cuchar", "cushort",
  "cuint", "culonglong", "cstringArray",
}

for _, type in ipairs(standard_types) do
  symbols[type] = "keyword2"
end

local standard_generic_types = {
  "range",
  "array", "open[aA]rray", "varargs", "seq", "set",
  "sink", "lent", "owned",
}

for _, type in ipairs(standard_generic_types) do
  table.insert(patterns, { pattern = type.."%f[%[]", type = "keyword2" })
  table.insert(patterns, { pattern = type.." +%f[%w]", type = "keyword2" })
end

local user_patterns = {
  -- comments
  { pattern = { "##?%[", "]##?" },            type = "comment" },
  { pattern = "##?.-\n",                      type = "comment" },
  -- strings and chars
  { pattern = { '"', '"', '\\' },             type = "string" },
  { pattern = { '"""', '"""[^"]' },           type = "string" },
  { pattern = { "'", "'", '\\' },             type = "literal" },
  -- function calls
  { pattern = "[a-zA-Z][a-zA-Z0-9_]*%f[(]",   type = "function" },
  -- identifiers
  { pattern = "[A-Z][a-zA-Z0-9_]*",           type = "keyword2" },
  { pattern = "[a-zA-Z][a-zA-Z0-9_]*",        type = "symbol" },
  -- operators
  { pattern = "%.%f[^.]",                     type = "normal" },
  { pattern = ":%f[ ]",                       type = "normal" },
  { pattern = "[=+%-*/<>@$~&%%|!?%^&.:\\]+",  type = "operator" },
}

for _, pattern in ipairs(user_patterns) do
  table.insert(patterns, pattern)
end

--
-- NOTE: ... until here, where the following is ubernim specific.
--

local utype = "literal" -- you can change it if you want

local upatterns = {
  -- LANGUAGE
  { pattern = { '%.note', '^%.end' }, type = "comment" },
  { pattern = { '%.docs', '^%.%w+' }, type = utype },
  { pattern = "%.protocol", type = utype },
  { pattern = "%.imports", type = utype },
  { pattern = "%.exports", type = utype },
  { pattern = "%.importing", type = utype },
  { pattern = "%.exporting", type = utype },
  { pattern = "%.applying", type = utype },
  { pattern = "%.push", type = utype },
  { pattern = "%.pop", type = utype },
  { pattern = "%.pragmas", type = utype },
  { pattern = "%.class", type = utype },
  { pattern = "%.record", type = utype },
  { pattern = "%.compound", type = utype },
  { pattern = "%.interface", type = utype },
  { pattern = "%.protocol", type = utype },
  { pattern = "%.applies", type = utype },
  { pattern = "%.extends", type = utype },
  { pattern = "%.templates", type = utype },
  { pattern = "%.constructor", type = utype },
  { pattern = "%.getter", type = utype },
  { pattern = "%.setter", type = utype },
  { pattern = "%.setter var", type = utype },
  { pattern = "%.method", type = utype },
  { pattern = "%.template", type = utype },
  { pattern = "%.routine", type = utype },
  { pattern = "%.code", type = utype },
  { pattern = "%.uses", type = utype },
  { pattern = "%.member", type = utype },
  { pattern = "%.member var", type = utype },
  { pattern = "%.value", type = utype },
  { pattern = "%.fields", type = utype },
  { pattern = "%.methods", type = utype },
  { pattern = "%.end", type = utype },
  -- TARGETED
  { pattern = "%.targeted[:]pass", type = utype },
  { pattern = "%.targeted[:]compile", type = utype },
  { pattern = "%.targeted[:]link", type = utype },
  { pattern = "%.targeted[:]emit", type = utype },
  { pattern = "%.targeted[:]end", type = utype },
  { pattern = "%.targeted", type = utype },
  -- SWITCHES
  { pattern = "%.nimc[:]target", type = utype },
  { pattern = "%.nimc[:]project", type = utype },
  { pattern = "%.nimc[:]config", type = utype },
  { pattern = "%.nimc[:]define", type = utype },
  { pattern = "%.nimc[:]switch", type = utype },
  { pattern = "%.nimc[:]minimum", type = utype },
  -- SHELLCMD
  { pattern = "%.exec", type = utype },
  -- UNIMCMDS
  { pattern = "%.unim[:]version", type = utype },
  { pattern = "%.unim[:]cleanup", type = utype },
  { pattern = "%.unim[:]flush", type = utype },
  { pattern = "%.unim[:]mode", type = utype },
  { pattern = "%.unim[:]destination", type = utype },
  -- UNIMPRJS
  { pattern = "%.project", type = utype },
  { pattern = "%.defines", type = utype },
  { pattern = "%.undefines", type = utype },
  { pattern = "%.main", type = utype },
  -- FSACCESS
  { pattern = "%.make", type = utype },
  { pattern = "%.copy", type = utype },
  { pattern = "%.move", type = utype },
  { pattern = "%.remove", type = utype },
  { pattern = "%.write", type = utype },
  { pattern = "%.append", type = utype },
  { pattern = "%.mkdir", type = utype },
  { pattern = "%.chdir", type = utype },
  { pattern = "%.cpdir", type = utype },
  { pattern = "%.rmdir", type = utype },
  -- REQUIRES
  { pattern = "%.require", type = utype },
  { pattern = "%.requirable", type = utype },
  -- PREROD
  { pattern = "%.$.*", type = utype },
  { pattern = "%.#.*", type = "comment" },
  -- DECLARATIONS
  { pattern = "[%+%-%<%>]*[a-zA-Z][a-zA-Z0-9_]*[%*]*%f[(]", type = "function" },
}

for _, upattern in ipairs(upatterns) do
  table.insert(patterns, 1, upattern) -- insert at the top
end

local unim = {
  name = "Ubernim",
  files = { "%.unim$", "%.unimp$" },
  comment = "#",
  patterns = patterns,
  symbols = symbols,
}

syntax.add(unim)
