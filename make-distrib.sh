#!/bin/sh

version=$1
echo "Packing version ${version:?}"

plugin=itrajcomp
dir=$plugin
tar=$plugin-v$version.tgz

cd ../

tar zcvf $tar $dir/pkgIndex.tcl $dir/README.txt $dir/maingui.tcl $dir/buttonbar.tcl $dir/utils.tcl $dir/object.tcl $dir/save.tcl $dir/load.tcl $dir/combine.tcl $dir/gui.tcl $dir/standard.tcl $dir/user.tcl $dir/rmsd.tcl $dir/covar.tcl $dir/dist.tcl $dir/contacts.tcl $dir/hbonds.tcl $dir/labels.tcl

mv $tar $dir/versions
chmod go+rX $dir/versions/$tar
cd $dir

