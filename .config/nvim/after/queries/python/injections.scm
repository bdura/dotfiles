; extends

; Inject language specified in "# lang:<language>" comment
(module
  (comment) @injection.language
  .
  (expression_statement
    (assignment
      right: (string
        (string_content) @injection.content)))
  (#lua-match? @injection.language "lang:%w+")
  (#gsub! @injection.language ".*lang:(%w+).*" "%1"))
