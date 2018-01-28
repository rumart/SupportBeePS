# SupportBeePS

A Powershell module wrapping the SupportBee ticketing API, https://supportbee.com/

This module was created for use in the Invoke-{your}RestMethod session at NIC 2018.

The SupportBee API supports several actions on your tickets, all documented here https://developers.supportbee.com/api

Note that most of the API calls and also the functions in this module requires an access token which needs to be retrieved from your SupportBee web portal.
If you don't want to have to add the token to every command you could easily adopt the functions to use a global variable or an environmental variable.

In this release the module supports the following functions:

- *Get-SBTicket*
- *New-SBTicket*
- *Set-SBTicket*
- *Get-SBComment*
- *New-SBComment*
- *Get-SBReply*
- *New-SBReply*
- *Get-SBLabel*
- *Add-SBLabel*
