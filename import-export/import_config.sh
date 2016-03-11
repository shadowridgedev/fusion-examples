#!/bin/bash

# Fusion server/auth
PROTOCOL="http"
SERVER="localhost:8764"
USERNAME="admin"

TIMESTAMP=`date +%s`

FRESH_INSTALL=`curl -k -s $PROTOCOL://$SERVER/api | grep \"initMeta\":null | wc -l`

if [ $FRESH_INSTALL -ne 0 ]
then
  # create initial Fusion account
  PWDSET=0
  while [ $PWDSET -eq 0 ]; do
    echo -n "Set Fusion Admin password: "
    read -es PASSWORD
    echo " "
    echo -n "Confirm Fusion Admin password: "
    read -es PASSWORD2
    echo " "
    if [ "$PASSWORD" = "$PASSWORD2" ]; then
      echo "Admin password set"
      PWDSET=1
      CMD="curl -k -s -XPOST '$PROTOCOL://$SERVER/api/' -H 'Content-Type: application/json' -d '{\"password\":\"$PASSWORD\"}'"
      eval $CMD
    else
      echo "Passwords did not match - try again"
    fi
  done
else
  echo -n "Fusion admin password: "
  read -es PASSWORD

  echo
  status=`curl -k -s -o /dev/null -w "%{http_code}" -u $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/collections/"`

  if [ $status -ne "200" ]
  then
    echo "Unable to access fusion with those credentials. Received $status status code";
    exit 1
  fi
fi


upload_collections() {
  if [ -d $1/collections ]; then
    NUM_NODES=`curl -s -k -u $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/solrAdmin/default/admin/collections?action=clusterstatus&wt=json" | sed 's/.*live_nodes":\[\([^\]*\)\].*/\1/' | grep -o "solr" | wc -l`
    for f in $1/collections/*.json
    do
      BASENAME=`basename $f`
      COLLECTIONNAME="${BASENAME%%.*}"
      echo "Uploading config for collection $COLLECTIONNAME"
      sed -i.bak "s/replicationFactor\".*/replicationFactor\": $NUM_NODES/" $f
      status=`curl -k -s -o /dev/null -w "%{http_code}" -u $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/collections/$COLLECTIONNAME"`
      if [ $status -ne "200" ]
      then
        echo "Collection is new, creating it."
        cmd="curl -i -k -su $USERNAME:$PASSWORD -XPOST -H 'Content-type: application/json' $PROTOCOL://$SERVER/api/apollo/collections/ -d@$f"
      else
        echo "Collection already exists, updating config"
        cmd="curl -i -k -su $USERNAME:$PASSWORD -XPUT -H 'Content-type: application/json' $PROTOCOL://$SERVER/api/apollo/collections/$COLLECTIONNAME -d@$f"
      fi

      eval $cmd 1> "$1.output.$TIMESTAMP/collection.$COLLECTIONNAME"

      if [ -f $1/collections/$COLLECTIONNAME.jdbc.jar ]
      then
        cmd_upload="curl -k -su $USERNAME:$PASSWORD -XPOST --form file=@$1/collections/$COLLECTIONNAME.jdbc.jar '$PROTOCOL://$SERVER/api/apollo/connectors/plugins/lucid.jdbc/resources/jdbc?collection=$COLLECTIONNAME'"
        eval $cmd_upload 1> "$1.output.$TIMESTAMPS/collection.$COLLECTIONNAME.jdbc.jar"
      fi

      if [ -f $1/collections/$COLLECTIONNAME.signals ]
      then
        curl -i -k -su $USERNAME:$PASSWORD -X PUT -H Content-type:application/json -d '{"enabled":true}' $PROTOCOL://$SERVER/api/apollo/collections/$COLLECTIONNAME/features/signals 1> "$1.output.$TIMESTAMP/collection.$COLLECTIONNAME.signals"
      fi

      if [ -f $1/collections/$COLLECTIONNAME.dynamicSchema ]
      then
        curl -i -k -su $USERNAME:$PASSWORD -X PUT -H Content-type:application/json -d '{"enabled":true}' $PROTOCOL://$SERVER/api/apollo/collections/$COLLECTIONNAME/features/dynamicSchema > "$1.output.$TIMESTAMP/collection.$COLLECTIONNAME.dynamicSchema"
      fi

      if [ -f $1/collections/$COLLECTIONNAME.searchLogs ]
      then
        curl -i -k -su $USERNAME:$PASSWORD -X PUT -H Content-type:application/json -d '{"enabled":true}' $PROTOCOL://$SERVER/api/apollo/collections/$COLLECTIONNAME/features/searchLogs > "$1.output.$TIMESTAMP/collection.$COLLECTIONNAME.searchLogs"
      fi
    done
  else
    echo "No collections found"
  fi
}

upload_solr_config() {
  if [ -d $1/collections ]; then
    for f in $1/collections/*.json
    do
      BASENAME=`basename $f`
      COLLECTIONNAME="${BASENAME%%.*}"
      echo "Uploading solr config for collection $COLLECTIONNAME"
      for sf in $1/collections/$COLLECTIONNAME/*
      do
        if [[ "$sf" == *xml ]]
        then
          CONTENTTYPE="application/xml"
        else
          CONTENTTYPE="text/plain"
        fi
        #CONTENTTYPE='application/json'
        FILENAME=`basename $sf`

        status=`curl -k -s -o /dev/null -w "%{http_code}" -u $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/collections/$COLLECTIONNAME/solr-config/$FILENAME"`
        if [ $status -ne "200" ]
        then
          method="POST"
        else
          method="PUT"
        fi

        echo "Uploading $FILENAME for collection $COLLECTIONNAME"
        cmd="curl -i -k -s -u $USERNAME:$PASSWORD -X$method -H 'Content-type: $CONTENTTYPE' '$PROTOCOL://$SERVER/api/apollo/collections/$COLLECTIONNAME/solr-config/$FILENAME?reload=true' --data-binary @$sf"
	eval $cmd 1> "$1.output.$TIMESTAMP/collection.$COLLECTIONNAME.$FILENAME"
      done;
    done;
  fi
}

upload_index_pipelines() {
  if [ -d $1/index-pipelines ]; then
    for f in $1/index-pipelines/*
    do
      BASENAME=`basename $f`
      PIPELINENAME="${BASENAME%%.*}"
      cmd="curl -i -k -s -u $USERNAME:$PASSWORD -XPUT -H 'Content-type: application/json' '$PROTOCOL://$SERVER/api/apollo/index-pipelines/$PIPELINENAME' -d@$f"
      eval $cmd 1> "$1.output.$TIMESTAMP/index-pipeline.$PIPELINENAME"
    done
  else
    echo "No index pipelines found"
  fi
}

upload_query_pipelines() {
  if [ -d $1/query-pipelines ]; then
    for f in $1/query-pipelines/*
    do
      BASENAME=`basename $f`
      PIPELINENAME="${BASENAME%%.*}"
      cmd="curl -i -k -s -u $USERNAME:$PASSWORD -XPUT -H 'Content-type: application/json' '$PROTOCOL://$SERVER/api/apollo/query-pipelines/$PIPELINENAME' -d@$f"
      eval $cmd 1> "$1.output.$TIMESTAMP/query-pipeline.$PIPELINENAME"
    done
  else
    echo "No query pipelines found"
  fi
}

upload_data_sources() {
  if [ -d $1/datasources ]; then
    for f in $1/datasources/*
    do
      BASENAME=`basename $f`
      DSNAME="${BASENAME%%.*}"

      status=`curl -s -o /dev/null -w "%{http_code}" -u $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/connectors/datasources/$DSNAME"`
      if [ $status -ne "200" ]
      then
        cmd="curl -i -k -s -u $USERNAME:$PASSWORD -XPOST -H 'Content-type: application/json' '$PROTOCOL://$SERVER/api/apollo/connectors/datasources' -d@$f"
      else
        cmd="curl -i -k -s -u $USERNAME:$PASSWORD -XPUT -H 'Content-type: application/json' '$PROTOCOL://$SERVER/api/apollo/connectors/datasources/$DSNAME' -d@$f"
      fi
      eval $cmd 1> "$1.output.$TIMESTAMP/datasource.$DSNAME"
    done
  else
    echo "No datasources found"
  fi
}

upload_schedules() {
  if [ -d $1/schedules ]; then
    for f in $1/schedules/*
    do
      BASENAME=`basename $f`
      SNAME="${BASENAME%%.*}"

      status=`curl -k -s -o /dev/null -w "%{http_code}" -u $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/scheduler/schedules/$SNAME"`
      if [ $status -ne "200" ]
      then
        cmd="curl -i -k -s -u $USERNAME:$PASSWORD -XPOST -H 'Content-type: application/json' '$PROTOCOL://$SERVER/api/apollo/scheduler/schedules' -d@$f"
      else
        cmd="curl -i -k -s -u $USERNAME:$PASSWORD -XPUT -H 'Content-type: application/json' '$PROTOCOL://$SERVER/api/apollo/scheduler/schedules/$SNAME' -d@$f"
      fi
      echo "Adding $SNAME"
      eval $cmd 1> "$1.output.$TIMESTAMP/schedule.$SNAME"
    done
  else
    echo "No schedules found"
  fi
}


main() {
  mkdir -p "$1.output.$TIMESTAMP"
  upload_collections $1;
  sleep 10
  upload_solr_config $1;
  upload_index_pipelines $1;
  upload_query_pipelines $1;
  upload_data_sources $1;
  upload_schedules $1;
}

main ${@%/} 2>&1 | tee upload.out
