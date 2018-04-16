

// This is a javascript stage to filter documents based on a security entitlement stored in a database.
// It uses the Fusion JDBC Lookup stage to get info from the DB. The DB results are placed into a
// 'context' object which is then processed into a Solr 'terms' filter query. This is useful when
// document access is managed in a database instead of on the document ACLs themselves.

logger.info("Trimming results using Entitlements stored in JDBC and pulled via Fusion's JDBC Query Lookup Stage");

var SECURITYFIELD = "acct_num"; // Field name in Fusion/Solr (case-sensitive)
var lookup_prefix = "acl"; // as set in the JDBC Lookup Query Stage
var dbFieldName = "acct_num"; // as returned from the SQL Query
var lookup_result_prefix = lookup_prefix + "_" + dbFieldName + "_";
var fq_str = null;

// loop over results, which are in the context object
var i = 1;
var acl = _context.getProperty(lookup_result_prefix + "1");
while (null != acl) {
  // we have a field value to enable access!
  
  if (fq_str == null) {
    // first time through loop
    fq_str = "{!terms f=" + SECURITYFIELD + "}" + acl;
  } else {
    fq_str += "," + acl;
  }
  
  i = i+1;
  acl = _context.getProperty(lookup_result_prefix + i);
}

// fail-safe, deny all docs!
if (fq_str == null) {
  fq_str = "-(*:*)";
}

request.putSingleParam('fq', fq_str);
logger.info("Done trimming - Filter Query is: " + fq_str + " len: " + fq_str.length );
