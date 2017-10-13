Set(@METSKnownSenders, [qw(
        "tickteystem@example.com"
    )]) unless @METSKnownSenders;

Set(@METSTicketRegexp, [qw(
        "TKTS-\d{4} "
    )]) unless @METSTicketRegex;

Set($METSCFFieldID, 4) unless $METSCFFieldID;

1;