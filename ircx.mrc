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
  if ($me ison $1) { echo -t $1 * $nick set property $2- }
}
raw 801:*:{
  if ($me ison $2) { echo -t $2 * Added access $3- }
}
raw 802:*:{
  if ($me ison $2) { echo -t $2 * Deleted access $3- }
}
raw 818:*:{
  ;; if property is a key (useful), save it to memory
  ;; can be useful for if channel is attacked/taken over you can rejoin with +o/+a/+v with the key
  if ($right($3,1) == key) {
    if ($hget($chan,$3) == $null) || ($hget($chan,$3) != $4) {
      hadd -m $chan $3 $4  
    }
  }
  if ($me ison $2) { echo -t $2 * $3 is $4 }
}
raw 804:*:{
  if ($5 == 0) { var %time = no-expiration }
  if ($5 > 1) { var %time = $5 $+ secs }
  if ($me ison $2) { echo -t $2 * ACL: $3 %time }
}

;;join with last known access key.
;; if script sees it, will /join #channel password and attempt to gain op/voice access
;; and mode evade (+b/+i/+l/+k etc)
alias joinkey {
  if ($hget($1,voicekey) != $null) { var %jkey = $hget($1,voicekey) }
  if ($hget($1,opkey) != $null) { var %jkey = $hget($1,voicekey) }
  if ($hget($1,ownerkey) != $null) { var %jkey = $hget($1,voicekey) }
  join $1 %jkey
}

on *:op:#:{
  if ($opnick == $me) { 
    .timerprop. $+ $chan 1 1 prop $chan
    .timeraccess. $+ $chan 1 1 access $chan list
  }
}
;;when booted out, attempt to rejoin channel with last known key (or just rejoin if no key is available
on *:kick:#:{
  if ($knick == $me) { joinkey $chan }-
  }
}
