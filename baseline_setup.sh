#!/bin/bash
#
# baseline setup for efg-gui
#

cat > occi_vomses <<EOF
indigo indigo
fedcloud fedcloud.egi.eu
chinreds vo.chain-reds.eu
EOF

cat > occi_endpoints <<EOF
stack-01 https://stack-server-01.ct.infn.it:8787
stack-02 https://stack-server-02.ct.infn.it:8787
cesnet https://carach5.ics.muni.cz:11443
nebula-01 https://nebula-server-01.ct.infn.it:9000
ceta-grid https://controller.ceta-ciemat.es:8787
recas-ba http://cloud.recas.ba.infn.it:8787/occi
in2p3 https://sbgcloud.in2p3.fr:8787/occi1.1
EOF

