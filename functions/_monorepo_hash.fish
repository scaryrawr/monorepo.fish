# Computes a combined SHA256 hash from the provided input(s).
function _monorepo_hash
    echo $argv | xargs sha256sum | sha256sum | awk '{print $1}'
end
