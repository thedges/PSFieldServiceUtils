trigger PSWorkOrderTemplateTrigger on WorkOrder (after insert) {
    
    Map<ID, PS_Work_Order_Template__c> templateMap = new Map<ID, PS_Work_Order_Template__c>();
    
    ///////////////////////////////////
    // get list of all work type ids //
    ///////////////////////////////////
    List<Id> workTypeIdList = new List<Id>();
    List<Id> woIdList = new List<Id>();
    List<Id> assetIdList = new List<Id>();
    for (WorkOrder wo : Trigger.new)
    {
        woIdList.add(wo.Id);
        if (wo.WorkTypeId != null) workTypeIdList.add(wo.WorkTypeId);
        if (wo.AssetId != null) assetIdList.add(wo.AssetId);
    }
    
    
    List<Id> woTempIdList = new List<Id>();
    if (workTypeIdList.size() > 0)
    {
        ////////////////////////////////////////  
        // get map of all work type templates //
        ////////////////////////////////////////  
        List<ID> kaIdList = new List<ID>();
        Map<ID, KnowledgeArticleVersion> kaMap = new Map<ID, KnowledgeArticleVersion>();
        for (PS_Work_Order_Template__c tmp : [SELECT ID, Work_Type__c, 
                                              (SELECT Id, Name, Order__c, Knowledge_ID__c FROM KA_Templates__r ORDER BY Order__c ASC), 
                                              (SELECT Id, Name, Order__c, Subject__c, Description__c, Copy_WO_Address__c FROM WOLI_Templates__r ORDER BY Order__c ASC) 
                                              FROM PS_Work_Order_Template__c 
                                              WHERE Work_Type__c IN :workTypeIdList])
        {
            //System.debug(JSON.serializePretty(tmp));
            woTempIdList.add(tmp.Id);
            templateMap.put(tmp.Work_Type__c, tmp);
            
            if (tmp.KA_Templates__r != null)
            {
                for (PS_KA_Template__c kaTmp : tmp.KA_Templates__r)
                { 
                    kaIdList.add(kaTmp.Knowledge_ID__c);
                }
            }
        }
        
        /////////////////////////////////  
        // retrieve knowledge articles //
        /////////////////////////////////
        List<Id> kaVerIdList = new List<Id>();
        Map<ID, ID> tmpKAMap = new Map<ID, ID>();
        Map<ID, KnowledgeArticleVersion> kaVerMap = new Map<ID, KnowledgeArticleVersion>();
        if (kaIdList.size() > 0)
        {
            for (Knowledge__kav k : [SELECT Id, KnowledgeArticleId FROM Knowledge__kav WHERE IsLatestVersion = true AND Id IN :kaIdList])
            {
                kaVerIdList.add(k.KnowledgeArticleId);
                tmpKAMap.put(k.KnowledgeArticleId, k.Id);
            }
        }
        
        if (kaVerIdList.size() > 0)
        {
            for (KnowledgeArticleVersion ver : [SELECT Id, Title, KnowledgeArticleId FROM KnowledgeArticleVersion WHERE IsLatestVersion = true AND KnowledgeArticleId IN :kaVerIdList AND PublishStatus = 'Online'])
            {
                kaVerMap.put(tmpKAMap.get(ver.KnowledgeArticleId), ver);
            }
        }
        
        ///////////////////////////////////////////////////////////  
        // loop through all new WorkOrders and add template info //
        ///////////////////////////////////////////////////////////  
        List<WorkOrderLineItem> woliList = new List<WorkOrderLineItem>();
        List<LinkedArticle> linkArticleList = new List<LinkedArticle>();  
        for (WorkOrder wo : Trigger.new)
        {
            if (templateMap.containsKey(wo.WorkTypeId))
            {
                PS_Work_Order_Template__c tmp = (PS_Work_Order_Template__c)templateMap.get(wo.WorkTypeId);
                System.debug(JSON.serializePretty(tmp));
                
                //////////////////
                // create WOLIs //
                //////////////////
                if (tmp.WOLI_Templates__r != null)
                {
                    for (PS_WOLI_Template__c woliTmp : tmp.WOLI_Templates__r)
                    {
                        WorkOrderLineItem woli = new WorkOrderLineItem();
                        woli.WorkOrderId = wo.Id;
                        woli.Subject = woliTmp.Subject__c;
                        woli.Description = woliTmp.Description__c;
                        woliList.add(woli);
                    }
                }
                
                ////////////////
                // create KAs //
                ////////////////
                if (tmp.KA_Templates__r != null)
                {
                    for (PS_KA_Template__c kaTmp : tmp.KA_Templates__r)
                    {
                        if (kaVerMap.containsKey(kaTmp.Knowledge_ID__c))
                        {
                            KnowledgeArticleVersion kaVer = kaVerMap.get(kaTmp.Knowledge_ID__c);
                            
                            LinkedArticle la = new LinkedArticle();
                            la.KnowledgeArticleId = kaVer.KnowledgeArticleId;
                            la.KnowledgeArticleVersionId = kaVer.Id;
                            la.LinkedEntityId = wo.Id;
                            la.Name = kaVer.Title;
                            linkArticleList.add(la);
                        }
                    }
                }
                
            }
        }
        
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////  
        // create ContentDocumentLinks to WorkOrder for all content documents attached to work order template //
        ////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (woTempIdList != null && woTempIdList.size() > 0)
        {
            List<Id> attachFileIdList = new List<Id>();
            Map<Id, List<Id>> cdlMap = new Map<Id, List<Id>>();
            for (ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :woTempIdList])
            {
                if (cdlMap.containsKey(cdl.LinkedEntityId))
                {
                    List<Id> tmpIdList = (List<Id>)cdlMap.get(cdl.LinkedEntityId);
                    tmpIdList.add(cdl.ContentDocumentId);
                }
                else
                {
                    List<Id> tmpIdList = new List<Id>();
                    tmpIdList.add(cdl.ContentDocumentId);
                    cdlMap.put(cdl.LinkedEntityId, tmpIdList);
                }
            }
            
            for (WorkOrder wo : Trigger.new)
            {
                if (templateMap.containsKey(wo.WorkTypeId))
                {
                    PS_Work_Order_Template__c t = (PS_Work_Order_Template__c)templateMap.get(wo.WorkTypeId);
                    if (cdlMap.containsKey(t.Id))
                    {
                        List<Id> docIdList = (List<Id>)cdlMap.get(t.Id);
                        
                        if (docIdList != null)
                        {
                            for (Id docId : docIdList)
                            {
                                ContentDocumentLink cdlNew = new ContentDocumentLink();
                                cdlNew.LinkedEntityId = wo.Id;
                                cdlNew.ContentDocumentId = docId;
                                cdlNew.ShareType = 'V';
                                cdlNew.Visibility = 'InternalUsers';
                                cdlList.add(cdlNew);
                            }
                        }
                    }
                }
            }
        }
        
        //////////////////////////////////////////////////////////////////////////////////////////  
        // create ContentDocumentLinks to WorkOrder for all content documents attached to asset //
        //////////////////////////////////////////////////////////////////////////////////////////
        if (assetIdList != null && assetIdList.size() > 0)
        {
            List<Id> attachFileIdList = new List<Id>();
            Map<Id, List<Id>> cdlMap = new Map<Id, List<Id>>();
            for (ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :assetIdList])
            {
                if (cdlMap.containsKey(cdl.LinkedEntityId))
                {
                    List<Id> tmpIdList = (List<Id>)cdlMap.get(cdl.LinkedEntityId);
                    tmpIdList.add(cdl.ContentDocumentId);
                }
                else
                {
                    List<Id> tmpIdList = new List<Id>();
                    tmpIdList.add(cdl.ContentDocumentId);
                    cdlMap.put(cdl.LinkedEntityId, tmpIdList);
                }
            }
            
            for (WorkOrder wo : Trigger.new)
            {
                if (wo.AssetId != null && cdlMap.containsKey(wo.AssetId))
                {
                    List<Id> docIdList = (List<Id>)cdlMap.get(wo.AssetId);
                    
                    if (docIdList != null)
                    {
                        for (Id docId : docIdList)
                        {
                            ContentDocumentLink cdlNew = new ContentDocumentLink();
                            cdlNew.LinkedEntityId = wo.Id;
                            cdlNew.ContentDocumentId = docId;
                            cdlNew.ShareType = 'V';
                            cdlNew.Visibility = 'InternalUsers';
                            cdlList.add(cdlNew);
                        }
                    }
                }
                
            }
        }
        
        
        
        if (woliList.size() > 0) insert woliList;
        if (linkArticleList.size() > 0) insert linkArticleList;
        if (cdlList.size() > 0) insert cdlList;
    }
    
}