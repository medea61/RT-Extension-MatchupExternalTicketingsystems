package RT::Action::MatchupExternalTicketingsystems;

use strict;
use warnings;

use base 'RT::Action';

sub Describe {
    my $self = shift;
    return ( ref $self );
}

sub Prepare {
    my $self = shift;
    my $Ticket = $self->TicketObj;
    my $Transaction = $self->TransactionObj;
    my $Subject = $Transaction->Subject;

    # grab list of senders to check against subject-regexp
    my @senders = RT->Config->Get('METSKnownSenders');
    
    # grab list of subject-regexp to match
    my @ticketregexp = RT->Config->Get('METSTicketRegexp');

    # lookup CustomField ID
    my $CustomField = RT::CustomField->LoadByName( Name => 'External Ticket ID' );
    my $CustomFieldId = $CustomField->id;

    # we are only catching new ticket creation here
    return 0 unless $Transaction->Type eq "Create";

    # without a subject there is nothing to match
    return 0 unless defined($Subject);

    $RT::Logger->debug("METS - checking for known external ticket ids");

    my $ticketRequestor = lc($Ticket->RequestorAddresses);

    foreach my $regexp (@ticketregexp) {
        if ( $Subject =~ /($regexp)/) {
            $RT::Logger->debug("METS - found known external ticket id");
            foreach (@senders) {
                if ($ticketRequestor =~ /$_/) {
                    $RT::Logger->debug("METS - found external ticket id and permitted sender");

                    $RT::Logger->debug("METS - about to set custom field with external ticket id");
                    my $externalTicketID = $Subject;
                    $externalTicketID =~ s/.*($regexp).*/$1/;

                    # create CustomField on ticket and write external id to it
                    my $cf = RT::CustomField->new ( $RT::SystemUser );
                    $cf->Load($CustomFieldId);
                    $Ticket->AddCustomFieldValue ( Field => $cf, Value => $externalTicketID );

                    $RT::Logger->debug("METS - set custom field with external ticket id: " . $externalTicketID);
                    return 1;
                }
            }
        }
    }

    return 0;
}

sub Commit {
    my $self = shift;
    my $Ticket = $self->TicketObj;
    my $Transaction = $self->TransactionObj;
    my $Subject = $Transaction->Subject;

    # lookup CustomField ID
    my $CustomField = RT::CustomField->LoadByName( Name => 'External Ticket ID' );
    my $CustomFieldId = $CustomField->id;

    $RT::Logger->debug("METS - looking up external ticket id");
    my $externalTicketID = $Ticket->FirstCustomFieldValue($CustomFieldId);
    $RT::Logger->debug("METS - found external ticket id: " . $externalTicketID);

    # find all the ticket to the reference number from ticketsystem 
    $RT::Logger->debug("METS - searching database for tickets matching external id");
    my $search = new RT::Tickets(RT->SystemUser);
    $search->LimitCustomField(CUSTOMFIELD => $CustomFieldId, OPERATOR => '=', VALUE => $externalTicketID);

    while (my $foundticket = $search->Next) {
        $RT::Logger->debug("METS - found ticket: " . $foundticket->Id);

        # ignore if finding the new ticket itself
        next if $Ticket->Id == $foundticket->Id;

        # merge Tickets
        $RT::Logger->info("METS - Merging ticket " . $Ticket->Id . " into " . $foundticket->Id . " because of Reference number " . $externalTicketID . " match.");
        $Ticket->MergeInto($foundticket->Id);
    } 

    return 1;
}

1;