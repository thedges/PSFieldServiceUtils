# PSFieldServiceUtils

This package contains a set of utilities for Field Service Lightning demos. The primary pieces of this repo are:

  1. <b>Apex Utility Class</b> - to include miscellaneous functions for variety of purposes
  2. <b>WorkOrder Template Engine</b> - config approach for generating standard WOLIs, knowledge articles and File attachments when new work orders are created

__Apex Utility Class__

First is utility Apex class to manipulate WorkOrders and ServiceAppointments for demo purposes. I will add to the methods available in the PSFieldServiceUtils class over time.

A description of the methods available are:

<b>1. moveAppointments(String sourceDate, String targetDate)</b>

This method will move all Service Appointments scheduled on the source date and move them to the exact times on the target date. This is used in demos where you have created a set of ServiceAppointments to fill up your Gantt chart and need to move them to another day.

Dates are string values in format: mm/dd/yyyy

<b>Usage:</b> Go to <b>Developer Console > Debug > Open Execute Anonymous Window</b>. Run the following command and substitute the date strings as needed:

<b><i>PSFieldServiceUtils.moveAppointments('03/14/2018', '03/29/2018');</i></b>

![alt text](https://github.com/thedges/PSFieldServiceUtils/blob/master/MoveAppointments.gif "Move Appointments")

__WorkOrder Template Engine__

This engine is implemented with the following:

  1. <b>PSWorkOrderTemplateTrigger</b> - the Apex trigger that will run when new WorkOrders are created. Based on the WorkType referenced in the WorkOrder, it will lookup the PS_Work_Order_Template__c record of that WorkType and apply the template configuration. Any child WOLIs defined in the template automatically get created on new WorkOrder, any child Knowledge articles defined in template get automatic share link created in the WorkOrder, and any file attached to the template get automatic share link created in the WorkOrder. Also if you have any file attachments added to assets that you reference in the WorkOrder, the trigger will create a share link to that document and associate to WorkOrder.
  2. <b>PS_Work_Order_Template__c</b> - this is the base object to create a record to define your template. Just reference a WorkType and it will get applied to new WorkOrders.
  3. <b>PS_WOLI_Template__c</b> - child object of template where you define WOLIs for your new WorkOrders
  4. <b>PS_KA_Template__c</b> - child object of template where you define which Knowledge Articles to attach to your new WorkOrders. Right now you have to get the knowledge article number (not the record id) and add it since Lookup field to Knowledge Articles is not supported by Salesforce at this time.

Here is recording of demo using the template engine. The demo shows:
  1. The configuration of a Work Order template
  2. Creation of new Work Order and the template being applied
  3. Showing referencing the WOLIs, knowledge articles and file attachments on FSL mobile app
  
![alt text](https://github.com/thedges/PSFieldServiceUtils/blob/master/WorkOrderTemplateEngine.gif "WorkOrderTemplateEngine") 

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>
