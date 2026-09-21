export BENDOOM_IWAD="${BENDOOM_IWAD-$iwad}"
export BENDOOM_MUSIC="${BENDOOM_MUSIC-$music}"
export BENDOOM_SOUNDS="${BENDOOM_SOUNDS-$sounds}"

finish_recording() {
  decode_recording "$RECORD" > "$demo"
  rm -- "$RECORD"
}

if [ "${RECORD+x}" ]; then
  demo=$RECORD
  RECORD=$(mktemp "$demo.XXXXXX")
  export RECORD
  trap finish_recording EXIT
fi
run_game --threads 1 "$@"
