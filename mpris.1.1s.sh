#!/usr/bin/env bash

PLAYERS=$(dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames | grep 'org.mpris.MediaPlayer2.' | grep -E 'auryo|rhythmbox|Lollypop')
CUTENT_PLAYER=$(echo "$PLAYERS" | cut -d '"' -f 2 | head -1)
COMMAND_BASE="dbus-send --print-reply --dest=$CUTENT_PLAYER /org/mpris/MediaPlayer2"
PLAY_PAUSE="$COMMAND_BASE org.mpris.MediaPlayer2.Player.PlayPause"
NEXT="$COMMAND_BASE org.mpris.MediaPlayer2.Player.Next"
PREVIOUS="$COMMAND_BASE org.mpris.MediaPlayer2.Player.Previous"

MPRIS_META=$($COMMAND_BASE org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:Metadata)
ARTIST=$(echo "$MPRIS_META" | sed -n '/artist/{n;n;p}' | cut -d '"' -f 2 | cut -c1-30)
SONG_TITLE=$(echo "$MPRIS_META" | sed -n '/title/{n;p}' | cut -d '"' -f 2 | cut -c1-30)
ART_URL=$(echo "$MPRIS_META" | sed -n '/artUrl/{n;p}' | cut -d '"' -f 2)

SONG_TITLE=${SONG_TITLE//&/&#38;}
SONG_TITLE=${SONG_TITLE//|/&#124;}
ARTIST=${ARTIST//&/&#38;}
ARTIST=${ARTIST//|/&#124;}

if [[ "$CUTENT_PLAYER" == *"auryo"* ]]; then 
  player='auryo'
  icon='multimedia-audio-player-symbolic'
elif [[ "$CUTENT_PLAYER" == *"rhythmbox"* ]]; then	
  player='rhythmbox'
  icon='rhythmbox-notplaying'
else 
  player='lollypop'
  icon='org.gnome.Lollypop-symbolic'
fi

if [[ "$ART_URL" == *file://* ]]; then 
  base64img=$(base64 -w 0 < "${ART_URL//file:///}")
else
  base64img=$(curl -s "${ART_URL//large/t200x200}" | base64 -w 0)
fi

PLAYBACK_STATUS=$($COMMAND_BASE org.freedesktop.DBus.Properties.Get string:org.mpris.MediaPlayer2.Player string:PlaybackStatus)
if [[ $PLAYBACK_STATUS == *"Playing"* ]]; then
  TITLE="| iconName=media-playback-start"
  PLAY_PAUSE_TOGGLE="Pause | iconName=media-playback-pause bash='$PLAY_PAUSE' terminal=false refresh=true"
elif [[ $PLAYBACK_STATUS == *"Paused"* ]]; then
  TITLE="| iconName=media-playback-pause"
  PLAY_PAUSE_TOGGLE="Play | iconName=media-playback-start bash='$PLAY_PAUSE' terminal=false refresh=true"
else
  TITLE="| iconName=$icon" 
  PLAY_PAUSE_TOGGLE="Play | iconName=media-playback-start bash='$PLAY_PAUSE' terminal=false refresh=true"
fi

if [ "$PLAYERS" == "" ]; then echo "---"; fi
echo "$TITLE"
echo "---"
if [ "$base64img" != "" ]; then echo "| image=$base64img imageWidth=200 imageHeight=200 terminal=false"; fi
if [ "$SONG_TITLE" != "" ]; then echo "<b>$SONG_TITLE</b>"; fi
if [ "$ARTIST" != "" ]; then echo "$ARTIST"; fi
if [ "$SONG_TITLE" != "" ] && [ "$ARTIST" != "" ]; then echo "---"; fi
echo "$PLAY_PAUSE_TOGGLE"
echo "Next | iconName=media-skip-forward bash='$NEXT' terminal=false refresh=true"
echo "Previous | iconName=media-skip-backward bash='$PREVIOUS' terminal=false refresh=true"
if [[ $player == *"rhythmbox"* ]]; then 
  echo "Show | iconName='$icon' bash='$player' terminal=false"
  echo "Quit | iconName=window-close bash='pkill $player' terminal=false"
fi

