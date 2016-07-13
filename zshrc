#! /bin/zsh

# hzsh: Halostatue Zsh init scripts.
#
# Based on a lot of different influences, including but not limited to:
#   * Bart Trojanowski: http://www.jukie.net/~bart/conf/zshrc
#   * oh-my-zsh: https://github.com/robbyrussell/oh-my-zsh/

# zsh works better with caching. The hzsh system prefers to use a single
# directory (by default ${HOME}/.zsh-cache) for items it knows about, including
# certain parts of the completion cache, function and plug-in temporary
# directories (where possible), and zcompdumps.
#
# If the hzsh system cache is turned on, completion caching will also be turned
# on.

# Uncomment this command to disable the hzsh system cache.
# zstyle :hzsh use-cache off

# Uncomment and modify the next line to change the default path.
#
#     zstyle :hzsh cache-path ${HOME}/.zsh_cache

# Enable plug-ins that do not have detection files. There are three ways to do
# this:

# 1. Specify explicitly enabled plugins with `:hzsh:plugins enabled`.
# zstyle :hzsh:plugins enabled ack pybugz

# 2. Specify a plugin to enable explicitly.
# zstyle :hzsh:plugins:dirpersist enable yes
#
# 3. Enable all plugins automatically (not recommended).
# zstyle :hzsh:plugins enable-all yes

# Enable plug-ins based on the installed package name. Note that the plug-in
# *must* be named the same as the package name.
zstyle :hzsh:plugins enable-packages yes

zstyle :hzsh:plugins:interactive:open extensions mp3 wav aac ogg avi mp4 m4v \
  mov qt mpg mpeg jpg jpeg png psd bmp gif tif tiff eps ps pdf html

# Set ssh-agent plug-in options.
zstyle :hzsh:plugins:ssh-agent agent-forwarding on
zstyle :hzsh:plugins:ssh-agent all-identities yes

# Set MacTeX plug-in options.
zstyle :hzsh:plugins:mactex version "2012"
zstyle :hzsh:plugins:mactex use-64bit yes

# Enable chruby auto support
zstyle :hzsh:plugins:chruby auto yes

# Set the prompt name and the options to be used when setting the prompt. This
# is done just before returning from the setup. In this way, prompts may depend
# on things in plug-ins, too.
zstyle :hzsh:prompt name austin2
zstyle :hzsh:prompt options noverbose

# Enable support for these version control systems. Assumes your prompt uses
# vcs_info. The austin2 prompt does.
zstyle :hzsh:prompt:vcs_info enable git cvs svn hg bzr

# Do the real work of loading based on the above settings and the defaults in
# the prompt management scripts.
source ${HOME}/.zsh/loader ${1:-zshrc}
