function _monorepo_mtime_hash
    if test (uname) = Linux
        echo $argv | sort | xargs stat --format=%Y | sha256sum | awk '{print $1}'
    else
        echo $argv | sort | xargs stat -f %m | sha256sum | awk '{print $1}'
    end
end
