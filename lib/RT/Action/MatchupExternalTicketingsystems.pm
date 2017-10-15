package RT::Action::MatchupExternalTicketingsystems;

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(reftype);

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
    my $senders = RT->Config->Get('METSKnownSenders');
    $RT::Logger->debug("METS - Senders: " . Dumper($senders));
    
    # grab list of subject-regexp to match
    my $ticketregexp = RT->Config->Get('METSTicketRegexp');
    $RT::Logger->debug("METS - RegExps: " . Dumper($ticketregexp));

    # load CustomField
    my $CustomField = RT::CustomField->new($RT::SystemUser);
    $CustomField->LoadByName( Name => 'External Ticket ID' );

    # we are only catching new ticket creation here
    return 0 unless $Transaction->Type eq "Create";

    # without a subject there is nothing to match
    return 0 unless defined($Subject);

    $RT::Logger->debug("METS - Subject: " . $Subject);
    $RT::Logger->debug("METS - checking for known external ticket ids...");

    my $ticketRequestor = lc($Ticket->RequestorAddresses);

    foreach my $regexp (@${ticketregexp}) {
        $RT::Logger->debug("METS - checking subject for this regexp: " . $regexp);
        
        if ( $Subject =~ /($regexp)/) {
            $RT::Logger->debug("METS - found known external ticket id.");
            $RT::Logger->debug("METS - From: " . $ticketRequestor);
            $RT::Logger->debug("METS - checking for permitted senders...");
            
            foreach my $sender (@${senders}) {
                $RT::Logger->debug("METS - checking sender: " . $sender);
                
                if ($ticketRequestor =~ /$sender/) {
                    $RT::Logger->debug("METS - found external ticket id and permitted sender");


                    $RT::Logger->debug("METS - extracting external ticket id...");
                    my $externalTicketID = $Subject;
                    $externalTicketID =~ s/.*($regexp).*/$1/;
                    $RT::Logger->debug("METS - external ticket id: " . $externalTicketID);

                    $RT::Logger->debug("METS - about to set custom field with external ticket id");
                    # create CustomField on ticket and write external id to it
                    unless (defined($Ticket->FirstCustomFieldValue('External Ticket ID'))) {
                        $Ticket->AddCustomFieldValue ( Field => $CustomField, Value => $externalTicketID );
                        $RT::Logger->debug("METS - set custom field with external ticket id: " . $externalTicketID);
                    }
                    else {
                        $RT::Logger->debug("METS - STRANGE. custom field was previously set with external ticket id: " . $Ticket->FirstCustomFieldValue('External Ticket ID'));
                    }

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
    my $CustomField = RT::CustomField->new($RT::SystemUser);
    $CustomField = $CustomField->LoadByName( Name => 'External Ticket ID' );

    $RT::Logger->debug("METS - looking up external ticket id");
    my $externalTicketID = $Ticket->FirstCustomFieldValue('External Ticket ID');
    $RT::Logger->debug("METS - found external ticket id: " . $externalTicketID);

    # find all the ticket to the reference number from ticketsystem 
    $RT::Logger->debug("METS - searching database for tickets matching external id");
    my $search = new RT::Tickets(RT->SystemUser);
    $search->LimitCustomField(CUSTOMFIELD => 'External Ticket ID', OPERATOR => '=', VALUE => $externalTicketID);

    while (my $foundticket = $search->Next) {
        $RT::Logger->debug("METS - found ticket: " . $foundticket->Id);

        # ignore if finding the new ticket itself
        $RT::Logger->debug("METS - checking if it ourselfs and if so skip, otherwise...");
        next if $Ticket->Id == $foundticket->Id;

        # merge Tickets
        $RT::Logger->info("METS - merging ticket " . $Ticket->Id . " into " . $foundticket->Id . " because of Reference number " . $externalTicketID . " match.");
        $Ticket->MergeInto($foundticket->Id);
    } 

    return 1;
}

1;