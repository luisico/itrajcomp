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

# Our main namespace
namespace eval itrajcomp {
  namespace export init
  
  global env
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

  # GUI look
  option add *itrajcomp.*borderWidth 1
  option add *itrajcomp.*Button.padY 0
  option add *itrajcomp.*Menubutton.padY 0

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
  pack [buttonbar::create $menubar $win_main.tabcontent] -side top -fill x

  # Frame for molecule/frame selection
  [namespace current]::TabSel $menubar

  # Calculation Tab
  [namespace current]::TabCalc $menubar

  # Results tab
  [namespace current]::TabRes $menubar

  # Update GUI
  #-----------
  buttonbar::showframe $menubar sel
  [namespace current]::TabCalcUpdate
  update idletasks
}

proc itrajcomp::Menubar {w} {
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
  pack $w.help -side left
}

proc itrajcomp::Statusbar {w} {
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


proc itrajcomp::TabSel {w} {
  # Selection tab
  variable samemols 0

  variable tab_sel [buttonbar::add $w sel]
  buttonbar::name $w sel "Selection"
  
  # New object button
  button $tab_sel.new -text "New Calculation" -command "[namespace current]::NewObject"
  pack $tab_sel.new -side top

  # Set 1
  [namespace current]::SelWidget $tab_sel 1

  # Same selections checkbutton
  checkbutton $tab_sel.same -text "Same selections" -variable [namespace current]::samemols -command [namespace current]::SwitchSamemols
  pack $tab_sel.same -side top -pady 1

  # Set 2
  [namespace current]::SelWidget $tab_sel 2
}

proc itrajcomp::SelWidget {w id} {
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


proc itrajcomp::TabCalc {w} {
  # Calculation tab
  variable tab_calc [buttonbar::add $w calc]
  buttonbar::name $w calc "Calculation"

  # New object button
  button $tab_calc.new -text "New" -command "[namespace current]::NewObject"
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
  [namespace current]::AddStandardCalc
  [namespace current]::AddUserCalc
}


proc itrajcomp::TabRes {w} {
  # Results tab
  variable tab_res [buttonbar::add $w res]
  buttonbar::name $w res "Results"

  variable dataframe [frame $tab_res.dataframe -relief ridge -bd 2]
  pack $dataframe -side top -fill both -expand yes

  grid columnconfigure $dataframe 3 -weight 2
  grid columnconfigure $dataframe 4 -weight 2
  grid rowconfigure    $dataframe 1 -weight 1

  label $dataframe.header_id    -text "Id"         -width 2  -relief sunken
  label $dataframe.header_state -text "S"          -width 1  -relief sunken
  label $dataframe.header_type  -text "Type"       -width 10 -relief sunken
  label $dataframe.header_opts  -text "Options"    -width 20 -relief sunken
  label $dataframe.header_sel   -text "Selections" -width 20 -relief sunken
  grid $dataframe.header_id    -column 0 -row 0
  grid $dataframe.header_state -column 1 -row 0
  grid $dataframe.header_type  -column 2 -row 0 -sticky we
  grid $dataframe.header_opts  -column 3 -row 0 -sticky we
  grid $dataframe.header_sel   -column 4 -row 0 -sticky we

  variable datalist
  set datalist(id)    [listbox $dataframe.body_id    -width 2  -height 10 -relief sunken -exportselection 0 -yscrollcommand [namespace current]::dataframe_yset -selectmode extended]
  set datalist(state) [listbox $dataframe.body_state -width 1  -height 10 -relief sunken -exportselection 0 -yscrollcommand [namespace current]::dataframe_yset -selectmode extended]
  set datalist(type)  [listbox $dataframe.body_type  -width 10 -height 10 -relief sunken -exportselection 0 -yscrollcommand [namespace current]::dataframe_yset -selectmode extended]
  set datalist(opts)  [listbox $dataframe.body_opts  -width 20 -height 10 -relief sunken -exportselection 0 -yscrollcommand [namespace current]::dataframe_yset -selectmode extended]
  set datalist(sel)   [listbox $dataframe.body_sel   -width 20 -height 10 -relief sunken -exportselection 0 -yscrollcommand [namespace current]::dataframe_yset -selectmode extended]
  grid $dataframe.body_id    -column 0 -row 1 -sticky ns
  grid $dataframe.body_state -column 1 -row 1 -sticky ns
  grid $dataframe.body_type  -column 2 -row 1 -sticky nswe
  grid $dataframe.body_opts  -column 3 -row 1 -sticky nswe
  grid $dataframe.body_sel   -column 4 -row 1 -sticky nswe

  bind $dataframe.body_state <Double-Button-1> "[namespace current]::dataframe_mapper %W"

  foreach key [array names datalist] {
    bind $dataframe.body_$key <<ListboxSelect>> "[namespace current]::dataframe_sel %W"
  }


  # Scrollbar
  scrollbar $dataframe.scrbar -orient vert -command [namespace current]::dataframe_yview
  grid $dataframe.scrbar -column 5 -row 0 -rowspan 3 -sticky ns

  [namespace current]::UpdateRes
}


proc itrajcomp::UpdateRes {} {
  variable datalist
  variable dataframe

  # Empty table
  foreach v [array names datalist] {
    $datalist($v) delete 0 end
  }

  # Fill table in order
  foreach obj [[namespace current]::Objlist] {
    set name [namespace tail $obj]
    set num [string trim $name {itc}]
    set objects($num) $name
  }

  foreach num [lsort -integer [array names objects]] {
    # TODO: check wm exists, maybe in the previous foreach
    set name $objects($num)
    set window ".${name}_main"
    $datalist(id) insert end "$num"
    case [wm state $window] {
      iconic {
        set state .
      }
      normal {
        set state S
      }
      withdrawn {
        set state -
      }
      default {
        set state ?
      }
    }
    $datalist(state) insert end $state
    $datalist(type) insert end [set ${name}::opts(type)]
    $datalist(opts) insert end [[namespace current]::concat_opts $name]
    $datalist(sel) insert end "([set ${name}::sets(mol1_def)], [set ${name}::sets(frame1_def)]), ([set ${name}::sets(mol2_def)], [set ${name}::sets(frame2_def)])"
  }

  [namespace current]::dataframe_color

}


proc itrajcomp::AddCalc {type {description ""} {script ""} {help ""}} {
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

  # Default options
  variable calc_${type}_opts
  array set calc_${type}_opts {
    force_samemols 0
  }
  
  # Options
  if {[llength [info procs "calc_${type}_options"]]} {
    variable calc_${type}_frame [frame $tab_calc.opt.$type]
    pack $tab_calc.opt.$type -side top -anchor nw
    [namespace current]::calc_${type}_options
    [namespace current]::TabCalcUpdate
  }
}


proc itrajcomp::DelCalc {type} {
  variable tab_calc
  
  grid forget $tab_calc.type.${type}_n $tab_calc.type.${type}_d
  pack forget $tab_calc.opt.$type
  destroy $tab_calc.type.${type}_n $tab_calc.type.${type}_d $tab_calc.opt.$type

}


proc itrajcomp::TabCalcUpdate {} {
  # Refresh the tab for calculations
  variable tab_calc
  variable calctype
  
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

  # Turn on samemols if requested
  variable calc_${calctype}_opts
  if {[set "calc_${calctype}_opts(force_samemols)"]} {
    [namespace current]::Samemols on
  }

  # Some user specifics
  if {[llength [info procs "calc_${calctype}_options_update"]]} {
    [namespace current]::calc_${calctype}_options_update
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


proc itrajcomp::Samemols {status} {
  # Turn Selection 2 on/off
  variable samemols
  variable tab_sel
  variable win_main
  variable calctype
  variable calc_${calctype}_opts

  set old_status $samemols
  if {$status == off} {
    if {[set "calc_${calctype}_opts(force_samemols)"]} {
      set samemols 1
      set vn [package present itrajcomp]
      tk_messageBox -title "Error" -parent .itrajcomp -message "The current calculation type ($calctype) requires same selections"
      return
    }
    set state "normal"
    set samemols 0
  } else {
    set state "disable"
    set samemols 1
  }

  foreach widget [[namespace current]::wlist $tab_sel.mol2] {
    catch {
      eval $widget config -state $state
    } msg
  }

  # Flash the Selection tab to let the user know samemols changed
  if {$samemols != $old_status} {
    [namespace current]::flash_widget $win_main.menubar.tabs.c.sel
    variable tab_sel
    [namespace current]::highlight_widget $tab_sel.same 5000
  }
}


proc itrajcomp::ProgressBar {num max} {
  # TODO: reset bar after sometime when a task has finished
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
    set x [expr {($num * $width / double($max))}]
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


proc itrajcomp::NewObject {} {
  # Initialize an object
  # TODO: move to object?

  variable calctype
  
  # update GUI in to check compatibility of options
  [namespace current]::TabCalcUpdate

  # Create new object
  set obj [eval [namespace current]::Objnew ":auto"]

  # Pass sel options
  set temp [[namespace current]::SelOptions]
  if {$temp == -1} {
    return -code return
  } else {
    array set ${obj}::sets $temp
  }

  # Pass calc options
  variable calc_${calctype}_opts
  array set ${obj}::opts [array get calc_${calctype}_opts]

  # Pass datatypes
  variable calc_${calctype}_datatype
  array set datatype [array get calc_${calctype}_datatype]
  if {![info exists datatype(mode)]} {
    set datatype(mode) "single"
  }
  switch $datatype(mode) {
    single {
      set datatype(sets) [list $calctype]
    }
    multiple {
      set datatype(sets) [list avg std min max]
    }
    dual {
      if {[info exists datatype(ascii)] && $datatype(ascii) == 1} {
        set datatype(sets) [list $calctype]
      } else {
        set datatype(sets) [list $calctype avg std min max]
      }
    }
  }
  array set ${obj}::datatype [array get datatype]
  
  variable diagonal
  set ${obj}::opts(type) $calctype
  set ${obj}::opts(diagonal) $diagonal

  # Pass graph options
  variable calc_${calctype}_graph
  # defaults
  array set graph_opts {
    type ""
    formats "f" format_key ""
    format_data "" format_scale ""
    rep_style1 NewRibbons
    rep_color1 Molecule
    rep_colorid1 0
    connect lines
  }
  array set graph_opts [array get calc_${calctype}_graph]
  array set ${obj}::graph_opts [array get graph_opts]

  # Do the calculation
  [namespace current]::Status "Calculating $calctype ..."
  if [catch { [namespace current]::calc_$calctype $obj } msg] {
    [namespace current]::Objdelete $obj
    return 1
  }

  # Create the new graph
  [namespace current]::Status "Creating graph for $obj ..."
  [namespace current]::itcObjGui $obj
  
  # Update results table
  [namespace current]::UpdateRes
}


proc itrajcomp::SelOptions {} {
  # Parse all options to create a new object

  # Selection options
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
  set mol_all [[namespace current]::CombineMols $mol1 $mol2]
  if {$mol1 == -1 || $mol2 == -1} {
    return -1
  }

  # Parse frames
  set frame1 [[namespace current]::ParseFrames $frame1_def $mol1 $skip1 $mol1_f_list]
  if {$frame1 == -1} {
    return -1
  }
  set frame2 [[namespace current]::ParseFrames $frame2_def $mol2 $skip2 $mol2_f_list]
  if {$frame2 == -1} {
    return -1
  }

  #puts "$mol1 $frame1 $mol2 $frame2 $selmod"
  set sel1 [ParseSel [$tab_sel.mol1.a.sel get 1.0 end] $selmod1]
  set sel2 [ParseSel [$tab_sel.mol2.a.sel get 1.0 end] $selmod2]

  return [list\
            mol1 $mol1       mol1_def $mol1_def\
            frame1 $frame1   frame1_def $frame1_def\
            mol2 $mol2       mol2_def $mol2_def\
            frame2 $frame2   frame2_def $frame2_def\
            sel1 $sel1\
            sel2 $sel2\
            rep_sel1 $sel1\
            mol_all $mol_all\
            samemols $samemols
         ]
}


proc itrajcomp::help_about {{parent .itrajcomp}} {
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
source [file join $env(ITRAJCOMPDIR) frames.tcl]
source [file join $env(ITRAJCOMPDIR) segments.tcl]
source [file join $env(ITRAJCOMPDIR) graphics.tcl]
source [file join $env(ITRAJCOMPDIR) balloons.tcl]
#source [file join $env(ITRAJCOMPDIR) clustering.tcl]
