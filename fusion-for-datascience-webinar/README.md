All working examples from Grant Ingersoll's Fusion For Data Science Webinar on May 27th, 2015.


Requirements
==============

You will need:

1. Fusion 1.4.0: http://lucidworks.com/fusion/download/
1. Postman: https://www.getpostman.com/ (use the packaged app, not the Chrome extension)
1. A Twitter account with developer API keys: https://dev.twitter.com/


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
