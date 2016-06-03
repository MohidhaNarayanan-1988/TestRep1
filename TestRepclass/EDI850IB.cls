global class EDI850IB implements Database.Batchable<sObject>,Database.Stateful,KNDY4.Process.Runnable {
  
  global Set<Id> orderIds;  
  global List<KNDY4.Notify.Message> errMessages = new List<KNDY4.Notify.Message>();
    global static List<KNDY4.Notify.Message> messages = new List<KNDY4.Notify.Message>();
    private static KNDY4.ExceptionServiceAPI expSrvAPI = new KNDY4.ExceptionServiceAPI();
    private static Map<Id, Id> mp_EdiOrderToIgnore = new Map<Id, Id>();
    private static Map<Id, DerivedValues> mp_DerivedValues = new Map<Id, DerivedValues>(); 
    private static Map<Id, List<EDI__Order_Line__c>> mp_OrderLines = new Map<Id, List<EDI__Order_Line__c>>();
    //private static Id defaultCompanyId;
    private static KNDY4__Company__c defaultCompany = EDIUtility_Static.getDefaultCompany();
    private static Map<Id, Map<String, Task>> mp_OpenTasks = new Map<Id, Map<String, Task>>();
    /**
     * @description parameterized constructor that accepts set of order Id as parameter.
     *
     * @param set of order Id.
     * @return no return type.
     */
    global EDI850IB(Set<Id> orderIds) {
        this.orderIds = orderIds;
    }
     /**
     * @description default constructor that accepts no parameter.
     *
     * @return no return type.
     */
    global EDI850IB() {  }
  /**
     * @description The batch class is invoked by calling Database.executeBatch and passing it the instance of the batch class .It Accepts company Id as parameter and executes the batch.
     *
     * @param company Id.
     * @return void.
     */
    global void runBatch(Id companyId) {
    //defaultCompanyId = companyId;
        EDI__Process__c proc;
        try {
            proc = [SELECT Id,EDI__Batch_Size__c FROM EDI__Process__c WHERE Name = 'RCVORD' LIMIT 1];
        } catch(Exception e) {
            throw new EDI850IBException('Process RCVORD has not been set up');
        }
        if (proc != null && proc.EDI__Batch_Size__c != null) {
            Database.executeBatch(this,(Integer)proc.EDI__Batch_Size__c);
        } else {
            Database.executeBatch(this);
        }
    }
   /**
    * @description This method is called at the beginning of a batch Apex job. It collects the records or objects to be passed to the interface method execute.It Accepts BatchableContext object as parameter and returns the list of EDI orders
    *
    * @param Database.BatchableContext
    * @return List of Edi orders
    */
    global List<EDI__Order__c> start(Database.BatchableContext bc) {
          String query = 'SELECT Id FROM EDI__Order__c ';
        if (orderIds != null && orderIds.size() > 0) {
            query += 'WHERE Id IN :orderIds ';
        } else {
            EDI__Process__c proc;
            try {
                proc = [SELECT Id,EDI__Records_To_Process__c FROM EDI__Process__c WHERE Name = 'RCVORD' LIMIT 1];
            } catch(Exception e) {
                throw new EDI850IBException('Process RCVORD has not been set up');
            }        
            query += 'WHERE EDI__Process_Name__c = \'RCVORD\' AND EDI__Process_Flag__c = \'U\' AND EDI__Exception__c = false AND EDI__Process__r.EDI__Active__c = true And EDI__TP_Process__r.EDI__Active__c = true ';
            query += 'ORDER BY CreatedDate ASC ';
            if (proc != null && proc.EDI__Records_To_Process__c != null) {
                query += 'LIMIT ' + proc.EDI__Records_To_Process__c;
            }
        }
        return (List<EDI__Order__c>)Database.query(query);
    }
  /**
     * @description This method is called for each batch of records. Batches of records tend to execute in the order in which they’re received from the start method. It Accepts BatchableContext object and List of EDI orders as parameters.It will invoke EDI.EDIService.processRecords function.
     *
     * @param Database.BatchableContext.
     * @param List of EDI orders.
     * @return void.
     */ 
     global void execute(Database.BatchableContext bc,List<EDI__Order__c> orders) {
        List<Schema.sObjectField> orderFields = EDI__Order__c.sObjectType.getDescribe().fields.getMap().values();
        String query = 'SELECT ' + orderFields.get(0);
        for (Integer i=1;i<orderFields.size();i++) {
            query += ',' + orderFields.get(i);
        }
        query += ',EDI__Trading_Partner__r.Name,EDI__Trading_Partner__r.EDI__Sender_ID__c,EDI__Process__r.Name';
        query += ' FROM EDI__Order__c'+
                 ' WHERE Id IN :orders FOR UPDATE ';
        try {
            orders = (List<EDI__Order__c>)Database.query(query);
        } catch (Exception e) {
            errMessages.add(new KNDY4.Notify.Message('One or more records in this batch is already being processed',''));
            return;
        }
        for (Integer i=0;i<orders.size();i++) {
            if (orders.get(i).EDI__Process_Flag__c == 'P') {
                orders.remove(i);
                i--;
            }
        }
        if (orders.size() > 0) {
            Savepoint sp = Database.setSavepoint();
            try {                
                List<Task> exceptions = EDI.EDIService.processRecords(orders,'RCVORD');              
                for(Task exTask : exceptions) {
                    if(exTask.Status.equalsIgnoreCase('Closed')) {
                        exTask.Status  = 'Completed';
                    }
                }
                EdiExceptionUtility.upsertExceptions(exceptions);   
                
            } catch (Exception e) {
                errMessages.add(new KNDY4.Notify.Message(e.getMessage(),e.getStackTraceString()));
                Database.rollback(sp);
            }
        }
        errMessages.addAll(messages);
    }
    /**
     * @description This method is used to send confirmation emails or execute post-processing operations. It is called after all batches are processed. Accepts BatchableContext object as parameter.
     *
     * @param Database.BatchableContext.
     * @return void.
     */
    global void finish(Database.BatchableContext bc) {
        if (orderIds == null || orderIds.size() == 0) {
            KNDY4.MasterControlProgram.finishedBatch(this);
        }
        KNDY4.Notify.sendEmailBatchFinish(errMessages.size(), 'EDI Inbound 850 job has completed',errMessages,bc);
    }
    /**
     * @author HiBiZ Solutions
     * @date 02/19/2016
     * @description Validate Class created for validating the inbound EDI order and EDI order lines by Implementing the EDIService.EDIStep.
     */
   global class Validate implements EDI.EDIService.EDIStep {

    List<EDI__Order_Line__c> ediOrderLineList = new List<EDI__Order_Line__c>();
    Map<String, EDI__Trading_Partner_Entity__c> mp_TpEntityShipTo = new Map<String, EDI__Trading_Partner_Entity__c>();
    List<String> upcCodeList = new List<String>();
    List<Id> taskIdList = new List<Id>();
    /**
   * @description Accepts list of EDI orders as parameter and executes by performing validations on EDI order and EDI order lines. It updates List of exceptions. Also fetches valid EDI orders , which passes all the validations.
   *
   * @param List EDI Orders.
   * @return EDI.EDIService.Response.
   */
    global EDI.EDIService.Response execute(List<EDI__Order__c> ediOrderList) {
            EDI.EDIService.Response response = new EDI.EDIService.Response();
            populateMapsAndServices(ediOrderList);
            mp_OpenTasks = EDIUtility_Static.getTasks(taskIdList, 'Open');            
            validateOrderHeaders(ediOrderList);
            if (ediOrderLineList.size() > 0) {
                validateOrderLines(ediOrderLineList);
            }
            response.records = ediOrderList;
            return response;
        }
    /**
         * @description Accepts List of EDI order as parameter and populates the required maps.
         *
         * @param List of EdiOrder.
         * @return void.
         */
        private void populateMapsAndServices(List<EDI__Order__c> ediOrderList) {
            List<Id> orderIds = new List<Id>();
            List<Id> tpProcessIdList = new List<Id>();
            List<String> custEntityList = new List<String>();
            
            for (EDI__Order__c ediOrder : ediOrderList) {
                orderIds.add(ediOrder.Id);
                if (ediOrder.EDI__TP_Process__c != null) {
                    tpProcessIdList.add(ediOrder.EDI__TP_Process__c);
                }
                taskIdList.add(ediOrder.Id);
            }
            queryOrderLines(orderIds);
            Map<Id, EDI__TP_Process__c> mp_Tp_Process = EDIUtility_Static.getTpProcess('Id, Name, (Select Name, EDI__Value_1__c, EDI__Value_2__c, EDI__Value_3__c, EDI__Value_4__c, EDI__Value_5__c From EDI__Parameters__r)', tpProcessIdList);
            for(EDI__Order__c ediOrder : ediOrderList) {
                if (mp_DerivedValues.containsKey(ediOrder.Id) == false) {
                    mp_DerivedValues.put(ediOrder.Id, new DerivedValues());
                }
                EDI__TP_Process__c ediTpProcess = mp_Tp_Process.get(ediOrder.EDI__TP_Process__c);                   
                Map<String, List<String>> parametersMap = EDIUtility_Static.getParameters(ediTpProcess);
                if (parametersMap != null) {
                    mp_DerivedValues.get(ediOrder.Id).mp_Parameter = parametersMap;
                    custEntityList.addAll(collectCustomerEntites(ediOrder, parametersMap));
                    upcCodeList.addAll(collectUpcCodes(ediOrder, parametersMap));
                } else {
                    mp_DerivedValues.get(ediOrder.Id).mp_Parameter = new Map<String, List<String>>();
                }
            }
            if (custEntityList.size() > 0) {
                getTpEntityShipToReference('Id, Name, EDI__Trading_Partner__c, EDI__Ship_To_Customer__c, EDI__Ship_To_Customer__r.KNDY4__Parent_Customer__c, EDI__Ship_To_Customer__r.KNDY4__Parent_Customer__r.KNDY4__Parent_Customer__c,EDI__Ship_To_Customer__r.KNDY4__Top_Parent_Customer__c', custEntityList);
            }
        }
    /**
         * @description Accepts List of EDI order Id as parameter and fetch the EDI order lines.
         *
         * @param List of EdiOrder id.
         * @return void.
         */
        private void queryOrderLines(List<Id> orderIds) {
          List<Schema.sObjectField> orderLineFields = EDI__Order_Line__c.sObjectType.getDescribe().fields.getMap().values();
          String query = 'SELECT ' + orderLineFields.get(0);
          for (Integer i=1;i<orderLineFields.size();i++) {
              query += ',' + orderLineFields.get(i);
          }
          query += ',EDI__Order__r.EDI__TP_Process__c, EDI__Order__r.Name,EDI__Order__r.EDI__Trading_Partner__c,EDI__Order__r.EDI__Trading_Partner__r.Name,';
          query += 'EDI__Order__r.EDI__Process__c,EDI__Order__r.EDI__Process__r.Name,EDI__Order__r.EDI__Document_ID__c';
          query += ' FROM EDI__Order_Line__c WHERE EDI__Order__c IN :orderIds Order By EDI__Line_Number__c';
          for (EDI__Order_Line__c orderLine : Database.query(query)) {
            List<EDI__Order_Line__c> orderLines = new List<EDI__Order_Line__c>();
                if (mp_OrderLines.containsKey(orderLine.EDI__Order__c)) {
                    orderLines = mp_OrderLines.get(orderLine.EDI__Order__c);
                }
                orderLines.add(orderLine);
                mp_OrderLines.put(orderLine.EDI__Order__c, orderLines);
                taskIdList.add(orderLine.Id);
          }
        }
    /**
         * @description Accepts string of columns names and list of trading partner entity names as parameters and fetches the ship to customer.
         *
         * @param string of columns.
         * @param list of trading partner entity names.
         * @return void.
         */
        private void getTpEntityShipToReference(String columns, List<String> tpEntityNameList) {
          String query = 'SELECT ' + columns + ' FROM EDI__Trading_Partner_Entity__c WHERE Name in :tpEntityNameList ';
            for (EDI__Trading_Partner_Entity__c ediTradingPartnerEntity : Database.query(query)) {
                mp_TpEntityShipTo.put(ediTradingPartnerEntity.Name+''+ediTradingPartnerEntity.EDI__Trading_Partner__c, ediTradingPartnerEntity);
            }
        }
    /**
         * @description Accepts EDI order and map which has string and list of string (key - value pair) as parameters .It is used to retrieve the entity which matches the "CUSTOMER" parameter.
         *
         * @param string.
         * @param map which has string and list of string (key - value pair).
         * @return List of String.
         */
        private List<String> collectCustomerEntites(EDI__Order__c ediOrder, Map<String, List<String>> parametersMap) {
            List<String> entityList = new List<String>();
            List<String> valuesList = parametersMap.get('CUSTOMER');
            String custEntity = null;
            for(String value : valuesList) {
                custEntity = getCustEntity(ediOrder, value);
                if (custEntity != null) {
                    break;
                }                    
            }
            if (custEntity == null) {
                // If customer entity is not found then try to look for default qual ST to get customer
                custEntity = getCustEntity(ediOrder, 'ST');
            }
            if (custEntity !=null) {
                entityList.add(custEntity);
            }
            return entityList;
        }
    /**
         * @description Accepts EDI order and map which has string and list of string (key - value pair) as parameters .It is used to retrieve the upc codes which matches the "ERPITEM" parameter.
         *
         * @param string.
         * @param map which has string and list of string (key - value pair).
         * @return List of String.
         */
        private List<String> collectUpcCodes(EDI__Order__c ediOrder, Map<String, List<String>> parametersMap) {
            List<String> upcList = new List<String>();
            if (mp_OrderLines.containsKey(ediOrder.Id) == false) {
                return upcList;
            }
            List<String> valuesList = parametersMap.get('ERPITEM');
            for (EDI__Order_Line__c ediOrderLine : mp_OrderLines.get(ediOrder.Id)) {
                for (String value : valuesList) {
                    String alias = getAliasFromLine(ediOrderLine, value);
                    if (alias == null || alias == '') {
                        continue; // If the qualifier is not found in the line, skip to next qualifier
                    }
                    upcList.add(alias);
                }
            }

            return upcList;
        }
    /**
         * @description Accepts EDI order line and string as parameters .It is used to get the alias value from the EDI order line which matches the ERPITEM qualifier.
         *
         * @param EDI order line.
         * @param String.
         * @return String.
         */
        private String getAliasFromLine(EDI__Order_Line__c ediOrderLine, String qualifier) {
            if (qualifier != null) {
                List<String> qualFields = new List<String>{'EDI__Qualifier1__c','EDI__Qualifier2__c','EDI__Qualifier3__c','EDI__Qualifier4__c','EDI__Qualifier5__c','EDI__Qualifier6__c','EDI__Qualifier7__c','EDI__Qualifier8__c','EDI__Qualifier9__c','EDI__Qualifier10__c'};
                List<String> aliasFields = new List<String>{'EDI__Alias1__c','EDI__Alias2__c','EDI__Alias3__c','EDI__Alias4__c','EDI__Alias5__c','EDI__Alias6__c','EDI__Alias7__c','EDI__Alias8__c','EDI__Alias9__c','EDI__Alias10__c'};
                for (Integer i=0; i<qualFields.size(); i++) {
                    if (ediOrderLine.get(qualFields.get(i)) != null && String.valueOf(ediOrderLine.get(qualFields.get(i))).equalsIgnoreCase(qualifier)) {
                        return ediOrderLine.get(aliasFields.get(i)) != null ? String.valueOf(ediOrderLine.get(aliasFields.get(i))) : null;
                    }
                }
            }
            return null;
        }
    /**
         * @description Accepts EDI order and string of customer qualifier as parameters. It is used to get the entity value from the EDI order header which matches with the CUSTOMER qualifier or else with the default qualifier(ST).
         *
         * @param EDI order.
         * @param String.
         * @return String.
         */
        private String getCustEntity(EDI__Order__c ediOrder, String custQualifier) {
            if (custQualifier != null) {
                List<String> idFields = new List<String>{'EDI__N101_ID1__c','EDI__N101_ID2__c','EDI__N101_ID3__c','EDI__N101_ID4__c','EDI__N101_ID5__c'};
                List<String> entityFields = new List<String>{'EDI__N104_Entity1__c','EDI__N104_Entity2__c','EDI__N104_Entity3__c','EDI__N104_Entity4__c','EDI__N104_Entity5__c'};
                List<String> nameFields = new List<String>{'EDI__N102_Name1__c','EDI__N102_Name2__c','EDI__N102_Name3__c','EDI__N102_Name4__c','EDI__N102_Name5__c'};
                for (Integer i=0; i<idFields.size(); i++) {
                    if (ediOrder.get(idFields.get(i)) != null && String.valueOf(ediOrder.get(idFields.get(i))).equalsIgnoreCase(custQualifier)) {
                        return String.valueOf(ediOrder.get(entityFields.get(i)));
                    }
                }
            }
            return null;
        }
    /**
         * @description Accepts EDI order and string as parameters. It is used to assign the ship to customer field to customerObj in DerivedValues class .
         *
         * @param EDI order.
         * @param String.
         * @return void.
         */
        private void setCustomer(EDI__Order__c ediOrder, String custEntity) {
            if (custEntity == null) {
                return;
            }
            EDI__Trading_Partner_Entity__c tpEntity = null;
            if (mp_TpEntityShipTo.containsKey(custEntity+''+ediOrder.EDI__Trading_Partner__c)) {
                tpEntity = mp_TpEntityShipTo.get(custEntity+''+ediOrder.EDI__Trading_Partner__c);
            }
            if (tpEntity != null && tpEntity.EDI__Ship_To_Customer__c != null) {
                mp_DerivedValues.get(ediOrder.Id).customerObj = tpEntity.EDI__Ship_To_Customer__r;                
            }
        }
    /**
         * @description Accepts list of EDI order as parameter.It is used to validate the EDI order header
         *
         * @param List of EDI order.
         * @return void.
         */
        private void validateOrderHeaders(List<EDI__Order__c> ediOrderList) {
          for (EDI__Order__c ediOrder : ediOrderList) {
                try {
                    if (mp_OrderLines.containsKey(ediOrder.Id)) {
                      ediOrderLineList.addAll(mp_OrderLines.get(ediOrder.Id));
                      if (mp_OpenTasks.containsKey(ediOrder.Id) && mp_OpenTasks.get(ediOrder.Id).containsKey('IB850_001'))
                      {
                        EdiExceptionUtility.clearProcessException(expSrvAPI, ediOrder, 'IB850_001');
                      }
                    } else {
                        EdiExceptionUtility.setProcessException(expSrvAPI, ediOrder, 'IB850_001');
                        mp_EdiOrderToIgnore.put(ediOrder.Id, ediOrder.Id);
                    }
                    // Validate Customer
                    List<String> valuesList = mp_DerivedValues.get(ediOrder.Id).mp_Parameter.get('CUSTOMER');
                    String custEntity = null;
                    for(String value : valuesList) {
                        if (value != null) {
                            custEntity = getCustEntity(ediOrder, value);
                            if (custEntity != null) {
                                break;
                            }
                        }
                    }
                    if (custEntity == null) {
                        // If customer entity is not found then try to look for default qual ST to get customer
                        custEntity = getCustEntity(ediOrder, 'ST');
                    }
                    if (custEntity !=null) {
                        setCustomer(ediOrder, custEntity);
                    }
                    if (mp_DerivedValues.get(ediOrder.Id).customerObj == null) {
                        EdiExceptionUtility.setProcessException(expSrvAPI, ediOrder, 'IB850_002');
                        mp_EdiOrderToIgnore.put(ediOrder.Id, ediOrder.Id);
                    } else {
                        if (mp_OpenTasks.containsKey(ediOrder.Id) && mp_OpenTasks.get(ediOrder.Id).containsKey('IB850_002'))
                        {
                            EdiExceptionUtility.clearProcessException(expSrvAPI, ediOrder, 'IB850_002');
                        }
                    }
                    if (mp_OpenTasks.containsKey(ediOrder.Id) && mp_OpenTasks.get(ediOrder.Id).containsKey('IB850_000'))
                    {
                        EdiExceptionUtility.clearOtherException(expSrvAPI, ediOrder, 'IB850_000', 'Unhandled Exception',  'Unhandled Exception');
                    }
                } catch(Exception e) {
                    System.debug(LoggingLevel.FINEST,e.getMessage() + ' --> ' + e.getStackTraceString());
                    EdiExceptionUtility.setOtherException(expSrvAPI, ediOrder, 'IB850_000', 'Unhandled Exception :' + e.getMessage(), e.getStackTraceString());
                    messages.add(new KNDY4.Notify.Message(e.getMessage(), e.getStackTraceString()));
                }
            }
        }
    /**
         * @description Accepts list of EDI order lines as parameter .It is used to validate the EDI order Lines 
         *
         * @param List of EDI order lines.
         * @return void.
         */
        private void validateOrderLines(List<EDI__Order_Line__c> ediOrderLineList) {
            validateQtyPrice(ediOrderLineList);
            determineErpItem(ediOrderLineList);
            Database.update(ediOrderLineList, false);
        }
    /**
         * @description Accepts list of EDI order lines as parameter .It is used to validate the quantity and original price in EDI order Lines 
         *
         * @param List of EDI order lines.
         * @return void.
         */
        private void validateQtyPrice(List<EDI__Order_Line__c> ediOrderLineList) {
          for (EDI__Order_Line__c ediOrderLine : ediOrderLineList) {
            if (ediOrderLine.EDI__Customer_Quantity__c!= null && ediOrderLine.EDI__Quantity_Ordered__c==null) {
              ediOrderLine.EDI__Quantity_Ordered__c = ediOrderLine.EDI__Customer_Quantity__c;
            }
            if (ediOrderLine.EDI__Quantity_Ordered__c==null||ediOrderLine.EDI__Quantity_Ordered__c<=0) {
              EdiExceptionUtility.setProcessException(expSrvAPI, ediOrderLine, 'IB850_003');
              mp_EdiOrderToIgnore.put(ediOrderLine.EDI__Order__c, ediOrderLine.EDI__Order__c);
            } else {
                    if (mp_OpenTasks.containsKey(ediOrderLine.Id) && mp_OpenTasks.get(ediOrderLine.Id).containsKey('IB850_003'))
                    {
                        EdiExceptionUtility.clearProcessException(expSrvAPI, ediOrderLine, 'IB850_003');
                    }
                }
                if (ediOrderLine.EDI__Customer_Price__c!=null && ediOrderLine.EDI__Original_Price__c==null) {
                  ediOrderLine.EDI__Original_Price__c = ediOrderLine.EDI__Customer_Price__c;
                }
                if (ediOrderLine.EDI__Original_Price__c==null||ediOrderLine.EDI__Original_Price__c<=0) {
                  EdiExceptionUtility.setProcessException(expSrvAPI, ediOrderLine, 'IB850_004');
              mp_EdiOrderToIgnore.put(ediOrderLine.EDI__Order__c, ediOrderLine.EDI__Order__c);
            } else {
                    if (mp_OpenTasks.containsKey(ediOrderLine.Id) && mp_OpenTasks.get(ediOrderLine.Id).containsKey('IB850_004'))
                    {
                        EdiExceptionUtility.clearProcessException(expSrvAPI, ediOrderLine, 'IB850_004');
                    }
                }
          }
        }
    /**
         * @description Accepts list of EDI order lines as parameter .It is used to validate the ERP item using the values in the UPC PRODUCT MAPPING custom table
         *
         * @param List of EDI order lines.
         * @return void.
         */
        private void determineErpItem(List<EDI__Order_Line__c> ediOrderLineList) {
          EDI.CustomTableService upcProductTableService = null;
          Boolean canFilter = false;
          String filters = '"Customer UPC" IN "(';
            for (String upc : upcCodeList) {
                filters += '\'' + upc+ '\'' + ',';
                canFilter = true;
            }
            if (canFilter) {
                filters = filters.substring(0, filters.length()-1);
                filters += ')"';
                upcProductTableService = new EDI.CustomTableService('UPC PRODUCT MAPPING', filters);
            }
            for (EDI__Order_Line__c ediOrderLine : ediOrderLineList) {
                try {
                    List<String> valuesList = mp_DerivedValues.get(ediOrderLine.EDI__Order__c).mp_Parameter.get('ERPITEM');
                    Id tradingPartnerId = ediOrderLine.EDI__Order__r.EDI__Trading_Partner__c;
                    if (valuesList != null) {
                        for (String value : valuesList) {
                            String alias = getAliasFromLine(ediOrderLine, value);
                            if (alias == null) {
                                continue;
                            }
                            if (upcProductTableService.records != null) {
                              for (Map<String, Object> record : upcProductTableService.records) {
                          String rowUpc = (String)record.get('Customer UPC');
                          Id tpId = (String)record.get('Customer');
                          if (rowUpc.equalsIgnoreCase(alias) && tpId == tradingPartnerId) {
                              ediOrderLine.EDI__Product__c = (Id)record.get('Product');
                              break;
                          }
                      }
                            }
                            if (ediOrderLine.EDI__Product__c != null) {
                                break; // Means that if a product is resolved then exit the loop
                            }
                        }
                    }
                    if (ediOrderLine.EDI__Product__c == null) {
                        mp_EdiOrderToIgnore.put(ediOrderLine.EDI__Order__c, ediOrderLine.EDI__Order__c);
                        EdiExceptionUtility.setProcessException(expSrvAPI, ediOrderLine, 'IB850_005');
                    } else {
                        if (mp_OpenTasks.containsKey(ediOrderLine.Id) && mp_OpenTasks.get(ediOrderLine.Id).containsKey('IB850_005'))
                        {
                            EdiExceptionUtility.clearProcessException(expSrvAPI, ediOrderLine, 'IB850_005');
                        }
                    }
                    if (mp_OpenTasks.containsKey(ediOrderLine.Id) && mp_OpenTasks.get(ediOrderLine.Id).containsKey('IB850_000'))
                    {
                        EdiExceptionUtility.clearOtherException(expSrvAPI, ediOrderLine, 'IB850_000', 'Unhandled Exception', 'Unhandled Exception');
                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.FINEST,e.getMessage() + ' --> ' + e.getStackTraceString());
                    EdiExceptionUtility.setOtherException(expSrvAPI, ediOrderLine, 'IB850_000', 'Unhandled Exception:' + e.getMessage(),  e.getStackTraceString());
                    messages.add(new KNDY4.Notify.Message(e.getMessage(), e.getStackTraceString()));
                }
            }
        }
  }
/**
 * @author HiBiZ Solutions
 * @date 02/19/2016
 * @description Class created for extracting sales order and sales order lines from valid EDI order and EDI order lines by Implementing the EDIService.EDIStep.
 */
  global class Post implements EDI.EDIService.EDIStep {

    List<SoSolNotes> lst_SalesOrdersToBeCreated = new List<SoSolNotes>();
  /**
     * @description Accepts List of EDI order as parameter and updates them into ERP system and create new sales order and sales order lines based on the input EDI order and EDI order lines.
     * 
     * @param List of EDI Order.
     * @return EDI.EDIService.Response
     */
    global EDI.EDIService.Response execute(List<EDI__Order__c> ediOrderList) {
            EDI.EDIService.Response response = new EDI.EDIService.Response();
            try {
                for (EDI__Order__c ediOrder : ediOrderList) {
                    if (mp_EdiOrderToIgnore.containsKey(ediOrder.Id)) {
                        continue;
                    }
                    postOrder(ediOrder, mp_OrderLines.get(ediOrder.Id), mp_DerivedValues.get(ediOrder.Id).mp_Parameter);
                }
                Map<Id, KNDY4__Sales_Order__c> soMaps = new Map<Id, KNDY4__Sales_Order__c>();
                Map<Id, KNDY4__Sales_Order__c> soMapsToDelete = new Map<Id, KNDY4__Sales_Order__c>();
                //Map<Id, KNDY4__Sales_Order__c> soMapsToUpdate = new Map<Id, KNDY4__Sales_Order__c>();
                Map<Id, EDI__Order__c> orderMapBySoId = new Map<Id, EDI__Order__c> ();
                if (lst_SalesOrdersToBeCreated.size() > 0) {
                    List<KNDY4__Sales_Order__c> salesOrdersToInsert = new List<KNDY4__Sales_Order__c>();
                    List<KNDY4__Sales_Order_Line__c> salesOrderLinesToInsert = new List<KNDY4__Sales_Order_Line__c>();
                    for (SoSolNotes so : lst_SalesOrdersToBeCreated) {
                        salesOrdersToInsert.add(so.salesOrder);
                    }
                    Integer i = 0;
                    for (Database.SaveResult saveR : Database.insert(salesOrdersToInsert, false)) {
                        SoSolNotes so = lst_SalesOrdersToBeCreated.get(i);
                        if (saveR.isSuccess()) {
                            if (mp_OpenTasks.containsKey(so.refOrder.Id) && mp_OpenTasks.get(so.refOrder.Id).containsKey('IB850_006'))
                            {
                                EdiExceptionUtility.clearOtherException(expSrvAPI, so.refOrder, 'IB850_006', 'Failed to create sales order', 'Failed to create sales order');
                            }
                            so.refOrder.EDI__Process_Flag__c = 'P';
                            soMaps.put(so.salesOrder.Id, so.salesOrder);
                            orderMapBySoId.put(so.salesOrder.Id, so.refOrder);
                            for (KNDY4__Sales_Order_Line__c soLine : so.lst_SalesOrderLine) {
                                soLine.KNDY4__Sales_Order__c = so.salesOrder.Id;
                            }
                            salesOrderLinesToInsert.addAll(so.lst_SalesOrderLine);
                        } else {
                            for (Database.Error databaseError : saveR.getErrors()) {
                                EdiExceptionUtility.setOtherException(expSrvAPI, so.refOrder, 'IB850_006', ' Failed to create sales order ', databaseError.getStatusCode() + ' : ' + databaseError.getMessage()+' Fields that caused this error: ' + databaseError.getFields());
                                break;
                            }
                            so.refOrder.EDI__Process_Flag__c = 'U';
                        }
                        i++;
                    }
                    if (salesOrderLinesToInsert.size() > 0) {
                        Integer j = 0;
                        for (Database.SaveResult saveR : Database.insert(salesOrderLinesToInsert, false)) {
                            KNDY4__Sales_Order_Line__c soLine = salesOrderLinesToInsert[j];
                            EDI__Order__c refOrder = orderMapBySoId.get(soLine.KNDY4__Sales_Order__c);
                            KNDY4__Sales_Order__c salesOrder = soMaps.get(soLine.KNDY4__Sales_Order__c);
                            if (saveR.isSuccess()) {
                                if (mp_OpenTasks.containsKey(refOrder.Id) && mp_OpenTasks.get(refOrder.Id).containsKey('IB850_007'))
                                {
                                    EdiExceptionUtility.clearOtherException(expSrvAPI, refOrder, 'IB850_007', 'Failed to create sales order line(s)', 'Failed to create sales order line(s)');
                                }
                                refOrder.EDI__Process_Flag__c = 'P';
                                refOrder.EDI__Sales_Order__c = salesOrder.Id;
                                //soMapsToUpdate.put(salesOrder.Id, salesOrder);
                            }
                            else {
                                for (Database.Error databaseError : saveR.getErrors()) {
                                    System.debug(LoggingLevel.FINEST,databaseError.getMessage());
                                    System.debug(LoggingLevel.FINEST,'edi order line ='+soLine.EDI__Order_Line__c);                                   
                                    EdiExceptionUtility.setOtherException(expSrvAPI, refOrder, 'IB850_007', ' Failed to create sales order line(s) ', databaseError.getStatusCode() + ' : ' + databaseError.getMessage()+' Fields that caused this error: ' + databaseError.getFields());
                                    break;
                                }
                                refOrder.EDI__Process_Flag__c = 'U';
                                refOrder.EDI__Sales_Order__c = null;
                                soMapsToDelete.put(salesOrder.Id, salesOrder);
                            }
                            j++;
                        }
                    }
                    //if (soMapsToUpdate.size() > 0) {
                     //   System.debug(LoggingLevel.FINEST,'soMapsToUpdate = '+soMapsToUpdate);
                     //   Database.update(soMapsToUpdate.values(), false);
                    //}
                    if (soMapsToDelete.size() > 0) {
                        System.debug(LoggingLevel.FINEST,'soMapsToDelete = '+soMapsToDelete);                       
                        Database.delete(soMapsToDelete.values(), false);
                    }
                }
            }
            catch(Exception e) {
                System.debug(LoggingLevel.FINEST,e.getMessage() + ' --> ' + e.getStackTraceString());
                messages.add(new KNDY4.Notify.Message(e.getMessage(), e.getStackTraceString()));
            }
            response.records =  ediOrderList;
            response.exceptions = expSrvAPI.finish(false);
            return response;
        }
     /**
        * @description Accepts EDI order, list of EDI order lines and map which has string and list of string (as key value pair) as parameters and construct sales order and sales order lines.
        *
        * @param EDI order.
        * @param list of EDI order lines.
        * @param map which has string and list of string (as key value pair).
        * @return void.
        */
        private void postOrder(EDI__Order__c ediOrder, List<EDI__Order_Line__c> ediOrderLineList, Map<String, List<String>> parametersMap) {
            KNDY4__Sales_Order__c salesOrder = constructSalesOrder(ediOrder  , parametersMap);
            List<KNDY4__Sales_Order_Line__c> salesOrderLineList = constructSalesOrderLines(ediOrderLineList, ediOrder, parametersMap , salesOrder);
            SoSolNotes soSolNotesObj = new SoSolNotes();
            soSolNotesObj.salesOrder = salesOrder;
            soSolNotesObj.lst_SalesOrderLine = salesOrderLineList;
            soSolNotesObj.refOrder = ediOrder;
            lst_SalesOrdersToBeCreated.add(soSolNotesObj);
            System.debug(LoggingLevel.FINEST,'salesOrder = '+salesOrder);
            System.debug(LoggingLevel.FINEST,'salesOrderLineList = '+salesOrderLineList);
        }
       /**
        * @description Accepts EDI order as parameter and construct sales order header information from the EDI order header.
        *
        * @param EDI order.
        * @return sales order.
        */
        private KNDY4__Sales_Order__c constructSalesOrder(EDI__Order__c ediOrder , Map<String, List<String>> parametersMap) {
            KNDY4__Sales_Order__c salesOrder = new KNDY4__Sales_Order__c();
            if (ediOrder.EDI__PO_Date__c != null) {
                salesOrder.KNDY4__Customer_Purchase_Order_Date__c = ediOrder.EDI__PO_Date__c;
            } else {
                salesOrder.KNDY4__Customer_Purchase_Order_Date__c = Date.today();
            }
            salesOrder.EDI__Order__c = ediOrder.Id;
            salesOrder.KNDY4__Customer_Purchase_Order__c = ediOrder.EDI__Purchase_Order__c;
            salesOrder.KNDY4__Ship_to__c = mp_DerivedValues.get(ediOrder.Id).customerObj.Id;
            salesOrder.KNDY4__Customer__c = mp_DerivedValues.get(ediOrder.Id).customerObj.KNDY4__Parent_Customer__c;
            salesOrder.KNDY4__Bill_to__c = mp_DerivedValues.get(ediOrder.Id).customerObj.KNDY4__Parent_Customer__r.KNDY4__Parent_Customer__c;
            if (defaultCompany != null)         
                salesOrder.KNDY4__Company__c = defaultCompany.Id;
            salesOrder.KNDY4__Type__c = 'Standard';
            salesOrder.EDI__Secondary_Reference__c = ediOrder.EDI__Secondary_PO__c;
            List<String> valuesList = parametersMap.get('DELVRYDTE');
            Date deliveryDate = null;
            if (valuesList != null) {
                for (String value : valuesList) {
                    if (value != null) {
                        deliveryDate = getDtmDate(ediOrder, value);
                        if (deliveryDate != null) {
                            break;
                        }
                    }
                }
            }
            if(deliveryDate != null){
                salesOrder.KNDY4__Required_Date__c = deliveryDate;
            }
            return salesOrder;
        }
       /**
        * @description Accepts List of EDI order lines , EDI order ,map which has string and list of string (as key value pair) and sales order as parameters .It extract sales order lines information .
        *
        * @param List of EDI order lines.
        * @param EDI order.
        * @param map which has string and list of string (as key value pair).
        * @param sales order.
        * @return List of sales order lines.
        */
        private List<KNDY4__Sales_Order_Line__c> constructSalesOrderLines(List<EDI__Order_Line__c> ediOrderLineList, EDI__Order__c ediOrder, Map<String, List<String>> parametersMap , KNDY4__Sales_Order__c kndy4SalesOrder)  {
            List<KNDY4__Sales_Order_Line__c> salesOrderLineList = new List<KNDY4__Sales_Order_Line__c>();
            for (EDI__Order_Line__c ediOrderLine : ediOrderLineList) {
                KNDY4__Sales_Order_Line__c salesOrderLine = new KNDY4__Sales_Order_Line__c();
                salesOrderLine.EDI__Order_Line__c = ediOrderLine.Id;
                salesOrderLine.KNDY4__Quantity_Ordered__c = ediOrderLine.EDI__Quantity_Ordered__c;
                salesOrderLine.KNDY4__Product__c = ediOrderLine.EDI__Product__c;
                if (ediOrderLine.EDI__Line_Number__c != null) {
                    salesOrderLine.KNDY4__Line__c = Decimal.valueOf(ediOrderLine.EDI__Line_Number__c);
                } 
                salesOrderLine.KNDY4__Expected_Price__c = ediOrderLine.EDI__Original_Price__c;
                salesOrderLine.KNDY4__Company__c = kndy4SalesOrder.KNDY4__Company__c;
                if (defaultCompany != null && defaultCompany.KNDY4__Default_Sales_Order_Ship_From_Facility__c != null){
                                        salesOrderLine.KNDY4__Ship_From_Location__c = defaultCompany.KNDY4__Default_Sales_Order_Ship_From_Facility__r.KNDY4__Default_Sales_Order_Ship_From_Location__c;
                }
                salesOrderLineList.add(salesOrderLine);                
            }
            return salesOrderLineList;
        }
       /**
        * @description  Return date which matches with the qualifier.
        *
        * @param EDI order.
        * @param map which has string and list of string (as key value pair).
        * @return Date.
        */
        private Date getDtmDate(EDI__Order__c ediOrder, String dateQualifier) {
            if (dateQualifier != null) {
                List<String> qualFields = new List<String>{'EDI__DTM_Qualifier1__c','EDI__DTM_Qualifier2__c','EDI__DTM_Qualifier3__c','EDI__DTM_Qualifier4__c','EDI__DTM_Qualifier5__c'};
                List<String> dateFields = new List<String>{'EDI__DTM_Date1__c','EDI__DTM_Date2__c','EDI__DTM_Date3__c','EDI__DTM_Date4__c','EDI__DTM_Date5__c'};
                for (Integer i=0; i<qualFields.size(); i++) {
                    if (ediOrder.get(qualFields.get(i)) != null && String.valueOf(ediOrder.get(qualFields.get(i))).equalsIgnoreCase(dateQualifier)) {
                        return Date.valueOf(ediOrder.get(dateFields.get(i)));
                    }
                }
            }
            return null;
        }
  }
  /**
   * @author HiBiZ Solutions
   * @date 02/19/2016
   * @description Class that extends exception.
   *
   */  
  private class EDI850IBException extends Exception { }
  /**
   * @author HiBiZ Solutions
   * @date 02/19/2016
   * @description Class used for storing Newly created sales order, sales order Lines and related edi order.
   *
   */
  private class SoSolNotes {
        KNDY4__Sales_Order__c salesOrder;
        List<KNDY4__Sales_Order_Line__c> lst_SalesOrderLine;
        EDI__Order__c refOrder;
    }
  /**
   * @author HiBiZ Solutions
   * @date 02/19/2016
   * @description Class used for storing ship to customer and parameters.
   *
   */
    private class DerivedValues {
      KNDY4__Customer__c customerObj;
      Map<String, List<String>> mp_Parameter;
    }
}