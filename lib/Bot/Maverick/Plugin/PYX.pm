package Bot::Maverick::Plugin::PYX;

use Mojo::URL;

use Moo;
with 'Bot::Maverick::Plugin';

our $VERSION = '0.50';

use constant PYX_ENDPOINT_MISSING =>
	"PYX plugin requires configuration option 'pyx_endpoint' in section 'apis'\n";
use constant PYX_MAX_PICK => 3;
use constant PYX_MAX_COUNT => 10;

sub register {
	my ($self, $bot) = @_;
	my $endpoint = $bot->config->param('apis','pyx_endpoint');
	die PYX_ENDPOINT_MISSING unless defined $endpoint;
	
	$bot->add_command(
		name => 'pyx',
		help_text => 'Generate random Cards Against Humanity matches',
		usage_text => '[<pick count>|<black card> [<pick count>]|w <white card> ...]',
		on_run => sub {
			my $m = shift;
			my $args = $m->args;
			
			my ($black_card_text, $white_cards, $black_card_pick, $white_card_count);
			$white_cards = [];
			if (length $args) {
				if ($args =~ m/^w\s/i) {
					@$white_cards = $args =~ m/w\s+(.+?)(?=(?:\s+w\s|$))/ig;
					undef $_ for grep { m/^[?_]+$/ } @$white_cards;
					splice @$white_cards, PYX_MAX_PICK if @$white_cards > PYX_MAX_PICK;
					$black_card_pick = @$white_cards;
					$white_card_count = grep { !defined } @$white_cards;
				} elsif ($args =~ m/^\d+$/) {
					$black_card_pick = $args;
				} elsif ($args =~ m/^(.+?)\s+(\d+)$/) {
					$black_card_text = $1;
					$white_card_count = $2;
				} else {
					$black_card_text = $args;
					$white_card_count =()= $args =~ m/__+/g;
				}
			}
			
			my $future;
			if (defined $black_card_text) {
				$white_card_count = 1 if $white_card_count < 1;
				$future = $m->bot->new_future->done({ text => $black_card_text, pick => $white_card_count });
			} else {
				$future = _get_black_card($m, $black_card_pick);
			}
			return $future->then(sub {
				my $card = shift;
				$white_card_count //= $card->{pick} // 1;
				if ($white_card_count > 0) {
					return _get_white_cards($m, $white_card_count)->transform(done => sub {
						my $cards = shift;
						if (@$white_cards) {
							$_ //= shift @$cards for @$white_cards;
						} else {
							$white_cards = $cards;
						}
						return ($card->{text}, $white_cards);
					});
				} else {
					return $m->bot->new_future->done($card->{text}, $white_cards);
				}
			})->on_done(sub { _show_pyx_match($m, @_) })
				->on_fail(sub { $m->reply("Error retrieving PYX cards: $_[0]") });
		},
	);
}

sub _get_black_card {
	my ($m, $pick) = @_;
	if (defined $pick) {
		$pick = 1 if $pick < 1;
		$pick = PYX_MAX_PICK if $pick > PYX_MAX_PICK;
	}
	
	my $endpoint = $m->config->param('apis','pyx_endpoint');
	die PYX_ENDPOINT_MISSING unless defined $endpoint;
	my $card_sets = $m->config->param('apis','pyx_card_sets');
	my @card_sets = defined $card_sets ? split ' ', $card_sets : ();
	
	my $url = Mojo::URL->new($endpoint)->path('black/rand');
	$url->query({card_set => \@card_sets}) if @card_sets;
	$url->query({pick => $pick}) if defined $pick;
	
	return $m->bot->ua_request($url)->then(sub {
		my $res = shift;
		my $card = $res->json->{card};
		return $m->bot->new_future->fail('No applicable black cards') unless defined $card and defined $card->{text};
		$card->{text} = _format_pyx_card($card->{text});
		return $m->bot->new_future->done($card);
	});
}

sub _get_white_cards {
	my ($m, $count) = @_;
	$count //= 1;
	$count = 1 if $count < 1;
	$count = PYX_MAX_COUNT if $count > PYX_MAX_COUNT;
	
	my $endpoint = $m->config->param('apis','pyx_endpoint');
	die PYX_ENDPOINT_MISSING unless defined $endpoint;
	my $card_sets = $m->config->param('apis','pyx_card_sets');
	my @card_sets = defined $card_sets ? split ' ', $card_sets : ();
	
	my $url = Mojo::URL->new($endpoint)->path('white/rand');
	$url->query({card_set => \@card_sets}) if @card_sets;
	$url->query({count => $count});
	
	return $m->bot->ua_request($url)->transform(done => sub {
		my $res = shift;
		my $cards = $res->json->{cards} // [];
		$_ = _format_pyx_card($_->{text}) for @$cards;
		return $cards;
	});
}

sub _show_pyx_match {
	my ($m, $black_card, $white_cards) = @_;
	$black_card //= '';
	$white_cards //= [];
	
	my $u_code = chr hex '0x1f';
	foreach my $white_card (@$white_cards) {
		my $formatted = "_${u_code}$white_card${u_code}_";
		unless ($black_card =~ s/__+/$formatted/) {
			$black_card = "$black_card $formatted";
		}
	}
	
	$m->reply_bare("PYX Match: $black_card");
}

sub _format_pyx_card {
	my $text = shift // return undef;
	my $b_code = chr 2;
	$text =~ s!</?i>!/!g;
	$text =~ s!</?b>!$b_code!g;
	$text =~ s!</?u>!_!g;
	$text =~ s!<.*?>!!g;
	$text =~ s!\r?\n! !g;
	return $text;
}

1;

=head1 NAME

Bot::Maverick::Plugin::PYX - Pretend You're Xyzzy plugin for Maverick

=head1 SYNOPSIS

 my $bot = Bot::Maverick->new(
   plugins => { PYX => 1 },
 );

=head1 DESCRIPTION

Adds C<pyx> command for forming random Cards Against Humanity combinations to a
L<Bot::Maverick> IRC bot.

This plugin requires access to a REST interface to pick random cards, as
implemented by L<cah-cards|https://github.com/Grinnz/cah-cards>. The URL
endpoint must be set with the configuration option C<pyx_endpoint> in section
C<apis>.

=head1 COMMANDS

=head2 pyx

 !pyx
 !pyx __ and __: A perfect match.
 !pyx w A giant snail. w Doritos.
 !pyx 3
 !pyx Write a haiku. 3

Generate random Cards Against Humanity combinations, using the supplied black
card or white card(s) if any. Blanks in black cards are specified as two or
more consecutive underscores, and white cards are prefixed by the lone letter
C<w>. White cards that consist only of underscores or question marks will
additionally be replaced by random cards. If only an integer is specified, or
it is specified after black card text, it will be used as the number of white
cards to retrieve.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Bot::Maverick>
