# fedcloud-gui 
This is a text based GUI application within a collection of bash scripts aiming to manage the EGI FedCloud CLI commands easily.

## Installation 
Create a folder named for instance 'fedcloud'
Extract the content of this repo inside that directory

To configure the GUI at the moment the user requires to edit files

`occi_endpoints` - The file contains space separated couples such as \<endpoint-short name\> \<endpoint URL\>
`occi_vomses`    - This file contains space separated couples such as \<VO short name\> \<VO real name\>

## GUI usage
Once configured to start the GUI just cd the 'fedcloud-gui' directory and type: `./efc-gui` or source it typing: `. ./efc-gui`
The first call does not setup directly the environment variable once exiting from the GUI; at the end a text message will show the necessary environment to setup in order to select values managed by the GUI. The second call loads all environment variables automatically after exiting from the GUI.

The GUI does not provide yet all rOCCI capabilities; the `efc_*` command line could be necessary to complete your work. Actions like create a new virtual appliance are still not available at all, but following commands could help:

```bash
OCCI_RES=$(occi -e $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --voms $VOMS --action create --resource compute --mixin os_tpl#$(echo $OS_TPL | awk -F"#" '{ print $2 }') --mixin resource_tpl#$(echo $RES_TPL | awk -F"#" '{ print $2 }') --attribute occi.core.title="futuregateway" --context user_data="file://$HOME/userdata.txt"); echo "Resource: $OCCI_RES"
OCCI_PNET=$(occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --voms $VOMS --action link --resource $OCCI_RES --link /network/public); echo "Public IP: $OCCI_PNET"
``` 
The first command creates the resource while the second assigns a public IP if necessary. 

## The command line
The GUI make use of set of comman line tools wrapping several occi commands. These tools can be used by sourcing the file: `. ./fedcloudenv.sh`.
It is possible to have a brief view of tools capabilities typing: `efc_help`.

## Attention
The GUI utility makes use of 'dialog' command line
