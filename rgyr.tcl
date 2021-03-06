#****h* itrajcomp/rgyr
# NAME
# rgyr
#
# DESCRIPTION
# Functions to calculate diff radius of gyration between structures.
#****

#****f* rgyr/calc_rgyr
# NAME
# calc_rgyr
# SYNOPSIS
# itrajcomp::calc_rgyr self
# FUNCTION
# This functions gets called when adding a new type of calculation.
# Radius of gyration rmsd calculation type
# PARAMETERS
# * self -- object
# RETURN VALUE
# Status code
# SOURCE
proc itrajcomp::calc_rgyr {self} {
  #array set guiopts [array get ${self}::guiopts]
  array set sets [array get ${self}::sets]

  # Precalculate
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
#*****

#****f* rgyr/calc_rgyr_hook
# NAME
# calc_rgyr_hook
# SYNOPSIS
# itrajcomp::calc_rgyr_hook self
# FUNCTION
# This function gets called for each pair.
# Calculte the radius of gyration rmsd
# PARAMETERS
# * self -- object
# RETURN VALUE
# Rgyr
# SOURCE
proc itrajcomp::calc_rgyr_hook {self} {
  return [expr {[set ${self}::rgyr([set ${self}::i]:[set ${self}::j])] - [set ${self}::rgyr([set ${self}::k]:[set ${self}::l])]} ]
}
#*****

#****f* rgyr/calc_rgyr_options
# NAME
# calc_rgyr_options
# SYNOPSIS
# itrajcomp::calc_rgyr_options
# FUNCTION
# This functions gets called when adding a new type of calculation. It sets up the GUI and other options.
# SOURCE
proc itrajcomp::calc_rgyr_options {} {
  # Options
  variable calc_rgyr_opts
  array set calc_rgyr_opts {
    mode         frames
    sets         single
    formats      f
    style        NewRibbons
  }

  # GUI options
  # TODO: if not declared do it in maingui.tcl
  variable calc_rgyr_gui
  variable calc_rgyr_guiopts
}
#*****
