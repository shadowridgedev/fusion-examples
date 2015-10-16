var id = doc.getId();
if (id.indexOf("/commit/") != -1){
	doc.addField("source_type", "commit");
} else if (id.indexOf("/milestones/") != -1){
	doc.addField("source_type", "milestones");
} else if (id.indexOf("/blob/") != -1){
	doc.addField("source_type", "blob");//File?
} else if (id.indexOf("/tree/") != -1){
	doc.addField("source_type", "tree");
} else{
    if (doc.getFirstFieldValue("type_s").equals("User")){
        doc.addField("source_type", "user");
    } else {
    	doc.addField("source_type", "N/A");
    }
}