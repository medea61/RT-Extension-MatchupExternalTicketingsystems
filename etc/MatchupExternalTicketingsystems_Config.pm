Set($METSCFName, 'External Ticket ID') unless $METSCFName;

Set(@METSKnownSenders, qw(
        tickteystem@example.com
    )) unless @METSKnownSenders;

Set(@METSTicketRegexp, qw(
        TKTS-\d{4}
    )) unless @METSTicketRegex;

1;