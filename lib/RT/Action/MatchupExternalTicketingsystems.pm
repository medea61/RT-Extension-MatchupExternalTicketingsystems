package RT::Action::MatchupExternalTicketingsystems;
use strict;
use warnings;
use base 'RT::Action';


# only tickets that are unassigned will be automatically assigned.
# RT::Action::AutomaticReassignment overrides this to remove this restriction
sub _PrepareOwner {
    my $self = shift;
    my $Ticket = $self->TicketObj;
    my $Transaction = $self->TransactionObj;
    my $Subject = $Transaction->Subject;

    # grab list of senders to check against subject-regexp
    my @senders = RT->Config->Get('METSKnownSenders');
    # grab list of subject-regexp to match
    my @ticketregexp = RT->Config->Get('METSTicketRegexp');

    # we are only catching new ticket creation here
    return 0 unless $Transaction->Type eq "Create";

    # without a subject there is nothing to match
    return 0 unless defined($subject);

    $RT::Logger->debug("METS - checking for known external ticket ids");

    # mail-addresses from other ticket systems
    #my @ticketsender = ('roman1978', 'support@lung.ch'); #<-- this is an array of addresses or parts of addresses wich are recognized for other ticketsystem-verification.

    my $ticketRequestor = lc($Ticket->RequestorAddresses);

    foreach my $regexp (@ticketregexp) {
        if ( $Subject =~ /($regexp)/) {  #<-- regex-code for other external ticket numbers in message subject 
            $RT::Logger->debug("METS - found known external ticket id");
            foreach (@ticketsender) {
                if ($ticketRequestor =~ /$_/) { #<-- check if sender is permitted
                    $RT::Logger->debug("METS - found external ticket id and permitted sender");
                    return 1;
                }
            }
        }
    }

    return 0;
}

sub Prepare {
    my $self = shift;
    my $Ticket = $self->TicketObj;
    my $Transaction = $self->TransactionObj;
    my $Subject = $Transaction->Subject;

    # grab list of senders to check against subject-regexp
    my $CFFieldId = RT->Config->Get('METSCFFieldID');

    $RT::Logger->debug("METS - about to set custom field with external ticket id");

    my $externalTicketID = "";

    foreach my $regexp (@($ticketregexp)) {
        if ( $Subject =~ /($regexp)/) {  #<-- regex-code for other external ticket numbers in message subject
            $externalTicketID = $Subject;
            $externalTicketID =~ ~/.*($regexp).*/$1/;
        }
    }

    # create CustomField on ticket and write external id to it
    my $cf = RT::CustomField->new ( $RT::SystemUser );
    $cf->Load($CFFieldId); #<-- ID of the custom field from step 1
    $Ticket->AddCustomFieldValue ( Field => $cf, Value => $externalTicketID );

    $RT::Logger->debug("METS - set custom field with external ticket id: " . $externalTicketID);

    return 1;
}

sub Commit {
    my $self = shift;
    my $Ticket = $self->TicketObj;
    my $Transaction = $self->TransactionObj;
    my $Subject = $Transaction->Subject;

    # grab list of senders to check against subject-regexp
    my $CFFieldId = RT->Config->Get('METSCFFieldID');

    $RT::Logger->debug("METS - looking up external ticket id");
    my $externalTicketID = $Ticket->FirstCustomFieldValue($CFFieldId); #<-- load the custom field value
    $RT::Logger->debug("METS - found external ticket id: " . $externalTicketID);

    # find all the ticket to the reference number from ticketsystem 
    my $search = new RT::Tickets(RT->SystemUser);
    $RT::Logger->debug("METS - searching database for tickets matching external id");
    $search->LimitCustomField(CUSTOMFIELD => $CFFieldId, OPERATOR => '=', VALUE => $externalTicketID);

    while (my $foundticket = $search->Next) {
        $RT::Logger->debug("METS - found ticket: " . $foundticket->Id);

        # ignore if finding the new ticket itself
        next if $Ticket->Id == $foundticket->Id;

        # Logging
        $RT::Logger->info("METS - Merging ticket " . $Ticket->Id . " into " . $foundticket->Id . " because of Reference number " . $externalTicketID . " match.");

        # merge Tickets
        $Ticket->MergeInto($foundticket->Id);
    } 

    return 1;
}

1;