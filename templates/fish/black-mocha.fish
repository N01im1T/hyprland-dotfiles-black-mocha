set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL kitty
fish_add_path $HOME/.local/bin
if status is-interactive
  set -g fish_greeting
  fastfetch
end
