# fzfplay
Navigate and play media with [fzf](http://jamesmclendon.com) and Spotlight.

    usage: fzfplay [-als] [-dpqrt arguments]
    
    options:
    -a                Display image files (if any) with Quick Look.
    -d "directory"    Specify a top-level directory. Current directory is default.
    -l                Loop.
    -p "player"       Specify player (e.g. "mpg123"). `afplay` is default.
    -q "query"        Filter by "query".
    -r "n"            Items added within the last "n" days.
    -s                Shuffle.
    -t "tag"          Filter by "tag".
