; extends

; Dim injected language regions marked with "# lang:<language>"
(module
  (comment) @_marker
  .
  (expression_statement
    (assignment
      right: (string
        (string_content) @injection.dimmed)))
  (#lua-match? @_marker "lang:%w+"))

; Module docstring
(module . (expression_statement (string) @comment))

; Class docstring
(class_definition
  body: (block . (expression_statement (string) @comment)))

; Function/method docstring
(function_definition
  body: (block . (expression_statement (string) @comment)))

; Attribute docstring
((expression_statement (assignment)) . (expression_statement (string) @comment))
