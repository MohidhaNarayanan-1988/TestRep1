/************************************************************************************************************************************
  Class       		:  EDIUtility static
  Author      		:  HiBiZ Solutions
  Date Created  	:  02/16/2016
  Purpose      		:  Class that implements Utility methods EDI Classes
************************************************************************************************************************************/
global with sharing class EDIUtility_Static
{
    private static String SPACE_CHARACTER = '';
     /**
     * @description Accepts no parameter constructs object name using current datetime.
     *
     * @return String
     *
     */
    public static String constructObjectName()
    {
        return Datetime.now().format('yyyyMMddHHmmssS');
    } 
    /**
     * @description Accepts String value of street address as parameter and determines street address based on the length of characters.
     *
     * @param String Street Address
     * @return String Street Address
     *
     */
     public static String getStreetAddressPart1(String streetAddress)
     {
         String streetAddressPart1 = '';                        
         if((streetAddress != null) && (streetAddress.length() > 0))
         {
             if(streetAddress.length() > 55)
             {
                 streetAddressPart1 = streetAddress.substring(0, 54);                    
             }
             else
             {
                 streetAddressPart1 = streetAddress;
             }
         }
         return streetAddressPart1;
     }
    /**
     * @description Accepts String value of street address as parameter and returns the 2nd part of street address based on the length of characters 
     *
     * @param string value of streetAddress
     * @return String
     */
    public static String getStreetAddressPart2(String streetAddress)
    {
        String streetAddressPart2 = '';                        
        if((streetAddress != null) && (streetAddress.length() > 0))
        {
            if(streetAddress.length() > 110)
            {
                streetAddressPart2 = streetAddress.substring(55, 109);               
            }  
            else if(streetAddress.length() > 55)
            {
                streetAddressPart2 = streetAddress.substring(55, streetAddress.length() - 1); 
            }             
        }
        return streetAddressPart2;
    } 
    /**
     * @description Accepts input string , string value of pad characters and integer length as parameter.It concatenate the pad characters at the begining of the input string
     *
     * @param String
     * @param String
     * @param Integer
     * @return String
     *
     */
    public static String leftPad(String inputString, String padCharacters, Integer length)
    {
        String result = inputString;
        while (result.length() < length)
            result = padCharacters + result;
        return result;
    }
    /**
     * @description Accepts a String value of column names and List of Id values as parameters and determines the KNDY4 Customer Invoices that matches with the input values
     *
     * @param String
     * @param List of Id
     * @return Map of KNDY4 Customer Invoice
     *
     */
    public static Map<Id, KNDY4__Customer_Invoice__c> getKndy4CustomerInvoiceMap(String columns, List<Id> kndy4CustomerInvoiceIdList)
    {
        Map<Id, KNDY4__Customer_Invoice__c> kndy4CustomerInvoiceMap = new Map<Id, KNDY4__Customer_Invoice__c>();
        String query = 'SELECT ';
        query += columns;
        query += ' FROM KNDY4__Customer_Invoice__c';
        query += ' WHERE Id In : kndy4CustomerInvoiceIdList';
        for (KNDY4__Customer_Invoice__c kndy4CustomerInvoice : Database.query(query))
        {
            kndy4CustomerInvoiceMap.put(kndy4CustomerInvoice.Id, kndy4CustomerInvoice);
        }
        return kndy4CustomerInvoiceMap;
    }
    /**
     * @description Accepts a String value of column names and List of customer invoice Id as parameters and determines the customer invoice line that matches with the input values
     *
     * @param String
     * @param List of Id
     * @return Map of KNDY4 Customer Invoice Line
     *
     */
    public static Map<Id, List<KNDY4__Customer_Invoice_Line__c>> getKndy4CustomerInvoiceLine(String columns, List<Id> customerInvoiceIdList)
    {
        Map<Id, List<KNDY4__Customer_Invoice_Line__c>> kndy4CustomerInvoiceLineMap = new Map<Id, List<KNDY4__Customer_Invoice_Line__c>>();
        try
        {
            String query = 'SELECT ';
            query += columns + ' FROM KNDY4__Customer_Invoice_Line__c WHERE KNDY4__Customer_Invoice__c In : customerInvoiceIdList';
            for (KNDY4__Customer_Invoice_Line__c cil : Database.query(query))
            {
                List<KNDY4__Customer_Invoice_Line__c> kndy4CustomerInvoiceLineList = new List<KNDY4__Customer_Invoice_Line__c>();
                if (kndy4CustomerInvoiceLineMap.containsKey(cil.KNDY4__Customer_Invoice__c))
                {
                    kndy4CustomerInvoiceLineList = kndy4CustomerInvoiceLineMap.get(cil.KNDY4__Customer_Invoice__c);
                }
                kndy4CustomerInvoiceLineList.add(cil);
                kndy4CustomerInvoiceLineMap.put(cil.KNDY4__Customer_Invoice__c, kndy4CustomerInvoiceLineList);
            }
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
        }
        return  kndy4CustomerInvoiceLineMap;
    }
    /**
     * @description Accepts EDI tp process object as parameter and determines the parameters associated with that EDI__TP_Process__c
     *
     * @param EDI__TP_Process__c
     * @return Map which has String as key and list of string as values.
     *
     */
    public static Map<String, List<String>> getParameters(EDI__TP_Process__c process) 
    {
        Map<String, List<String>> tpParameterMap = new Map<String, List<String>>();
        for (EDI__TP_Process_Parameter__c param : process.EDI__Parameters__r) 
        {
            List<String> paramValues = new List<String>();
            if (param.EDI__Value_1__c != null && param.EDI__Value_1__c != SPACE_CHARACTER)
                paramValues.add(param.EDI__Value_1__c);
            if (param.EDI__Value_2__c != null && param.EDI__Value_2__c != SPACE_CHARACTER)
                paramValues.add(param.EDI__Value_2__c);
            if (param.EDI__Value_3__c != null && param.EDI__Value_3__c != SPACE_CHARACTER)
                paramValues.add(param.EDI__Value_3__c);
            if (param.EDI__Value_4__c != null && param.EDI__Value_4__c != SPACE_CHARACTER)
                paramValues.add(param.EDI__Value_4__c);
            if (param.EDI__Value_5__c != null && param.EDI__Value_5__c != SPACE_CHARACTER)
                paramValues.add(param.EDI__Value_5__c);
            tpParameterMap.put(param.Name, paramValues);
        }
        return tpParameterMap;
    }
    /**
     * @description Accepts a String value of column names and List of tp process Id as parameters and determines EDI Tp Processes that matches the input values.
     *
     * @param String
     * @param List of Id
     * @return Map of EDI__TP_Process__c
     *
     */
    public static Map<Id, EDI__TP_Process__c> getTpProcess(String columns, List<Id> tpProcessIdList)
    {
        try {
            String query = 'SELECT ';
            query += columns;
            query += ' FROM EDI__TP_Process__c WHERE Id in : tpProcessIdList';
            List<EDI__TP_Process__c> tpProcessList = Database.query(query);
            return new Map<Id, EDI__TP_Process__c>(tpProcessList);
        }
        catch(Exception e) {
            System.debug(e.getStackTraceString());
        }
        return new Map<Id, EDI__TP_Process__c>();
    }
   /** 
    * @description Accepts no parameter and determines default company
    *
    * @return company object
    *
    */  
   public static KNDY4__Company__c getDefaultCompany() 
   {
        KNDY4__Company__c company = [SELECT Id, Name, KNDY4__Default_Sales_Order_Ship_From_Facility__c, KNDY4__Default_Sales_Order_Ship_From_Facility__r.KNDY4__Default_Sales_Order_Ship_From_Location__c  FROM KNDY4__Company__c LIMIT 1];
        return company;
   }
   /** 
    * @description Accepts list of id and string value of task status as parameter and fetches the related task which matches the input condition
    *
    * @param List of id
    * @param String
    * @return Map<Id, Map<String, Task>>
    *
    */  
   public static Map<Id, Map<String, Task>> getTasks(List<Id> whatIds, String status)
    {
        Map<Id, Map<String, Task>> tasksMap = new Map<Id, Map<String, Task>>();
        try
        {
            for (Task aTask : [Select Id, WhatId, KNDY4__Exception_Code__c From Task Where WhatId IN :whatIds And Status = :status])
            {
                Map<String, Task> taskMap = new Map<String, Task>();
                if (tasksMap.containsKey(aTask.WhatId))
                {
                    taskMap = tasksMap.get(aTask.WhatId);
                }
                taskMap.put(aTask.KNDY4__Exception_Code__c, aTask);
                tasksMap.put(aTask.WhatId, taskMap);
            }
        }
        catch(Exception e)
        { }
        return tasksMap;
    }
}