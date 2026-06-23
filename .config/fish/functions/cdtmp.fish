function cdtmp -d "Create a temp directory and cd into it"
    set -l dir (mktemp -d)
    and cd $dir
end
