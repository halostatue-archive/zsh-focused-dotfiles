# vim: set ft=clojure

(require 'boot.repl)

(swap! boot.repl/*default-dependencies*
       concat '[[cider/cidr-nrepl "0.14.0"]])

(swap! boot.repl/*default-middleware*
       conj 'cider.nrepl/cider-middleware)
