#!/bin/bash
#
# fedcloudenv.sh - Script to easily manage EGI FedCloud appliances
#
#set -x
MAXCACHETIME=$((120*60)) # Templates, ResTemplates and Resources use a caching mechanism
export BASEPATH=$PWD
export CAPATH=/etc/grid-security/certificates
export OCCI_ENDPOINTS=$BASEPATH/occi_endpoints
export OCCI_VOMSES=$BASEPATH/occi_vomses
export OCCI_RESOURCES=$BASEPATH/occi_resources
export OCCI_TEMPLATES=$BASEPATH/occi_templates
export OCCI_RESTEMPLATES=$BASEPATH/occi_restemplates
export LAST_OCCI_ENDPOINT=.last_occi_endpoint
export LAST_OCCI_VOMS=.last_occi_voms
export LAST_OS_TPL=.last_os_tpl
export LAST_RES_TPL=.last_res_tpl
export LAST_OCCI_RES=.last_occi_res

efc_list_vomses() {
  cat $OCCI_VOMSES | awk '{ printf("%s\t%s\n",$1,$2); }'
  return 0 
}

efc_use_voms() {
 if [ "$1" != "" ]; then
   VOMS=$(cat $OCCI_VOMSES | grep $1 | head -n 1 | awk '{ print $2 }')
   if [ "$VOMS" != "" ]; then
     export OCCI_VOMS=$VOMS
     echo $OCCI_VOMS > $LAST_OCCI_VOMS
     echo "Selected VOMS is now: $VOMS"
   else
     echo "Could not find VOMS with name: $1"
     return 1
   fi
 else
   echo "Usage: $FUNCNAME <server_name>"
 fi
 return 0
}

efc_list_endpoints() {
  cat $OCCI_ENDPOINTS | awk '{ printf("%s\t%s\n",$1,$2); }'
  return 0
}

efc_add_endpoint() {
 if [ "$1" != "" -a "$2" != "" ]; then
   echo "$1 $2" >> $BASEPATH/occi_endpoints
 else
   echo "Usage: $FUNCNAME <server_name> <occi_endpoint>"
 fi
 return 0 
}

efc_del_endpoint() {
 if [ "$1" != "" ]; then
   TMP=$(mktemp)
   cp $OCCI_ENDPOINTS $TMP
   cat $TMP | grep -v $1 > $OCCI_ENDPOINTS 
   rm -f $TMP 
 else
   echo "Usage: $FUNCNAME <server_name>"
 fi
 return 0
}

efc_use_endpoint() {
 if [ "$1" != "" ]; then
   ENDPOINT=$(cat $OCCI_ENDPOINTS | grep $1 | head -n 1 | awk '{ print $2 }')
   if [ "$ENDPOINT" != "" ]; then
     export OCCI_ENDPOINT=$ENDPOINT
     echo $OCCI_ENDPOINT > $LAST_OCCI_ENDPOINT
     echo "Selected endpoint is now: $ENDPOINT"
   else
     echo "Could not find entry point with name: $1"
     return 1
   fi
 else
   echo "Usage: $FUNCNAME <server_name>"
 fi
 return 0
}

efc_get_voms_timeleft() {
 RES=
 RET=0
 [ ! -f $USER_CRED ] && return 1
 RES=$(voms-proxy-info --all 2>/dev/null | grep timeleft | awk '{ print $3 }' | tail -n 1)
 [ "$RES" = "" ] && RES="00:00:00" && RET=1
 if [ "$1" != "noout" ]; then
   echo "$RES"
 fi
 return $RET
}

efc_get_proxy_timeleft() {
 RES=
 RET=0
 [ ! -f $USER_CRED ] && return 1
 RES=$(voms-proxy-info --all 2>/dev/null | grep timeleft | awk '{ print $3 }' | head -n 1)
 [ "$RES" = "" ] && RES="00:00:00" && RET=1
 if [ "$1" != "noout" ]; then
   echo "$RES"
 fi
 return $RET
}

efc_check_proxy() {
  if [ ! -f $USER_CRED ]; then
    echo "Could not find proxy file at: '"$USER_CRED"'"
    echo "Generating proxy ..."
    voms-proxy-init --voms $OCCI_VOMS --rfc
  fi
}

HMS2SEC() {
  RES=
  HR=$(echo $1 | awk -F':' '{ print $1 }' | awk '{printf("%d",$X)}')
  MN=$(echo $1 | awk -F':' '{ print $2 }' | awk '{printf("%d",$X)}')
  SC=$(echo $1 | awk -F':' '{ print $3 }' | awk '{printf("%d",$X)}')
  RES=$((SC+MN*60+HR*3600))
}

SEC2HMS() {
  RES=
  SEC=$1
  SC=$((SEC%60))
  MN=$(((SEC/60)%60))
  HR=$(((SEC/60/60)%24))
  DY=$(((SEC/60/60/24)%24))
  TS=$(printf "%02d:%02d:%02d" $HR $MN $SC)
  if [ $DY -eq 1 ]; then
    RES="tomorrow at: "$TS
  elif [ $DY -ne 0 ]; then
    RES="next "$((DY-1))" days at: "$TS
  else
    RES="today at: "$TS
  fi
}

efc_voms_info() {
  efc_get_voms_timeleft noout
  VOMS_TL=$RES
  HMS2SEC $VOMS_TL
  VOMS_TL_SEC=$RES
  efc_get_proxy_timeleft noout
  PROXY_TL=$RES
  HMS2SEC $PROXY_TL
  PROXY_TL_SEC=$RES
  NOW=$(date +%H:%M:%S)
  HMS2SEC $NOW
  NOW_SEC=$RES
  VOMS_EXP_SEC=$((NOW_SEC+VOMS_TL_SEC))
  SEC2HMS $VOMS_EXP_SEC
  VOMS_EXP=$RES
  PROXY_EXP_SEC=$((NOW_SEC+PROXY_TL_SEC))
  SEC2HMS $PROXY_EXP_SEC
  PROXY_EXP=$RES
  if [ "$VOMS_EXP" = "" -o "$PROXY_EXP" = "" ]; then
    NEEDPROXY=1 
  elif [ $PROXY_TL_SEC -eq 0 -o $VOMS_TL_SEC -eq 0 ]; then
    NEEDPROXY=1
  else
    NEEDPROXY=0
  fi
}

efc_show_conf() {
  efc_voms_info
  if [ "$OCCI_ENDPOINT" = "" -a -f $LAST_OCCI_ENDPOINT ]; then
    OCCI_ENDPOINT=$(cat $LAST_OCCI_ENDPOINT)
  fi
  if [ "$OCCI_VOMS" = "" -a -f $LAST_OCCI_VOMS ]; then 
    OCCI_VOMS=$(cat $LAST_OCCI_VOMS)
  fi
  if [ "$OS_TPL" = "" -a -f $LAST_OS_TPL ]; then 
    OS_TPL=$(cat $LAST_OS_TPL)
  fi
  if [ "$RES_TPL" = "" -a -f $LAST_RES_TPL ]; then
    RES_TPL=$(cat $LAST_RES_TPL)
  fi
  if [ "$OCCI_RES" = "" -a -f $LAST_OCCI_RES ]; then
    OCCI_RES=$(cat $LAST_OCCI_RES)
  fi 
  echo "Showing current OCCI configuration:"
  echo "OCCI_ENDPOINT: '"$OCCI_ENDPOINT"'"
  if [ "$VOMS_EXP" = "" -o "$PROXY_EXP" = "" ]; then
    echo "OCCI_VOMS    : '"$OCCI_VOMS"'; could not find a valid proxy"
  elif [ $PROXY_TL_SEC -eq 0 -o $VOMS_TL_SEC -eq 0 ]; then
    echo "OCCI_VOMS    : '"$OCCI_VOMS"'; proxy or its voms extensions are expired"
  else
    echo "OCCI_VOMS    : '"$OCCI_VOMS"'"
    echo "             proxy expires '"$PROXY_EXP"', timeleft: '"$PROXY_TL"'"
    echo "             VOMS expires  '"$VOMS_EXP"', timeleft: '"$VOMS_TL"'"
  fi
  echo "USER_CRED    : '"$USER_CRED"'"
  echo "USER_PUBKEY  : '"$USER_PUBKEY"'"
  echo "OS_TPL       : '"$OS_TPL"'"
  echo "RES_TPL      : '"$RES_TPL"'"
  echo "OCCI_RES     : '"$OCCI_RES"'"
}

efc_resources() {
  NOCACHE=0 && [ "$1" != "" -a "$1" = "1" ] && NOCACHE=1
  if [ -f $OCCI_RESOURCES ]; then
    TPL_OCCI_VOMS=$(cat $OCCI_RESOURCES | grep "\#\ " | grep OCCI_VOMS | awk -F"=" '{ print $2 }')
    TPL_OCCI_ENDPOINT=$(cat $OCCI_RESOURCES | grep "\#\ " | grep OCCI_ENDPOINT | awk -F"=" '{ print $2 }')
    TPL_OCCI_CACHE=$(cat $OCCI_RESOURCES | grep "\#\ " | grep OCCI_CACHE | awk -F"=" '{ print $2 }')
  fi
  TIMENOW=$(date +%s)
  CACHEDIFF=$((TIMENOW-TPL_OCCI_CACHE))
  if [ $NOCACHE -eq 0 -a "$OCCI_VOMS" = "$TPL_OCCI_VOMS" -a "$OCCI_ENDPOINT" = "$TPL_OCCI_ENDPOINT" -a $CACHEDIFF -lt $MAXCACHETIME ]; then
    # Reporting directly
    efc_res_list
  else
    if [ -f $OCCI_RESOURCES ]; then
      while read res_record 
      do
        RESNAME=$(echo $res_record | awk '{ print $1 }')
        RESINFO=$(echo $res_record | awk '{ print $2 }')
        rm -f $RESINFO
      done < $OCCI_RESOURCES
      rm -f $OCCI_RESOURCES
    fi
    RESLIST=$(mktemp)
    occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --ca-path $CAPATH --voms --action list --resource compute > $RESLIST
    RES=$?
    if [ $RES -eq 0 -a -s $RESLIST ]; then
      echo "# OCCI_VOMS=$OCCI_VOMS" > $OCCI_RESOURCES
      echo "# OCCI_ENDPOINT=$OCCI_ENDPOINT" >> $OCCI_RESOURCES
      echo "# OCCI_CACHE=$(date +%s)" >> $OCCI_RESOURCES
      # occi CLI does not work inside a
      # 'while read do ... done < $TMPTPL' loop;
      # using for cycle instead    
      for resource in $(cat $RESLIST) 
      do
        RESINFO=$(mktemp)
         if [ ! -z $resource ]; then
          occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --ca-path $CAPATH --voms --action describe --resource $resource > $RESINFO
          echo $resource" "$RESINFO >> $OCCI_RESOURCES
        fi
      done
      rm -f $RESLIST
      # Now reporting ...
      efc_res_list
    else
      echo "Error reading resource list"
    fi
  fi
}

efc_res_list() {
  if [ -f $OCCI_RESOURCES -a -s $OCCI_RESOURCES ]; then
    while read res_record
    do
      RMRK=$(echo $res_record | awk '{ print substr($1,1,1) }')
      if [ "$RMRK" != "#" ]; then
        RESNAME=$(echo $res_record | awk '{ print $1 }')
        RESINFO=$(echo $res_record | awk '{ print $2 }')
        RES_NAME=$(cat $RESINFO | grep "occi.compute.hostname" | awk -F"=" '{ print $2 }' | xargs echo)
        echo $(basename $RESNAME)" \""$RES_NAME"\""
      fi
    done < $OCCI_RESOURCES
  else
    echo "No resources available"
  fi
}

efc_templates() {
  NOCACHE=0 && [ "$1" != "" -a "$1" = "1" ] && NOCACHE=1
  if [ -f OCCI_TEMPLATES ]; then
    TPL_OCCI_VOMS=$(cat $OCCI_TEMPLATES | grep "\#\ " | grep OCCI_VOMS | awk -F"=" '{ print $2 }')
    TPL_OCCI_ENDPOINT=$(cat $OCCI_TEMPLATES | grep "\#\ " | grep OCCI_ENDPOINT | awk -F"=" '{ print $2 }')
    TPL_OCCI_CACHE=$(cat $OCCI_TEMPLATES | grep "\#\ " | grep OCCI_CACHE | awk -F"=" '{ print $2 }')
  fi
  TIMENOW=$(date +%s)
  CACHEDIFF=$((TIMENOW-TPL_OCCI_CACHE))
  if [ $NOCACHE -eq 0 -a "$OCCI_VOMS" = "$TPL_OCCI_VOMS" -a "$OCCI_ENDPOINT" = "$TPL_OCCI_ENDPOINT" -a $CACHEDIFF -lt $MAXCACHETIME ]; then
    # Reporting directly
    efc_tpl_list
  else
    if [ -f $OCCI_TEMPLATES -a -s $OCCI_TEMPLATES ]; then
      while read tpl_record
      do
        TPLNAME=$(echo $tpl_record | awk '{ print $1 }')
        TPLINFO=$(echo $tpl_record | awk '{ print $2 }')
        rm -f $TPLINFO
      done < $OCCI_TEMPLATES
      rm -f $OCCI_TEMPLATES
    fi
    echo "# OCCI_VOMS=$OCCI_VOMS" > $OCCI_TEMPLATES
    echo "# OCCI_ENDPOINT=$OCCI_ENDPOINT" >> $OCCI_TEMPLATES
    echo "# OCCI_CACHE=$(date +%s)" >> $OCCI_TEMPLATES
    TMPTPL=$(mktemp)
    occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --ca-path $CAPATH --voms --action list --resource os_tpl > $TMPTPL
    RES=$?
    if [ $RES -eq 0 -a -s $TMPTPL ]; then
      # occi CLI does not work inside a 
      # 'while read do ... done < $TMPTPL' loop;
      # using for cycle instead
      for tpl_record in $(cat $TMPTPL)
      do
        TPLINFO=$(mktemp)
        occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --ca-path $CAPATH --voms --action describe --resource $tpl_record > $TPLINFO
        echo $tpl_record" "$TPLINFO >> $OCCI_TEMPLATES
      done 
      rm -f $TMPTPL
      # Now reporting ...
      efc_tpl_list
    else
      echo "Unable to get template list"
    fi
  fi
}

efc_tpl_list() {
  if [ -f $OCCI_TEMPLATES -a -s $OCCI_TEMPLATES ]; then
    while read tpl_record
    do
      RMRK=$(echo $tpl_record | awk '{ print substr($1,1,1) }')
      if [ "$RMRK" != "#" ]; then
        TPLADDR=$(echo $tpl_record | awk '{ print $1}' |awk -F"#" '{ print $2 }')
        TPLINFO=$(echo $tpl_record | awk '{ print $2 }')
        TPLNAME=$(cat $TPLINFO | grep title |awk -F"title:" '{ print $2}' | xargs echo)
        echo $TPLADDR" \""$TPLNAME"\""
      fi
    done < $OCCI_TEMPLATES
  else
    echo "No templates available"
  fi
}

efc_restemplates() {
  NOCACHE=0 && [ "$1" != "" -a "$1" = "1" ] && NOCACHE=1
  if [ -f $OCCI_RESTEMPLATES ]; then
    RESTPL_OCCI_VOMS=$(cat $OCCI_RESTEMPLATES | grep "\#\ " | grep OCCI_VOMS | awk -F"=" '{ print $2 }')
    RESTPL_OCCI_ENDPOINT=$(cat $OCCI_RESTEMPLATES | grep "\#\ " | grep OCCI_ENDPOINT | awk -F"=" '{ print $2 }')
    RESTPL_OCCI_CACHE=$(cat $OCCI_RESTEMPLATES | grep "\#\ " | grep OCCI_CACHE | awk -F"=" '{ print $2 }')
  fi
  TIMENOW=$(date +%s)
  CACHEDIFF=$((TIMENOW-RESTPL_OCCI_CACHE))
  if [ $NOCACHE -eq 0 -a "$OCCI_VOMS" = "$RESTPL_OCCI_VOMS" -a "$OCCI_ENDPOINT" = "$RESTPL_OCCI_ENDPOINT" -a $CACHEDIFF -lt $MAXCACHETIME ]; then
    # Reporting directly
    efc_restpl_list
  else
    if [ -f $OCCI_RESTEMPLATES -a -s $OCCI_RESTEMPLATES ]; then
      while read restpl_record
      do
        RESTPLNAME=$(echo $restpl_record | awk '{ print $1 }')
        RESTPLINFO=$(echo $restpl_record | awk '{ print $2 }')
        rm -f $RESTPLINFO
      done < $OCCI_RESTEMPLATES
      rm -f $OCCI_RESTEMPLATES
    fi
    echo "# OCCI_VOMS=$OCCI_VOMS" > $OCCI_RESTEMPLATES
    echo "# OCCI_ENDPOINT=$OCCI_ENDPOINT" >> $OCCI_RESTEMPLATES
    echo "# OCCI_CACHE=$(date +%s)" >> $OCCI_RESTEMPLATES
    RESTMPTPL=$(mktemp)
    occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --ca-path $CAPATH --voms --action list --resource resource_tpl > $RESTMPTPL
    RES=$?
    if [ $RES -eq 0 -a -s $RESTMPTPL ]; then
      # occi CLI does not work inside a
      # 'while read do ... done < $TMPTPL' loop;
      # using for cycle instead
      for restpl_record in $(cat $RESTMPTPL)
      do
        RESTPLINFO=$(mktemp)
        occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --ca-path $CAPATH --voms --action describe --resource $restpl_record > $RESTPLINFO
        echo $restpl_record" "$RESTPLINFO >> $OCCI_RESTEMPLATES
      done
      rm -f $RESTMPTPL
      # Now reporting ...
      efc_restpl_list
    else
      echo "Unable to get resource template list"
    fi
  fi
}

efc_restpl_list() {
  if [ -f $OCCI_RESTEMPLATES -a -s $OCCI_RESTEMPLATES ]; then
    while read restpl_record
    do
      RMRK=$(echo $restpl_record | awk '{ print substr($1,1,1) }')
      if [ "$RMRK" != "#" ]; then
        RESTPLADDR=$(echo $restpl_record | awk '{ print $1}' | awk -F"#" '{ print $2 }')
        RESTPLINFO=$(echo $restpl_record | awk '{ print $2 }')
        RESTPLNAME=$(cat $RESTPLINFO | grep "title:" | awk -F"Flavor: " '{ print $2 }' | xargs echo)
        echo $RESTPLADDR" \""$RESTPLNAME"\""
      fi
    done < $OCCI_RESTEMPLATES
  else
    echo "No resource templates available"
  fi
}

efc_res_del() {
  if [ "$OCCI_RES" != "" ]; then
    echo "Deleting resource: $OCCI_RES"
    occi --endpoint $OCCI_ENDPOINT --action delete --resource $OCCI_RES --auth x509 --user-cred $USER_CRED --voms $VOMS
  else
    echo "Sorry, you must select a resrouce first"
  fi
}

efc_res_select() {
  if [ "$1" != "" ]; then
    SELRES=$(cat $OCCI_RESOURCES | grep $1 | awk '{ print $1 }')
    if [ "$SELRES" != "" ]; then
      OCCI_RES=$SELRES 
      echo $OCCI_RES > $LAST_OCCI_RES
      echo "Selected resource is now: $OCCI_RES"
    else
      echo "Could not find resource: '"$1"'" 
    fi
  else
    echo "Please provide a resource identifier as argument"
  fi
}

efc_res_pip() {
  if [ "$OCCI_RES" != "" ]; then
    echo "Assigning a public IP to resource: $OCCI_RES"
    occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --voms $VOMS --action link --resource $OCCI_RES --link /network/public
  else
    echo "Sorry, you must select a resource first"
  fi
}

efc_res_desc() {
  if [ "$OCCI_RES" != "" -o "$1" != "" ]; then
    if [ "$OCCI_RES" = "" ]; then
      OCCI_RES=$1
    fi
    TPL_OCCI_VOMS=$(cat $OCCI_RESOURCES | grep "\#\ " | grep OCCI_VOMS | awk -F"=" '{ print $2 }')
    TPL_OCCI_ENDPOINT=$(cat $OCCI_RESOURCES | grep "\#\ " | grep OCCI_ENDPOINT | awk -F"=" '{ print $2 }')
    TPL_OCCI_CACHE=$(cat $OCCI_RESOURCES | grep "\#\ " | grep OCCI_CACHE | awk -F"=" '{ print $2 }')
    TIMENOW=$(date +%s)
    CACHEDIFF=$((TIMENOW-TPL_OCCI_CACHE))
    if [ "$OCCI_VOMS" = "$TPL_OCCI_VOMS" -a "$OCCI_ENDPOINT" = "$TPL_OCCI_ENDPOINT" -a $CACHEDIFF -lt $MAXCACHETIME ]; then
      RES=$(cat $OCCI_RESOURCES | grep $OCCI_RES | awk '{ print $1 }')
      INFO=$(cat $OCCI_RESOURCES | grep $OCCI_RES | awk '{ print $2 }')
      cat $INFO
    else
      occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --ca-path $CAPATH --voms --action describe --resource $OCCI_RES
    fi
  else
    echo "You must specify an occi resource or specify it as argument"
  fi
}

efc_ostpl_info() {
   if [ "$OS_TPL" != "" -o "$1" != "" ]; then
    if [ "$OS_TPL" = "" ]; then
      OS_TPL=$1
    fi
    TPL_OCCI_VOMS=$(cat $OCCI_TEMPLATES | grep "\#\ " | grep OCCI_VOMS | awk -F"=" '{ print $2 }')
    TPL_OCCI_ENDPOINT=$(cat $OCCI_TEMPLATES | grep "\#\ " | grep OCCI_ENDPOINT | awk -F"=" '{ print $2 }')
    TPL_OCCI_CACHE=$(cat $OCCI_TEMPLATES | grep "\#\ " | grep OCCI_CACHE | awk -F"=" '{ print $2 }')
    TIMENOW=$(date +%s)
    CACHEDIFF=$((TIMENOW-TPL_OCCI_CACHE))
    if [ "$OCCI_VOMS" = "$TPL_OCCI_VOMS" -a "$OCCI_ENDPOINT" = "$TPL_OCCI_ENDPOINT" -a $CACHEDIFF -lt $MAXCACHETIME ]; then
      TPLRESINFO=$(cat $OCCI_TEMPLATES | grep $OS_TPL | awk '{ print $2 }')
      cat $TPLRESINFO
    else
      occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --ca-path $CAPATH --voms --action describe --resource $OS_TPL
    fi
  else
    echo "You must specify an os template or specify it as argument"
  fi
}

efc_restpl_info() {
   if [ "$RES_TPL" != "" -o "$1" != "" ]; then
    if [ "$RES_TPL" = "" ]; then
      RES_TPL=$1
    fi
    TPL_OCCI_VOMS=$(cat $OCCI_RESTEMPLATES | grep "\#\ " | grep OCCI_VOMS | awk -F"=" '{ print $2 }')
    TPL_OCCI_ENDPOINT=$(cat $OCCI_RESTEMPLATES | grep "\#\ " | grep OCCI_ENDPOINT | awk -F"=" '{ print $2 }')
    TPL_OCCI_CACHE=$(cat $OCCI_RESTEMPLATES | grep "\#\ " | grep OCCI_CACHE | awk -F"=" '{ print $2 }')
    TIMENOW=$(date +%s)
    CACHEDIFF=$((TIMENOW-TPL_OCCI_CACHE))
    if [ "$OCCI_VOMS" = "$TPL_OCCI_VOMS" -a "$OCCI_ENDPOINT" = "$TPL_OCCI_ENDPOINT" -a $CACHEDIFF -lt $MAXCACHETIME ]; then
      TPLRESINFO=$(cat $OCCI_RESTEMPLATES | grep $RES_TPL | awk '{ print $2 }')
      cat $TPLRESINFO
    else
      occi --endpoint $OCCI_ENDPOINT --auth x509 --user-cred $USER_CRED --ca-path $CAPATH --voms --action describe --resource $RES_TPL
    fi
  else
    echo "You must specify an os template or specify it as argument"
  fi
}

efc_help() {
  echo "User calls:"
  echo "  efc_show_conf          Show current configuration"
  echo "  efc_list_vomses        Show available vomses"
  echo "  efc_use_voms           Select a VOMS"
  echo "  efc_list_endpoints     Show available OCCI endpoints"
  echo "  efc_add_endpoint       Add a new OCCI endpoint"
  echo "  efc_del_endpoint       Delete an OCCI endpoint"
  echo "  efc_use_endpoint       Select an endpoint"
  echo "  efc_get_voms_timeleft  Get proxy' VOMS extension timeleft"
  echo "  efc_get_proxy_timeleft Get proxy timeleft"
  echo "  efc_check_proxy        Check proxy"
  echo "  efc_resources          Get the list of current endpoint resources"
  echo "  efc_templates          Get the list of current endpoint templates"
  echo "  efc_restemplates       Get the list of current endpoint resource templates"
  echo "  efc_res_select         Select a given resource"
  echo "  efc_res_desc           Return the description of the given or selected resource"
  echo "  efc_ostpl_info         Return the description of the given or selected os template"
  echo "  efc_restpl_info        Return the description of the given or selected resource template"
  echo "  efc_help               Show this help"
  echo "Internal calls:"
  echo "  efc_voms_info          Calclulate voms expiration (no output)"
  echo "  efc_res_list           Show cached resources"
  echo "  efc_tpl_list           Show cached templates"
  echo "  efc_restpl_list        Show cached resource templates"
}

export OCCI_VOMS=fedcloud.egi.eu  
export USER_CRED=/tmp/x509up_u$(id -u)
export USER_PUBKEY=$(cat $HOME/.ssh/id_rsa.pub)
