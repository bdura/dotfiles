function watch-stubtest -d "Watch files for change and run stubtest check"
    watchexec -c -r --no-vcs-ignore -w src/ -w uv.lock -w tests/ stubtest $(tq --file pyproject.toml '.tool.maturin.module-name') --allowlist .stubtest-allowlist
end
