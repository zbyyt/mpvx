#!/bin/bash
# vim:ft=bash
# mpvx modified by Iarom Madden
SOCKET="$1" && shift 1
	# must be of the form /tmp/mpv...
	# MPV_SOCKET="/tmp/mpvsockets/soc"

# Save args and options
POSITIONAL_ARGS=()
OPTIONS=""

# Load options and its values
while [[ $# -gt 0 ]]; do
  case $1 in
    --force-media-title=*)
      # This option must be parsed specifically as loadfile seems to fail loading strings with spaces or commas
      option="${1:20}"
      option_no_commas_or_spaces=$(echo $option | sed 's/,//g' | sed 's/ /_/g')
      OPTIONS="$OPTIONS,force-media-title=$option_no_commas_or_spaces"
      shift
      ;;
    --*=*)
      # Parse regular options (--example=value format)
      OPTIONS="$OPTIONS,${1:2}"
      shift
      ;;
    --*)
      # Parse boolean options (--no-ytdl format)
      OPTIONS="$OPTIONS,${1:2}=1"
      shift
      ;;
    *)
      # Parse usual positional args (file input in this case)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# Remove initial options comma (if options specified)
if [[ ! -z "$OPTIONS" ]]; then
  OPTIONS="${OPTIONS:1}"
fi

# Restore positional arguments
set -- "${POSITIONAL_ARGS[@]}"

# Sends commands to Mpv instance
commandMpv () {
  echo $1 | socat - $SOCKET
}

# Play file mpv command
play () {
  commandMpv "{ \"command\": [\"loadfile\", \"$2\", \"$1\", \"$3\"] }"
} 

# Replaces what it is currently playing
playFirst () {
  play "replace" "$@"
}

# Appends file to queue and instantly plays it next
playNext () {
  wmctrl -x -R gl.mpv
  play "append" "$@"
  commandMpv playlist-next
}

# Starts mpv allowing remote (and insecure) control
start () {
  mpv \
		--input-ipc-server="${SOCKET}" \
		--player-operation-mode=pseudo-gui &
  # Sleep needed to open mpv before immediately sending command with next file
  sleep 0.05
}
#pid=$(pidof "mpv")
pid=$(pgrep -f "mpv .*$SOCKET")
#if pgrep -f "mpv .*$SOCKET" >> /dev/null 2>&1; then
if [[ "$pid" ]]; then
	#echo "SOC: $SOCKET"
	#echo "PID: $pid"
  #If instance is running
  playNext "$1" "$OPTIONS"
else
  # Start instance and play first file
  start
  playFirst "$1" "$OPTIONS"
fi

