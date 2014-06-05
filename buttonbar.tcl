#****h* /buttonbar
# NAME
# buttonbar
#
# DESCRIPTION
# Buttonbar widget.
#
# SOURCE
namespace eval buttonbar {}
#****

#****f* buttonbar/create
# NAME
# create
# SYNOPSIS
# buttonbar::create widget frame
# FUNCTION
# Create a new buttonbar
# PARAMETERS
# * widget -- container widget
# * frame -- frame to display
# RETURN VALUE
# Widget
# SOURCE
proc buttonbar::create {widget frame} {
  variable buttonbar

  frame $widget.tabs -relief sunken -bd 1 -width 500
  pack $widget.tabs -side left -anchor nw

  canvas $widget.tabs.c -highlightthickness 0
  pack $widget.tabs.c -fill y -side right

  set buttonbar($widget) $frame
  return $widget.tabs
}
#*****

#****f* buttonbar/add
# NAME
# add
# SYNOPSIS
# buttonbar::add widget name
# FUNCTION
# Add a tab
# PARAMETERS
# * widget -- container widget
# * name -- tab name
# RETURN VALUE
# Widget
# SOURCE
proc buttonbar::add {widget name} {
  variable buttonbar
  eval frame $buttonbar($widget).$name
  button $widget.tabs.c.$name -text $name -highlightthickness 0 -relief groove -pady 0 -padx 2
  pack $widget.tabs.c.$name -side left -pady 0 -padx 0 -fill y
  bindtags $widget.tabs.c.$name tab_$widget
  bind tab_$widget <Button-1> "[namespace current]::showframe $widget %W"
  showframe $widget $name
  return $buttonbar($widget).$name
}
#*****

#****f* buttonbar/name
# NAME
# name
# SYNOPSIS
# buttonbar::name widget tab name
# FUNCTION
# Set name of tab
# PARAMETERS
# * widget -- container widget
# * tab -- tab
# * name -- name
# SOURCE
proc buttonbar::name {widget tab name} {
  if {![winfo exists $widget.tabs.c.$tab]} return
  $widget.tabs.c.$tab configure -text $name
}
#*****

#****f* buttonbar/showframe
# NAME
# showframe
# SYNOPSIS
# buttonbar::showframe widget name
# FUNCTION
# Show tab
# PARAMETERS
# * widget -- container widget
# * name -- name
# SOURCE
proc buttonbar::showframe {widget name} {
  variable buttonbar
  set name [lindex [split $name .] end]
  if {[$widget.tabs.c.$name cget -relief] == "raised"} return
  foreach x [winfo children $buttonbar($widget)] {
    if {$x != $widget} {pack forget $x}
  }
  foreach x [winfo children $widget.tabs.c] {$x configure -relief groove -foreground black -bd 0}
  pack $buttonbar($widget).$name -fill both -expand 1
  $widget.tabs.c.$name configure -foreground black -activeforeground black -relief raised -bd 1
}
#*****
