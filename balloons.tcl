#
#         iTrajComp v1.0
#
# interactive Trajectory Comparison
#
# http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp

# Author
# ------
#      Luis Gracia, PhD
#      Department of Physiology & Biophysics
#      Weill Medical College of Cornell University
#      1300 York Avenue, Box 75
#      New York, NY 10021
#      lug2002@med.cornell.edu

# Description
# -----------
#      See maingui.tcl

# Documentation
# ------------
#      The documentation can be found in the README.txt file and
#      http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp

# balloons.tcl
#    Provides balloon style tooltips.


# http://wiki.tcl.tk/16317
# modified to wrap msg
proc itrajcomp::setBalloonHelp {w msg args} {
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
    switch -- [winfo class $w] {
      Text {
        $w tag bind $opt(-tag) <Enter> $enterScript
        $w tag bind $opt(-tag) <Leave> $leaveScript
      }
      Canvas {
        $w bind $opt(-tag) <Enter> $enterScript
        $w bind $opt(-tag) <Leave> $leaveScript
      }
      default {
        bind $w <Enter> $enterScript
        bind $w <Leave> $leaveScript
      }
    }
  } else {
    bind $w <Enter> $enterScript
    bind $w <Leave> $leaveScript
  }
}

proc itrajcomp::showBalloonHelp {w msg} {
  set t .balloonHelp
  catch {destroy $t}
  toplevel $t -bg black
  wm overrideredirect $t yes
  if {$::tcl_platform(platform) == "macintosh"} {
    unsupported1 style $t floating sideTitlebar
  }
  pack [label $t.l -text [subst $msg] -bg #ffffcc -font {Helvetica 9}] -padx 1 -pady 1
  set width [expr {[winfo reqwidth $t.l] + 2}]
  set height [expr {[winfo reqheight $t.l] + 2}]
  set xMax [expr {[winfo screenwidth $w] - $width}]
  set yMax [expr {[winfo screenheight $w] - $height}]
  set x [winfo pointerx $w]
  set y [expr {[winfo pointery $w] + 20}]
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

proc itrajcomp::wrapmsg {msg} {
  set length [string length $msg]
  set end 50
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
