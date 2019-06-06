function pidwd
  lsof -a -p $argv[1] -d cwd -n | tail -1 | awk '{ print $NF }'
  end
