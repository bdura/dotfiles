function watch-cargo-test -d "Watch files for change and run Cargo lint/test"
    watchexec -c -w crates/ -w Cargo.lock cargo t
end
