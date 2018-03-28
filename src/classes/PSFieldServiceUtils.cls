public class PSFieldServiceUtils {
    
  public static void moveAppointments(String sourceDate, String targetDate)
  {
      // format should be 'MM/DD/YYYY'
      moveAppointments(Date.parse(sourceDate), Date.parse(targetDate));
  }
  
  public static void moveAppointments(Date sourceDate, Date targetDate)
  {
      DateTime startDttm = DateTime.newInstance(sourceDate, Time.newInstance(0, 0, 0, 0));
      DateTime endDttm = DateTime.newInstance(sourceDate, Time.newInstance(23, 59, 59, 0));
      
      Integer daysDiff = sourceDate.daysBetween(targetDate);
      
      ////////////////////////////////////////////////////////////////////////
      // get list of all Service Appointments scheduled for the source date //
      ////////////////////////////////////////////////////////////////////////
      List<Id> woIdList = new List<Id>();
      List<ServiceAppointment> saList = [SELECT Id, SchedStartTime, SchedEndTime, ActualStartTime, ActualEndTime, 
                                                ArrivalWindowStartTime , ArrivalWindowEndTime, EarliestStartTime, DueDate,
                                                ParentRecordType, ParentRecordId
                                           FROM ServiceAppointment 
                                          WHERE SchedStartTime >= :startDttm AND
                                                SchedEndTime <= :endDttm
                                          ];
      //System.debug('saListOrig=' + JSON.serializePretty(saList));
      
      //////////////////////////////////////////////////////////
      // shift all Date/Time fields by the difference in days //
      //////////////////////////////////////////////////////////
      for (ServiceAppointment sa : saList)
      {
          if (sa.SchedStartTime != null) sa.SchedStartTime = sa.SchedStartTime.addDays(daysDiff);
          if (sa.SchedEndTime != null) sa.SchedEndTime = sa.SchedEndTime.addDays(daysDiff);
          if (sa.ActualStartTime != null) sa.ActualStartTime = sa.ActualStartTime.addDays(daysDiff);
          if (sa.ActualEndTime != null) sa.ActualEndTime = sa.ActualEndTime.addDays(daysDiff);
          if (sa.ArrivalWindowStartTime != null) sa.ArrivalWindowStartTime = sa.ArrivalWindowStartTime.addDays(daysDiff);
          if (sa.ArrivalWindowEndTime != null) sa.ArrivalWindowEndTime = sa.ArrivalWindowEndTime.addDays(daysDiff);
          if (sa.EarliestStartTime != null) sa.EarliestStartTime = sa.EarliestStartTime.addDays(daysDiff);
          if (sa.DueDate != null) sa.DueDate = sa.DueDate.addDays(daysDiff);
          
          if (sa.ParentRecordType == 'WorkOrder') woIdList.add(sa.ParentRecordId);
      }
      //System.debug('saListUpdate=' + JSON.serializePretty(saList));

      ////////////////////////////////////////////////////////////////////      
      // shift all WorkOrder Date/Time fields by the difference in days //
      ////////////////////////////////////////////////////////////////////      
      List<WorkOrder> woList = new List<WorkOrder>();
      for (WorkOrder wo : [SELECT Id, StartDate, EndDate FROM WorkOrder WHERE ID IN :woIdList])
      {
         if (wo.StartDate != null || wo.EndDate != null)
         {
           if (wo.StartDate != null) wo.StartDate = wo.StartDate.addDays(daysDiff);
           if (wo.EndDate != null) wo.EndDate = wo.EndDate.addDays(daysDiff);
           woList.add(wo);
         }
      }
      //System.debug('woListUpdate=' + JSON.serializePretty(woList));
      
      ///////////////////////////////////////////////////////
      // update the ServiceAppoints and related WorkOrders //
      ///////////////////////////////////////////////////////
      if (saList != null && saList.size() > 0) update saList;
      if (woList != null && woList.size() > 0) update woList;
      
  }
    
  public static void test()
  {
      PSFieldServiceUtils.moveAppointments('03/14/2018', '03/29/2018');
  }
}