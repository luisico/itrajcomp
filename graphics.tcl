#****h* itrajcomp/graphics
# NAME
# graphics -- Graphics functions
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
#
# Graphics functions.
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

#****f* graphics/draw_line
# NAME
# draw_line
# SYNOPSIS
# itrajcomp::draw_line mol point1 point2
# FUNCTION
# Draws a line between two points
# PARAMETERS
# * mol -- molecule to store the graphics object
# * point1 -- selection representing the first point (must be a single atom).
# * point2 -- selection representing the second point (must be a single atom).
# RETURN VALUE
# Graphics object id
# SOURCE
proc itrajcomp::draw_line {{mol top} point1 point2} {
  lassign [$point1 get {x y z}] point1_coord
  lassign [$point2 get {x y z}] point2_coord
  return [graphics $mol line $point1_coord $point2_coord]
}
#*****


#****f* graphics/draw_cone
# NAME
# draw_cone
# SYNOPSIS
# itrajcomp::draw_cone mol base tip radius
# FUNCTION
# Draws a cone between two points
# PARAMETERS
# * mol -- molecule to store the graphics object
# * base -- selection representing the base of the cone (must be a single atom).
# * tip -- selection representing the tip of the cone (must be a single atom).
# * radius -- radius of the base
# RETURN VALUE
# Graphics object id
# SOURCE
proc itrajcomp::draw_cone {{mol top} base tip {radius .3}} {
  lassign [$base get {x y z}] point1_coord
  lassign [$tip get {x y z}]  point2_coord
  return [graphics $mol cone $point2_coord $point1_coord radius $radius]
}
#*****


#****f* graphics/set_color
# NAME
# set_color
# SYNOPSIS
# itrajcomp::set_color mol color
# FUNCTION
# Change the colorr of next graphics objects
# PARAMETERS
# * mol -- molecule to store the graphics object
# * color -- color 
# SOURCE
proc itrajcomp::set_color {{mol top} {color ""}} {
  if {$color == ""} {
    return
  }
  graphics $mol color $color
}
#*****
