use inc::Module::Install;

RTx     'RT-Extension-MatchupExternalTicketingsystems';
license 'mit';
repository 'https://github.com/medea61/rt-extension-matchupexternalticketingsystems';

requires_rt '4.0.0';
rt_too_new '4.4.5';

sign;
WriteAll;
