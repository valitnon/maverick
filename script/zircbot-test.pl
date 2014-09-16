#!/usr/bin/env perl

use strict;
use warnings;
use ZIRCBot;

my $bot = ZIRCBot->new;
print $bot->config->{irc}{nick}, "\n";
print $bot->irc->server, "\n";
