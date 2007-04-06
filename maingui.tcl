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

# maingui.tcl
#    Main GUI for the iTrajComp plugin.


package provide itrajcomp 1.0

namespace eval itrajcomp {
  namespace export init
  
  # Global variables
  global env
  variable w
  #variable mol1_m_list
  #variable mol_ref

  variable open_format_list [list tab matrix plotmtv plotmtv_binary]
  variable save_format_list [list tab matrix plotmtv plotmtv_binary postscript]

  variable tmpdir
  if { [info exists env(TMPDIR)] } {
    set tmpdir $env(TMPDIR)
  } else {
    set tmpdir /tmp
  }
}


proc itrajcomp_tk_cb {} {
  # Hook for vmd
  ::itrajcomp::init
  return $itrajcomp::w
}


proc itrajcomp::init {} {
  # Initialize main window
  variable w
  variable open_format_list

  # If already initialized, just turn on
  if { [winfo exists .itrajcomp] } {
    wm deiconify $w
    return
  }
  
  # Create the main window
  set w [toplevel .itrajcomp]
#  catch {destroy $w}
  wm title $w "iTrajComp"
  wm iconname $w "iTrajComp" 
  wm resizable $w 1 0

  # Define main gui variables
  #--
  variable mol1_def   top
  variable frame1_def all
  variable mol2_def   top
  variable frame2_def all

  variable mol1_m_list 0
  variable mol1_f_list 0
  variable mol2_m_list 0
  variable mol2_f_list 0

  variable skip1 0
  variable skip2 0

  variable selmod1 "no"
  variable selmod2 "no"

  variable samemols 0

  variable calctype "rmsd"
  variable align 0
  
  variable diagonal 0
  variable cutoff 5.0
  variable angle 30.0
  variable reltype 1
  variable byres 1
  variable normalize "none"

  variable label_type "Dihedrals"
  variable labels_status
  variable labels_status_array

  # Menu
  #--
  frame $w.menubar -relief raised -bd 2
  pack $w.menubar -side top -padx 1 -fill x

  menubutton $w.menubar.file -text "File" -underline 0 -menu $w.menubar.file.menu
  menu $w.menubar.file.menu -tearoff no
  $w.menubar.file.menu add cascade -label "Load..." -underline 0 -menu $w.menubar.file.menu.load
  menu $w.menubar.file.menu.load -tearoff no
  foreach as $open_format_list {
    $w.menubar.file.menu.load add command -label $as -command "[namespace current]::loadDataBrowse $as"
  }
  pack $w.menubar.file -side left

  menubutton $w.menubar.options -text "Options" -underline 0 -menu $w.menubar.options.menu
  menu $w.menubar.options.menu -tearoff no
  $w.menubar.options.menu add checkbutton -label "Progress bar" -variable [namespace current]::options(progress) -command "[namespace current]::ProgressBar 0 0"
  pack $w.menubar.options -side left

  menubutton $w.menubar.combine -text "Combine" -underline 0 -menu $w.menubar.combine.menu
  menu $w.menubar.combine.menu -tearoff no
  $w.menubar.combine.menu add command -label "Combine" -command "[namespace current]::Combine"
  pack $w.menubar.combine -side left

  menubutton $w.menubar.help -text "Help" -underline 0 -menu $w.menubar.help.menu
  menu $w.menubar.help.menu -tearoff no
  $w.menubar.help.menu add command -label "About" -command [namespace current]::help_about
  $w.menubar.help.menu add command -label "Help..." -command "vmd_open_url http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp/index.html"
  pack $w.menubar.help -side right

  # Status line
  #--
  frame $w.status
  label $w.status.label -text "Status:"

  canvas $w.status.info -relief sunken -height 20 -highlightthickness 0
  $w.status.info xview moveto 0
  $w.status.info yview moveto 0
  $w.status.info create rect 0 0 0 0 -tag progress -fill cyan -outline cyan
  $w.status.info create text 5 4 -tag txt -anchor nw

  pack $w.status -side bottom -fill x -expand yes
  pack $w.status.label -side left
  pack $w.status.info -side left -fill x -expand yes

  # Tabs
  #--
  frame $w.tabcontent
  pack $w.tabcontent -side bottom -padx 1 -fill x
  pack [buttonbar::create $w.tabs $w.tabcontent] -side top -fill x

  # Frame for molecule/frame selection
  #--
  variable tab_sel [buttonbar::add $w.tabs sel]
  buttonbar::name $w.tabs sel "Selection"

  # SET1
  #--
  labelframe $tab_sel.mol1 -relief ridge -bd 4 -text "Set 1"
  pack $tab_sel.mol1 -side top -anchor nw -expand yes -fill x

  # atom1
  #--
  labelframe $tab_sel.mol1.a -relief ridge -bd 2 -text "Atom selection"
  text $tab_sel.mol1.a.sel -exportselection yes -height 5 -width 25 -wrap word
  $tab_sel.mol1.a.sel insert end "all"
  pack $tab_sel.mol1.a -side top -expand yes -fill x
  pack $tab_sel.mol1.a.sel -side left -expand yes -fill x

  # mol1
  #--
  labelframe $tab_sel.mol1.m -relief ridge -bd 2 -text "Molecules"
  radiobutton $tab_sel.mol1.m.all -text "All"    -variable [namespace current]::mol1_def -value "all"
  radiobutton $tab_sel.mol1.m.top -text "Top"    -variable [namespace current]::mol1_def -value "top"
  radiobutton $tab_sel.mol1.m.act -text "Active" -variable [namespace current]::mol1_def -value "act"
  frame $tab_sel.mol1.m.ids
  radiobutton $tab_sel.mol1.m.ids.r -text "IDs:" -variable [namespace current]::mol1_def -value "id"
  entry $tab_sel.mol1.m.ids.list -width 10 -textvariable [namespace current]::mol1_m_list

  pack $tab_sel.mol1.m -side left
  pack $tab_sel.mol1.m.all $tab_sel.mol1.m.top $tab_sel.mol1.m.act $tab_sel.mol1.m.ids -side top -anchor w 
  pack $tab_sel.mol1.m.ids.r $tab_sel.mol1.m.ids.list -side left
  
  # frame1
  #--
  labelframe $tab_sel.mol1.f -relief ridge -bd 2 -text "Frames"
  radiobutton $tab_sel.mol1.f.all -text "All"     -variable [namespace current]::frame1_def -value "all"
  radiobutton $tab_sel.mol1.f.top -text "Current" -variable [namespace current]::frame1_def -value "cur"
  frame $tab_sel.mol1.f.ids
  radiobutton $tab_sel.mol1.f.ids.r -text "IDs:"  -variable [namespace current]::frame1_def -value "id"
  entry $tab_sel.mol1.f.ids.list -width 5 -textvariable [namespace current]::mol1_f_list
  frame $tab_sel.mol1.f.skip
  label $tab_sel.mol1.f.skip.l -text "Skip:"
  entry $tab_sel.mol1.f.skip.e -width 3 -textvariable [namespace current]::skip1

  pack $tab_sel.mol1.f -side left -anchor n -expand yes -fill x
  pack $tab_sel.mol1.f.all $tab_sel.mol1.f.top -side top -anchor w 
  pack $tab_sel.mol1.f.ids -side top -anchor w -expand yes -fill x
  pack $tab_sel.mol1.f.skip -side top -anchor w -padx 20
  pack $tab_sel.mol1.f.ids.r -side left
  pack $tab_sel.mol1.f.ids.list -side left -expand yes -fill x
  pack $tab_sel.mol1.f.skip.l $tab_sel.mol1.f.skip.e -side left

  # opt1
  #--
  labelframe $tab_sel.mol1.opt -relief ridge -bd 2 -text "Modifiers"
  radiobutton $tab_sel.mol1.opt.no -text "All atoms" -variable [namespace current]::selmod1 -value "no"
  radiobutton $tab_sel.mol1.opt.bb -text "Backbone"  -variable [namespace current]::selmod1 -value "bb"
  radiobutton $tab_sel.mol1.opt.tr -text "Trace"     -variable [namespace current]::selmod1 -value "tr"
  radiobutton $tab_sel.mol1.opt.sc -text "Sidechain" -variable [namespace current]::selmod1 -value "sc"
  pack $tab_sel.mol1.opt -side right
  pack $tab_sel.mol1.opt.no $tab_sel.mol1.opt.bb $tab_sel.mol1.opt.tr $tab_sel.mol1.opt.sc -side top -anchor w

  # Same selections
  #--
  checkbutton $tab_sel.same -text "Same selections" -variable [namespace current]::samemols -command [namespace current]::UpdateTabSel
  pack $tab_sel.same -side top

  # SET2
  #--
  labelframe $tab_sel.mol2 -relief ridge -bd 4 -text "Set 2"
  pack $tab_sel.mol2 -side top -anchor n -expand yes -fill x

  # atom2
  #--
  labelframe $tab_sel.mol2.a -relief ridge -bd 2 -text "Atom selection"
  text $tab_sel.mol2.a.sel -exportselection yes -height 5 -width 25 -wrap word
  $tab_sel.mol2.a.sel insert end "all"
  pack $tab_sel.mol2.a -side top -expand yes -fill x
  pack $tab_sel.mol2.a.sel -side left -expand yes -fill x

  # mol2
  #--
  labelframe $tab_sel.mol2.m -relief ridge -bd 2 -text "Molecules"
  radiobutton $tab_sel.mol2.m.all -text "All"    -variable [namespace current]::mol2_def -value "all"
  radiobutton $tab_sel.mol2.m.top -text "Top"    -variable [namespace current]::mol2_def -value "top"
  radiobutton $tab_sel.mol2.m.act -text "Active" -variable [namespace current]::mol2_def -value "act"
  frame $tab_sel.mol2.m.ids
  radiobutton $tab_sel.mol2.m.ids.r -text "IDs:" -variable [namespace current]::mol2_def -value "id"
  entry $tab_sel.mol2.m.ids.list -width 10 -textvariable [namespace current]::mol2_m_list

  pack $tab_sel.mol2.m -side left
  pack $tab_sel.mol2.m.all $tab_sel.mol2.m.top $tab_sel.mol2.m.act $tab_sel.mol2.m.ids -side top -anchor w 
  pack $tab_sel.mol2.m.ids.r $tab_sel.mol2.m.ids.list -side left
  
  # frame2
  #--
  labelframe $tab_sel.mol2.f -relief ridge -bd 2 -text "Frames"
  radiobutton $tab_sel.mol2.f.all -text "All"     -variable [namespace current]::frame2_def -value "all"
  radiobutton $tab_sel.mol2.f.top -text "Current" -variable [namespace current]::frame2_def -value "cur"
  frame $tab_sel.mol2.f.ids
  radiobutton $tab_sel.mol2.f.ids.r -text "IDs:"  -variable [namespace current]::frame2_def -value "id"
  entry $tab_sel.mol2.f.ids.list -width 5 -textvariable [namespace current]::mol2_f_list
  frame $tab_sel.mol2.f.skip
  label $tab_sel.mol2.f.skip.l -text "Skip:"
  entry $tab_sel.mol2.f.skip.e -width 3 -textvariable [namespace current]::skip2

  pack $tab_sel.mol2.f -side left -anchor n -expand yes -fill x
  pack $tab_sel.mol2.f.all $tab_sel.mol2.f.top -side top -anchor w 
  pack $tab_sel.mol2.f.ids -side top -anchor w -expand yes -fill x
  pack $tab_sel.mol2.f.skip -side top -anchor w -padx 20
  pack $tab_sel.mol2.f.ids.r -side left
  pack $tab_sel.mol2.f.ids.list -side left -expand yes -fill x
  pack $tab_sel.mol2.f.skip.l $tab_sel.mol2.f.skip.e -side left

  # opt2
  #--
  labelframe $tab_sel.mol2.opt -relief ridge -bd 2 -text "Modifiers"
  radiobutton $tab_sel.mol2.opt.no -text "All atoms" -variable [namespace current]::selmod1 -value "no"
  radiobutton $tab_sel.mol2.opt.bb -text "Backbone"  -variable [namespace current]::selmod1 -value "bb"
  radiobutton $tab_sel.mol2.opt.tr -text "Trace"     -variable [namespace current]::selmod1 -value "tr"
  radiobutton $tab_sel.mol2.opt.sc -text "Sidechain" -variable [namespace current]::selmod1 -value "sc"
  pack $tab_sel.mol2.opt -side right
  pack $tab_sel.mol2.opt.no $tab_sel.mol2.opt.bb $tab_sel.mol2.opt.tr $tab_sel.mol2.opt.sc -side top -anchor w

  # Calculation Tab
  #--
  variable tab_calc [buttonbar::add $w.tabs calc]
  buttonbar::name $w.tabs calc "Calculation"

  button $tab_calc.new -text "New object" -command "[namespace current]::CreateObject"
  pack $tab_calc.new -side top

  # type
  # --
  labelframe $tab_calc.type -relief ridge -bd 2 -text "Type"
  pack $tab_calc.type -side top -anchor nw -expand yes -fill x

  grid columnconfigure $tab_calc.type 2 -weight 1
  set row 1
  foreach mytype {rmsd covar dist contacts hbonds} desc {"Root mean square deviation" "Covariance" "Distance" "Number of contacts" "Number of hydrogen bonds"} {
    radiobutton $tab_calc.type.${mytype}_n -text $mytype -variable [namespace current]::calctype -value $mytype -command [namespace current]::UpdateTabCalc
    label $tab_calc.type.${mytype}_d -text $desc
    grid $tab_calc.type.${mytype}_n -row $row -column 1 -sticky nw
    grid $tab_calc.type.${mytype}_d -row $row -column 2 -sticky nw
    incr row
  }
  set mytype "labels"
  set desc  "VMD labels: distance, angles, dihedrals"
  radiobutton $tab_calc.type.${mytype}_n -text $mytype -variable [namespace current]::calctype -value $mytype -command "[namespace current]::UpdateTabCalc; [namespace current]::UpdateLabels"
  label $tab_calc.type.${mytype}_d -text $desc
  grid $tab_calc.type.${mytype}_n -row $row -column 1 -sticky nw
  grid $tab_calc.type.${mytype}_d -row $row -column 2 -sticky nw

  # options
  #--
  labelframe $tab_calc.opt -relief ridge -bd 2 -text "Options"
  pack $tab_calc.opt -side top -anchor nw -expand yes -fill x

  checkbutton $tab_calc.opt.diagonal -text "Only diagonal" -variable [namespace current]::diagonal
  pack $tab_calc.opt.diagonal -side top -anchor nw

  checkbutton $tab_calc.opt.align -text "align" -variable [namespace current]::align
  pack $tab_calc.opt.align -side top -anchor nw

  checkbutton $tab_calc.opt.byres -text "byres" -variable [namespace current]::byres
  pack $tab_calc.opt.byres -side top -anchor nw

  frame $tab_calc.opt.norm
  pack $tab_calc.opt.norm -side top -anchor nw
  
  label $tab_calc.opt.norm.l -text "Normalization:"
  pack $tab_calc.opt.norm.l -side left
  foreach entry [list none exp expmin minmax] {
    radiobutton $tab_calc.opt.norm.$entry -text $entry -variable [namespace current]::normalize -value $entry
    pack $tab_calc.opt.norm.$entry -side left
  }

  frame $tab_calc.opt.cutoff
  pack $tab_calc.opt.cutoff -side top -anchor nw
  label $tab_calc.opt.cutoff.l -text "Cutoff:"
  entry $tab_calc.opt.cutoff.v -width 5 -textvariable [namespace current]::cutoff
  pack $tab_calc.opt.cutoff.l $tab_calc.opt.cutoff.v -side left

  frame $tab_calc.opt.angle
  pack $tab_calc.opt.angle -side top -anchor nw
  label $tab_calc.opt.angle.l -text "Angle:"
  entry $tab_calc.opt.angle.v -width 5 -textvariable [namespace current]::angle
  pack $tab_calc.opt.angle.l $tab_calc.opt.angle.v -side left
  
  frame $tab_calc.opt.labs
  pack $tab_calc.opt.labs -side top -anchor nw
  label $tab_calc.opt.labs.l -text "Labels:"
  pack $tab_calc.opt.labs.l -side left
  foreach entry [list Bonds Angles Dihedrals] {
    radiobutton $tab_calc.opt.labs.[string tolower $entry] -text $entry -variable [namespace current]::label_type -value $entry -command "[namespace current]::UpdateLabels"
    pack $tab_calc.opt.labs.[string tolower $entry] -side left
  }
  menubutton $tab_calc.opt.labs.id -text "Id" -menu $tab_calc.opt.labs.id.m -relief raised
  menu $tab_calc.opt.labs.id.m
  pack $tab_calc.opt.labs.id -side left


  # Results tab
  #--
  buttonbar::add $w.tabs res
  buttonbar::name $w.tabs res "Results"


  # Finalize
  buttonbar::showframe $w.tabs calc
  update idletasks
  # needed? or updatelabels is enough?
  [namespace current]::UpdateTabCalc
}


proc itrajcomp::UpdateLabels {} {
  # Update list of available labels and reset their status
  # Each label has the format: 'num_label (atom_label, atom_label,...)'
  #    * num_label is the label number
  #    * atom_label is $mol-$resname$resid-$name
  variable tab_calc
  variable label_type

  # TODO: why hold two variables with the same info?
  variable labels_status_array
  variable labels_status

  set labels [label list $label_type]
  set n [llength $labels]
  $tab_calc.opt.labs.id.m delete 0 end
  # TODO: don't reset their status (try to keep them when swithing between label types in the gui)
  array unset labels_status_array
  if {$n > 0} {
    $tab_calc.opt.labs.id config -state normal
    set nat [expr [llength [lindex $labels 0]] -2]
    for {set i 0} {$i < $n} {incr i} {
      set label "$i ("
      for {set j 0} {$j < $nat} {incr j} {
	set mol   [lindex [lindex [lindex $labels $i] $j] 0]
	set index [lindex [lindex [lindex $labels $i] $j] 1]
	set at    [atomselect $mol "index $index"]
	set resname [$at get resname]
	set resid   [$at get resid]
	set name    [$at get name]
	append label "$mol-$resname$resid-$name"
	if {$j < [expr $nat-1]} {
	  append label ", "
	}
      }
      append label ")"
      $tab_calc.opt.labs.id.m add checkbutton -label $label -variable [namespace current]::labels_status_array($i) -command "[namespace current]::UpdateLabelStatus $i"
    }
  }

  if {[info exists labels_status]} {
    unset labels_status
  }
  foreach x [array names labels_status_array ] {
    lappend labels_status $labels_status_array($x)
  }
}


proc itrajcomp::UpdateLabelStatus {i} {
  # Update status of a label
  variable labels_status_array
  variable labels_status
  
  set labels_status [lreplace $labels_status $i $i $labels_status_array($i)]
}


proc itrajcomp::UpdateTabSel {} {
  # Refresh the tab for selections
  # Switch Selection 2 on/off
  variable samemols
  variable tab_sel
   
  set state "normal"
  if {$samemols} {
    set state "disable"
  }

  foreach widget [[namespace current]::wlist $tab_sel.mol2] {
    if {[winfo class $widget] eq "Frame" || [winfo class $widget] eq "Labelframe" } {
      continue
    }
    $widget config -state $state
  }
}


proc itrajcomp::UpdateTabCalc {} {
  # Refresh the tab for calculations
  variable tab_calc
  variable calctype
  variable samemols
   
  $tab_calc.opt.align config -state disable
  $tab_calc.opt.byres config -state disable
  foreach widget [winfo children $tab_calc.opt.norm] {$widget config -state disable}
  foreach widget [winfo children $tab_calc.opt.cutoff] {$widget config -state disable}
  foreach widget [winfo children $tab_calc.opt.angle] {$widget config -state disable}
  foreach widget [winfo children $tab_calc.opt.labs] {$widget config -state disable}

  switch $calctype {
    rmsd {
      $tab_calc.opt.align config -state normal
    }
    dist -
    covar {
      set samemols 1
      [namespace current]::UpdateTabSel
      $tab_calc.opt.byres config -state normal
      foreach widget [winfo children $tab_calc.opt.norm] {$widget config -state normal}
    }
    contacts {
      foreach widget [winfo children $tab_calc.opt.cutoff] {$widget config -state normal}
    }
    hbonds {
      foreach widget [winfo children $tab_calc.opt.cutoff] {$widget config -state normal}
      foreach widget [winfo children $tab_calc.opt.angle] {$widget config -state normal}
    }
    labels {
      foreach widget [winfo children $tab_calc.opt.labs] {$widget config -state normal}
    }
  }
}


proc itrajcomp::help_about { {parent .itrajcomp} } {
  # Help window
  set vn [package present itrajcomp]
  tk_messageBox -title "iTrajComp v$vn - About"  -parent $parent -message \
    "iTrajComp v$vn

Copyright (C) Luis Gracia <lug2002@med.cornell.edu> 

"
}


proc itrajcomp::ProgressBar {num max} {
  # Progress bar
  variable w
  variable options

  set wp $w.status.info
  set height [winfo height $wp]

  if {$num == 0} {
    set x 0
    set height 0
    $wp coords progress 0 0 $x $height
    $wp lower progress
    update idletasks
  }

  if {!$options(progress)} return

  if {$max == 0} {
    set x 0
  } else {
    set width [winfo width $wp]
    set x [expr ($num * $width / double($max))]
  }
  $wp coords progress 0 0 $x $height
  $wp lower progress
  update idletasks
}


proc itrajcomp::Status {txt} {
  # Status bar
  variable w
  $w.status.info itemconfigure txt -text $txt
  update idletasks

}


proc itrajcomp::ClearStatus {} {
  # TODO: this is not use anywhere
  after 1000 "[namespace current]::Status {}"
  after 1000 "[namespace current]::ProgressBar 1 0"
}


proc itrajcomp::CreateObject {} {
  # Initialize an object
  # TODO: move to object?

  variable w
  variable tab_sel

  variable mol1_def
  variable frame1_def
  variable mol1_m_list
  variable mol1_f_list
  variable skip1
  variable selmod1

  variable mol2_def
  variable frame2_def
  variable mol2_m_list
  variable mol2_f_list
  variable skip2
  variable selmod2

  variable samemols

  variable calctype
  variable diagonal
  variable align
  variable cutoff
  variable angle
  variable reltype
  variable byres
  variable normalize
  variable label_type
  variable labels_status

  if {$samemols} {
    set mol2_def $mol1_def
    set frame2_def $frame1_def
    set mol2_m_list $mol1_m_list
    set mol2_f_list $mol1_f_list
    set skip2 $skip1
    set selmod2 $selmod1
    $tab_sel.mol2.a.sel config -state normal
    $tab_sel.mol2.a.sel delete 1.0 end
    $tab_sel.mol2.a.sel insert end [$tab_sel.mol1.a.sel get 1.0 end]
    $tab_sel.mol2.a.sel config -state disable
  }

  # Parse list of molecules
  set mol1 [[namespace current]::ParseMols $mol1_def $mol1_m_list]
  set mol2 [[namespace current]::ParseMols $mol2_def $mol2_m_list]

  # Parse frames
  set frame1 [[namespace current]::ParseFrames $frame1_def $mol1 $skip1 $mol1_f_list]
  set frame2 [[namespace current]::ParseFrames $frame2_def $mol2 $skip2 $mol2_f_list]

  #puts "$mol1 $frame1 $mol2 $frame2 $selmod"
  set sel1 [ParseSel [$tab_sel.mol1.a.sel get 1.0 end] $selmod1]
  set sel2 [ParseSel [$tab_sel.mol2.a.sel get 1.0 end] $selmod2]

  set defaults [list\
		mol1 $mol1     mol1_def $mol1_def\
		frame1 $frame1 frame1_def $frame1_def\
		mol2 $mol2     mol2_def $mol2_def\
		frame2 $frame2 frame2_def $frame2_def\
		sel1 $sel1\
		sel2 $sel2\
		rep_sel1 $sel1\
		type $calctype\
		diagonal $diagonal\
	       ]

  # TODO: if there are no labels, prevent to execute with calctype=labels
  switch $calctype {
    rmsd {
      lappend defaults align $align
    }
    relrms {
      lappend defaults cutoff $cutoff
      lappend defaults reltype $reltype
    }
    dist -
    covar {
      lappend defaults byres $byres normalize $normalize
    }
    contacts {
      lappend defaults cutoff $cutoff
    }
    hbonds {
      lappend defaults cutoff $cutoff angle $angle
    }
    labels {
      lappend defaults label_type $label_type labels_status $labels_status
    }
  }

  set r [eval [namespace current]::Objnew ":auto" $defaults]

#  [namespace current]::Objdump $r
  [namespace current]::Status "Calculating $calctype ..."
  set err [[namespace current]::$calctype $r]
  if {$err} {
    [namespace current]::Objdelete $r
    return 1
  }
  [namespace current]::Status "Creating graph for $r ..."
  [namespace current]::NewPlot $r
#  [namespace current]::ClearStatus
}

# Source rest of files
source [file join $env(ITRAJCOMPDIR) rmsd.tcl]
source [file join $env(ITRAJCOMPDIR) utils.tcl]
source [file join $env(ITRAJCOMPDIR) object.tcl]
source [file join $env(ITRAJCOMPDIR) save.tcl]
source [file join $env(ITRAJCOMPDIR) load.tcl]
source [file join $env(ITRAJCOMPDIR) combine.tcl]
source [file join $env(ITRAJCOMPDIR) contacts.tcl]
source [file join $env(ITRAJCOMPDIR) hbonds.tcl]
source [file join $env(ITRAJCOMPDIR) gui.tcl]
source [file join $env(ITRAJCOMPDIR) labels.tcl]
source [file join $env(ITRAJCOMPDIR) covar.tcl]
source [file join $env(ITRAJCOMPDIR) dist.tcl]
source [file join $env(ITRAJCOMPDIR) buttonbar.tcl]
#source [file join $env(ITRAJCOMPDIR) clustering.tcl]
