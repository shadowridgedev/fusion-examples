All working examples from Grant Ingersoll's Data Engineering with Solr and Spark talk.

Requirements
==============

1. Postman: https://www.getpostman.com/ (use the packaged app, not the Chrome extension)
1. A Twitter account with developer API keys: https://dev.twitter.com/


Requirements if using Fusion
==============

You will need:

1. Fusion 2.2.0: http://lucidworks.com/fusion/download/ 


Requirements if using Solr and Spark
==============

1. Solr 5.4.0
1. Spark 1.5
1. Spark-Solr library http://github.com/lucidworks/spark-solr


Getting Started
==============

1. Start Fusion: $FUSION_HOME/bin/fusion start
1. Load the postman/datascience_webinar.json.postman_collection file into Postman
1. Setup your Postman environment with the following values
   1. host: The name/IP where you are running Fusion
   1. Your twitter credentials as: twitter_consumer_key, twitter_consumer_secret, twitter_token_secret, twitter_access_token.  See https://docs.lucidworks.com/display/fusion/Twitter+Search+Connector+and+Datasource+Configuration for more details.
1. Execute the items in the Setup folder: Create collection, etc.
1. Give the collection a few minutes to populate with data values


Aggregations
==============

The Aggregations folder ships with various examples of running aggregations on the raw Twitter data that was indexed.  See https://docs.lucidworks.com/display/fusion/Aggregations and https://docs.lucidworks.com/display/fusion/Aggregator+Functions for more details on what each of these do.

To execute any one of the aggregations, first POST the definition of the aggregation to Fusion and then POST the run command to the Jobs API.  For instance, POST the "Lang Cardinality" defintion for determining the cardinality of the lang_s field and then run it by executing the "Run Lang Cardinality Aggregations" function.


Spark Shell
================

1. In $FUSION_HOME: bin/spark-shell (Fusion 2.3+ only) or start spark-shell via the instructions on the spark-solr project
1. See src/main/spark-shell/commands.md for details on running spark shell commands