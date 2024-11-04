require('luasnip.session.snippet_collection').clear_snippets('rust')

local ls = require('luasnip')

local s = ls.snippet
local i = ls.insert_node

local fmt = require('luasnip.extras.fmt').fmt

local rstests = [[
#[cfg(test)]
mod tests {{
    use rstest::rstest;

    use super::*;

    #[rstest]
    #[case({})]
    fn {}(#[case] {}) {{
        {}
    }}
}}
]]

ls.add_snippets('rust', {
  s('trs', fmt(rstests, { i(1), i(2), i(3), i(0) })),
})
