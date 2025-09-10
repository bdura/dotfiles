abbr -a -- c clear
abbr -a -- gl serie
abbr -a -- lg lazygit

abbr -a -- .. 'cd ..'

abbr -a -- rmf 'rm -rf'

# Direnv
abbr -a -- da 'direnv allow'
abbr -a -- de 'direnv edit'

# Execute
abbr -a -- watchc 'watchexec -c -w crates/ -w Cargo.lock cargo t'
abbr -a -- watchm 'watchexec -c -w crates/ -w Cargo.lock maturin develop --uv -r'
abbr -a -- watcht 'watchexec -c --no-vcs-ignore -w src/ -w uv.lock -w tests/ --no-process-group pytest'
abbr -a -- watchs 'watchexec -c --no-vcs-ignore -w src/ -w uv.lock stubtest --allowlist .stubtest-allowlist'
