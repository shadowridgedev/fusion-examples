All working examples from Grant Ingersoll's Searching for Better Code talk, first given at Lucene Revolution in Oct. 2015.


Requirements
==============

You will need:

1. Fusion 2.1.0: http://lucidworks.com/fusion/download/
1. Postman: https://www.getpostman.com/ (use the packaged app, not the Chrome extension)
1. A Github account, a JIRA account, a Slack account.


Getting Started
==============

1. Start Fusion: $FUSION_HOME/bin/fusion start
1. Load the postman/Searching%20for%20Better%20code.json.postman_collection file into Postman
1. Setup your Postman environment with the following values
   1. host: The name/IP where you are running Fusion
   1. github_user
   1. github_pass
   1. jira_url
   1. jira_user
   1. jira_pass
   1. slack_token
   1. Search for {{ in the file and add any other attributes I may have missed

Aggregations
==============

The Aggregations folder ships with various examples of running aggregations on the raw Twitter data that was indexed.  See https://docs.lucidworks.com/display/fusion/Aggregations and https://docs.lucidworks.com/display/fusion/Aggregator+Functions for more details on what each of these do.

To execute any one of the aggregations, first POST the definition of the aggregation to Fusion and then POST the run command to the Jobs API.  For instance, POST the "Lang Cardinality" defintion for determining the cardinality of the lang_s field and then run it by executing the "Run Lang Cardinality Aggregations" function.
