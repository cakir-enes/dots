#!/bin/sh
Xaxis=$(xrandr --current | grep '*+' | uniq | awk '{print $1}' |  cut -d 'x' -f1)
Yaxis=$(xrandr --current | grep '*+' | uniq | awk '{print $1}' |  cut -d 'x' -f2)
WIDTH=$(echo "scale=0;$Xaxis*.65"|bc)
HEIGHT=$(echo "$Yaxis*.8" | bc)
X=$(echo "scale=0;$Xaxis/2-$WIDTH/2"|bc)
Y=$(echo "($Yaxis-$HEIGHT)/2" | bc)
WIN=`xdotool getactivewindow`
echo Resolution: $Xaxis x $Yaxis
echo New dimensions: $WIDTH x $HEIGHT
echo New position: $X x $Y
# unmaximize
wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz
xdotool windowmove $WIN $X $Y
xdotool windowsize $WIN $WIDTH $HEIGHT
