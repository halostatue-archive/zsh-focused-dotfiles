# Hz

This repository contains a fairly extensive set of configuration files with a
deep zsh configuration.

# halostatue's Zsh Configuration

This repository has my (fairly extensive) configuration files and standard
scripts that I use for everything except vim configuration on Unixish hosts
(primarily Mac OS X and Ubuntu Linux). My vim configuration is a separate
[repository][vim-config] for historical and practical reasons (it has been used
on Windows in the past and may still work).

[vim-config]: https://github.com/halostatue/vim-config/

## Prerequisites

> Note: This will be changing in the future.

* Ruby 2.0 or later
* Rake 11 or later

## Installation

    git clone git://github.com/halostatue/dotfiles ~/.dotfiles
    cd ~/.dotfiles
    bin/hz bootstrap

### Template Files

> Note: the implementation format of the template formats will be changing.

Files can be installed in one of two ways: linking or template generation. A
*template* file is one that will be run through `erb` to evaluate the contents
of the file. The output will be written as the install target.

A method `include_file` is available to include the contents of another file
(included files are automatically treated like template files). Relative paths
may be given to `include_file`; they will be expanded (using `expand_path`) on
use. If the `include_file` path includes the string `{PLATFORM}`, it will be
replaced with the equivalent of `uname | tr A-Z a-z`.

Files that are installed by template are given named tasks, in the `file`
namespace:

    rake file:gitconfig   # Includes: ~/.github-token, platform/gitconfig.darwin
    rake file:hgrc        # Includes: platform/hgrc.darwin
    rake file:ssh-config  # Includes: ~/.ssh-home, ~/.ssh-work

> NOTE: Template files do not have `%` processing enabled when processed
> through ERB. Only `<%= … %>` tags are recognized.

## Features

There are tons of features. One of these days, I'll document them all.

### Ordered startup

Some startup is provided for the zsh environment and is controlled by the names
of the files in `zsh/rc.d`. Startup within the `.zshrc` is fairly ordered.

### Plugins

There's a plug-in system to load functionality only when the prerequisites are
present. Plug-ins are not guaranteed to load in any particular order, but
plug-ins as a whole will load last.

> NOTE: plug-ins do not currently load last. This is changing as more of the
> shell system is moving toward plug-in definitions.

## Changes 

## Inspiration

The basic structure was originally based on Ryan Bates's dotfile
configurations, but my own biases and influences from other example
repositories have been adopted here making regular merges impossible.

I have liberally taken inspiration and code from the following projects,
repositories and other places on the 'net that I'm not even sure of anymore.

### ryanb/dotfiles

* https://github.com/ryanb/dotfiles

### henrik/dotfiles

* https://github.com/henrik/dotfiles

### zshkit

* https://github.com/bkerley/zshkit
* https://github.com/mattfoster/zshkit

### oh-my-zsh

* https://github.com/robbyrussell/oh-my-zsh

## Startup Order

 |                  | Interactive login | Interactive non-login | Script | 
 | ---------------- | :---------------- | :-------------------- | :----- | 
 | /etc/zshenv      |     A             |     A                 |   A    | 
 | ~/.zshenv        |     B             |     B                 |   B    | 
 | /etc/zprofile    |     C             |                       |        | 
 | ~/.zprofile      |     D             |                       |        | 
 | /etc/zshrc       |     E             |     C                 |        | 
 | ~/.zshrc         |     F             |     D                 |        | 
 | /etc/zlogin      |     G             |                       |        | 
 | ~/.zlogin        |     H             |                       |        | 
 |                  |                   |                       |        | 
 | ~/.zlogout       |     I             |                       |        | 
 | /etc/zlogout     |     J             |                       |        | 


Here is a non-exclusive list of what each file tends to contain:

Since `.zshenv` is always sourced, it often contains exported variables that
should be available to other programs. For example, `$PATH`, `$EDITOR`, and
`$PAGER` are often set in `.zshenv`. Also, you can set `$ZDOTDIR` in `.zshenv`
to specify an alternative location for the rest of your zsh configuration.

`.zshrc` is for interactive shell configuration. You set options for the
interactive shell there with the setopt and unsetopt commands. You can also
load shell modules, set your history options, change your prompt, set up zle
and completion, et cetera. You also set any variables that are only used in the
interactive shell (e.g. `$LS_COLORS`).

`.zlogin` is sourced on the start of a login shell. This file is often used to
start X using startx. Some systems start X on boot, so this file is not always
very useful.

`.zprofile` is basically the same as `.zlogin` except that it's sourced
directly before `.zshrc` is sourced instead of directly after it. According to
the zsh documentation, "`.zprofile` is meant as an alternative to `.zlogin` for
ksh fans; the two are not intended to be used together, although this could
certainly be done if desired."

`.zlogout` is sometimes used to clear and reset the terminal.

## Profiling

Add `zmodload zsh/zprof at` the top of your `.zshrc` and run `zprof`.

## Tracing

You can trace what zsh is doing (note that the tracing itself will slow things
down, but in a mostly-uniform manner). Add `setopt prompt_subst; zmodload
zsh/datetime; PS4='+[$EPOCHREALTIME]%N:%i> '; set -x` at the top of your
`.zshrc`.
