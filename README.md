# fedcloud-gui 
This is a text based GUI application within a collection of bash scripts aiming to manage the EGI FedCloud CLI commands easily.

## Installation 
Create a folder named for instance 'fedcloud'
Extract the content of this repo inside that directory

To configure the GUI at the moment the user requires to edit files

`occi_endpoints` - The file contains space separated couples such as \<endpoint-short name\> \<endpoint URL\>
`occi_vomses`    - This file contains space separated couples such as \<VO short name\> \<VO real name\>

## Using the GUI
Once configured to start the GUI just cd the 'fedcloud-gui' dir and type: `./efc-gui` or source it typing: . `./efc-gui`

## The command line
The GUI make use of set of comman line tools wrapping several occi commands. These tools can be used by sourcing the file: `. ./fedcloudenv.sh`.
It is possible to have a brief view of tools capabilities typing: `efc_help`.

## Attention
The GUI utility makes use of 'dialog' command line
