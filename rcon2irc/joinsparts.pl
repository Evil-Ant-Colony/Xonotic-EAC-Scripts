# Xonotic rcon2irc plugin by Merlijn Hofstra licensed under GPL - joinsparts.pl
# Place this file inside the same directory as rcon2irc.pl and add the full filename to the plugins.
# Don't forget to edit the options below to suit your needs.

{ my %pj = (
	irc_announce_joins => 1,
	irc_announce_parts => 1,
	irc_show_playerip => 0,
	irc_show_statusnumber => 0,
	irc_show_mapname => 1,
	irc_show_amount_of_players => 1,
	irc_show_country => 1,
	check_clones => 1
);

# current code has been tested against version 0.8 of the Geo::IPfree module
# You can obtain a copy here: http://search.cpan.org/~bricas/Geo-IPfree-0.8/lib/Geo/IPfree.pm
# Place the 'Geo' dir in the same directory as this plugin or anywhere in @INC.
if ($pj{irc_show_country}) {
	eval { 
		require Geo::IPfree;
		$pj{geo} = Geo::IPfree->new;
		$pj{geo}->Faster; # Due to a relatively large amount of lookups, this is probably a good idea 
	} or die "joinsparts.pl: requested countrynames, but can't load data, $@";
} 

$store{plugin_joinsparts} = \%pj; }

sub out($$@);

sub get_player_count
{
	my ($real_active, $real_spect) = count_players();
	return $real_active+$real_spect;
}
# Catch joins and display requested info
[ dp => q{:join:(\d+):(\d+):([^:]*):(.*)} => sub {
	my ($id, $slot, $ip, $nick) = @_;
	my $pj = $store{plugin_joinsparts};
	$pj->{alive_check}->[$slot] = 1;
	
	return 0 if ($ip eq 'bot');
	
	my (undef,$cn) = $pj->{geo}->LookUp($ip) if ($pj->{irc_show_country});
	
	my $clonenicks;
	if ($pj->{check_clones}) {
		for (1 .. $store{slots_max}) {
			my $plrid = $store{"playerid_byslot_$_"};
			next if (!defined $plrid || $plrid == $id || $ip ne $store{"playerip_byid_$plrid"});
			$clonenicks .= ' ' . $store{"playernick_byid_$plrid"} . "\017";
		}
	}
	
	$nick = color_dp2irc $nick;
	if ($pj->{irc_announce_joins} && !$store{"playerid_byslot_$slot"}) {
		out irc => 0, "PRIVMSG $config{irc_channel} :\00309+ join\017: $nick\017" . 
			($pj->{irc_show_playerip} ? " (\00304$ip\017)" : '') .
			($pj->{irc_show_country} && $cn ? " - \00302$cn\017" : '') .
			($pj->{irc_show_statusnumber} ? " #\00304$slot\017" : '') .
			($clonenicks ? " Clone of:$clonenicks" : '') .
			($pj->{irc_show_mapname} ? " \00304$store{map}\017" : '') .
			($pj->{irc_show_amount_of_players} ? " [\00304" . (get_player_count()+1) . "\017/$store{slots_max}]" : '');
	}
	return 0;
} ],

# Record parts so the info in $store is always up to date
[ dp => q{:part:(\d+)} => sub {
	my ($id) = @_;
	my $pj = $store{plugin_joinsparts};
	
	my $ip = $store{"playerip_byid_$id"};
	my (undef,$cn) = $pj->{geo}->LookUp($ip) if ($pj->{irc_show_country} && $ip && $ip ne 'bot');
	
	if ($pj->{irc_announce_parts} && defined $store{"playernick_byid_$id"} && $store{"playerip_byid_$id"} ne 'bot') {
		out irc => 0, "PRIVMSG $config{irc_channel} :\00304- part\017: " . $store{"playernick_byid_$id"} . "\017" . 
			($pj->{irc_show_playerip} ? " (\00304$ip\017)" : '') .
			($pj->{irc_show_country} && $cn ? " - \00302$cn\017": '') .
			($pj->{irc_show_mapname} ? " \00304$store{map}\017" : '') .
			($pj->{irc_show_amount_of_players} ? " [\00304" . (get_player_count()-1) . "\017/$store{slots_max}]" : '');
	}
	my $slot = $store{"playerslot_byid_$id"};
	$store{"playernickraw_byid_$id"} = undef;
	$store{"playernick_byid_$id"} = undef;
	$store{"playerip_byid_$id"} = undef;
	$store{"playerslot_byid_$id"} = undef;
	$store{"playerid_byslot_$slot"} = undef;
	return 0;
} ],

# Add some functionality that should clear 'ghost' clients that disconnect at unfortunate times
[ dp => q{:end} => sub {
	return 0 unless (time() - $store{map_starttime} > 180); # make sure the map has been played at least 3 minutes
	
	my $pj = $store{plugin_joinsparts};
	for (1 .. $store{slots_max}) {
		if ($store{"playerid_byslot_$_"} && !$pj->{alive_check}->[$_]) {
			my $id = $store{"playerid_byslot_$_"};
			$store{"playernickraw_byid_$id"} = undef;
			$store{"playernick_byid_$id"} = undef;
			$store{"playerip_byid_$id"} = undef;
			$store{"playerslot_byid_$id"} = undef;
			$store{"playerid_byslot_$_"} = undef;
		}
	}
	$pj->{alive_check} = ();
	
	return 0;
} ],
