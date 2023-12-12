#!/bin/bash
# echo "starting dbus..."
# mkdir -p /run/dbus/
# export DBUS_FATAL_WARNINGS=0
# dbus-daemon --system
stream_url="${1:-}"
default_start='https://pkg.go.dev/time'
start_page="${2:-"$default_start"}"

echo "starting xvfb..."
Xvfb $DISPLAY -ac -screen 0 $XVFB_WHD -nolisten tcp &
sleep 1

echo "starting pulseaudio..."
pulseaudio -D --verbose --exit-idle-time=-1 --disallow-exit

# echo "starting xterm..."
# xterm -maximized &
echo "starting chrome..."
google-chrome --no-default-browser-check --remote-debugging-port=9222 --window-position=0,0 --window-size=1280,720 --no-first-run --kiosk  & # --start-maximized --start-fullscreen
sleep 10
echo "starting chromestage..."
/bin/chromestage "$start_page" &
echo "starting x11vnc..."
x11vnc -display $DISPLAY -forever -passwd chromestage &
sleep 1
if [ -n "$stream_url" ]; then
  echo "starting ffmpeg..."
  ffmpeg \
    -f x11grab -video_size 1280x720 -framerate 30 -i $DISPLAY \
    -f alsa -i pulse -ac 2 \
    -c:v libx264 -preset veryfast -c:a aac -strict experimental \
    -copyts \
    -f flv "$stream_url"
else
  cat
fi
