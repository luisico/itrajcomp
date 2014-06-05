#****h* itrajcomp/balloons
# NAME
# balloons
#
# DESCRIPTION
# Provides balloon style tooltips.
#****

#****f* balloons/setBalloonHelp
# NAME
# setBalloonHelp
# SYNOPSIS
# itrajcomp::setBalloonHelp widget msg args
# FUNCTION
# Create a balloon for a widget
# PARAMETERS
# * widget -- widget
# * msg -- Message
# * args -- arguments
# SOURCE
proc itrajcomp::setBalloonHelp {widget msg args} {
  array set opt [concat { -tag "" } $args]
  if {$msg ne ""} {
    set msg [[namespace current]::wrapmsg $msg]
    set toolTipScript [list [namespace current]::showBalloonHelp %W [string map {% %%} $msg]]
    set enterScript [list after 1000 $toolTipScript]
    set leaveScript [list after cancel $toolTipScript]
    append leaveScript \n [list after 200 [list destroy .balloonHelp]]
  } else {
    set enterScript {}
    set leaveScript {}
  }
  if {$opt(-tag) ne ""} {
    switch -- [winfo class $widget] {
      Text {
        $widget tag bind $opt(-tag) <Enter> $enterScript
        $widget tag bind $opt(-tag) <Leave> $leaveScript
      }
      Canvas {
        $widget bind $opt(-tag) <Enter> $enterScript
        $widget bind $opt(-tag) <Leave> $leaveScript
      }
      default {
        bind $widget <Enter> $enterScript
        bind $widget <Leave> $leaveScript
      }
    }
  } else {
    bind $widget <Enter> $enterScript
    bind $widget <Leave> $leaveScript
  }
}
#*****

#****f* balloons/showBalloonHelp
# NAME
# showBalloonHelp
# SYNOPSIS
# itrajcomp::showBalloonHelp widget msg
# FUNCTION
# Show balloon
# PARAMETERS
# * widget -- widget
# * msg -- Message
# SOURCE
proc itrajcomp::showBalloonHelp {widget msg} {
  set t .balloonHelp
  catch {destroy $t}
  toplevel $t -bg black
  wm overrideredirect $t yes
  if {$::tcl_platform(platform) == "macintosh"} {
    unsupported1 style $t floating sideTitlebar
  }
  pack [label $t.l -text [subst $msg] -bg #ffffcc -font {Helvetica 9} -justify left] -padx 1 -pady 1
  set width [expr {[winfo reqwidth $t.l] + 2}]
  set height [expr {[winfo reqheight $t.l] + 2}]
  set xMax [expr {[winfo screenwidth $widget] - $width}]
  set yMax [expr {[winfo screenheight $widget] - $height}]
  set x [winfo pointerx $widget]
  set y [expr {[winfo pointery $widget] + 20}]
  if {$x > $xMax} {
    set x $xMax
  }
  if {$y > $yMax} {
    set y $yMax
  }
  wm geometry $t +$x+$y
  set destroyScript [list destroy .balloonHelp]
  bind $t <Enter> [list after cancel $destroyScript]
  bind $t <Leave> $destroyScript
}
#*****

#****f* balloons/wrapmsg
# NAME
# wrapmsg
# SYNOPSIS
# itrajcomp::wrapmsg msg
# FUNCTION
# Wraps a text to a character limit width
# PARAMETERS
# * msg -- text
# * width -- width
# RETURN VALUE
# String with wrappred text
# SOURCE
proc itrajcomp::wrapmsg {msg {width 50}} {
  set length [string length $msg]
  set end $width
  if {$length > $end} {
    set end [string last " " $msg $end]
    set msg1 [string range $msg 0 $end]
    set msg2 [string range $msg [expr {$end+1}] end]

    set msg $msg1
    append msg "\n"
    append msg [[namespace current]::wrapmsg $msg2]
  }

  return $msg
}
#*****
