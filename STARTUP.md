# Startup

## Zsh

|   | Interactive Login | Interactive Non-Login | Script |
| --- | ----------------- | --------------------- | ------ |
| `/etc/zshenv` | A | A | A |
| `~/.zshenv` | B | B | B |
| `/etc/zprofile` | C |   |   |
| `~/.zprofile` | D |   |   |
| `/etc/zshrc` | E | C |   |
| `~/.zshrc` | F | D |   |
| `/etc/zlogin` | G |   |   |
| `~/.zlogin` | H |   |   |

In an interactive login shell, on logout, `~/.zlogout` and `/etc/zlogout` are
executed.

## Bash

| Interactive | Login | --rcfile <file> | --norc | --noprofile | Run |
| ----------- | ----- | --------------- | ------ | ----------- | --- |
| Yes | No | No | No | – | `/etc/bash.bashrc` |
|   |   |   |   |   | `~/.bashrc` |
| Yes | No | No | Yes | – | – |
| Yes | No | Yes | – | – | `<file>` |
| Yes | Yes | – | – | Yes | – |
| Yes | Yes | – | – | No | `/etc/profile` |
|   |   |   |   |   | `$PROFILE` |
| No | Yes | – | – | Yes | – |
| No | Yes | – | – | No | `/etc/profile` |
|   |   |   |   |   | `$PROFILE` |
| No | No | – | – | – | `$BASH_ENV` |

`$PROFILE` is the first of: `~/.bash_profile`,  `~/.bash_login`, *or*,
`~/.profile` any of which may include `~/.bashrc` and/or `$BASH_ENV`.

There is a common recommendation to configure Bash startup in one of the
`$PROFILE` files and then differentiate based on certain options:

```bash
source ~/.bashrc.common

if [[ -n "${PS1}" ]]; then
  source ~/.bashrc.interactive
else
  source ~/.bashrc.noninteractive
fi

if shopt -q login_shell; then
  source ~/.bashrc.login
else
  source ~/.bashrc.nonlogin
fi
```
