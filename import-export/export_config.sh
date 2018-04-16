#!/bin/bash

# Fusion server/auth
PROTOCOL="http"
SERVER="localhost:8764"
echo -n "Fusion username: "
read -e USERNAME
echo -n "Fusion password: "
read -es PASSWORD

echo ""
colresp=`curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/collections/"`
if [ "$colresp" = "{\"code\":\"unauthorized\"}" ]; then
  echo "FATAL: Unable to get collection information. Verify your credientials. Aborting.";
  exit 1;
fi;

IFS=$'\r\n' GLOBIGNORE='*' :; ids=($(curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/collections/" | grep \"id\" | sed -e 's/^.*:.*"\(.*\)",/\1/g' | egrep -v '_signals[[:cntrl:]]*$|_signals_aggr[[:cntrl:]]*$|^system_|_logs[[:cntrl:]]*$|^logs[[:cntrl:]]*$'))
IFS=$'\r\n' sorted=($(sort <<<"${ids[*]}"))

echo "The following collections exist in fusion: ${sorted[@]}"

echo -n "Collections to export (comma separated, blank for none, * for all): "
IFS=', ' read -a COLLECTIONS

if [ "$COLLECTIONS" == "*" ]; then
  COLLECTIONS=(${ids[@]})
fi;

echo 

# Solr config-files
SOLR_FILES="schema.xml solrconfig.xml stopwords.txt synonyms.txt"
IFS=$'\r\n' GLOBIGNORE='*' :; ids=($(curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/connectors/datasources/" | grep "^  \"id\"" | sed -e 's/^.*:.*"\(.*\)",/\1/g'))
IFS=$'\r\n' sorted=($(sort <<<"${ids[*]}"))
echo "The following datasources exist in fusion: ${sorted[@]}"

echo -n "Datasources to export (comma separated, blank for none, * for all): "
IFS=', ' read -a DATASOURCES

if [ "$DATASOURCES" == "*" ]; then
  DATASOURCES=(${ids[@]})
fi;


echo

IFS=$'\r\n' GLOBIGNORE='*' :; ids=($(curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/index-pipelines/" | grep "^  \"id\"" | sed -e 's/^.*:.*"\(.*\)",/\1/g' | egrep -v '^aggr_|^signals_ingest[[:cntrl:]]*$|^system_'))
IFS=$'\r\n' sorted=($(sort <<<"${ids[*]}"))
echo "The following INDEX PIPELINES exist in fusion: ${sorted[@]}"

echo -n "Index pipelines to export (comma separated, blank for none, * for all): "
IFS=', ' read -a INDEX_PIPELINES

if [ "$INDEX_PIPELINES" == "*" ]; then
  INDEX_PIPELINES=(${ids[@]})
fi;

echo

IFS=$'\r\n' GLOBIGNORE='*' :; ids=($(curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/query-pipelines/" | grep "^  \"id\"" | sed -e 's/^.*:.*"\(.*\)",/\1/g' | egrep -v '^system_'))
IFS=$'\r\n' sorted=($(sort <<<"${ids[*]}"))
echo "The following QUERY PIPELINES exist in fusion: ${sorted[@]}"

echo -n "Query pipelines to export (comma separated, blank for none, * for all): "
IFS=', ' read -a QUERY_PIPELINES

if [ "$QUERY_PIPELINES" == "*" ]; then
  QUERY_PIPELINES=(${ids[@]})
fi;

echo

main () {
    for COLLECTION in "${COLLECTIONS[@]}"
    do  
      echo "Geting data for collection '$COLLECTION'"
      COLLECTION_DIR="$DIR/collections"
      if [ ! -d "$COLLECTION_DIR" ]; then
        mkdir "$COLLECTION_DIR"
      fi

      curl -k -su $USERNAME:$PASSWORD $PROTOCOL'://'$SERVER'/api/apollo/collections/'$COLLECTION > "$COLLECTION_DIR/$COLLECTION.json"

      logs=`curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/collections/$COLLECTION/features/searchLogs" | grep enabled | awk '{print $3}'`
      if [ "$logs" == "true" ] 
      then
        echo "$COLLECTION has searchLogs enabled"
        touch "$COLLECTION_DIR/$COLLECTION.searchLogs"
      fi

      signals=`curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/collections/$COLLECTION/features/signals" | grep enabled | awk '{print $3}'`
      if [ "$signals" == "true" ]
      then
        echo "$COLLECTION has signals enabled"
        touch "$COLLECTION_DIR/$COLLECTION.signals"
      fi

      dynamic=`curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/collections/$COLLECTION/features/dynamicSchema" | grep enabled | awk '{print $3}'`
      if [ "$dynamic" == "true" ]
      then
        echo "$COLLECTION has dynamicSchema enabled"
        touch "$COLLECTION_DIR/$COLLECTION.dynamicSchema"
      fi


      # Solr config
      SOLR_DIR="$COLLECTION_DIR/$COLLECTION"
      if [ ! -d "$SOLR_DIR" ]; then
        mkdir "$SOLR_DIR"
      fi
      IFS=' ';
      for sf in $SOLR_FILES; do
        echo -e "Downloading '"$sf"'... "
        curl -k -su $USERNAME:$PASSWORD -H "Accept: text/plain" "$PROTOCOL://$SERVER/api/apollo/collections/$COLLECTION/solr-config/$sf" > "$SOLR_DIR/$sf"

        if [ $? -ne 0 ]; then 
          echo "FATAL: Unable to get collection info for collection '$COLLECTION'. Aborting.";
          exit 1;
        fi;
      done;
    done;

    # Fusion index-pipeline
    INDEX_PIPELINE_DIR="$DIR/index-pipelines";
    for ip in "${INDEX_PIPELINES[@]}"; do
        if [ ! -d "$INDEX_PIPELINE_DIR" ]; then
            mkdir "$INDEX_PIPELINE_DIR"
        fi
        echo -e "Downloading index-pipeline '"$ip"'..."
        curl -k -su $USERNAME:$PASSWORD $PROTOCOL'://'$SERVER'/api/apollo/index-pipelines/'$ip > "$INDEX_PIPELINE_DIR/$ip.json"
    done;

    # Fusion query-pipelines
    QUERY_PIPELINE_DIR="$DIR/query-pipelines";
    for qp in "${QUERY_PIPELINES[@]}"; do
        if [ ! -d "$QUERY_PIPELINE_DIR" ]; then
            mkdir "$QUERY_PIPELINE_DIR"
        fi
        echo -e "Downloading query-pipeline '"$qp"'..."
        curl -k -su $USERNAME:$PASSWORD $PROTOCOL'://'$SERVER'/api/apollo/query-pipelines/'$qp > "$QUERY_PIPELINE_DIR/$qp.json"
    done;
    
    IFS=$'\r\n' GLOBIGNORE='*' :; allschedules=($(curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/scheduler/schedules" | grep id |  sed -e 's/^.*:.*"\(.*\)",/\1/g'))

    # Fusion datasources
    DATASOURCES_DIR="$DIR/datasources";
    for ds in "${DATASOURCES[@]}"; do
        if [ ! -d "$DATASOURCES_DIR" ]; then
            mkdir "$DATASOURCES_DIR"
        fi
        echo -e "Downloading datasource '"$ds"'..."
        curl -k -su $USERNAME:$PASSWORD $PROTOCOL'://'$SERVER'/api/apollo/connectors/datasources/'$ds | sed -e 's/password\"\s*:.*/password" : "",/g' | sed -e 's/credentials\"\s*:.*/credentials" : "",/g'  | sed -e 's/verify_access\"\s*:.*/verify_access" : false,/g' > "$DATASOURCES_DIR/$ds.json"

        schedules=`curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/scheduler/schedules" | grep \"service://connectors/jobs/$ds\" | wc -l`
        SCHEDULES_DIR="$DIR/schedules"
        if [ "$schedules" != "0" ]; then
          if [ ! -d "$SCHEDULES_DIR" ]; then
            mkdir "$SCHEDULES_DIR"
          fi
          echo -e "Downloading schedules for datasource '"$ds"', $schedules discovered..."
          for s in "${allschedules[@]}"; do 
            found=($(curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/scheduler/schedules/$s" | grep \"service://connectors/jobs/$ds\" | wc -l))
            if [ "$found" != "0" ]; then
              curl -k -su $USERNAME:$PASSWORD "$PROTOCOL://$SERVER/api/apollo/scheduler/schedules/$s" | sed -e 's/active\"\s*:.*/active" : false,/g' > "$SCHEDULES_DIR/$s.json"
            fi
          done

        fi
    done;
    echo ""

    echo "Export completed to directory '$DIR'"

    echo ""
    protocols=`grep -R :// $DIR/datasources/ | wc -l`
    if [[ "$protocols" != "0" ]]; then
        echo "Please inspect the following datasources for the new environment prior to importing it"
        grep -R :// $DIR/datasources/
    fi
}

# find the directory containing this script, make a timestamped sub-directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR="$DIR/fusion_config_`date +%s`"
if [ ! -d "$DIR" ]; then
    mkdir "$DIR"
fi
main 2>&1 | tee $DIR/download.out
