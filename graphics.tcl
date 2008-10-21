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


proc itrajcomp::draw_line {point1 point2 color} {
  lassign [$point1 get {x y z}] point1_coord
  lassign [$point2 get {x y z}] point2_coord
  graphics top color $color
  return [graphics top line $point1_coord $point2_coord]
}


proc itrajcomp::draw_cone {base tip color {radius .3}} {
  lassign [$base get {x y z}] point1_coord
  lassign [$tip get {x y z}]  point2_coord
  graphics top color $color
  return [graphics top cone $point1_coord $point1_coord radius $radius]
}
