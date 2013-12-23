# Use this to prevent IRC flood
use Time::HiRes qw/usleep/;

# Nicer color (Replace yellow with dark yellow/orange to improve readability)
our @color_dp2irc_table = (-1, 4, 9, 7, 12, 11, 13, -1, -1, -1); 

# Admins, will be notified on !admin
my @admin_highlighs=('Melanosuchus', 'Floris', 'KproxaPy', 'Cesy', 'IRC-Love');

# Prevent flooding
# @param $1 an integer value, increase it for multiple calls to this
sub flood_sleep
{
	usleep($1*100000);
}

# Prettify gametype and map name
my %gametypes = (
	"dm" => "deathmatch",
	"tdm" => "team deathmatch",
	"duel" => "duel",
	"ft" => "freezetag",
	"ctf" => "capture the flag",
	"inf" => "infection",
);

sub map_n_gametype
{
	my $game = "?";
	my $map = "?";
	if ( $store{map} =~ /([^_]+)_(.*)/ )
	{
		$game=$1;
		$map=$2;
		if ( exists($gametypes{$game}) )
		{
			$game=$gametypes{$game};
		}
	}
#	out irc => 1, "PRIVMSG $config{irc_channel} : Test ($map,$game,$store{map})";
	return ($map,$game);
}

# Cvars that may be usueful to show on status
my $g_nades = 1;

# Request cvar updates
sub update_cvars {
	out dp => 1, "rcon2irc_eval g_nades";
}

# Show player status
# @param $1 output channel
# @param $2 regex to match player name, empty string will match all players
sub player_status
{
	my ($chan,$match) = @_;
	
	my $found = 0;
	my $foundany = 0;
	for my $slot(@{$store{playerslots_active} || []})
	{
		my $s = $store{"playerslot_$slot"};
		next unless $s;
		if(not defined $match or $match eq "" or color_dp2none($s->{name}) =~ /$match/i )
		{
			if ( !$found )
			{
				out irc => 1, sprintf 'PRIVMSG %s :'."\002".'%-21s %2s %4s %5s %-4s %s'."\017", $chan, "ip address", "pl", "ping", "frags", "num", "name";
			}
			my $frags = sprintf("%5i",$s->{frags});
			if ( $frags eq " -666" )
			{
				$frags = "spect";
			}
			#                             chan  ip   pl ping frags ent name 
			out irc => 1, sprintf 'PRIVMSG %s :%-21s %2i %4i %5s #%-3u %s', $chan, $s->{ip}, $s->{pl}, $s->{ping}, $frags, $slot, color_dp2irc $s->{name};
			++$found;
			flood_sleep($found);
		}
		++$foundany;
	}
	
	if(!$foundany)
	{
		out irc => 0, "PRIVMSG $chan :no nicknames match";
	}
	
	my ($map,$game) = map_n_gametype();
	out irc => 1, "PRIVMSG $chan :Players: \00304$store{slots_active}\017/$store{slots_max}, Map: \00304$map\017";
	out irc => 1, "PRIVMSG $chan :Game: \00304$game\017, Nades: \00304".($g_nades?"on":"off")."\017";

}
################################################
#             Here be commands                 #
################################################

# status
[ irc => q{:([^! ]*)![^ ]* (?i:PRIVMSG) (?i:(??{$config{irc_channel}})) :(?i:(??{$store{irc_nick}}))(?: |: ?|, ?)status ?(.*)} => sub {
	
	player_status($config{irc_channel},"$2");
	return 1;
} ],

[ irc => q{:([^! ]*)![^ ]* (?i:PRIVMSG) (?i:(??{$store{irc_nick}})) :status ?(.*)} => sub {
	
	player_status($1,"$2");
	return 1;
} ],

# update cvars when a vote ends
[ dp => q{:vote:v(yes|no|timeout):(\d+):(\d+):(\d+):(\d+):(-?\d+)} => sub {
        update_cvars();
        return 0;
}],

# update cvars when a game starts
[ dp => q{:gamestart:(.*):[0-9.]*} => sub {
	update_cvars();
	return 0;
} ],

# Read cvar changes
[ dp => q{"([^"]+)" is "([^"]*)".*} => sub {
        my ($cvar,$value) = @_;
        if ( $cvar eq "g_nades" )
        {
                $g_nades = $value;
        }
        #out irc => 0, "PRIVMSG $config{irc_channel} :CVAR:$cvar=$value";
        return 0;
} ],

# Update map name when possible
[ dp => q{map:\s*(.+)} => sub {
	my $map = $1;
	if ( $store{map} eq "" )
	{
		$store{map} = "?_$map";
	}
	return 0;
}],

# IRC messages to RCON

# Messages starting with [ won't be shown, otherwise everything is sent
[ irc => q{:([^! ]*)![^ ]* (?i:PRIVMSG) (?i:(??{$config{irc_channel}})) :(?i:(??{$store{irc_nick}})(?: |: ?|, ?))?([^[].*)} => sub {
	my ($nick, $message) = @_;
	$message = color_irc2dp $message;
	$message =~ s/(["\\])/\\$1/g;
	$message =~ s/([;])/:/g;
	if ($message =~ /^ACTION(.*)/) 
	{ 
		$message = $1; 
		out dp => 0, "_ircmessage \"^4*^3 $nick^7 \" $message";
	} 
	else
	{ 
		out dp => 0, "_ircmessage \"$nick^7: \" $message"; 
	}
	
	return 1;
} ],

[ irc => q{:([^! ]*)![^ ]* (?i:JOIN) (?i:(??{$config{irc_channel}})).*} => sub {
	my $nick = $1;
	out dp => 0, "_ircmessage \"$nick \" ^3has Joined";
	return 0;
}],

[ irc => q{:([^! ]*)![^ ]* (?i:PART|QUIT) (?i:(??{$config{irc_channel}})).*} => sub {
	my $nick = $1;
	out dp => 0, "_ircmessage \"$nick \" ^3has Left";
	return 0;
}],

[ irc => q{:([^! ]*)![^ ]* (?i:KICK) (?i:(??{$config{irc_channel}})) ([^! ]*).*} => sub {
	out dp => 0, "_ircmessage \"$1 \" ^3has kicked $2";
	return 0;
}],


# !admin
[ dp => q{\001(.*?)\^7:\s*!admin\s*(.*)} => sub {
	my ($nick, $message) = map { color_dp2irc $_ } @_;
	foreach (@admin_highlighs)
	{
		out irc => 0, "PRIVMSG $_ :$config{irc_channel} <$nick\017> $message";
	}
	return 0;
} ],


# Match score
[ dp => q{:end} => sub {
	if ( not exists $store{scores} )
	{
			return 0;
	}

	my $s = $store{scores};
	delete $store{scores};
	my $teams_matter = defined $s->{teams};

	my @t = ();
	my @p = ();

	if($teams_matter)
	{
		# put players into teams
		my %t = ();
		for(@{$s->{players}})
		{
			my $thisteam = ($t{$_->[1]} ||= {score => 0, team => $_->[1], players => []});
			push @{$thisteam->{players}}, [$_->[0], $_->[1], $_->[2]];
			if($s->{teams})
			{
				$thisteam->{score} = $s->{teams}{$_->[1]};
			}
			else
			{
				$thisteam->{score} += $_->[0];
			}
		}

		# sort by team score
		@t = sort { $b->{score} <=> $a->{score} } values %t;

		# sort by player score
		@p = ();
		for(@t)
		{
			@{$_->{players}} = sort { $b->[0] <=> $a->[0] } @{$_->{players}};
			push @p, @{$_->{players}};
		}
	}
	else
	{
		@p = sort { $b->[0] <=> $a->[0] } @{$s->{players}};
		#@p = @{$s->{players}};
	}

	# display only for non-empty server
	if ( @p )
	{
		my $floodcount = 0;
		my ($map,$game) = map_n_gametype();
		out irc => 1, "PRIVMSG $config{irc_channel} :\00304$game\017 on \00304$map\017 ended:";
		flood_sleep(++$floodcount);

		if($teams_matter)
		{
			my $scores_string = '';
			my $sep = '';
			for(@t)
			{
				$scores_string .= $sep . "\003" . $color_team2irc_table{$_->{team}}. "\002\002" . $_->{score} . "\017";
				$sep = ':';
			}
			out irc => 1, "PRIVMSG $config{irc_channel} :Team score: $scores_string";
			flood_sleep(++$floodcount);
		}
		for(@p)
		{
			my ($frags, $team, $name, $id) = @$_;
			$name = color_dpfix $name;
			if($teams_matter)
			{
				$name = "\003" . $color_team2irc_table{$team} . " " . color_dp2none $name;
			}
			else
			{
				$name = " " . color_dp2irc $name;
			}
			out irc => 1, "PRIVMSG $config{irc_channel} :\002".sprintf('%3d',$frags)."\017 $name\017";
			flood_sleep(++$floodcount);
			#out irc => 1, "PRIVMSG $config{irc_channel} :(score)F:$frags,T:$team,ID:$id,N:".color_dp2irc($name)."\017";
			#flood_sleep(++$floodcount); 

		}
	}
	return 1;
} ],

# Update scores, ensure that everyone is included
[ dp => q{:player:see-labels:(-?\d+)[-0-9,]*:(\d+):(-?\d+):(\d+):(.*)} => sub {
	my ($frags, $time, $team, $id, $name) = @_;
	return if not exists $store{scores};
	my $found = 0;
	#for ( @{$store{scores}{players}} )
	#{
	#	if ( @$_[3] == $id )
	#	{
	#		$found = 1;
	#		@$_[0] = $frags;
	#		@$_[1] = $team;
	#		@$_[2] = $name;
	#		last;
	#	}
	#}
	if ( ! $found )
	{
		push @{$store{scores}{players}}, [$frags, $team, $name, $id];
	}
	#out irc => 0, "PRIVMSG $config{irc_channel} :F:$frags,T:$time,Te:$team,ID:$id,N:".color_dp2irc($name)."\017";

	return 1;
} ],
