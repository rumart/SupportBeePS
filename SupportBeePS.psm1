function Invoke-SBApiRequest {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        $SBCompany,
        [parameter(Mandatory=$true)]
        $Resource,
        $Query,
        $Content,
        $Method = "GET",
        $AuthToken
    )
        $baseUrl = "https://$SBCompany.supportbee.com/"
        
        if(!$AuthToken -and $Resource -ne "tickets" -and $Method -ne "POST"){
            Write-Error ""
        }
        
        if($AuthToken){
            if($query){
                $q = "&" + $Query
            }
            $uri = $baseUrl + $Resource + "?auth_token=$AuthToken" + $Q
        }
        else{
            $uri = $baseUrl + $Resource
        }
        
        $headers = @{
            "Content-Type" = 'application/json';
            "Accept" = 'application/json'
        }

        if($Method -eq "POST"){
            $body = $Content
        }
        
        Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body $body

}

function Get-SBTicket {
    <#
        .SYNOPSIS
            Retrieve SupportBee tickets
        .DESCRIPTION
            The function retrieves tickets from the SupportBee company.

            An Access token is required for this function.
            Access tokens can be found under the Settings > API Token screen
            on your Support Bee site        
        .NOTES
            Info
            Author: Rudi Martinsen / Intility AS and Martin Ehrnst / Intility AS
            Date: 20/01-2018
            Version: 0.1.0
            Revised: 
            Changelog:
        .PARAMETER SupportBeeCompany
            Company name for the SupportBee organization
        .PARAMETER TicketId
            Id of the ticket to retrieve. If omitted all tickets are retrieved
        .PARAMETER UnansweredOnly
            Retrieves only Unanswered tickets
        .PARAMETER AuthToken
            API token for the SupportBee company
        .EXAMPLE
            Get-SBTicket -SupportBeeCompany Company1 -AuthToken $token
            Retrieves all tickets for Company1
    #>
    [cmdletbinding(DefaultParameterSetName="default")]
    param(
        $SupportBeeCompany = "nicdemo",
        [parameter(parametersetname="id")]
        [int]
        $TicketId,
        [parameter(parametersetname="qry")]
        [switch]
        $UnansweredOnly = $false,
        [parameter(Mandatory=$true)]
        $AuthToken
    )
    if ($UnansweredOnly) {
       $qry = "label=unanswered"
    }
    $resource = "tickets"
    if($ticketid){
        $resource += "/$ticketid"
    }
    $response = Invoke-SBApiRequest -Method GET -SBCompany $SupportBeeCompany -Resource $resource -AuthToken $AuthToken -Query $qry
    
    if($response.tickets){
        return $response.tickets
    }
    if($response.ticket){
        return $response.ticket
    }
}

function New-SBTicket {
    <#
        .SYNOPSIS
            Creates a SupportBee ticket
        .DESCRIPTION
            The function creates a ticket for the SupportBee company.
            This function does not require authentication.
        .NOTES
            Info
            Author: Rudi Martinsen / Intility AS and Martin Ehrnst / Intility AS
            Date: 20/01-2018
            Version: 0.1.0
            Revised: 
            Changelog:
        .PARAMETER SupportBeeCompany
            Company name for the SupportBee organization
        .PARAMETER Requester
            Name of the Requester
        .PARAMETER RequesterEmail
            Emailaddress of the Requester
        .PARAMETER Subject
            The subject of the ticket
        .PARAMETER Message
            The message/body of the ticket
        .PARAMETER AuthToken
            API token for the SupportBee company
        .EXAMPLE
            New-SBTicket -SupportBeeCompany Company1 -Requester "Luke Skywalker" -RequesterEmail "luke@skywalker.com" -Subject "Injured hand" -Message "I've injured my hand. Need a new!" -AuthToken $token
            Creates a new SupportBee ticket
    #>
    [cmdletbinding()]
    param(
        $SupportBeeCompany = "nicdemo",
        [parameter(Mandatory=$true)]
        $Requester,
        [parameter(Mandatory=$true)]
        $RequesterEmail,
        [parameter(Mandatory=$true)]
        $Subject,
        [parameter(Mandatory=$true)]
        $Message,
        $AuthToken
    )

    $Content = @{
        ticket = @{
            subject = "$Subject"
            requester_name = "$Requester"
            requester_email = "$RequesterEmail"
            content = @{
                text = "$Message"
            }
        }  
    } | ConvertTo-Json -Depth 3

    Invoke-SBApiRequest -Method "POST" -SBCompany $SupportBeeCompany -Resource "tickets" -Content $Content -AuthToken $AuthToken
}

function Set-SBTicket {
    <#
        .SYNOPSIS
            Alters a SupportBee ticket
        .DESCRIPTION
            The function changes the state of a SupportBee ticket.
            
            An Access token is required for this function.
            Access tokens can be found under the Settings > API Token screen
            on your Support Bee site  
        .NOTES
            Info
            Author: Rudi Martinsen / Intility AS and Martin Ehrnst / Intility AS
            Date: 20/01-2018
            Version: 0.1.0
            Revised: 
            Changelog:
        .PARAMETER SupportBeeCompany
            Company name for the SupportBee organization
        .PARAMETER TicketId
            ID of the ticket to change
        .PARAMETER Ticket
            A ticket object to change
        .PARAMETER Answered
            Alters the "UnAnswered" state of the ticket
        .PARAMETER Archive
            Alters the "Archive" state of the ticket
        .PARAMETER AuthToken
            API token for the SupportBee company
        .EXAMPLE
            Set-SBTicket -SupportBeeCompany Company1 -TicketId 1234567 -Answered -AuthToken $token
            Sets the Unanswered state to FALSE for the given ticket
    #>
    [cmdletbinding(DefaultParametersetname="none")]
    param(
        $SupportBeeCompany = "nicdemo",
        [Parameter(ParameterSetName="id")]
        [int]
        $TicketId,
        [Parameter(ParameterSetName="ticket",ValueFromPipeline=$true)]
        [object]
        $Ticket,
        [switch]
        $Answered = $false,
        [switch]
        $Archive = $false,
        [parameter(Mandatory=$true)]
        $AuthToken
    )

    if($ticketid){
        $ticket = Get-SBTicket -SupportBeeCompany $SupportBeeCompany -Id $ticketid -AuthToken $AuthToken
    }

    if ($ticket) {
        Write-Verbose $ticket
        $ticketid = $ticket.id

        if($ticket.unanswered -and $Answered){
            Invoke-SBApiRequest -Method POST -SBCompany $SupportBeeCompany -Resource "tickets/$ticketid/answered" -AuthToken $AuthToken
        }
        if (!$ticket.archived -and $Archive) {
            Invoke-SBApiRequest -Method POST -SBCompany $SupportBeeCompany -Resource "tickets/$ticketid/archive" -AuthToken $AuthToken
        }
        if (!$ticket.unanswered -and !$Answered) {
            Invoke-SBApiRequest -Method DELETE -SBCompany $SupportBeeCompany -Resource "tickets/$ticketid/answered" -AuthToken $AuthToken
        }
        if($ticket.archived -and !$Archive){
            Invoke-SBApiRequest -Method DELETE -SBCompany $SupportBeeCompany -Resource "tickets/$ticketid/archive" -AuthToken $AuthToken
        }
    }
}

function Get-SBComment {
    <#
        .SYNOPSIS
            Retrieves comments in a SupportBee ticket
        .DESCRIPTION
            The function retrieves all comments in a SupportBee ticket.
            
            An Access token is required for this function.
            Access tokens can be found under the Settings > API Token screen
            on your Support Bee site  
        .NOTES
            Info
            Author: Rudi Martinsen / Intility AS and Martin Ehrnst / Intility AS
            Date: 20/01-2018
            Version: 0.1.0
            Revised: 
            Changelog:
        .PARAMETER SupportBeeCompany
            Company name for the SupportBee organization
        .PARAMETER TicketId
            ID of the ticket to retrieve comments from
        .PARAMETER Ticket
            A ticket object to retrieve comments from
        .PARAMETER AuthToken
            API token for the SupportBee company
        .EXAMPLE
            Get-SBComment -SupportBeeCompany Company1 -TicketId 123456 -AuthToken $token
            Retrieves all comments for the given ticket
    #>
    [cmdletbinding(DefaultParameterSetName="none")]
    param(
        $SupportBeeCompany = "nicdemo",
        [Parameter(ParameterSetName="id")]
        [int]
        $TicketId,
        [Parameter(ParameterSetName="ticket",ValueFromPipeline=$true)]
        [object]
        $Ticket,
        [parameter(Mandatory=$true)]
        $AuthToken
    )

    if($ticket){
        $TicketId = $ticket.id
    }

    $response = Invoke-SBApiRequest -SBCompany $SupportBeeCompany -Resource "tickets/$ticketid/comments" -Method GET -AuthToken $AuthToken
    $response.comments
}

function New-SBComment {
    <#
        .SYNOPSIS
            Adds a comment to a SupportBee ticket
        .DESCRIPTION
            The function adds a new comment to a SupportBee ticket.
            
            An Access token is required for this function.
            Access tokens can be found under the Settings > API Token screen
            on your Support Bee site  
        .NOTES
            Info
            Author: Rudi Martinsen / Intility AS and Martin Ehrnst / Intility AS
            Date: 20/01-2018
            Version: 0.1.0
            Revised: 
            Changelog:
        .PARAMETER SupportBeeCompany
            Company name for the SupportBee organization
        .PARAMETER TicketId
            ID of the ticket to comment
        .PARAMETER Ticket
            A ticket object to comment
        .PARAMETER Comment
            The comment to add to the ticket
        .PARAMETER AuthToken
            API token for the SupportBee company
        .EXAMPLE
            New-SBComment -SupportBeeCompany Company1 -TicketId 123456 -Comment "We need to fix a new hand for Luke" -AuthToken $token
            Adds a comment to the given ticket
    #>
    [cmdletbinding(DefaultParameterSetName="default")]
    param(
        $SupportBeeCompany = "nicdemo",
        [Parameter(ParameterSetName="id")]
        [int]
        $TicketId,
        [Parameter(ParameterSetName="ticket",ValueFromPipeline=$true)]
        [object]
        $Ticket,
        [Parameter(Mandatory=$true)]
        [string]
        $Comment,
        [parameter(Mandatory=$true)]
        $AuthToken
    )

    if($ticket){
        $TicketId = $ticket.id
    }

    $Content = @{
        comment = @{
            content = @{
                text = "$Comment"
            }
        }
    } | ConvertTo-Json -Depth 3

    Invoke-SBApiRequest -SBCompany $SupportBeeCompany -Resource "tickets/$ticketId/comments" -Method "POST" -Content $Content -AuthToken $AuthToken
}

function Get-SBReply {
    <#
        .SYNOPSIS
            Retrieves all Replies to a SupportBee ticket
        .DESCRIPTION
            The function retrieves all Replies to the given SupportBee ticket.
            
            An Access token is required for this function.
            Access tokens can be found under the Settings > API Token screen
            on your Support Bee site  
        .NOTES
            Info
            Author: Rudi Martinsen / Intility AS and Martin Ehrnst / Intility AS
            Date: 20/01-2018
            Version: 0.1.0
            Revised: 
            Changelog:
        .PARAMETER SupportBeeCompany
            Company name for the SupportBee organization
        .PARAMETER TicketId
            ID of the ticket to retrieve replies from
        .PARAMETER Ticket
            A ticket object to retrieve replies from
        .PARAMETER AuthToken
            API token for the SupportBee company
        .EXAMPLE
            Get-SBReply -SupportBeeCompany Company1 -TicketId 123456 -AuthToken $token
            Retrieves all replies for the given ticket
    #>
    [cmdletbinding(DefaultParameterSetName="default")]
    param(
        $SupportBeeCompany = "nicdemo",
        [Parameter(ParameterSetName="id")]
        [int]
        $TicketId,
        [Parameter(ParameterSetName="ticket",ValueFromPipeline=$true)]
        [object]
        $Ticket,
        [parameter(Mandatory=$true)]
        $AuthToken
    )

    if($ticket){
        $TicketId = $ticket.id
    }

    $response = Invoke-SBApiRequest -SBCompany $SupportBeeCompany -Resource "tickets/$ticketid/replies" -Method GET -AuthToken $AuthToken
    $response.replies
}

function New-SBReply {
    <#
        .SYNOPSIS
            Adds a Reply to a SupportBee ticket
        .DESCRIPTION
            The function adds a Reply to the given SupportBee ticket.

            Please note that Replies is not available in the Free tier
            
            An Access token is required for this function.
            Access tokens can be found under the Settings > API Token screen
            on your Support Bee site  
        .NOTES
            Info
            Author: Rudi Martinsen / Intility AS and Martin Ehrnst / Intility AS
            Date: 20/01-2018
            Version: 0.1.0
            Revised: 
            Changelog:
        .PARAMETER SupportBeeCompany
            Company name for the SupportBee organization
        .PARAMETER TicketId
            ID of the ticket to add a reply to
        .PARAMETER Ticket
            A ticket object to add a reply to
        .PARAMETER Reply
            The Reply to add
        .PARAMETER AuthToken
            API token for the SupportBee company
        .EXAMPLE
            New-SBReply -SupportBeeCompany Company1 -TicketId 123456 -Reply "Hi Luke, we will fix your hand!" -AuthToken $token
            Adds a new Reply to the given ticket
    #>
    [cmdletbinding(DefaultParameterSetName="default")]
    param(
        $SupportBeeCompany = "nicdemo",
        [Parameter(ParameterSetName="id")]
        [int]
        $TicketId,
        [Parameter(ParameterSetName="ticket",ValueFromPipeline=$true)]
        [object]
        $Ticket,
        [Parameter(Mandatory=$true)]
        [string]
        $Reply,
        [parameter(Mandatory=$true)]
        $AuthToken
    )

    if($ticket){
        $TicketId = $ticket.id
    }

    $Content = @{
        reply = @{
            content = @{
                text = "$Reply"
            }
        }
    } | ConvertTo-Json -Depth 3

    Invoke-SBApiRequest -SBCompany $SupportBeeCompany -Resource "tickets/$ticketId/replies" -Method "POST" -Content $Content -AuthToken $AuthToken
}

function Get-SBLabel {
    <#
        .SYNOPSIS
            Adds a Label to a SupportBee ticket
        .DESCRIPTION
            The function adds a Label to the given SupportBee ticket.
            The label needs to exist already and currently labels can
            only be created through the Web interface
            
            An Access token is required for this function.
            Access tokens can be found under the Settings > API Token screen
            on your Support Bee site  
        .NOTES
            Info
            Author: Rudi Martinsen / Intility AS and Martin Ehrnst / Intility AS
            Date: 20/01-2018
            Version: 0.1.0
            Revised: 
            Changelog:
        .PARAMETER SupportBeeCompany
            Company name for the SupportBee organization
        .PARAMETER TicketId
            ID of the ticket to add a label to
        .PARAMETER Ticket
            A ticket object to add a label to
        .PARAMETER AuthToken
            API token for the SupportBee company
        .EXAMPLE
            Get-SBLabel -SupportBeeCompany Company1 -TicketId 123456 -AuthToken $token
            Retrieves the labels on the given ticket
    #>
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        $SupportBeeCompany = "nicdemo",
        [parameter(Mandatory=$true)]
        $AuthToken
    )

    $response = Invoke-SBApiRequest -Method GET -SBCompany $SupportBeeCompany -Resource "labels" -AuthToken $AuthToken
    $response.labels
}

function New-SBLabel {
    throw "Sorry! Not supported by the Support Bee API at this time"
}

function Add-SBLabel {
    <#
        .SYNOPSIS
            Adds a Label to a SupportBee ticket
        .DESCRIPTION
            The function adds a Label to the given SupportBee ticket.
            The label needs to exist already and currently labels can
            only be created through the Web interface
            
            An Access token is required for this function.
            Access tokens can be found under the Settings > API Token screen
            on your Support Bee site  
        .NOTES
            Info
            Author: Rudi Martinsen / Intility AS and Martin Ehrnst / Intility AS
            Date: 20/01-2018
            Version: 0.1.0
            Revised: 
            Changelog:
        .PARAMETER SupportBeeCompany
            Company name for the SupportBee organization
        .PARAMETER TicketId
            ID of the ticket to add a label to
        .PARAMETER Ticket
            A ticket object to add a label to
        .PARAMETER Label
            The Label to add
        .PARAMETER AuthToken
            API token for the SupportBee company
        .EXAMPLE
            Add-SBLabel -SupportBeeCompany Company1 -TicketId 123456 -Label CRITICAL -AuthToken $token
            Adds the CRITICAL label to the given ticket
    #>
    [cmdletbinding(DefaultParameterSetName="default")]
    param(
        $SupportBeeCompany = "nicdemo",
        [Parameter(ParameterSetName="id")]
        [int]
        $TicketId,
        [Parameter(ParameterSetName="ticket",ValueFromPipeline=$true)]
        [object]
        $Ticket,
        [Parameter(Mandatory=$true)]
        [string]
        $Label,
        [parameter(Mandatory=$true)]
        $AuthToken
    )

    if($ticket){
        $TicketId = $ticket.id
    }

    Invoke-SBApiRequest -Method POST -SBCompany $SupportBeeCompany -Resource "tickets/$ticketid/labels/$label" -AuthToken $AuthToken

}
