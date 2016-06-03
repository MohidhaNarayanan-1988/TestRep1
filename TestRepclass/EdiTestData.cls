@isTest
public class EdiTestData
{
    public static RecordType RecTypeCorpParent = [Select Id From RecordType  Where SobjectType = 'KNDY4__Customer__c' and DeveloperName = 'Corporate_Parent'];
    public static RecordType RecTypeBillTo = [Select Id From RecordType  Where SobjectType = 'KNDY4__Customer__c' and DeveloperName = 'Bill_To'];
    public static RecordType RecTypeSoldTo = [Select Id From RecordType  Where SobjectType = 'KNDY4__Customer__c' and DeveloperName = 'Sold_To'];
    public static RecordType RecTypeShipTo = [Select Id From RecordType  Where SobjectType = 'KNDY4__Customer__c' and DeveloperName = 'Ship_To'];
    public static Account createAccount()  {   
        Account objAccount = new Account();
        objAccount.name = 'PRE Brands, LLC';
        objAccount.BillingStreet='600 W Chicago Suite 670';
        objAccount.BillingCity='Chicago';
        objAccount.BillingState='IL';
        objAccount.BillingCountry='US';
        objAccount.BillingPostalCode='60654';
        return objAccount;        
    }
    public static KNDY4__Company__c createCompany(Account a) {    
        KNDY4__Company__c objCompany = new KNDY4__Company__c();
        objCompany.Name = 'PRE Brands, LLC';
        objCompany.KNDY4__Address__c = a.Id;
        return objCompany;
    }
    public static KNDY4__Facility__c getFacility(Id companyId){
        KNDY4__Facility__c facility = new KNDY4__Facility__c();
        facility.KNDY4__Company__c = companyId;
        facility.Name = 'Test facility';
        return facility;
    } 
    public static KNDY4__Location__c getLocation(Id facilityId){
        KNDY4__Location__c location = new KNDY4__Location__c();
        location.KNDY4__Facility__c = facilityId;
        return location;
    }
    public static EDI__Process__c getEdiProces(String processName, Decimal batchSize, String processDescription, Decimal recordsToProcess)
    {
        EDI__Process__c ediProcess = new EDI__Process__c();
        ediProcess.Name = processName;
        ediProcess.EDI__Batch_Size__c = batchSize;
        ediProcess.EDI__Description__c = processDescription;
        ediProcess.EDI__Records_To_Process__c = recordsToProcess;
        ediProcess.EDI__Active__c = true;
        return ediProcess;
    }
    public static EDI__Trading_Partner__c getEdiTradingPartner(String tradingPartnerName, String senderId, String Description, String type)
    {
       EDI__Trading_Partner__c ediTradingPartner = new EDI__Trading_Partner__c();
       ediTradingPartner.Name = tradingPartnerName;
       ediTradingPartner.EDI__Description__c = Description;
       ediTradingPartner.EDI__Sender_ID__c = senderId;
       ediTradingPartner.EDI__Type__c = type;
       return ediTradingPartner;
    }
    public static EDI__TP_Process__c getTpProcess(Integer priority, Id processId, Id tpId)
    {
        EDI__TP_Process__c ediTpProcess = new EDI__TP_Process__c();
        ediTpProcess.EDI__Active__c = true;
        ediTpProcess.EDI__Priority__c = priority; 
        ediTpProcess.EDI__Process__c = processId;
        ediTpProcess.EDI__Trading_Partner__c = tpId;
        return ediTpProcess;
    }
    public static EDI__TP_Process_Step__c getTpProcessStep(Id processId, Id processStepId)
    {
        EDI__TP_Process_Step__c ediTpProcessStep = new EDI__TP_Process_Step__c();
        ediTpProcessStep.EDI__Execute__c = true;
        ediTpProcessStep.EDI__Process__c = processId;
        ediTpProcessStep.EDI__Step__c = processStepId;
        return ediTpProcessStep;
    }

    public static EDI__Trading_Partner_Entity__c getEdiTradingPartnerEntity(Id tradingPartnerId, String tradingPartnerEntityName, KNDY4__Customer__c shipTo)
    {
       EDI__Trading_Partner_Entity__c ediTradingPartnerEntity = new EDI__Trading_Partner_Entity__c();
       ediTradingPartnerEntity.Name = tradingPartnerEntityName;
       ediTradingPartnerEntity.EDI__Trading_Partner__c = tradingPartnerId;
       ediTradingPartnerEntity.EDI__Ship_To_Customer__c = shipTo.Id;
       return ediTradingPartnerEntity;
    }
    public static EDI__TP_Process_Parameter__c getTpProcessParameter(String processParameterName, Id tpProcessId, Id processParameterId, List<String> paramValueList)
    {
        EDI__TP_Process_Parameter__c tpProcessParameter = new EDI__TP_Process_Parameter__c();
        tpProcessParameter.EDI__Parameter__c = processParameterId;
        tpProcessParameter.EDI__Process__c = tpProcessId;
        tpProcessParameter.Name = processParameterName;
        tpProcessParameter.EDI__Value_1__c = paramValueList[0];
        tpProcessParameter.EDI__Value_2__c = paramValueList[1];
        tpProcessParameter.EDI__Value_3__c = paramValueList[2];
        tpProcessParameter.EDI__Value_4__c = paramValueList[3];
        tpProcessParameter.EDI__Value_5__c = paramValueList[4];
        return tpProcessParameter;
    }
    public static EDI__Process_Parameter__c getProcessParameter(String processParameterName, Id processId, String uniqueName, List<String> paramValueList)
    {
        EDI__Process_Parameter__c processParameter = new EDI__Process_Parameter__c();
        processParameter.EDI__Process__c = processId;
        processParameter.Name = processParameterName;
        processParameter.EDI__Unique__c = uniqueName;
        processParameter.EDI__Value_1__c = paramValueList[0];
        processParameter.EDI__Value_2__c = paramValueList[1];
        processParameter.EDI__Value_3__c = paramValueList[2];
        processParameter.EDI__Value_4__c = paramValueList[3];
        processParameter.EDI__Value_5__c = paramValueList[4];
        return processParameter;
    }
    public static EDI__Process_Step__c getEdiProcessStep(String processStepName, String className, Id processId, Decimal ord)
    {
        EDI__Process_Step__c ediProcessStep = new EDI__Process_Step__c();
        ediProcessStep.Name = processStepName;
        ediProcessStep.EDI__Class_Name__c = className;
        ediProcessStep.EDI__Process__c = processId;
        ediProcessStep.EDI__Order__c = ord;
        return ediProcessStep;
    }
        public static Map<String,EDI__Table__c> customTables {
        get {
            if (customTables == null)
                customTables = new Map<String,EDI__Table__c>();
            return customTables;     
        }
    }
    public static Map<String,Map<String,EDI__Field__c>> tableFields {
        get {
            if (tableFields == null)
                tableFields = new Map<String,Map<String,EDI__Field__c>>();
            return tableFields;
        }
    }
    public static void createCustomTableRecord(String tableName,List<Map<String,Object>> values) {
        List<EDI__Value__c> valuesToInsert = new List<EDI__Value__c>();
        
        for (Map<String,Object> record:values) {
            System.debug(' record: ' + record);
            EDI__Record__c rec = new EDI__Record__c(
                EDI__Table__c = customTables.get(tableName).Id
            );
            insert rec;
            System.debug(' rec: ' + rec);
            EDI__Record__c recCreated = [select Id, Name from EDI__Record__c limit 1];
            System.debug (' created rec: ' + recCreated);
            for (String fieldName:record.keySet()) {
                System.Debug ('fieldName: ' + fieldName);
                EDI__Field__c field = tableFields.get(tableName).get(fieldName);
                System.Debug ('field: ' + field);
                EDI__Value__c val = new EDI__Value__c(
                    EDI__Record__c = rec.Id,
                    EDI__Field__c = field.Id
                );  
                if (field.EDI__Type__c != 'Lookup')
                    val.put('EDI__' + field.EDI__Type__c + '__c',record.get(fieldName));
                else
                    val.EDI__Lookup_URL__c = '/' + record.get(fieldName);
                valuesToInsert.add(val);
            }
        }
        insert valuesToInsert;
    }
    public static void createUpcsProductMapping() {
        EDI__Table__c custUpc = new EDI__Table__c(
            Name = 'UPC PRODUCT MAPPING',
            EDI__Description__c = '',
            EDI__Number_of_Fields__c = 3
        );
        insert custUpc;
        List<EDI__Field__c> fields = new List<EDI__Field__c>();
        EDI__Field__c customerUpc = new EDI__Field__c(
            Name = 'Customer UPC',
            EDI__Type__c = 'Text',
            EDI__Required__c = true,
            EDI__Key__c = true,
            EDI__Field_Number__c = 1,
            EDI__Length__c = 255,
            EDI__Table__c = custUpc.Id
        );
        fields.add(customerUpc);
        EDI__Field__c customer = new EDI__Field__c(
            Name = 'Customer',
            EDI__Type__c = 'Lookup',
            EDI__Required__c = true,
            EDI__Key__c = false,
            EDI__Field_Number__c = 2,
            EDI__Lookup_Object__c = 'EDI__Trading_Partner__c',
            EDI__Lookup_Field__c = 'Name',
            EDI__Table__c = custUpc.Id
        );
        fields.add(customer);
        EDI__Field__c product = new EDI__Field__c(
            Name = 'Product',
            EDI__Type__c = 'Lookup',
            EDI__Required__c = true,
            EDI__Key__c = false	,
            EDI__Field_Number__c = 3,
            EDI__Lookup_Object__c = 'KNDY4__Product__c',
            EDI__Lookup_Field__c = 'Name',
            EDI__Table__c = custUpc.Id
        );
        fields.add(product);
        insert fields;
        customTables.put('UPC PRODUCT MAPPING',custUpc);
        tableFields.put('UPC PRODUCT MAPPING',new Map<String,EDI__Field__c>());
        for (EDI__Field__c field:fields)
            tableFields.get('UPC PRODUCT MAPPING').put(field.Name,field);
    }
    public static KNDY4__Payment_Term__c createPaymentTerms() {    
        KNDY4__Payment_Term__c objPaymentTerm = new KNDY4__Payment_Term__c();
        objPaymentTerm.Name = 'Test Payment Term';
        objPaymentTerm.KNDY4__Description__c='desc';
        objPaymentTerm.KNDY4__Discount_Days__c=3;
        objPaymentTerm.KNDY4__Discount_Percent__c=20;
        objPaymentTerm.KNDY4__Due_Days__c=2;
        objPaymentTerm.KNDY4__Payment_Term_Unique__c='pay';
        return objPaymentTerm;
    } 
      public static EDI__Order__c getEdiOrder(EDI__Trading_Partner__c tp, EDI__Process__c proc) 
    { 
        EDI__Order__c ediOrder = new EDI__Order__c();
        ediOrder.Name = 'Test_Case_1';
        ediOrder.EDI__Sender_ID__c = tp.EDI__Sender_ID__c;
        ediOrder.EDI__Process_Name__c = proc.Name;
        ediOrder.EDI__Process_Flag__c = 'U';
        return ediOrder;
    }
    public static EDI__Order_Line__c getEdiOrderLine(EDI__Order__c ediOrder) 
    { 
        EDI__Order_Line__c ediOrderLine = new EDI__Order_Line__c();
        ediOrderLine.EDI__Order__c = ediOrder.Id;
        ediOrderLine.EDI__LINE_NUMBER__C = '1';
        return ediOrderLine;
    }
    public static KNDY4__Hierarchy__c createHiearchy()
    {
        KNDY4__Hierarchy__c objHierarchy = new KNDY4__Hierarchy__c();
        objHierarchy.Name = 'Test Hierarchy';
        objHierarchy.KNDY4__Code__c = '1';
        objHierarchy.KNDY4__Parent_Code__c = '2';
        return objHierarchy;
    }
    public static KNDY4__Customer__c createCorpCustomer(KNDY4__Hierarchy__c hierarchy, User u ) {    
        KNDY4__Customer__c objCorpPCustomer = new KNDY4__Customer__c ();
        objCorpPCustomer.Name = 'Test Corp Customer';
        objCorpPCustomer.RecordTypeId=recTypeCorpParent.id;
        objCorpPCustomer.KNDY4__Status__c = 'Approved';
        objCorpPCustomer.KNDY4__Customer_Identifier__c = '799998';
        objCorpPCustomer.KNDY4__Credit_Limit__c = 1500;
        return objCorpPCustomer;
    }
    public static KNDY4__Customer__c createBillToCustomer(KNDY4__Customer__c cust, KNDY4__Hierarchy__c hierarchy, KNDY4__Payment_Term__c pay, User u ) {    
        KNDY4__Customer__c objBillToCustomer = new KNDY4__Customer__c ();
        objBillToCustomer.Name = 'Test BillTo customer';
        objBillToCustomer.KNDY4__Parent_Customer__c=cust.id;       
        objBillToCustomer.RecordTypeId=RecTypeBillTo.id;
        objBillToCustomer.KNDY4__Payment_Term__c = pay.id;
        objBillToCustomer.KNDY4__Status__c = 'Approved';
        objBillToCustomer.KNDY4__Customer_Identifier__c = '499998';
        return objBillToCustomer;
    }
    public static KNDY4__Customer__c createSoldToCustomer(KNDY4__Customer__c cust, KNDY4__Hierarchy__c hierarchy, User u ) {    
        KNDY4__Customer__c objSoldToCustomer = new KNDY4__Customer__c ();
        objSoldToCustomer.Name = 'Test SoldTo Cust';
        objSoldToCustomer.KNDY4__Parent_Customer__c=cust.id;       
        objSoldToCustomer.RecordTypeId=RecTypeSoldTo.id;
        objSoldToCustomer.KNDY4__Status__c = 'Approved';
        objSoldToCustomer.KNDY4__Customer_Identifier__c = '999998';
        return objSoldToCustomer;
    } 
    public static KNDY4__Customer__c createShipToCustomer(KNDY4__Customer__c cust, KNDY4__Hierarchy__c hierarchy ) {    
        KNDY4__Customer__c objShipCustomer = new KNDY4__Customer__c ();
        objShipCustomer.Name = 'Test ShipTo customer';
        objShipCustomer.KNDY4__Customer_Identifier__c = '0040040001';
        objShipCustomer.KNDY4__Parent_Customer__c=cust.id;
        objShipCustomer.RecordTypeId=RecTypeShipTo.id;
        objShipCustomer.KNDY4__Status__c = 'Approved';
        return objShipCustomer;
    }
    public static KNDY4__Sales_Order__c getKndy4SalesOrder(Id companyId, Id billToCustomerId, Id shipToCustomerId, Date requiredDate, String status, Id shipFromLocationId)
    {
        KNDY4__Sales_Order__c kndy4SalesOrder = new KNDY4__Sales_Order__c();
        kndy4SalesOrder.Name = String.valueOf(Datetime.now());
        kndy4SalesOrder.KNDY4__Company__c = companyId;
        kndy4SalesOrder.KNDY4__Bill_to__c = billToCustomerId;
        kndy4SalesOrder.KNDY4__Ship_to__c = shipToCustomerId;
        kndy4SalesOrder.KNDY4__Required_Date__c = requiredDate;
        kndy4SalesOrder.KNDY4__Status__c = status;
        kndy4SalesOrder.KNDY4__Ship_From_Location__c = shipFromLocationId;
        return kndy4SalesOrder;
    } 
    public static KNDY4__UOM__c getKndy4Uom(String Name, String Description)
    {
        KNDY4__UOM__c kndy4Uom = new KNDY4__UOM__c();
        kndy4Uom.Name = Name;
        kndy4Uom.KNDY4__Description__c = Description;
        return kndy4Uom;
    }
    public static KNDY4__Class__c createClass(String name, Decimal status1days, String status1name, Decimal status2days, String status2name, Decimal status3days, String status3name, Decimal shelfLifeDays) {
      KNDY4__Class__c objClass = new KNDY4__Class__c();
      objClass.name = name;
      objClass.KNDY4__Status_1_Name__c = status1name;
      objClass.KNDY4__Status_2_Name__c = status2name;
      objClass.KNDY4__Status_3_Name__c = status3name;
      objClass.KNDY4__Shelf_Life_Days__c = shelfLifeDays;
      return objClass;
    } 
    public static KNDY4__Product_Group__c createProductGroup(KNDY4__Company__c comp, KNDY4__Hierarchy__c hier) {
        KNDY4__Product_Group__c objProductGroup = new KNDY4__Product_Group__c();
        objProductGroup.Name = 'Test Product Group';
        objProductGroup.KNDY4__Company__c = comp.id;
        return objProductGroup;
    }
    public static KNDY4__Product__c createProduct(KNDY4__Company__c comp, KNDY4__Item__c item, KNDY4__Product_Group__c promoGroup) {
        KNDY4__Product__c objProduct = new KNDY4__Product__c();
        objProduct.Name = 'Test Product';
        objProduct.KNDY4__Company__c = comp.id;
        objProduct.KNDY4__Item__c = item.id;
        return objProduct;
    }
    public static KNDY4__Pricebook__c getKndy4PriceBook(String priceBookName, Id kndy4CompanyId)
    {
        KNDY4__Pricebook__c kndy4PriceBook = new KNDY4__Pricebook__c();
        kndy4PriceBook.Name = priceBookName;
        kndy4PriceBook.KNDY4__Company__c = kndy4CompanyId;
        return kndy4PriceBook;
    }
    public static KNDY4__Sales_Order_Line__c getKndy4SalesOrderLine(Id kndy4SalesOrderId, Id kndy4CompanyId, Id kndy4ProductId, Id kndy4PriceBookId, Id kndy4LocationId)
    {
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = new KNDY4__Sales_Order_Line__c();
        kndy4SalesOrderLine.name = String.valueOf(Datetime.now());
        kndy4SalesOrderLine.KNDY4__Sales_Order__c = kndy4SalesOrderId;
        kndy4SalesOrderLine.KNDY4__Company__c = kndy4CompanyId;
        kndy4SalesOrderLine.KNDY4__Product__c = kndy4ProductId;
        kndy4SalesOrderLine.KNDY4__Pricebook__c = kndy4PriceBookId;
        kndy4SalesOrderLine.KNDY4__Ship_From_Location__c = kndy4LocationId;
        kndy4SalesOrderLine.KNDY4__Required_Date__c = date.today();
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 1000;
        return kndy4SalesOrderLine;
    }
    public static KNDY4__Shipment__c getKndy4Shipment() {    
        KNDY4__Shipment__c kndy4Shipment = new KNDY4__Shipment__c();
        kndy4Shipment.Name = String.valueOf(Datetime.now());
        kndy4Shipment.KNDY4__Transaction_Currency__c='USD';
        kndy4Shipment.KNDY4__Movement_Number__c = 'K-000000001';
        kndy4Shipment.KNDY4__Date_Shipped__c = Datetime.now();
        kndy4Shipment.KNDY4__Status__c = 'Staged';
        return kndy4Shipment;
    }  
    public static KNDY4__Shipment_Line__c getShipmentLine(Id kndy4ShipmentId, Id kndy4SalesOrderLineId, Id kndy4OrderLineId, Id kndy4SalesOrderId)
    {     
        KNDY4__Shipment_Line__c kndy4ShipmentLine = new KNDY4__Shipment_Line__c ();
        kndy4ShipmentLine.Name = String.valueOf(Datetime.now());
        kndy4ShipmentLine.KNDY4__Shipment__c = kndy4ShipmentId;
        kndy4ShipmentLine.KNDY4__Order_Line__c = kndy4OrderLineId;
        kndy4ShipmentLine.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineId;
        kndy4ShipmentLine.KNDY4__Sales_Order__c = kndy4SalesOrderId;
        return kndy4ShipmentLine;
    }
    public static KNDY4__Customer_Invoice__c getCustomerInvoice(Id companyId, Id paymentTermId, Id salesOrderId, Id billToCustomerId, Date invoicedDate)
    {
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = new KNDY4__Customer_Invoice__c();     
        kndy4CustomerInvoice.Name = String.valueOf(Datetime.now());
        kndy4CustomerInvoice.KNDY4__Sales_Order__c = salesOrderId;
        kndy4CustomerInvoice.KNDY4__Payment_Term__c = paymentTermId;
        kndy4CustomerInvoice.KNDY4__Company__c = companyId;
        kndy4CustomerInvoice.KNDY4__Memo__c = 'Memo';
        kndy4CustomerInvoice.KNDY4__Date_Invoiced__c = invoicedDate;
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = billToCustomerId;        
        return kndy4CustomerInvoice;
    }
    public static KNDY4__Customer_Invoice_Line__c getCustomerInvoiceLine(Id customerInvoiceId, Id productId, Id shipmentId, Integer quantity, Decimal unitPrice)
    {
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = new KNDY4__Customer_Invoice_Line__c();       
        kndy4CustomerInvoiceLine.Name = String.valueOf(Datetime.now());
        kndy4CustomerInvoiceLine.KNDY4__Customer_Invoice__c = customerInvoiceId;
        kndy4CustomerInvoiceLine.KNDY4__Product__c = productId;
        kndy4CustomerInvoiceLine.KNDY4__Shipment__c = shipmentId;
        kndy4CustomerInvoiceLine.KNDY4__Quantity_Shipped__c = quantity;
        kndy4CustomerInvoiceLine.KNDY4__Unit_Price__c = unitPrice;
        return kndy4CustomerInvoiceLine;
    }
    public static KNDY4__Item__c getKndy4Item(String itemName, Id companyId, String source, Id kndy4ClassId, String itemType)
    {
        KNDY4__Item__c kndy4Item = new KNDY4__Item__c();
        kndy4Item.Name = itemName;
        kndy4Item.KNDY4__Company__c = companyId;
        kndy4Item.KNDY4__Source__c = source;
        kndy4Item.KNDY4__Class__c = kndy4ClassId;
        kndy4Item.KNDY4__Description__c = 'Test Class Description';
        return kndy4Item;
    }
    public static EDI__Document__c getEdiDocument(String documentName, String ediEventName, Id processId, Id tradingPartnerId)
    {
        EDI__Document__c ediDocument = new EDI__Document__c();
        ediDocument.Name = documentName;
        ediDocument.EDI__Event_Name__c = ediEventName;
        ediDocument.EDI__Process__c = processId;
        ediDocument.EDI__Trading_Parnter__c = tradingPartnerId; 
        return ediDocument;
    }
    public static EDI__Event__c getEdiEvent(Id processId, Id tradingPartnerId, Id documentId, Id tpProcessId, String objectId, String eventName, String objectName, String objectType)
    {
        EDI__Event__c ediEvent = new EDI__Event__c();
        ediEvent.EDI__Consumed__c = false;
        ediEvent.EDI__Object_ID__c = objectId;
        ediEvent.EDI__Object_Name__c = objectName;
        ediEvent.EDI__Process__c = processId;
        ediEvent.EDI__TP_Process__c = tpProcessId;
        ediEvent.EDI__Trading_Partner__c = tradingPartnerId;
        ediEvent.EDI__Event_Name__c = eventName;
        ediEvent.EDI__Document__c = documentId;
        ediEvent.EDI__Type__c = objectType;
        return ediEvent;
    }
    public static KNDY4__Assignment__c createAssignment(String code, String description) {
        KNDY4__Assignment__c assignment = new KNDY4__Assignment__c();
        assignment.Name = code;
        assignment.Error_Message__c = description;
        assignment.KNDY4__Exception_Code__c = code;
        return assignment;
    }
    public static Task getOpenTask(Id whatId , String exCode) 
    {
        Task taskObj = new Task();
        taskObj.KNDY4__Exception_Code__c =exCode;
        taskObj.Status = 'Open';
        taskObj.WhatId = whatId;
        return taskObj;
    }
}