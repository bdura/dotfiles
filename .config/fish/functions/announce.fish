# Shamelessly ripped from: <https://github.com/clo4/nix-dotfiles/blob/b4b72ec2c357d5cead2e05f67ae2e6d1c4901f60/config/fish/functions/announce.fish>
function announce
    set colored_command (string escape -- $argv | string join ' ' | fish_indent --ansi)
    echo "$(set_color magenta)>>>$(set_color normal) $colored_command"
    $argv
end
