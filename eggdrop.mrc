;; if your eggdrop has an SSL telnet running
;; /egg server.com port login password
;; will open a socket to that eggdrop and give you a control @window to type in
alias egg {
  sockclose egg. $+ $1
  sockopen -e egg. $+ $1 $2 $3
  sockmark egg. $+ $1 $4 $5
}
on *:sockopen:egg.*:{
  var %mark = $sock($sockname).mark
  if ($sock($sockname).mark) != $null) {
    .timer 1 5 sockwrite -n $sockname $gettok($sock($sockname).mark,1,32)
    .timer 1 8 sockwrite -n $sockname $gettok($sock($sockname).mark,2,32)
  }
}
on *:sockread:egg.*:{
  var %a | sockread %a | tokenize 32 %a
  ;echo -a $1-
  if ($window(@ $+ $sockname) == $null) { window -e @ $+ $sockname }
  echo -t @ $+ $sockname TELNET: $1-
}
on *:input:@egg.*:{
  if ($left($1,1) != /) { sockwrite -n $right($active,-1) $1- | echo -ta Sent: $1- }
}
on *:sockclose:egg.*:{
  egg $gettok($sockname,2,$asc(.)) $sock($sockname).ip $sock($sockname).port $sock($sockname).port
  debugg $sockname closed, reopening eggdrop: $sock($sockname).ip $sock($sockname).port $sock($sockname).port
}
alias eggwrite {
  sockwrite -n egg.* $1-
}
alias eggrehash {
  sockwrite -n egg.* .rehash
}
