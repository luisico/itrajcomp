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

# graphics.tcl
#    Graphics functions.


proc itrajcomp::draw_line {{mol top} point1 point2 color} {
  lassign [$point1 get {x y z}] point1_coord
  lassign [$point2 get {x y z}] point2_coord
  return [graphics $mol line $point1_coord $point2_coord]
}


proc itrajcomp::draw_cone {{mol top} base tip color {radius .3}} {
  lassign [$base get {x y z}] point1_coord
  lassign [$tip get {x y z}]  point2_coord
  return [graphics $mol cone $point2_coord $point1_coord radius $radius]
}


proc itrajcomp::set_color {{mol top} {color ""}} {
  if {$color == ""} {
    return
  }
  graphics $mol color $color
}