#!/bin/bash
# echo "starting dbus..."
# mkdir -p /run/dbus/
# export DBUS_FATAL_WARNINGS=0
# dbus-daemon --system
echo "starting xvfb..."
Xvfb $DISPLAY -ac -screen 0 $XVFB_WHD -nolisten tcp &
sleep 1
# echo "starting xterm..."
# xterm -maximized &
echo "starting chrome..."
google-chrome --no-sandbox --no-default-browser-check --remote-debugging-port=9222 --window-position=0,0 --window-size=1280,720 --no-first-run --kiosk  & # --start-maximized --start-fullscreen
sleep 1
echo "starting chromestage..."
/bin/chromestage &
sleep 1
echo "starting x11vnc..."
x11vnc -display $DISPLAY -forever -passwd chromestage &
sleep 1
if [ -n "$1" ]; then
  echo "starting ffmpeg..."
  ffmpeg \
    -f x11grab -video_size 1280x720 -framerate 30 -i $DISPLAY \
    -f lavfi -i anullsrc=r=44100:cl=stereo -c:v libx264 -preset veryfast -c:a aac -strict experimental \
    -f flv $1
else
  cat
fi
