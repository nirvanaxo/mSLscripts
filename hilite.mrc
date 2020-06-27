on *:text:*:#:{
  if ($me isin $1-) || ($anick isin $1-) {
    if ($window(@highlights) == $null) { window -ne @highlights }
    echo @highlights * $date(ddd/mmm/yyyy h:nnt) $nick $+ / $+ $chan $+ / $+ $network $+ : $strip($1-)
    if ($active != $chan) { scid -a echo.all.chans.except $chan * Highlight: $nick  /  $chan  /  $network $+ : $strip($1-) }
  }
}
alias echo.all.chans {
  var %a = 1 | var %b = $chan(0)
  while (%a <= %b) {
    if ($me ison $chan(%a)) { echo -ti $chan(%a) $1- }
    inc %a
  }
}
alias echo.all.chans.except {
  var %a = 1 | var %b = $chan(0)
  while (%a <= %b) {
    if ($me ison $chan(%a)) && ($chan(%a) != $1) { echo -ti $chan(%a) $2- }
    inc %a
  }
}
