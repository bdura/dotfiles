function watch-maturin -d "Watch files for change and rebuild PyO3 project"
    watchexec -c -r -w crates/ -w Cargo.lock maturin develop --uv -r
end
