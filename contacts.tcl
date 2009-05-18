#****h* itrajcomp/contacts
# NAME
# contacts -- Functions to calculate contacts between atoms
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
#
# Functions to calculate contacts between atoms.
# 
# SEE ALSO
# More documentation can be found in:
# * README.txt
# * itrajcomp.tcl
# * http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp
#
# COPYRIGHT
# Copyright (C) 2005-2008 by Luis Gracia <lug2002@med.cornell.edu> 
#
#****

#****f* contacts/calc_contacts
# NAME
# calc_contacts
# SYNOPSIS
# itrajcomp::calc_contacts self
# FUNCTION
# This functions gets called when adding a new calctype.
# Contacts calculation type
# PARAMETERS
# * self -- object
# RETURN VALUE
# Status code
# SOURCE
proc itrajcomp::calc_contacts {self} {
  return [[namespace current]::LoopFrames $self]
}
#*****

#****f* contacts/calc_contacts_hook
# NAME
# calc_contacts_hook
# SYNOPSIS
# itrajcomp::calc_contacts_hook self
# FUNCTION
# This function gets called for each pair.
# Contacts
# PARAMETERS
# * self -- object
# RETURN VALUE
# List with number of contacts and contacts list
# SOURCE
proc itrajcomp::calc_contacts_hook {self} {
  set contacts [measure contacts [set ${self}::guiopts(cutoff)] [set ${self}::s1] [set ${self}::s2]]
  set number_contacts [llength [lindex $contacts 0]]
  return [list $number_contacts $contacts]
}
#*****

#****f* contacts/calc_contacts_options
# NAME
# calc_contacts_options
# SYNOPSIS
# itrajcomp::calc_contacts_options
# FUNCTION
# This functions gets called when adding a new type of calculation. It sets up the GUI and other options.
# SOURCE
proc itrajcomp::calc_contacts_options {} {
  # Options
  variable calc_contacts_opts
  array set calc_contacts_opts {
    mode         frames
    sets         dual
    ascii        1
    formats      i
    style        NewRibbons
  }

  # GUI options
  variable calc_contacts_gui
  variable calc_contacts_guiopts
  array set calc_contacts_guiopts {
    cutoff    5.0
  }

  frame $calc_contacts_gui.cutoff
  pack $calc_contacts_gui.cutoff -side top -anchor nw
  label $calc_contacts_gui.cutoff.l -text "Cutoff:"
  entry $calc_contacts_gui.cutoff.v -width 5 -textvariable [namespace current]::calc_contacts_guiopts(cutoff)
  pack $calc_contacts_gui.cutoff.l $calc_contacts_gui.cutoff.v -side left
  [namespace current]::setBalloonHelp $calc_contacts_gui.cutoff "Maximum distance of successful contacts"
}
#*****
