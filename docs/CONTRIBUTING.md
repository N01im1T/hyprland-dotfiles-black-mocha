# Contributing

Keep configuration modular and make canonical changes in TOML or templates. Do not add legacy Hyprlang syntax, duplicated keybindings, usernames, fixed monitor ports, secrets, or passwordless sudo rules.

Before submitting a change, run:

```bash
python -m unittest discover -s tests -v
python -m compileall -q dotctl
shellcheck install.sh uninstall.sh update.sh doctor.sh dotctl/dotctl lib/*.sh lib/*.bash scripts/*
```

Document new dependencies in the appropriate package group and prefer official Arch packages over AUR.
