 namespace eval buttonbar {}

 proc buttonbar::create {w frame} {
    variable buttonbar
    set ns [namespace current]
    frame $w
    frame $w.middle -relief raised -bd 1
    button $w.left  -text < -bd 1 -command [list ${ns}::scrollleft $w]   -highlightthickness 0 -width 2 -padx 0 -state disabled
    button $w.right -text > -bd 1 -command [list ${ns}::scrollright $w]  -highlightthickness 0 -width 2 -padx 0 -state disabled
    button $w.close -text X -bd 1 -command [list ${ns}::closecurrent $w] -highlightthickness 0 -width 3 -padx 0
    canvas $w.middle.c -height [winfo reqheight $w.right] -xscrollincrement 1 -highlightthickness 0
    frame $w.middle.c.f
    grid $w.left $w.right $w.middle $w.close -sticky nesw -padx 0 -pady 0
    grid columnconfigure $w {0 1 3} -minsize 15 -weight 0
    grid columnconfigure $w 2 -weight 2
    pack $w.middle.c -fill both
    $w.middle.c create window 0 0 -anchor nw -window $w.middle.c.f
    bind $w.middle.c.f <Configure> "$w.middle.c configure -scrollregion \[$w.middle.c bbox all\]"
    bind tab <Button-1> "[namespace current]::showframe $w %W; bind tab <Motion> \"[namespace current]::tabdrag $w %W\""
    bind tab <ButtonRelease-1> "[namespace current]::tearoff $w %W %X %Y; bind tab <Motion> {}; after cancel \"[namespace current]::tabdrag $w %W\""
    bind $w.middle.c <Configure> "[namespace current]::setscrollstate $w"
    set buttonbar($w) $frame
    return $w
 }

 proc buttonbar::add {w name} {
    variable buttonbar
    eval frame $buttonbar($w).$name
    button $w.middle.c.f.$name -text $name -highlightthickness 0 -padx 3m -relief groove
    pack $w.middle.c.f.$name -side left -pady 0 -padx 0 -fill y
    bindtags $w.middle.c.f.$name tab
    showframe $w $name
    after idle [namespace current]::setscrollstate $w
    return $buttonbar($w).$name
 }

 proc buttonbar::name {w tab name} {
    if {![winfo exists $w.middle.c.f.$tab]} return
    $w.middle.c.f.$tab configure -text $name
 }

 proc buttonbar::scrollright {w} {
    scrollsetleft $w [winfo containing [expr [winfo rootx $w.middle.c] + [winfo width $w.middle.c] - 1] [winfo rooty $w.middle.c]]
    $w.right configure -foreground black -activeforeground black
 }

 proc buttonbar::scrollleft {w} {
    scrollsetright $w [winfo containing [winfo rootx $w.middle.c] [winfo rooty $w.middle.c]]
    $w.left configure -foreground black -activeforeground black
 }

 proc buttonbar::scrollsetleft {w tab} {
    set tab [string map "$w.middle.c.f {}" $tab]
    if {![winfo exists $w.middle.c.f$tab]} return
    $w.middle.c xview scroll [expr [winfo rootx $w.middle.c.f$tab] - [winfo rootx $w.middle.c]] units
 }

 proc buttonbar::scrollleft {w} {
    scrollsetright $w [winfo containing [winfo rootx $w.middle.c] [winfo rooty $w.middle.c]]
    $w.left configure -foreground black -activeforeground black
 }

 proc buttonbar::scrollsetleft {w tab} {
    set tab [string map "$w.middle.c.f {}" $tab]
    if {![winfo exists $w.middle.c.f$tab]} return
    $w.middle.c xview scroll [expr [winfo rootx $w.middle.c.f$tab] - [winfo rootx $w.middle.c]] units
 }

 proc buttonbar::scrollsetright {w tab} {
    set tab [string map "$w.middle.c.f {}" $tab]
    if {![winfo exists $w.middle.c.f$tab]} return
    $w.middle.c xview scroll [expr -1 * (([winfo rootx $w.middle.c] + [winfo width $w.middle.c]) - ([winfo rootx $w.middle.c.f$tab] + [winfo width $w.middle.c.f$tab]))] units
 }

 proc buttonbar::closecurrent {w} {
    variable buttonbar
    foreach x [winfo children $w.middle.c.f] {
        if {[$x cget -relief] == "raised"} {
            destroy $x $buttonbar($w).[string map "$w.middle.c.f. {}" $x]
            return
        }
    }
 }

 proc buttonbar::hilightbutton {w name} {
    global info
    set name [winfo toplevel $name]
    if {[winfo ismapped $name]} return
    set view [tabvisibility $name]
    set color red
    if {[info exists info(text,$name)] && [string match *hilight* [$info(text,$name) tag names end-1l+8c]]} {
        set color yellow
    }
    if {[$w.middle.c.f$name cget -foreground] != "yellow"} {
        $w.middle.c.f$name configure -foreground $color -activeforeground $color
    }
    if {$view < 0 && [$w.left cget -foreground] != "yellow"} {
        $w.left configure -foreground $color -activeforeground $color
    }
    if {$view > 0 && [$w.right cget -foreground] != "yellow"} {
        $w.right configure -foreground $color -activeforeground $color
    }
 }

 proc buttonbar::tabvisibility {w name} {
    set s [winfo rootx $w.middle.c]
    set ts [winfo rootx $w.middle.c.f$name]
    if {$ts < $s} {return -1}
    if {$ts + [winfo width $w.middle.c.f$name] > $s + [winfo width $w.middle.c]} {return 1}
    return 0
 }

 proc buttonbar::showframe {w name} {
    variable buttonbar
    set name [lindex [split $name .] end]
    if {[$w.middle.c.f.$name cget -relief] == "raised"} return
    foreach x [winfo children $buttonbar($w)] {
        if {$x != $w} {pack forget $x}
    }
    foreach x [winfo children $w.middle.c.f] {$x configure -relief groove}
    pack $buttonbar($w).$name -fill both -expand 1
    $w.middle.c.f.$name configure -foreground black -activeforeground black -relief raised
 }

 proc buttonbar::setscrollstate {w} {
    set width [winfo width $w.middle.c]
    if {$width > 1 && [winfo width $w.middle.c.f] > $width} {
        $w.left configure -state normal
        $w.right configure -state normal
    } else {
        $w.left configure -foreground black -activeforeground black -state disabled
        $w.right configure -foreground black -activeforeground black -state disabled
    }
 }

 proc buttonbar::tearoff {w tab x y} {
    variable buttonbar
    set tab [string map "$w.middle.c.f. {}" $tab]
    set rx1 [winfo rootx $w]
    set ry1 [winfo rooty $w]
    set rx2 [expr $rx1 + [winfo width $w]]
    set ry2 [expr $ry1 + [winfo height $w]]
    if {$x < ($rx1 - 20) || $x > ($rx2 + 20) || $y < ($ry1 - 20) || $y > ($ry2 + 20)} {
      set win $buttonbar($w).$tab
      # add your function here
      closecurrent $w
    }
 }

 proc buttonbar::tabdrag {w tab} {
    set pointery [winfo pointery $tab]
    set pointerx [winfo pointerx $tab]
    set hi [winfo rooty $w.middle]
    if {$pointery < $hi || $pointery > ($hi + [winfo height $w.middle])} return
    set children [winfo children $w.middle.c.f]
    set c [lsearch -exact $children $tab]
    if {$pointerx < [winfo rootx $w.middle.c]} {
        bind tab <Motion> {}
        after 500 "[namespace current]::tabdrag $w $tab"
        if {[set to [lindex $children [expr $c - 1]]] == ""} return
        pack configure $tab -before $to
        lower $tab $to
        update idletasks
        if {[tabvisibility $w [string map "$w.middle.c.f {}" $tab]] < 0} {scrollsetleft $w $tab}
        return
    } elseif {$pointerx > ([winfo rootx $w.middle.c] + [winfo width $w.middle.c])} {
        bind tab <Motion> {}
        after 500 "[namespace current]::tabdrag $w $tab"
        if {[set to [lindex $children [expr $c + 1]]] == ""} return
        pack configure $tab -after $to
        raise $tab $to
        update idletasks
        if {[tabvisibility $w [string map "$w.middle.c.f {}" $tab]] > 0} {scrollsetright $w $tab}
        return
    }
    bind tab <Motion> "[namespace current]::tabdrag $w $tab"
    set in [winfo containing $pointerx $pointery]
    if {$tab == $in} return
    set i [lsearch -exact $children $in]
    if {$i < 0} {
        set to [lindex $children end]
        pack configure $tab -after $to
        raise $tab $to
    } elseif {$i < ($c - 1)} {
        set to [lindex $children [expr $c - 1]]
        pack configure $tab -before $to
        lower $tab $to
    } elseif {$i > ($c + 1)} {
        set to [lindex $children [expr $c + 1]]
        pack configure $tab -after $to
        raise $tab $to
    }
 }

