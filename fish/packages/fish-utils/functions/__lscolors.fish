function __lscolors
    set -l cols (math $COLUMNS - 4)
    set -l s (printf '%*s' $cols '=')
    for i in (seq -f %03g 000 (tput colors))
        printf '%s %s%s%s%s' $i (tput setaf $i) (tput setab $i) $s (tput op)
    end
end
