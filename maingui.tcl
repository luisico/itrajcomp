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
  
  global env
  variable open_format_list [list tab matrix plotmtv plotmtv_binary]
  variable save_format_list [list tab matrix plotmtv plotmtv_binary postscript]

  # TODO: tmpdir not used
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
  return $itrajcomp::win_main
}


proc itrajcomp::init {} {
  # Initialize main window
  variable win_main

  # If already initialized, just turn on
  if { [winfo exists .itrajcomp] } {
    wm deiconify $win_main
    return
  }
  
  # Create the main window
  set win_main [toplevel .itrajcomp]
#  catch {destroy $win_main}
  wm title $win_main "iTrajComp"
  wm iconname $win_main "iTrajComp" 
  wm resizable $win_main 1 0

  # Menu
  #-----
  set menubar [frame $win_main.menubar -relief raised -bd 2]
  pack $menubar -side top -padx 1 -fill x
  [namespace current]::Menubar $menubar

  # Status line
  #------------
  variable statusbar [frame $win_main.status]
  pack $statusbar -side bottom -fill x -expand yes
  [namespace current]::Statusbar $statusbar

  # Tabs
  #-----
  frame $win_main.tabcontent
  pack $win_main.tabcontent -side bottom -padx 1 -fill x
  pack [buttonbar::create $win_main.tabs $win_main.tabcontent] -side top -fill x

  # Frame for molecule/frame selection
 [namespace current]::TabSel $win_main

  # Calculation Tab
  [namespace current]::TabCalc $win_main

  # Results tab
  buttonbar::add $win_main.tabs res
  buttonbar::name $win_main.tabs res "Results"


  # Update GUI
  #-----------
  buttonbar::showframe $win_main.tabs calc
  [namespace current]::TabCalcUpdate
  update idletasks
}

proc itrajcomp::Menubar { w } {
  # Menu bar
  variable open_format_list

  menubutton $w.file -text "File" -underline 0 -menu $w.file.menu
  menu $w.file.menu -tearoff no
  $w.file.menu add cascade -label "Load..." -underline 0 -menu $w.file.menu.load
  menu $w.file.menu.load -tearoff no
  foreach as $open_format_list {
    $w.file.menu.load add command -label $as -command "[namespace current]::loadDataBrowse $as"
  }
  pack $w.file -side left

  menubutton $w.options -text "Options" -underline 0 -menu $w.options.menu
  menu $w.options.menu -tearoff no
  $w.options.menu add checkbutton -label "Progress bar" -variable [namespace current]::options(progress) -command "[namespace current]::ProgressBar 0 0"
  pack $w.options -side left

  menubutton $w.combine -text "Combine" -underline 0 -menu $w.combine.menu
  menu $w.combine.menu -tearoff no
  $w.combine.menu add command -label "Combine" -command "[namespace current]::Combine"
  pack $w.combine -side left

  menubutton $w.help -text "Help" -underline 0 -menu $w.help.menu
  menu $w.help.menu -tearoff no
  $w.help.menu add command -label "About" -command [namespace current]::help_about
  $w.help.menu add command -label "Help..." -command "vmd_open_url http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp/index.html"
  pack $w.help -side right
}

proc itrajcomp::Statusbar { w } {
  # Status bar
  label $w.label -text "Status:"

  canvas $w.info -relief sunken -height 20 -highlightthickness 0
  $w.info xview moveto 0
  $w.info yview moveto 0
  $w.info create rect 0 0 0 0 -tag progress -fill cyan -outline cyan
  $w.info create text 5 4 -tag txt -anchor nw

  pack $w.label -side left
  pack $w.info -side left -fill x -expand yes
}


proc itrajcomp::TabSel { w } {
  # Selection tab
  variable samemols 0

  variable tab_sel [buttonbar::add $w.tabs sel]
  buttonbar::name $w.tabs sel "Selection"
 
  # Set 1
  [namespace current]::SelWidget $tab_sel 1

  # Same selections checkbutton
  checkbutton $tab_sel.same -text "Same selections" -variable [namespace current]::samemols -command [namespace current]::SwitchSamemols
  pack $tab_sel.same -side top

  # Set 2
  [namespace current]::SelWidget $tab_sel 2
}

proc itrajcomp::SelWidget { w id } {
  # Selection widget
  # w is the container
  variable mol${id}_def top
  variable frame${id}_def all
  variable mol${id}_m_list 0
  variable mol${id}_f_list 0
  variable skip${id} 0
  variable selmod${id} "no"
  
  labelframe $w.mol$id -relief ridge -bd 4 -text "Set $id"
  pack $w.mol$id -side top -anchor nw -expand yes -fill x

  # Atom selection
  labelframe $w.mol$id.a -relief ridge -bd 2 -text "Atom selection"
  text $w.mol$id.a.sel -exportselection yes -height 5 -width 25 -wrap word
  $w.mol$id.a.sel insert end "all"
  pack $w.mol$id.a -side top -expand yes -fill x
  pack $w.mol$id.a.sel -side left -expand yes -fill x

  # Molecules
  labelframe $w.mol$id.m -relief ridge -bd 2 -text "Molecules"
  radiobutton $w.mol$id.m.all -text "All"    -variable [namespace current]::mol${id}_def -value "all"
  radiobutton $w.mol$id.m.top -text "Top"    -variable [namespace current]::mol${id}_def -value "top"
  radiobutton $w.mol$id.m.act -text "Active" -variable [namespace current]::mol${id}_def -value "act"
  frame $w.mol$id.m.ids
  radiobutton $w.mol$id.m.ids.r -text "IDs:" -variable [namespace current]::mol${id}_def -value "id"
  entry $w.mol$id.m.ids.list -width 10 -textvariable [namespace current]::mol${id}_m_list

  pack $w.mol$id.m -side left
  pack $w.mol$id.m.all $w.mol$id.m.top $w.mol$id.m.act $w.mol$id.m.ids -side top -anchor w 
  pack $w.mol$id.m.ids.r $w.mol$id.m.ids.list -side left
  
  # Frames
  labelframe $w.mol$id.f -relief ridge -bd 2 -text "Frames"
  radiobutton $w.mol$id.f.all -text "All"     -variable [namespace current]::frame${id}_def -value "all"
  radiobutton $w.mol$id.f.top -text "Current" -variable [namespace current]::frame${id}_def -value "cur"
  frame $w.mol$id.f.ids
  radiobutton $w.mol$id.f.ids.r -text "IDs:"  -variable [namespace current]::frame${id}_def -value "id"
  entry $w.mol$id.f.ids.list -width 5 -textvariable [namespace current]::mol${id}_f_list
  frame $w.mol$id.f.skip
  label $w.mol$id.f.skip.l -text "Skip:"
  entry $w.mol$id.f.skip.e -width 3 -textvariable [namespace current]::skip${id}

  pack $w.mol$id.f -side left -anchor n -expand yes -fill x
  pack $w.mol$id.f.all $w.mol$id.f.top -side top -anchor w 
  pack $w.mol$id.f.ids -side top -anchor w -expand yes -fill x
  pack $w.mol$id.f.skip -side top -anchor w -padx 20
  pack $w.mol$id.f.ids.r -side left
  pack $w.mol$id.f.ids.list -side left -expand yes -fill x
  pack $w.mol$id.f.skip.l $w.mol$id.f.skip.e -side left

  # Modifiers
  labelframe $w.mol$id.opt -relief ridge -bd 2 -text "Modifiers"
  radiobutton $w.mol$id.opt.no -text "All atoms" -variable [namespace current]::selmod${id} -value "no"
  radiobutton $w.mol$id.opt.bb -text "Backbone"  -variable [namespace current]::selmod${id} -value "bb"
  radiobutton $w.mol$id.opt.tr -text "Trace"     -variable [namespace current]::selmod${id} -value "tr"
  radiobutton $w.mol$id.opt.sc -text "Sidechain" -variable [namespace current]::selmod${id} -value "sc"
  pack $w.mol$id.opt -side right
  pack $w.mol$id.opt.no $w.mol$id.opt.bb $w.mol$id.opt.tr $w.mol$id.opt.sc -side top -anchor w
}


proc itrajcomp::TabCalc { w } {
  # Calculation tab
  variable tab_calc [buttonbar::add $w.tabs calc]
  buttonbar::name $w.tabs calc "Calculation"

  button $tab_calc.new -text "New object" -command "[namespace current]::CreateObject"
  pack $tab_calc.new -side top

  # Type frame
  labelframe $tab_calc.type -relief ridge -bd 2 -text "Type"
  pack $tab_calc.type -side top -anchor nw -expand yes -fill x
  grid columnconfigure $tab_calc.type 2 -weight 1

  # Options frame
  labelframe $tab_calc.opt -relief ridge -bd 2 -text "Options"
  pack $tab_calc.opt -side top -anchor nw -expand yes -fill x

  # General Options
  variable diagonal 0
  frame $tab_calc.opt.general
  pack $tab_calc.opt.general -side top -anchor nw
  
  checkbutton $tab_calc.opt.general.diagonal -text "Only diagonal" -variable [namespace current]::diagonal
  pack $tab_calc.opt.general.diagonal -side top -anchor nw

  # Add calc types
  [namespace current]::calc_standard
  [namespace current]::calc_user
}


proc itrajcomp::AddCalc { type {description ""} {script ""} {help ""} } {
  variable tab_calc
  variable calc_id

  if {[info exists calc_id]} {
    incr calc_id
  } else {
    set calc_id 1
  }

  # Source script
  if {$script != ""} {
    uplevel [info level] source $script
  }

  # Type
  radiobutton $tab_calc.type.${type}_n -text $type -variable [namespace current]::calctype -value $type -command [namespace current]::TabCalcUpdate
  label $tab_calc.type.${type}_d -text $description
  grid $tab_calc.type.${type}_n -row $calc_id -column 1 -sticky nw
  grid $tab_calc.type.${type}_d -row $calc_id -column 2 -sticky nw

  # Options
  if {[llength [info procs "${type}_options"]]} {
    variable ${type}_options [frame $tab_calc.opt.$type]
    pack $tab_calc.opt.$type -side top -anchor nw
    [namespace current]::${type}_options
  }
}


proc itrajcomp::TabCalcUpdate {} {
  # Refresh the tab for calculations
  variable tab_calc
  variable calctype
  variable samemols
  
  foreach opt [winfo children $tab_calc.opt] {
    if {[winfo name $opt] == "general"} {
      continue
    }
    if {[winfo name $opt] != $calctype} {
      pack forget $opt
    } else {
      pack $opt -side top -anchor nw
    }
  }

  # Some user specifics
  if {[llength [info procs "${calctype}_options_update"]]} {
    [namespace current]::${calctype}_options_update
  }
}


proc itrajcomp::ConfigChildren { w {option -state} {value normal} } {
  # Switch display of a widget and its children

  foreach widget [winfo children $w] {
    catch {
      eval $widget config $option $value
    } msg
    #puts "$widget -> [winfo class $widget] $option $value : $msg"
    [namespace current]::ConfigChildren $widget $option $value
  }
}


proc itrajcomp::SwitchSamemols {} {
  # Switch selection 2
  variable samemols
  
  set status "off"
  if {$samemols} {
    set status "on"
  }
  [namespace current]::Samemols $status
}

proc itrajcomp::Samemols { status } {
  # Turn Selection 2 on/off
  variable samemols
  variable tab_sel
  variable win_main

  set old_status $samemols
  if {$status == off} {
    set state "normal"
    set samemols 0
  } else {
    set state "disable"
    set samemols 1
  }

  [namespace current]::ConfigChildren $tab_sel.mol2 -state $state

  # Flass the Selection tab to let the user know samemols changed
  if {$samemols != $old_status} {
    $win_main.tabs.middle.c.f.sel flash
  }
}


proc itrajcomp::ProgressBar {num max} {
  # Progress bar
  variable statusbar
  variable options

  set wp $statusbar.info
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
  variable statusbar
  $statusbar.info itemconfigure txt -text $txt
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

  # Pass selection options
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
		rep_sel1 $sel1
		]

  # TODO: if there are no labels, prevent to execute with calctype=labels
  # Pass calculation options
  variable calctype
  variable diagonal
  variable ${calctype}_vars
  lappend defaults type $calctype diagonal $diagonal

  foreach var [set ${calctype}_vars] {
    variable $var
    lappend defaults $var [set $var]
  }
  lappend defaults vars [set ${calctype}_vars]

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

proc itrajcomp::help_about { {parent .itrajcomp} } {
  # Help window
  set vn [package present itrajcomp]
  tk_messageBox -title "iTrajComp v$vn - About" -parent $parent -message \
    "iTrajComp v$vn

Copyright (C) Luis Gracia <lug2002@med.cornell.edu> 

"
}


# Source rest of files
source [file join $env(ITRAJCOMPDIR) utils.tcl]
source [file join $env(ITRAJCOMPDIR) object.tcl]
source [file join $env(ITRAJCOMPDIR) gui.tcl]
source [file join $env(ITRAJCOMPDIR) save.tcl]
source [file join $env(ITRAJCOMPDIR) load.tcl]
source [file join $env(ITRAJCOMPDIR) combine.tcl]
source [file join $env(ITRAJCOMPDIR) standard.tcl]
source [file join $env(ITRAJCOMPDIR) user.tcl]
source [file join $env(ITRAJCOMPDIR) buttonbar.tcl]
#source [file join $env(ITRAJCOMPDIR) clustering.tcl]
