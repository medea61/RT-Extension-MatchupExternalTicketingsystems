# RT-Extension-MatchupExternalTicketingsystems
Matchup ticket ids of external systems automatically with RT Tickets

# DESCRIPTION
This module is designed for *Request Tracker 4*.
Sometimes 3rd-parties just do not want or are not able to or are just not 
willing keep the RT ticket marker in the subject. But they still keep their
own ticket id in the subject. Cue in: this extension... :)

# RT VERSION
Works with RT 4.4.2

# INSTALLATION
    perl Makefile.PL
    make
    make install

May need root permissions

Edit your /opt/rt4/etc/RT_SiteConfig.pm
If you are using RT 4.2 or greater, add this line:

	Plugin('RT::Extension::MatchupExternalTicketingsystems');

For RT 4.0, add this line:

	Set(@Plugins, qw(RT::Extension::MatchupExternalTicketingsystems));

Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj


Restart your webserver

# CONFIGURATION
Edit your /opt/rt4/etc/RT_SiteConfig.pm to include these config values:

    Set(@METSKnownSenders, 'tickteystem@example.com');
    Set(@METSTicketRegexp, 'TKTS-\d{4} ');
    Set($METSCFFieldID, 4);

# USE
Create a Scrip in the queue which you want this extension to work in.

* Condition 'On Create'
* Action 'Matchup External Ticketingsystems'
* Template 'Blank'

# AUTHORS
Roman Hochuli

# LICENSE AND COPYRIGHT
The MIT License (MIT)

Copyright (c) 2017 Roman Hochuli

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

