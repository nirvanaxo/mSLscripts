on *:load:{
  var %tg = $script | var %tgt = $gettok(%tg,0,$asc(\))
  echo -ta Loaded: $gettok(%tg,%tgt,$asc(\))
  echo -ta IRCx: /PROP #channel adminkey|opkey|voicekey value
  echo -ta IRCx: /PROP #channel (See channel properties)
  echo -ta IRCx: /ACCESS #channel ADD|DEL OP *!*@host 
  echo -ta IRCx: /ACCESS #channel LIST|CLEAR
  echo -ta IRCx: Keep IRC rockin.
}
raw PROP:*:{
  ;add properties to memory to be used later instead of hitting
  ;the ircd for data all the time
  hadd -m $1 $2 $3
  if ($me ison $1) { echo -t $1 * $nick set property $2- }
}
raw 801:*:{
  if ($me ison $2) { echo -t $2 * Added access $3- }
}
raw 802:*:{
  if ($me ison $2) { echo -t $2 * Deleted access $3- }
}
raw 818:*:{
  ;; add properties to memory (adminkey,opkey,meta,etc)
  echo -t $2 * $3 is $4
  hadd -m $2 $3 $4
}
raw 804:*:{
  if ($5 == 0) { var %time = no-expiration }
  if ($5 > 1) { var %time = $5 $+ secs }
  if ($me ison $2) { echo -t $2 * ACL: $3 %time }
}
raw 005:*:{
  if (IRCX isin $1-) {
    hadd -m $server IRCX 1
    .timer 1 2 echo -ts This server is IRCx capable.
    .timer 1 2 echo -ts IRCx: /PROP #channel adminkey|opkey|voicekey value
    .timer 1 2 echo -ts IRCx: /PROP #channel (See channel properties)
    .timer 1 2 echo -ts IRCx: /ACCESS #channel ADD|DEL OP *!*@host 
    .timer 1 2 echo -ts IRCx: /ACCESS #channel LIST|CLEAR
  }
}

;;join with last known access key.
;; if script sees it, will /join #channel password and attempt to gain op/voice access
;; and mode evade (+b/+i/+l/+k etc)
alias joinkey {
  if ($chan($1).key != $null) { var %jkey = $chan($1).key }
  if ($hget($1,voicekey) != $null) { var %jkey = $hget($1,voicekey) }
  if ($hget($1,opkey) != $null) { var %jkey = $hget($1,voicekey) }
  if ($hget($1,adminkey) != $null) { var %jkey = $hget($1,voicekey) }
  join $1 %jkey
}

on *:admin:#:{
  if ($admnick == $me) && ($hget($server,ircx) == 1) {
    ;;so if you're op/deop flooded your script wont flood disconnect you
    ;;sends commands 250ms after op with the same name so if you get mode o+o
    ;;flooded it only sends once

    .timerprop. $+ $chan -m 1 250 prop $chan
    ;;set this so if you're just opped it'll scan access
    ;;if your access isnt in the list it'll add yourself
    hadd -mu5 add.axs $chan 1 
    .timeraccess. $+ $chan -m 1 250 access $chan list
    if ($address($me,0) != $null) { .timeraccess. $+ $chan -m 1 250 access $chan add admin $address($me,0) }

  }
}
on *:op:#:{
  if ($opnick == $me) && ($hget($server,ircx) == 1) {
    ;;so if you're op/deop flooded your script wont flood disconnect you
    ;;sends commands 250ms after op with the same name so if you get mode o+o
    ;;flooded it only sends once

    .timerprop. $+ $chan -m 1 250 prop $chan
    ;;set this so if you're just opped it'll scan access
    ;;if your access isnt in the list it'll add yourself
    hadd -mu5 add.axs $chan 1 
    .timeraccess. $+ $chan -m 1 250 access $chan list
    if ($address($me,0) != $null) { .timeraccess. $+ $chan -m 1 250 access $chan add op $address($me,0) }

  }
}
;;when booted out,
;; attempt to rejoin channel with last known key
;; or just rejoin if no key is available
on *:kick:#:{
  if ($knick == $me) { joinkey $chan }-
  }
}
