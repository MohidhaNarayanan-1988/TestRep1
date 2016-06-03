@isTest
private class EDI810OBTest {
    //Success case 
    public static testMethod void test_method_one() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        //street address 1 and street address 2.
        acc.BillingStreet='600 W Chicago Suite 670 600 W Chicago Suite 670 600 W Chicago Suite 670 600 W Chicago Suite 670 Chicago Suite 670';
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        KNDY4__Customer__c objShipToCustomerUpdated = [Select Id,KNDY4__Zip_Code__c , KNDY4__Address__c from KNDY4__Customer__c where  Id =:  objShipToCustomer.id];
        objShipToCustomerUpdated.KNDY4__Address__c = acc.Id;
        update objShipToCustomerUpdated;
        //sales order
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, objShipToCustomer.Id, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Customer_Purchase_Order__c = '12345';
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CA', 'CA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        kndy4SalesOrderUpdated.KNDY4__Ship_to__c  = objShipToCustomer.Id;
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, kndy4SalesOrderUpdated.Id, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        //customer invoice line
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, kndy4Product.Id, kndy4Shipment.Id, 10, 10.00);
        kndy4CustomerInvoiceLine.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineUpdated1.Id;
        insert kndy4CustomerInvoiceLine;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Country__c = 'USA';
        update kndy4CustomerInvoiceCreated;
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLineCreated = [select Id, Name, KNDY4__Product__c from KNDY4__Customer_Invoice_Line__c where Id =: kndy4CustomerInvoiceLine.Id];
        kndy4CustomerInvoiceLineCreated.KNDY4__Product__c = kndy4Product.Id;
        update kndy4CustomerInvoiceLineCreated;
         List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4CustomerInvoice.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        List<EDI__Invoice__c> ediInvList= [Select Id, Name,EDI__Invoice__c From EDI__Invoice__c where EDI__Invoice__c =: kndy4CustomerInvoiceCreated.Name];
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4CustomerInvoice.id];
        System.assert(ediInvList != null && ediInvList.size() > 0); 
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == true)); 
    }
    //failure case 2 - event with wrong customer invoice object Id
    public static testMethod void test_method_two() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        //sales order
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, objShipToCustomer.Id, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Customer_Purchase_Order__c = '12345';
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CA', 'CA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        kndy4SalesOrderUpdated.KNDY4__Ship_to__c  = objShipToCustomer.Id;
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, kndy4SalesOrderUpdated.Id, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        //customer invoice line
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, kndy4Product.Id, kndy4Shipment.Id, 10, 10.00);
        kndy4CustomerInvoiceLine.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineUpdated1.Id;
        insert kndy4CustomerInvoiceLine;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        update kndy4CustomerInvoiceCreated;
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLineCreated = [select Id, Name, KNDY4__Product__c from KNDY4__Customer_Invoice_Line__c where Id =: kndy4CustomerInvoiceLine.Id];
        kndy4CustomerInvoiceLineCreated.KNDY4__Product__c = kndy4Product.Id;
        update kndy4CustomerInvoiceLineCreated;
         List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4SalesOrderUpdated.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4SalesOrderUpdated.id];
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == false)); 
    }
    //failure case  - customer purchase order is null
    public static testMethod void test_method_three() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        //sales order
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, objShipToCustomer.Id, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CA', 'CA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        kndy4SalesOrderUpdated.KNDY4__Ship_to__c  = objShipToCustomer.Id;
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, kndy4SalesOrderUpdated.Id, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        //customer invoice line
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, kndy4Product.Id, kndy4Shipment.Id, 10, 10.00);
        kndy4CustomerInvoiceLine.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineUpdated1.Id;
        insert kndy4CustomerInvoiceLine;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        update kndy4CustomerInvoiceCreated;
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLineCreated = [select Id, Name, KNDY4__Product__c from KNDY4__Customer_Invoice_Line__c where Id =: kndy4CustomerInvoiceLine.Id];
        kndy4CustomerInvoiceLineCreated.KNDY4__Product__c = kndy4Product.Id;
        update kndy4CustomerInvoiceLineCreated;
         List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4CustomerInvoice.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Task taskcreated1 = EdiTestData.getOpenTask(ediEvent1.Id, 'OB810_002') ;
        insert taskcreated1;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4CustomerInvoice.id];
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == false)); 
    }
    //Failure case  - ship to missing in sales order
    public static testMethod void test_method_four() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        //sales order
        Id dummyId = null;
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, dummyId, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Customer_Purchase_Order__c = '12345';
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CA', 'CA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, kndy4SalesOrderUpdated.Id, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        //customer invoice line
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, kndy4Product.Id, kndy4Shipment.Id, 10, 10.00);
        kndy4CustomerInvoiceLine.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineUpdated1.Id;
        insert kndy4CustomerInvoiceLine;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        update kndy4CustomerInvoiceCreated;
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLineCreated = [select Id, Name, KNDY4__Product__c from KNDY4__Customer_Invoice_Line__c where Id =: kndy4CustomerInvoiceLine.Id];
        kndy4CustomerInvoiceLineCreated.KNDY4__Product__c = kndy4Product.Id;
        update kndy4CustomerInvoiceLineCreated;
         List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4CustomerInvoice.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Task taskcreated2 = EdiTestData.getOpenTask(ediEvent1.Id, 'OB810_003') ;
        insert taskcreated2;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4CustomerInvoice.id];
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == false)); 
    }
    //Failure case - without lines
    public static testMethod void test_method_Five() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        //sales order
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, objShipToCustomer.Id, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Customer_Purchase_Order__c = '12345';
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CA', 'CA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        kndy4SalesOrderUpdated.KNDY4__Ship_to__c  = objShipToCustomer.Id;
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, kndy4SalesOrderUpdated.Id, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        update kndy4CustomerInvoiceCreated;
        List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4CustomerInvoice.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Task taskcreated3 = EdiTestData.getOpenTask(ediEvent1.Id, 'OB810_004') ;
        insert taskcreated3;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4CustomerInvoice.id];
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == false)); 
    }
    //Failure case - product not found
    public static testMethod void test_method_Six() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        //sales order
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, objShipToCustomer.Id, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Customer_Purchase_Order__c = '12345';
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CA', 'CA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        kndy4SalesOrderUpdated.KNDY4__Ship_to__c  = objShipToCustomer.Id;
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, kndy4SalesOrderUpdated.Id, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        //customer invoice line
        Id dummy = null;
        
        List<KNDY4__Customer_Invoice_Line__c>kndy4CustomerInvoiceLineList = new List<KNDY4__Customer_Invoice_Line__c>();
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, dummy, kndy4Shipment.Id, 10, 10.00);
        kndy4CustomerInvoiceLine.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineUpdated1.Id;
        kndy4CustomerInvoiceLineList.add(kndy4CustomerInvoiceLine);
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine1 = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, dummy, kndy4Shipment.Id, 10, 10.00);
        kndy4CustomerInvoiceLine1.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineUpdated1.Id;
        kndy4CustomerInvoiceLineList.add(kndy4CustomerInvoiceLine1);
        insert kndy4CustomerInvoiceLineList;
        
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        update kndy4CustomerInvoiceCreated;
        
         List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4CustomerInvoice.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Task taskcreated3 = EdiTestData.getOpenTask(ediEvent1.Id, 'OB810_006') ;
        insert taskcreated3;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4CustomerInvoice.id];
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == false)); 
    }
    //failure - sales order missing  in customer invoice
    public static testMethod void test_method_seven() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        //sales order
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, objShipToCustomer.Id, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Customer_Purchase_Order__c = '12345';
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CA', 'CA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        kndy4SalesOrderUpdated.KNDY4__Ship_to__c  = objShipToCustomer.Id;
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        Id dummyId = null;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, dummyId, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        //customer invoice line
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, kndy4Product.Id, kndy4Shipment.Id, 10, 10.00);
        insert kndy4CustomerInvoiceLine;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        update kndy4CustomerInvoiceCreated;
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLineCreated = [select Id, Name, KNDY4__Product__c from KNDY4__Customer_Invoice_Line__c where Id =: kndy4CustomerInvoiceLine.Id];
        kndy4CustomerInvoiceLineCreated.KNDY4__Product__c = kndy4Product.Id;
        update kndy4CustomerInvoiceLineCreated;
         List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4CustomerInvoice.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Task taskcreated = EdiTestData.getOpenTask(ediEvent1.Id, 'OB810_001') ;
        insert taskcreated;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4CustomerInvoice.id];
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == false)); 
    }
     //failure - customer invoice total amount < = 0 
    public static testMethod void test_method_eight() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        KNDY4__Customer__c objShipToCustomerUpdated = [Select Id,KNDY4__Zip_Code__c , KNDY4__Address__c from KNDY4__Customer__c where  Id =:  objShipToCustomer.id];
        objShipToCustomerUpdated.KNDY4__Address__c = acc.Id;
        update objShipToCustomerUpdated;
        //sales order
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, objShipToCustomer.Id, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Customer_Purchase_Order__c = '12345';
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CA', 'CA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        kndy4SalesOrderUpdated.KNDY4__Ship_to__c  = objShipToCustomer.Id;
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, kndy4SalesOrderUpdated.Id, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        //customer invoice line
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, kndy4Product.Id, kndy4Shipment.Id, 0, 0);
        kndy4CustomerInvoiceLine.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineUpdated1.Id;
        insert kndy4CustomerInvoiceLine;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Country__c = 'USA';
        update kndy4CustomerInvoiceCreated;
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLineCreated = [select Id, Name, KNDY4__Product__c from KNDY4__Customer_Invoice_Line__c where Id =: kndy4CustomerInvoiceLine.Id];
        kndy4CustomerInvoiceLineCreated.KNDY4__Product__c = kndy4Product.Id;
        update kndy4CustomerInvoiceLineCreated;
         List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4CustomerInvoice.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Task taskcreated4 = EdiTestData.getOpenTask(ediEvent1.Id, 'OB810_005') ;
        insert taskcreated4;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4CustomerInvoice.id];
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == false)); 
    }
    //Failure - unhandled  - failed to insert new invoice 
    public static testMethod void test_method_nine() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        KNDY4__Customer__c objShipToCustomerUpdated = [Select Id,KNDY4__Zip_Code__c , KNDY4__Address__c from KNDY4__Customer__c where  Id =:  objShipToCustomer.id];
        objShipToCustomerUpdated.KNDY4__Address__c = acc.Id;
        update objShipToCustomerUpdated;
        //sales order
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, objShipToCustomer.Id, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Customer_Purchase_Order__c = '12345';
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CA', 'CA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        kndy4SalesOrderUpdated.KNDY4__Ship_to__c  = objShipToCustomer.Id;
        kndy4SalesOrderUpdated.KNDY4__Customer_Purchase_Order__c  = '1234567890123456789012345678901234567890';
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, kndy4SalesOrderUpdated.Id, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        //customer invoice line
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, kndy4Product.Id, kndy4Shipment.Id, 10, 10.00);
        kndy4CustomerInvoiceLine.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineUpdated1.Id;
        insert kndy4CustomerInvoiceLine;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Country__c = 'USA';
        update kndy4CustomerInvoiceCreated;
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLineCreated = [select Id, Name, KNDY4__Product__c from KNDY4__Customer_Invoice_Line__c where Id =: kndy4CustomerInvoiceLine.Id];
        kndy4CustomerInvoiceLineCreated.KNDY4__Product__c = kndy4Product.Id;
        update kndy4CustomerInvoiceLineCreated;
         List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4CustomerInvoice.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4CustomerInvoice.id];
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == false)); 
    }
     //Failure case  - unhandled  - failed to insert new invoice line
    public static testMethod void test_method_ten() {  
        //Account
        Account acc =  EdiTestData.createAccount();
        insert acc;
        //company
        KNDY4__Company__c company = EdiTestData.createCompany(acc);
        insert company; 
        //payment terms
        KNDY4__Payment_Term__c payTerm = EdiTestData.createPaymentTerms();
        insert payTerm;
        //process
        EDI__Process__c proc = EdiTestData.getEdiProces('SNDINV', 10, '', 200);
        insert proc;
        //process steps
        List<EDI__Process_Step__c> procSteps = new List<EDI__Process_Step__c>();
        EDI__Process_Step__c procStep1 = EdiTestData.getEdiProcessStep('OBINV_Validate', 'EDI810OB.Validate', proc.Id, 1);
        procSteps.add(procStep1);
        EDI__Process_Step__c procStep2 = EdiTestData.getEdiProcessStep('OBINV_Extract', 'EDI810OB.Extract', proc.Id, 2);
        procSteps.add(procStep2);
        insert procSteps;
        //tp
        EDI__Trading_Partner__c tp = EdiTestData.getEdiTradingPartner('WALMARTSUPRCNTR', '925485US00', 'WALMART SUPERCENTERS', 'Customer');
        insert tp;
        //tpProcess
        EDI__TP_Process__c tpProcess = EdiTestData.getTpProcess(1, proc.Id, tp.Id);
        insert tpProcess;
        //tpProcessSteps
        List<EDI__TP_Process_Step__c> tpProcessSteps = new List<EDI__TP_Process_Step__c>();
        EDI__TP_Process_Step__c tpProcessStep1 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep1.Id);
        tpProcessSteps.add(tpProcessStep1);
        EDI__TP_Process_Step__c tpProcessStep2 = EdiTestData.getTpProcessStep(tpProcess.Id, procStep2.Id);
        tpProcessSteps.add(tpProcessStep2);
        insert tpProcessSteps;
        //Document
        EDI__Document__c ediDocument = EdiTestData.getEdiDocument('SendInvoice', 'CI Create', proc.Id, tp.Id);
        insert ediDocument;
        //bill-to,ship to and sold to hirarchy
        /*KNDY4__Hierarchy__c objHierarchy = EdiTestData.createHiearchy();
        objHierarchy.KNDY4__Start_Date__c = Date.today();
        insert objHierarchy;*/  
        KNDY4__Hierarchy__c objHierarchy = null;
        User user1 = [select id from user limit 1];    
        //Create Corp Parent      
        KNDY4__Customer__c   objCorpParentCustomer = EdiTestData.createCorpCustomer(objHierarchy, user1);  
        insert objCorpParentCustomer;
        //Crate Bill to Customer
        KNDY4__Customer__c objBillToCustomer = EdiTestData.createBillToCustomer(objCorpParentCustomer, objHierarchy, payTerm, user1);
        objBillToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objBillToCustomer;
        //Create Sold To Customer    
        KNDY4__Customer__c objSoldToCustomer = EdiTestData.createSoldToCustomer(objBillToCustomer, objHierarchy, user1);
        objSoldToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objSoldToCustomer;
         //Create Ship To Customer
        KNDY4__Customer__c objShipToCustomer = EdiTestData.createShipToCustomer(objSoldToCustomer, objHierarchy);
        objShipToCustomer.KNDY4__Top_Parent_Customer__c = objCorpParentCustomer.Id;
        insert objShipToCustomer;
        KNDY4__Customer__c objShipToCustomerUpdated = [Select Id,KNDY4__Zip_Code__c , KNDY4__Address__c from KNDY4__Customer__c where  Id =:  objShipToCustomer.id];
        objShipToCustomerUpdated.KNDY4__Address__c = acc.Id;
        update objShipToCustomerUpdated;
        //sales order
        KNDY4__Sales_Order__c kndy4SalesOrder = EdiTestData.getKndy4SalesOrder(company.Id, objBillToCustomer.Id, objShipToCustomer.Id, Date.today().addDays(20), 'Open', null);
        kndy4SalesOrder.KNDY4__Customer__c = objSoldToCustomer.Id;
        kndy4SalesOrder.KNDY4__Customer_Purchase_Order__c = '12345';
        kndy4SalesOrder.KNDY4__Delivery_Method__c ='Delivery';
        insert kndy4SalesOrder;
        //UOM
        KNDY4__UOM__c caUom = EdiTestData.getKndy4Uom('CAA', 'CAA');
        insert caUOM;
        //Item class
        KNDY4__Class__c itemClass = EdiTestData.createClass('Test Class', 1, '', 2, '', 3, '', 4);
        insert itemClass;
        //Item
        KNDY4__Item__c kndy4Item = EdiTestData.getKndy4Item('03422', company.Id, 'Purchased', itemClass.Id, 'Finished good');
        insert kndy4Item;
        //Product group
        KNDY4__Product_Group__c prdGroup = EdiTestData.createProductGroup(company, objHierarchy);
        insert prdGroup;
        //Product
        KNDY4__Product__c kndy4Product = EdiTestData.createProduct(company, kndy4Item, prdGroup);
        kndy4Product.KNDY4__UPC_Code__c = '00079100514502';
        kndy4Product.KNDY4__Selling_UOM__c = caUOM.Id;
        kndy4Product.KNDY4__Description__c = 'proddesc';
        insert kndy4Product;
        //PriceBook
        KNDY4__Pricebook__c kndy4PriceBook = EdiTestData.getKndy4PriceBook('TestPriceBook', company.Id);
        insert kndy4PriceBook;
        //sol
        List<KNDY4__Sales_Order_Line__c> solList = new List<KNDY4__Sales_Order_Line__c>();
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine);   
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLine2 = EdiTestData.getKndy4SalesOrderLine(kndy4SalesOrder.Id, company.Id, kndy4Product.Id, kndy4PriceBook.Id, null);
        kndy4SalesOrderLine2.KNDY4__Quantity_Ordered__c = 10;
        kndy4SalesOrderLine2.KNDY4__Quantity_Shipped__c = 5;
        solList.add(kndy4SalesOrderLine2);
        insert solList;
        
        KNDY4__Sales_Order__c kndy4SalesOrderUpdated = [select Id, Name, KNDY4__Ship_to__c, KNDY4__Bill_to__c, KNDY4__Customer_Purchase_Order__c, KNDY4__Delivery_Method__c, KNDY4__Ship_From_Location__c, KNDY4__Means_of_Transport__c, KNDY4__Customer_Purchase_Order_Date__c, KNDY4__Total_Order_Volume__c, KNDY4__Total_Quantity_Ordered__c from KNDY4__Sales_Order__c where Id =: kndy4SalesOrder.Id];
        KNDY4__Sales_Order_Line__c kndy4SalesOrderLineUpdated1 = [select Id, Name from KNDY4__Sales_Order_Line__c where Id =:  kndy4SalesOrderLine.id];
        kndy4SalesOrderUpdated.KNDY4__Ship_to__c  = objShipToCustomer.Id;
        update kndy4SalesOrderUpdated;
        //kndy4 shipment
        KNDY4__Shipment__c kndy4Shipment = EdiTestData.getKndy4Shipment();
        kndy4Shipment.KNDY4__Company__c = company.Id;
        insert kndy4Shipment;
        update kndy4Shipment;
        KNDY4__Shipment_Line__c kndy4ShipmentLine = EdiTestData.getShipmentLine(kndy4Shipment.Id, kndy4SalesOrderLineUpdated1.Id, Null, kndy4SalesOrderUpdated.Id);
        kndy4ShipmentLine.KNDY4__Product__c = kndy4Product.Id;
        kndy4ShipmentLine.KNDY4__Quantity_Planned__c = 1;
        kndy4ShipmentLine.KNDY4__Company__c = company.Id;
        insert kndy4ShipmentLine;
        //customer invoice
        KNDY4__Customer_Invoice__c kndy4CustomerInvoice = EdiTestData.getCustomerInvoice(company.Id, payTerm.Id, kndy4SalesOrderUpdated.Id, objBillToCustomer.Id, Date.today());
        kndy4CustomerInvoice.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoice.KNDY4__Ship_Date__c = date.today();
        kndy4CustomerInvoice.KNDY4__Invoice_Type__c = 'Ship Invoice';
        kndy4CustomerInvoice.KNDY4__Status__c = 'Open';
        kndy4CustomerInvoice.KNDY4__Bill_to_Zip_Code__c = '1234';
        insert kndy4CustomerInvoice;
        //customer invoice line
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLine = EdiTestData.getCustomerInvoiceLine(kndy4CustomerInvoice.Id, kndy4Product.Id, kndy4Shipment.Id, 10, 10.00);
        kndy4CustomerInvoiceLine.KNDY4__Sales_Order_Line__c = kndy4SalesOrderLineUpdated1.Id;
        insert kndy4CustomerInvoiceLine;
        KNDY4__Customer_Invoice__c kndy4CustomerInvoiceCreated = [select Id, Name, KNDY4__Bill_To_Customer__c, KNDY4__Bill_to_Zip_Code__c from KNDY4__Customer_Invoice__c where Id =: kndy4CustomerInvoice.Id];
        kndy4CustomerInvoiceCreated.KNDY4__Bill_To_Customer__c = objBillToCustomer.Id;
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Zip_Code__c = '1234';
        kndy4CustomerInvoiceCreated.KNDY4__Bill_to_Country__c = 'USA';
        update kndy4CustomerInvoiceCreated;
        KNDY4__Customer_Invoice_Line__c kndy4CustomerInvoiceLineCreated = [select Id, Name, KNDY4__Product__c , KNDY4__Quantity_Shipped__c from KNDY4__Customer_Invoice_Line__c where Id =: kndy4CustomerInvoiceLine.Id];
        kndy4CustomerInvoiceLineCreated.KNDY4__Product__c = kndy4Product.Id;
        update kndy4CustomerInvoiceLineCreated;
         List<EDI__Event__c> events = new List<EDI__Event__c>();
        EDI__Event__c ediEvent1 = EdiTestData.getEdiEvent(proc.Id, tp.Id, ediDocument.Id, tpProcess.Id, kndy4CustomerInvoice.Id, 'CI Create', kndy4CustomerInvoice.Name, 'KNDY4__Customer_Invoice__c');
        ediEvent1.EDI__Customer_Invoice__c = kndy4CustomerInvoice.id;
        events.add(ediEvent1);
        insert events;
        List<KNDY4__Assignment__c> assignmentList =  getAssignments();
        insert assignmentList;
        Test.startTest();
        EDI810OB ob810= new EDI810OB();     
        ob810.runBatch(company.Id);
        Test.stopTest();
        EDI__Event__c ediEvent = [Select Id, Name , EDI__Consumed__c , EDI__Object_ID__c from EDI__Event__c where EDI__Object_ID__c=:kndy4CustomerInvoice.id];
        System.assert(ediEvent != null && (ediEvent.EDI__Consumed__c == false)); 
    }
    public static List<KNDY4__Assignment__c> getAssignments()
    {
       List<KNDY4__Assignment__c>AssignmentsList = new List<KNDY4__Assignment__c>();
       KNDY4__Assignment__c assignment1 = EdiTestData.createAssignment('OB810_001', 'Exception'); 
       AssignmentsList.add(assignment1);
       KNDY4__Assignment__c assignment2 = EdiTestData.createAssignment('OB810_002', 'Exception'); 
       AssignmentsList.add(assignment2);
       KNDY4__Assignment__c assignment3 = EdiTestData.createAssignment('OB810_003', 'Exception'); 
       AssignmentsList.add(assignment3);
       KNDY4__Assignment__c assignment4 = EdiTestData.createAssignment('OB810_004', 'Exception'); 
       AssignmentsList.add(assignment4);
       KNDY4__Assignment__c assignment5 = EdiTestData.createAssignment('OB810_005', 'Exception'); 
       AssignmentsList.add(assignment5);
       KNDY4__Assignment__c assignment6 = EdiTestData.createAssignment('OB810_006', 'Exception'); 
       AssignmentsList.add(assignment6);
       KNDY4__Assignment__c assignment7 = EdiTestData.createAssignment('OB810_007', 'Exception'); 
       AssignmentsList.add(assignment7);
       KNDY4__Assignment__c assignment8 = EdiTestData.createAssignment('OB810_008', 'Exception'); 
       AssignmentsList.add(assignment8);
       KNDY4__Assignment__c assignment9 = EdiTestData.createAssignment('OB810_009', 'Exception'); 
       AssignmentsList.add(assignment9);
       KNDY4__Assignment__c assignment10 = EdiTestData.createAssignment('OB810_010', 'Exception'); 
       AssignmentsList.add(assignment10);
       return AssignmentsList;
    }
}