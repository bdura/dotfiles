; extends

; Case 1: comment and assignment are direct siblings
(_
  (comment) @injection.language
  .
  (expression_statement
    (assignment
      right: (string
        (string_content) @injection.content)))
  (#lua-match? @injection.language "lang:%w+")
  (#gsub! @injection.language ".*lang:(%w+).*" "%1"))

; Case 2: comment hoisted above a function/class body block
(function_definition
  (comment) @injection.language
  body: (block
    .
    (expression_statement
      (assignment
        right: (string
          (string_content) @injection.content))))
  (#lua-match? @injection.language "lang:%w+")
  (#gsub! @injection.language ".*lang:(%w+).*" "%1"))

(class_definition
  (comment) @injection.language
  body: (block
    .
    (expression_statement
      (assignment
        right: (string
          (string_content) @injection.content))))
  (#lua-match? @injection.language "lang:%w+")
  (#gsub! @injection.language ".*lang:(%w+).*" "%1"))
