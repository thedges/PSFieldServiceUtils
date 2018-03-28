# PSFieldServiceUtils

This package contains a utility Apex class to manipulate WorkOrders and ServiceAppointments for demo purposes. I will add to the methods available in the PSFieldServiceUtils class over time.

A description of the methods available are:

<b>1. moveAppointments(String sourceDate, String targetDate)</b>

This method will move all Service Appointments scheduled on the source date and move them to the exact times on the target date. This is used in demos where you have created a set of ServiceAppointments to fill up your Gantt chart and need to move them to another day.

Dates are string values in format: mm/dd/yyyy

Usage: Go to Developer Console > Debug > Open Execute Anonymous Window. Run the following in the screen and substitude the date strings as needed:

PSFieldServiceUtils.moveAppointments('03/14/2018', '03/29/2018');

<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>
