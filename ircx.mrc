on *:load:{
  var %tg = $script | var %tgt = $gettok(%tg,0,$asc(\))
  echo -ta Loaded: $gettok(%tg,%tgt,$asc(\))
  echo -ta $prefixsys IRCx: /PROP #channel adminkey|opkey|voicekey value
  echo -ta $prefixsys IRCx: /PROP #channel (See channel properties)
  echo -ta $prefixsys IRCx: /ACCESS #channel ADD|DEL OP *!*@host 
  echo -ta $prefixsys IRCx: /ACCESS #channel LIST|CLEAR
  echo -ta $prefixsys IRCx: Keep IRC rockin.
}
raw PROP:*:{
  ;add properties to memory to be used later instead of hitting
  ;the ircd for data all the time
  hadd -m $1 $2 $3
  if ($me ison $1) { echo -t $1 $prefixsys $nick set property $2- }
}
raw 801:*:{
  if ($hget(noacllist,$2) != $null) { halt }
  if ($me ison $2) { echo -t $2 $prefixsys Added access $3- }
}
raw 802:*:{
  if ($hget(noacllist,$2) != $null) { halt }
  if ($me ison $2) { echo -t $2 $prefixsys Deleted access $3- }
}
raw 818:*:{
  ;; add properties to memory (adminkey,opkey,meta,etc)
  if ($hget(noproplist,$2) != $null) { halt }
  echo -t $2 $prefixsys $3 is $4-
  hadd -m $2 $3 $4-
}
raw 804:*:{
  if ($hget(noacllist,$2) != $null) { halt }
  if ($5 == 0) { var %time = no-expiration }
  if ($5 > 1) { var %time = $5 $+ secs }
  if ($me ison $2) { echo -t $2 $prefixsys ACL: $3 $4 %time }
}
raw 005:*:{
  if (IRCX isin $1-) {
    hadd -m $server IRCX 1
    .timer 1 1 isircx
  }
}
alias isircx {
  echo -ts $prefixsys This server is IRCx capable.
  echo -ts $prefixsys /PROP #channel adminkey|opkey|voicekey value
  echo -ts $prefixsys /PROP #channel (See channel properties)
  echo -ts $prefixsys /ACCESS #channel ADD|DEL OP *!*@host 
  echo -ts $prefixsys /ACCESS #channel LIST|CLEAR
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
    if ($address($me,0) != $null) {
      hadd -mu2 noacclist $chan 1
      .timeraccessadmin. $+ $chan -m 1 250 access $chan add admin $address($me,0)
    }

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
    hadd -mu2 noacclist $chan 1
    .timeraccess. $+ $chan -m 1 250 access $chan list
    if ($address($me,0) != $null) { .timeraccessop. $+ $chan -m 1 250 access $chan add op $address($me,0) }

  }
}
;;when booted out,
;; attempt to rejoin channel with last known key
;; or just rejoin if no key is available
on *:kick:#:{
  if ($knick == $me) { joinkey $chan }-
  }
}
alias ircx.addaccess {
  hadd -mu2 noacllist $1 1
  access $1-
}
alias ircx.addall {
  var %chan = $1
  var %a = 1 | var %b = $nick(%chan,0)
  while (%a <= %b) {
    var %nick = $nick(%chan,%a)
    var %nickstatus = $left($nick(%chan,%nick).pnick,1)
    var %mystatus = $left($nick(%chan,$me).pnick,1)
    if (%nickstatus == .) && (%mystatus == .) {
      ircx.addaccess %chan ADD ADMIN $ircx.address(%nick)
    }
    if (%nickstatus == @) && (%mystatus == .) || (%mystatus == @) {
      ircx.addaccess %chan ADD OP $ircx.address(%nick)
    }
    if (%nickstatus == +) && (%mystatus == .) || (%mystatus == @) {
      ircx.addaccess %chan ADD VOICE $ircx.address(%nick)
    }
    inc %a
  }
}
alias ircx.address {
  var %address = $address($1,0)
  if ($fingerprint($1) != $null) { var %address = $chr(36) $+ z: $+ $fingerprint($1) }
  return %address
}
alias axs {
  var %a = 1 | var %b = $chan(0)
  while (%a <= %b) {
    var %chan = $chan(%a)
    ircx.addall %chan
    inc %a
  }
}
alias axs2 {
  var %a = 1 | var %b = $chan(0)
  while (%a <= %b) {
    var %chan = $chan(%a)
    ircx.add.all %chan
    if ($left($nick(%chan,$me).pnick,1) == .) {
      echo -a gogo
      if ($hget($chan,adminkey) == $null) || ($hget($chan,opkey) == $null) { prop $chan }
      ircx.addaccess %chan ADD ADMIN $ircx.address($me)
    }
    if ($left($nick(%chan,$me).pnick,1) == @) {
      ircx.addaccess %chan ADD OP $ircx.address($me)
    }
    inc %a
  }
}
alias keys {
  if ($hget($1,adminkey) != $null) { var %keys = adminkey: $+ $hget($1,adminkey) }
  if ($hget($1,opkey) != $null) { var %keys = %keys opkey: $+ $hget($1,opkey) }
  echo -t $1 %keys
}
raw 276:*has*client*certificate*fingerprint*:{
  echo -a RAW $1-
  hadd -m fingerprint $2 $7
}
alias fingerprint {
  if ($hget(fingerprint,$1) != $null) { return $hget(fingerprint,$1) }
  else { return $null }
}
