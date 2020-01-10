# OneDuty
> OneDuty is a simple lightweight PagerDuty solution for OSX. It operates as a Menubar application that can be opened for queries, or just used in an idle state to display who is on call for your team. In the full application mode, it lets you look up any team schedule at your company and will let you see who is on call for the team on that schedule. You can also select future dates and grab the contact information for who is on call. Using the "Set Default" method lets you display who is on call on the OSX menubar, which also updates daily.


![](https://github.com/cozma/OneDuty/blob/master/Images/od.gif)<br/>
![](https://github.com/cozma/OneDuty/blob/master/Images/OneDutyTouchBarSS.png)

## Setup Requirements

  - OSX 10+
  - XCode 10+

## How To Use

  1. Clone the repo
    `git clone https://github.com/cozma/OneDuty`
  
  2. Add your company schedule identifers in the placeholders
    IE. 
    `var scheduleType = "<INSERT PRIMARY SCHEDULE TYPE>"`

  3. Add your PagerDuty Token in API Call placeholders
    IE. 
    `"Authorization": "Token token=<INSERT PAGERDUTY TOKEN HERE>",`
  
  4. Build Application in XCode

