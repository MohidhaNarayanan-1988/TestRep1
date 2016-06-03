public with sharing class EDITriggerUtility {
    /**
     * @description Accepts event names, set of Id as parameters and fetches the edi events whose name and id matches with the parameters.
     *
     * @param List of event names.
     * @param Set of Id.
     * @return Map<String,Map<String,List<EDI__Event__c>>>.
     */
	public static Map<String,Map<String,List<EDI__Event__c>>> getExistingEvents(List<String> eventNames,Set<Id> recordIds) {
        Map<String,Map<String,List<EDI__Event__c>>> events = new Map<String,Map<String,List<EDI__Event__c>>>();
        for (EDI__Event__c event:[SELECT Id,Name,CreatedDate,EDI__Event_Name__c,EDI__Object_ID__c,EDI__Consumed__c,
                                  EDI__Skipped__c,EDI__Exception__c FROM EDI__Event__c 
                                  WHERE EDI__Event_Name__c IN :eventNames 
                                  AND EDI__Object_ID_EX__c IN :recordIds
                                  AND EDI__Event_Name__c != null 
                                  AND EDI__Object_ID__c != null
                                  AND EDI__Object_ID_EX__c != null]) {
            if (!events.containsKey(event.EDI__Event_Name__c))
                events.put(event.EDI__Event_Name__c,new Map<String,List<EDI__Event__c>>());
            if (!events.get(event.EDI__Event_Name__c).containsKey(event.EDI__Object_ID__c))
                events.get(event.EDI__Event_Name__c).put(event.EDI__Object_ID__c,new List<EDI__Event__c>());
            events.get(event.EDI__Event_Name__c).get(event.EDI__Object_ID__c).add(event);
        }
        return events;
    }
    /**
     * @description Method used to fetch Edi documents whose event name matches with parameter eventnames and gets the data from fields.
     *
     * @param List of event names.
     * @param map which has string and list of Edi document (as key value pair).
     * @param map which has string and set of String (as key value pair).
     * @return void.
     */
    public static void setDocumentInfo(List<String> eventNames,Map<String,List<EDI__document__c>> documentMap,Map<String,Set<String>> objectFields) {
        if (documentMap == null) documentMap = new Map<String,List<EDI__Document__c>>();
        if (objectFields == null) objectFields = new Map<String,Set<String>>();
        
        for (EDI__Document__c document:[SELECT Id,Name,EDI__Event_Name__c,EDI__Object_Name__c,EDI__Process__c,EDI__Selection_Field__c,EDI__Trading_Partner__c,EDI__Trading_Partner_Field__c,EDI__Trading_Partner_Type__c,EDI__TP_Entity_Field__c FROM EDI__Document__c WHERE EDI__Event_Name__c IN :eventNames]) {
            if (!documentMap.containsKey(document.EDI__Event_Name__c)) {
                documentMap.put(document.EDI__Event_Name__c,new List<EDI__Document__c>());
            }
            documentMap.get(document.EDI__Event_Name__c).add(document);
            if (!String.isBlank(document.EDI__Object_Name__c) && (!String.isBlank(document.EDI__Trading_Partner_Field__c) || !String.isBlank(document.EDI__Selection_Field__c))) {
                if (!objectFields.containsKey(document.EDI__Object_Name__c))
                    objectFields.put(document.EDI__Object_Name__c,new Set<String>());
                if (!String.isBlank(document.EDI__Trading_Partner_Field__c))
                    objectFields.get(document.EDI__Object_Name__c).add(document.EDI__Trading_Partner_Field__c);
                if (!String.isBlank(document.EDI__Selection_Field__c))
                    objectFields.get(document.EDI__Object_Name__c).add(document.EDI__Selection_Field__c);
            }
        }
        
        for (String eventName:documentMap.keySet()) {
            documentMap.put(eventName,new List<EDI__Document__c>(new Set<EDI__Document__c>(documentMap.get(eventName))));
        }
    }
    /**
     * @description Method used to determine the existance of event in eventList, which matches with the given input event name.
     *
     * @param map which has string and Map of Edi event whose key is String (as key value pair).
     * @param String.
     * @param Id.
     * @return Boolean.
     */
    public static Boolean eventExists(Map<String,Map<String,List<EDI__Event__c>>> eventList,String eventName,Id objectId) {
        if (eventList == null || eventList.size() == 0 || !eventList.containsKey(eventName) || !eventList.get(eventName).containsKey(objectId))
            return false;
        return true;       
    }
    /**
     * @description Method used create an Edi event and populates event custom fields with data from the parameters.
     *
     * @param sObject.
     * @param document.
     * @return EDI__Event__c.
     */
    public static EDI__Event__c createEDIEvent(sObject record,EDI__Document__c document) {
        String objectType = String.valueOf(record.getSObjectType());
        String lookupField = objectType;
        if (lookupField.indexOf('KNDY4__') != -1)
            lookupField = lookupField.replace('KNDY4__','EDI__'); 
        else if (lookupField.indexOf('EDI__') != -1)
            lookupField = lookupField.replace('EDI__','EDI__Staging_'); 
        EDI__Event__c event = new EDI__Event__c(
            EDI__Document__c = document.Id,
            EDI__Document__r = document,
            EDI__Event_Name__c = document.EDI__Event_Name__c,
            EDI__Object_ID__c = (String)record.get('Id'),
            EDI__Object_Name__c = (String)record.get('Name'),
            EDI__Object_Type__c = objectType,
            EDI__Process__c = document.EDI__Process__c,
            EDI__Type__c = 'EDI'
        );
        event.put(lookupField,record.Id);
        return event;
    }
    /**
     * @description Method used set the trading partners field value in the events using the trading partner entity Id.
     *
     * @param List of EDI Events.
     * @param  map which has string and Set of Id (as key value pair).
     * @return void.
     */
    public static void setTradingPartner(List<EDI__Event__c> events,Map<String,Set<Id>> tpEntityValues) {
        List<EDI__Event__c> newEvents = new List<EDI__Event__c>();
        Map<String,Map<String,List<EDI__Trading_Partner_Entity__c>>> entityMap = new Map<String,Map<String,List<EDI__Trading_Partner_Entity__c>>>();  
        if (tpEntityValues != null && tpEntityValues.size() > 0) {
            String tpEntityQuery = 'SELECT Id,Name,EDI__External_Entity__c,EDI__Trading_Partner__c,EDI__Trading_Partner__r.Name,EDI__Trading_Partner__r.EDI__Sender_ID__c,EDI__Trading_Partner__r.Id,EDI__Trading_Partner__r.EDI__Type__c ';
            for (String tpEntityField:tpEntityValues.keySet())
                tpEntityQuery = tpEntityQuery + ' , ' + tpEntityField + ' ';
            tpEntityQuery += 'FROM EDI__Trading_Partner_Entity__c WHERE ';
            Integer i = 0;
            for (String tpEntityField:tpEntityValues.keySet()) {
                Set<Id> entityValues = tpEntityValues.get(tpEntityField);
                if (entityValues.size() == 0)
                    continue;
                if (i != 0)
                    tpEntityQuery += ' OR ';
                tpEntityQuery = tpEntityQuery + tpEntityField + ' IN ( ';
                Integer j = 0;
                for (Id entityValue:entityValues) {
                    if (j != 0)
                        tpEntityQuery += ' , ';
                    tpEntityQuery += ' \'' + entityValue + '\' ';
                    j++;
                }
                tpEntityQuery += ' ) ';
                i++;
            }
            System.debug('tpEntityQuery '+tpEntityQuery);
            for (EDI__Trading_Partner_Entity__c entity:Database.query(tpEntityQuery)) {
                System.debug('entity '+entity);
                for (String tpEntityField:tpEntityValues.keySet()) {                    
                    if (entity.get(tpEntityField) != null) {
                        if (!entityMap.containsKey(tpEntityField))
                            entityMap.put(tpEntityField,new Map<String,List<EDI__Trading_Partner_Entity__c>>());
                        if (!entityMap.get(tpEntityField).containsKey((String)entity.get(tpEntityField)))
                            entityMap.get(tpEntityField).put((String)entity.get(tpEntityField),new List<EDI__Trading_Partner_Entity__c>());
                        entityMap.get(tpEntityField).get((String)entity.get(tpEntityField)).add(entity);
                    }
                }
            }   
        }
        for (EDI__Event__c event:events) {
            if (event.EDI__Document__r.EDI__Trading_Partner__c != null) {
                event.EDI__Trading_Partner__c = event.EDI__Document__r.EDI__Trading_Partner__c;
                newEvents.add(event);
            } else if (!String.isBlank(event.EDI__Skipped_Detail__c) && !String.isBlank(event.EDI__Document__r.EDI__TP_Entity_Field__c)) {
                if (!entityMap.containsKey(event.EDI__Document__r.EDI__TP_Entity_Field__c) || !entityMap.get(event.EDI__Document__r.EDI__TP_Entity_Field__c).containsKey(event.EDI__Skipped_Detail__c)) 
                    continue;
                Map<Id,EDI__Trading_Partner__c> tpMap = new Map<Id,EDI__Trading_Partner__c>();
                for (EDI__Trading_Partner_Entity__c tpEntity:entityMap.get(event.EDI__Document__r.EDI__TP_Entity_Field__c).get(event.EDI__Skipped_Detail__c))
                    tpMap.put(tpEntity.EDI__Trading_Partner__c,tpEntity.EDI__Trading_Partner__r);
                for (EDI__Trading_Partner__c tp:tpMap.values()) {
                    EDI__Event__c tempEvent = event.clone(false,true,false,false);
                    tempEvent.EDI__Trading_Partner__c = tp.Id;
                    tempEvent.EDI__Trading_Partner__r = tp;
                    newEvents.add(tempEvent);
                }
            }
        }
        events.clear();
        events.addAll(newEvents);
    }
    /**
     * @description Method used to set the tp process field value in the events.
     *
     * @param List of EDI Events.
     * @return void.
     */
    public static void setTPProcess(List<EDI__Event__c> events) {
        List<EDI__Event__c> newEvents = new List<EDI__Event__c>();
        Set<Id> tpIds = new Set<Id>();
        Set<Id> processIds = new Set<Id>();
        for (EDI__Event__c event:events) {
            tpIds.add(event.EDI__Trading_Partner__c);
            processIds.add(event.EDI__Document__r.EDI__Process__c);
        }
        
        Map<String,EDI__TP_Process__c> tpProcessMap = new Map<String,EDI__TP_Process__c>();
        for (EDI__TP_Process__c tpProcess:[SELECT Id,EDI__Trading_Partner__c,EDI__Process__c FROM EDI__TP_Process__c WHERE EDI__Trading_Partner__c IN :tpIds AND EDI__Process__c IN :processIds])
            tpProcessMap.put(''+tpProcess.EDI__Trading_Partner__c+tpProcess.EDI__Process__c,tpProcess);
    
        for (EDI__Event__c event:events) {
            if (event.EDI__Trading_Partner__c != null && event.EDI__Process__c != null) {
                String tpProcessKey = '' + event.EDI__Trading_Partner__c + event.EDI__Process__c;
                if (!tpProcessMap.containsKey(tpProcessKey))
                    continue;
                event.EDI__TP_Process__c = tpProcessMap.get(tpProcessKey).Id;
            }
            event.EDI__Skipped_Detail__c = null;
            newEvents.add(event);
        }
        events.clear();
        events.addAll(newEvents);
    }
}