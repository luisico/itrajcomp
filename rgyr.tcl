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
# 

# Documentation
# ------------
#      The documentation can be found in the README.txt file and
#      http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp

# rgyr.tcl
#    Functions to calculate diff radius of gyration between structures.


package provide itrajcomp 1.0

proc itrajcomp::calc_rgyr {self} {
  array set opts [array get ${self}::opts]
  array set sets [array get ${self}::sets]
  
  # Get values for each mol/frame
  foreach i $sets(mol1) {
    set s1 [atomselect $i $sets(sel1)]
    foreach j [lindex $sets(frame1) [lsearch -exact $sets(mol1) $i]] {
      $s1 frame $j
      set rgyr($i:$j) [measure rgyr $s1]
    }
  }
  # TODO: if atomsel is different, should it be weighted? No, because it already weights by number of atoms
  if {!$sets(samemols)} {
    foreach k $sets(mol2) {
      set s2 [atomselect $k $sets(sel2)]
      foreach l [lindex $sets(frame2) [lsearch -exact $sets(mol2) $k]] {
	$s2 frame $l
	set rgyr($k:$l) [measure rgyr $s2]
      }
    }
  }

  array set ${self}::rgyr [array get rgyr]

  return [[namespace current]::LoopFrames $self]
}


proc itrajcomp::calc_rgyr_hook {self} {
  return [expr {[set ${self}::rgyr([set ${self}::i]:[set ${self}::j])] - [set ${self}::rgyr([set ${self}::k]:[set ${self}::l])]} ]
}


proc itrajcomp::calc_rgyr_options {} {
  # Options for rgyr
  variable calc_rgyr_frame
  variable calc_rgyr_opts

  variable calc_rgyr_datatype
  set calc_rgyr_datatype(mode) "single"

  # Graph options
  variable calc_rgyr_graph
  array set calc_rgyr_graph {
    type         "frames"
    formats      "f"
    rep_style1   "NewRibbons"
  }
}
