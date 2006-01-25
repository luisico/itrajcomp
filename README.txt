RMSDTT2 short readme

Contact Luis Gracia (lug2002@med.cornell.edu) if you find any troubles.

Installation

1. Decompress the tar file in a directory of your choice (lets say, i.e.,
    ~/vmdplugins).

   mkdir -p ~/vmdplugins
   cd ~/vmdplugins
   tar xvf ~/rmsdtt2-vxx.tar

2. Add the following to your .vmdrc startup file (or create one)
   (for unix the path should be $HOME/.vmdrc, and for windows
   %USERPROFILE%\vmd.rc):
   For VMD 1.8.3 and up (for VMD 1.8.2 and down, please update to 1.8.3 ;-) )

     lappend auto_path [file join $env(HOME) vmdplugins]
     vmd_install_extension rmsdtt2 rmsdtt2_tk_cb "WMC PhysBio/RMSDTT2"

   Note: If you created the .vmdrc file, remember to add menu main on to get
   the main menu back.

3. Start VMD. The RMSDTT2 plugin should be accessible from the
   Extensions menu.


-- 
Luis Gracia, PhD
Department of Physiology & Biophysics
Weill Medical College of Cornell University
1300 York Avenue, Box 75
New York, NY 10021

Tel: (212) 746-6375
Fax: (212) 746-8690
lug2002@med.cornell.edu
