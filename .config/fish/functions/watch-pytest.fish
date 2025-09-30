function watch-pytest -d "Watch files for change and run Pytest"
    watchexec -c -r --no-vcs-ignore --no-process-group -w src/ -w uv.lock -w tests/ pytest $argv
end
