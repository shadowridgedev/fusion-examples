# import & export scripts

The scripts herein are intended for exporting the files relating to a collection, datasource, or pipeline so that they can be imported into a different Fusion instance. The most common usecase for this would be moving changes from a `dev` environment to `test` or `prod`. 

When running the export scripts you will be prompted to select which data to export, though some data will be exported automatically (schedules associated with a datasource, for instance).

## Known limitations

1. **Server details**: You must edit the scripts to change the server details. They are preconfigured to work with localhost:8764 over HTTP, but have been tested with HTTPS. 
2. **User details**: The import script assumes the username to use when importing is going to be `admin`, whose password the scripts supports setting if the install of fusion is completely fresh.
3. **Files fetched from Solr**: The scripts must be modified if any additional files are required to be fetched from Solr, besides the following: schema.xml solrconfig.xml stopwords.txt synonyms.txt
4. **Datasources and Schedules**: Since datasource configurations often contain environment specific things, like hosts and passwords, an imported datasource will often not work once imported into the new environment. For this reason, though the scheduled job is imported to the new environment, it is not set to "active", and will need to be reactivated manually from the Fusion UI once the datasource configuration has been verified.
5. **JDBC Driver jars**: There is some support for uploading JDBC Driver jars, but there is no support for exporting them. This part of the configuration is easiest done manually for now. 
