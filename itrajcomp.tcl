#****h* /itrajcomp
# NAME
# iTrajComp - interactive Trajectory Comparison
#
# http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp
#
# AUTHOR
# Luis Gracia, PhD
# Department of Physiology & Biophysics
# Weill Medical College of Cornell University
# 1300 York Avenue, Box 75
# New York, NY 10021
# lug2002@med.cornell.edu
#
# DESCRIPTION
# iTrajComp is a VMD plugin for general analysis of trajectories.
# This file sets up the environment and loads the rest of code.
# 
# SEE ALSO
# More documentation can be found in the README.txt file and
# http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp
#
# NOTES
#
# TODO
#
# BUGS
#
# COPYRIGHT
# Copyright (C) 2005-2008 by Luis Gracia <lug2002@med.cornell.edu> 
#
# 
# SOURCE
package provide itrajcomp 1.0

namespace eval itrajcomp {
  # TODO: does init conflict with other global functions?
  namespace export init
  
  global env

  # TODO: these lists could go to save/load or maingui.tcl
  variable open_format_list [list tab matrix plotmtv plotmtv_binary]
  variable save_format_list [list tab tab_raw matrix plotmtv plotmtv_binary postscript]

  # TODO: tmpdir not used
  variable tmpdir
  if { [info exists env(TMPDIR)] } {
    set tmpdir $env(TMPDIR)
  } else {
    set tmpdir /tmp
  }
}
#****

#****f* /itrajcomp_tk_cb
# NAME
# itrajcomp_tk_cb
# FUNCTION
# Hook for vmd
# RETURN VALUE
# Main plugin window
# SOURCE
proc itrajcomp_tk_cb {} {
  # Test hacks
  ::itrajcomp::test_hacks

  # Hook for vmd
  ::itrajcomp::init
  return $itrajcomp::win_main
}
#*****

# Source rest of files
source [file join $env(ITRAJCOMPDIR) balloons.tcl]
source [file join $env(ITRAJCOMPDIR) buttonbar.tcl]
source [file join $env(ITRAJCOMPDIR) combine.tcl]
source [file join $env(ITRAJCOMPDIR) frames.tcl]
source [file join $env(ITRAJCOMPDIR) graphics.tcl]
source [file join $env(ITRAJCOMPDIR) gui.tcl]
source [file join $env(ITRAJCOMPDIR) load.tcl]
source [file join $env(ITRAJCOMPDIR) maingui.tcl]
source [file join $env(ITRAJCOMPDIR) object.tcl]
source [file join $env(ITRAJCOMPDIR) save.tcl]
source [file join $env(ITRAJCOMPDIR) segments.tcl]
source [file join $env(ITRAJCOMPDIR) utils.tcl]
source [file join $env(ITRAJCOMPDIR) hacks.tcl]
source [file join $env(ITRAJCOMPDIR) standard.tcl]
source [file join $env(ITRAJCOMPDIR) user.tcl]
#source [file join $env(ITRAJCOMPDIR) clustering.tcl]
