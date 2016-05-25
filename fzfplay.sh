#!/bin/bash
#
# fzfplay -- navigate and play media with fzf and Spotlight
# requires fzf
#
# jamesmclendon.com
# 2015-07-20

usage() { echo -e '
  fzfplay -- navigate and play media with fzf and Spotlight
  usage: fzfplay [-als] [-dpqrt arguments]

  options:
  -a                Display image files (if any) with Quick Look.
  -d "directory"    Specify a top-level directory. Current directory is default.
  -l                Loop.
  -p "player"       Specify player (e.g. "mpg123"). `afplay` is default.
  -q "query"        Filter by "query".
  -r "n"            Items added within the last "n" days.
  -s                Shuffle.
  -t "tag"          Filter by "tag".'
}

# media player
player="afplay"

# set current directory to working directory
dir=$(pwd)

while getopts "ad:lp:q:r:st:" opt; do
  case $opt in
    a)
      artwork=true
      ;;
    d)
      dir="$OPTARG"
      #eval cd \"$OPTARG\"
      ;;
    l)
      loop=true
      ;;
    p)
      player="$OPTARG"
      ;;
    q)
      query="$OPTARG"
      ;;
    r)
      if ! [ -t 0 ]; then
        echo "-r is incompatible with STDIN"
        exit 1
      fi
      # make sure the provided date range is a number
      if ! [[ $OPTARG =~ ^[0-9]+$ ]] ; then
        echo "-r requires a number"
        exit 1
      fi
      # date range argument for Spotlight search
      range="kMDItemDateAdded >= \$time.today(-"$OPTARG") &&"
      ;;
    s)
      shuffle=true
      ;;
    t)
      if ! [ -t 0 ]; then
        echo "-t is incompatible with STDIN"
        exit 1
      fi
      # tag argument for Spotlight search
      tag="kMDItemUserTags == '$OPTARG' &&"
      ;;
    \?)
      echo "illegal option -$OPTARG"
      usage
      exit 1
      ;;
    :)
      echo -e "Option -$OPTARG requires an argument."
      usage
      exit 1
      ;;
    :)
  esac
done

# if date range or tag are provided
if [[ -n "$range" || -n $tag ]]; then
  # Spotlight search
  selection() {
    mdfind -onlyin "$dir" "$range" "$tag" "kMDItemKind == 'Folder'"
  }
  # if neither date range nor tag is provided
else
  selection() {
    find "$dir" -type d
  }
fi

# if query provided
if [[ -n $query ]]; then
  #eval "$(echo "query_selection()"; declare -f selection | tail -n +2)"
  # save results so far to a variable
  selection_output=$(eval selection)
  # filter results with grep
  selection() {
    echo "$selection_output" | grep -i "$query"
  }
fi

# if shuffle selected
if [[ $shuffle = true ]]; then
  #eval "$(echo "shuffle_selection()"; declare -f selection | tail -n +2)"
  # save results so far to a variable
  selection_output=$(eval selection)
  # shuffle results and return first line
  selection() {
    echo "$selection_output" | perl -MList::Util=shuffle -e "print shuffle(<STDIN>);" | head -n 1
  }
fi

play() {
  # if more than one result, prompt for selection with fzf
  selection=$(selection | fzf -1)
  # if anything was selected 
  if [[ -n $selection ]]; then
    # if artwork preview option selected
    if [[ $artwork = true ]]; then
      # look for jpgs
      jpgs=$(ls -1 *.jpg 2>/dev/null | wc -l)
      # if jpgs found
      if [ $jpgs != 0 ]; then
        # preview jpgs with "Quick Look" and send debug info to /dev/null
        qlmanage -p "$selection"/*.jpg &>/dev/null
      fi
    fi &
    # find mp3 and flac files in $selection and play with $player
    # send outut to /tmp/mp3output for use by external scripts
    find "$selection" \( -name "*.mp3" -o -name "*.flac" \) -exec $player {} \; | tee /tmp/fzfplay_output
  else
    echo "Nothing found or selected!"
  fi
}

if [[ $loop = true ]]; then
  # loop infinitely
  while :
  do
    play
  done
else
  # play selection and exit
  play
fi
