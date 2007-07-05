namespace eval buttonbar {}

proc buttonbar::create {w frame} {
  variable buttonbar

  frame $w.tabs -relief sunken -bd 1 -width 500
  pack $w.tabs -side left -anchor nw

  canvas $w.tabs.c -highlightthickness 0
  pack $w.tabs.c -fill y -side right

  set buttonbar($w) $frame
  return $w.tabs
}

proc buttonbar::add {w name} {
  variable buttonbar
  eval frame $buttonbar($w).$name
  button $w.tabs.c.$name -text $name -highlightthickness 0 -padx 3m -relief groove -pady 0 -padx 0
  pack $w.tabs.c.$name -side left -pady 0 -padx 0 -fill y
  bindtags $w.tabs.c.$name tab_$w
  bind tab_$w <Button-1> "[namespace current]::showframe $w %W"
  showframe $w $name
  return $buttonbar($w).$name
}

proc buttonbar::name {w tab name} {
  if {![winfo exists $w.tabs.c.$tab]} return
  $w.tabs.c.$tab configure -text $name
}

proc buttonbar::showframe {w name} {
  variable buttonbar
  set name [lindex [split $name .] end]
  if {[$w.tabs.c.$name cget -relief] == "raised"} return
  foreach x [winfo children $buttonbar($w)] {
    if {$x != $w} {pack forget $x}
  }
  foreach x [winfo children $w.tabs.c] {$x configure -relief groove -foreground black}
  pack $buttonbar($w).$name -fill both -expand 1
  $w.tabs.c.$name configure -foreground black -activeforeground black -relief raised
}





