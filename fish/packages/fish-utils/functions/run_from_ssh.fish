function run_from_ssh
    set -l parent (ps -o ppid= %self)
    set -l ppidsshd (ps x | grep $parent | grep sshd | grep -v grep)
    test -z $ppidsshd
end
