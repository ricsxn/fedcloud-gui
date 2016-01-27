# fedcloud-gui 
This is a collection of bash scripts aiming to manage the EGI FedCloud CLI commands through an easy textual GUI.

## Installation 
Create a folder named for instance 'fedcloud'
Extract the content of this repo inside that directory

To configure the GUI at the moment the user requires to edit files

occi\_endpoints - The file contains space separated couples such as \<endpoint-short name\> \<endpoint URL\>
occi\_vomses    - This file contains space separated couples such as \<VO short name\> \<VO real name\>

Once configured to start the GUI just cd the 'fedcloud' dir and type: ./efc-gui

## Attention
The GUI utility makes use of 'dialog' command line
