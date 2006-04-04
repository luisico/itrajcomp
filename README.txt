
                     iTrajComp v1.0

           interactive Trajectory Comparison

http://physiology.med.cornell.edu/faculty/hweinstein/vmdplugins/itrajcomp

Author
------
Luis Gracia, PhD
Department of Physiology & Biophysics
Weill Medical College of Cornell University
1300 York Avenue, Box 75
New York, NY 10021
lug2002@med.cornell.edu

Description
-----------


Installation
-----------
1. Decompress the tar file in a directory of your choice (lets say, i.e.,
    ~/vmdplugins).

   mkdir -p ~/vmdplugins
   cd ~/vmdplugins
   tar xvf ~/itrajcomp-vxx.tar

2. Add the following to your .vmdrc startup file or create one
   (for unix the path should be $HOME/.vmdrc, and for windows %USERPROFILE%\vmd.rc):
   For VMD 1.8.3 and up (for VMD 1.8.2 and down, please update to last VMD version ;-) )

     lappend auto_path [file join $env(HOME) vmdplugins]
     vmd_install_extension itrajcomp itrajcomp_tk_cb "WMC PhysBio/iTrajComp"

   Note: If you created the .vmdrc file, remember to add menu main on to get the main menu back.

3. Start VMD. The iTrajComp plugin should be accessible from the Extensions menu.

