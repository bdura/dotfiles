# Zellij

[Zellij] is a modern terminal multiplexer written in Rust.

Coming from [`tmux`], I've opted for the locked-by-default configuration setting,
although I may change that in the future (for [NeoVim navigation](#interaction-with-neovim)
in particular).

## To do

### Interaction with NeoVim

Seamless navigation between NeoVim and Zellij would be great. Possible solutions
include:

- [`zellij-autolock`] automatically switches between `Normal` and `Locked` mode
  depending on the command running within the focused pane.
  Together with [`zellij.vim`] or the Lua-based [`zellij-nav.nvim`], it allows
  seamless interaction at the condition of using `Normal` mode by default.
- To keep `Locked` mode by default, an alternative would be to use the same
  approach but switch to a different input mode. Alas, those are set -
  hence we would need to overload another mode (e.g. `Tmux`).

[Zellij]: https://zellij.dev/
[`tmux`]: https://github.com/tmux/tmux
[`zellij-autolock`]: https://github.com/fresh2dev/zellij-autolock
[`zellij.vim`]: https://github.com/fresh2dev/zellij.vim
[`zellij-nav.nvim`]: https://github.com/swaits/zellij-nav.nvim
