#****h* itrajcomp/clustering
# NAME
# clustering -- Functions for clustering
#
# AUTHOR
# Luis Gracia
#
# DESCRIPTION
#
# Functions for clustering.
# 
# SEE ALSO
# More documentation can be found in:
# * README.txt
# * itrajcomp.tcl
# * http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp
#
# SEE ALSO
# http://wiki.tcl.tk/16317
#
# COPYRIGHT
# Copyright (C) 2005-2008 by Luis Gracia <lug2002@med.cornell.edu> 
#
#****

#****f* clustering/Cluster
# NAME
# Cluster
# SYNOPSIS
# itrajcomp::Cluster self
# FUNCTION
# Cluster
# PARAMETERS
# * self -- object
# TODO
# Update for new code and activate in itrajcomp.tcl
# SOURCE
proc itrajcomp::Cluster {self} {
  set keys [set ${self}::keys]
  set plot [set ${self}::plot]
  set clustering_graphics [set ${self}::clustering_graphics]
  array set data [array get ${self}::data]
  set mol1 [set ${self}::mol1]
  set frame1 [set ${self}::frame1]
  set r_thres_rel [set ${self}::r_thres_rel]
  set N_crit_rel [set ${self}::N_crit_rel]
  
  puts "Clustering: $clustering_graphics"
  
  if {$clustering_graphics} {
    [namespace current]::MapClear $self
  }

  set nc 0
  foreach i $mol1 {
    foreach j [lindex $frame1 [lsearch -exact $mol1 $i]] {
      set csize($i:$j) 0
      set conf($i:$j) 1
      incr nc
    }
  }
  
  set z 0
  while {$z>=0} {
    puts "iteration $z:"

    ### 2.
    set r_max 0
    foreach key $keys {
      lassign [split $key ,] key1 key2
      if {$conf($key1) == 0 || $conf($key2) == 0} continue
      #if {$key1 eq $key2} continue
      if {$data($key) > $r_max} {
        set r_max $data($key)
      }
    }
    set r_thres [expr {$r_thres_rel * $r_max}]
    
    ### 3.
    foreach key $keys {
      lassign [split $key ,] key1 key2
      if {$conf($key1) == 0 || $conf($key2) == 0} continue
      if {$data($key) <= $r_thres} {
        set csize($key1) [expr {$csize($key1) +1}]
        if {$key1 ne $key2} {
          set csize($key2) [expr {$csize($key2) +1}]
        }
        if {$clustering_graphics} {
          set ${self}::add_rep($key) 1
        }
      }
    }
    set N_max 0
    foreach key [array names csize] {
      if {$conf($key) == 0} continue
      if {$csize($key) > $N_max} {
        set N_max $csize($key)
      }
    }
    set N_crit [expr {$N_crit_rel * $N_max}]
    
    puts [format "\tN_crit_rel:  %4.2f    N_crit:  %5.2f   N_max: %5.2f" $N_crit_rel $N_crit $N_max]
    puts [format "\tr_thres_rel: %4.2f    r_thres: %5.2f   r_max: %5.2f" $r_thres_rel $r_thres $r_max]
    puts "\tNumber confs: $nc"

    ### 4.
    set stop_here 1
    foreach key [array names csize] {
      if {$conf($key) == 0} continue
      if {$csize($key) < $N_crit} {
        set stop_here 0
        incr nc -1
        set conf($key) 0
        if {$clustering_graphics} {
          foreach mykey [array names data $key,*] {
            set ${self}::add_rep($mykey) 0
          }
          foreach mykey [array names data *,$key] {
            set ${self}::add_rep($mykey) 0
          }
        }
      }
    }

    incr z

    if {$stop_here == 1} {
      if {$clustering_graphics} {
        foreach key [array names ${self}::add_rep] {
          if {[set ${self}::add_rep($key)] == 1} {
            if {$data($key) <= $r_thres} {
              $plot itemconfigure $key -outline black
            } else {
              set ${self}::add_rep($key) 0
            }
          }
        }
      }
      puts -nonewline "\t"
      foreach key [array names csize] {
        if {$conf($key) == 0} continue
        puts -nonewline "$key\($csize($key)) "
        if {$clustering_graphics} {
          [namespace current]::AddRep $self $key
        }
      }
      puts ""
      return
    }

    foreach key [array names csize] {
      if {$conf($key) == 0} continue
      set csize($key) 0
    }
    incr z
  }
}
#*****
