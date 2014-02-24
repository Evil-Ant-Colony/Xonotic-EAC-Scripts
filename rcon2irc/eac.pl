# Use this to prevent IRC flood
use Time::HiRes qw/usleep/;

# Nicer color (Replace yellow with dark yellow/orange to improve readability)
our @color_dp2irc_table = (-1, 4, 9, 7, 12, 11, 13, -1, -1, -1); 
our %color_team2irc_table = (5 => 4, 14 => 12, 13 => 7, 10 => 13);

# Admins, will be notified on !admin
my @admin_highlighs=('Melanosuchus', 'Floris', 'KpoxaPy', 'Cesy', 'IRC-Love', 'Ameis');

# Prevent flooding
# @param $1 an integer value, increase it for multiple calls to this
sub flood_sleep
{
	usleep($1*100000);
}

# escape and prevent DP injection
sub dp_esc
{
	my $text = color_irc2dp join(" ",@_);
	$text =~ s/(["\\])/\\$1/g;
	$text =~ s/([;])/:/g;
	return $text;
}

#change server admin nick and perform command
# @param $1 dp-escaped nick
# @param $2 raw dp command
sub dp_cmd_as
{
	#my $sv_oldnick = $sv_adminnick;
	$sv_adminnick = "[IRC] ".$_[0];
	out dp => 1, 'set say_as_restorenick "" ',
		'sv_adminnick "'.$sv_adminnick.'" ',
		'sv_adminnick ',
		$_[1]." ",
		'defer 3 rcon2irc_say_as_restore ',
		'defer 5 sv_adminnick ';
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
	return ($map,$game);
}

#count platers
#return:
#	active players
#	spectators
#	bots
#	total
sub count_players
{
	my $real_active = 0, $real_spect = 0, $bots = 0;

	for my $slot(@{$store{playerslots_active} || []})
	{
		my $s = $store{"playerslot_$slot"};
		next unless $s;
		if ( $s->{ip} ne 'botclient')
		{
			if ( $s->{frags} == -666 )
			{
				$real_spect++;
			}
			else
			{
				$real_active++;
			}
		}
		else
		{
			$bots++;
		}
	}
	return ($real_active, $real_spect, $bots, $store{slots_active});
}



# Cvars that may be usueful to show on status
my $g_nades = 1, g_za;
my $sv_adminnick = "(console)";
my @g_maplist;

# Request cvar updates
sub update_cvars {
	out dp => 1, "rcon2irc_eval g_nades";
	out dp => 1, "rcon2irc_eval g_za";
	out dp => 1, "rcon2irc_eval g_maplist";
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
				flood_sleep(0);
			}
			my $frags = sprintf("%5i",$s->{frags});
			if ( $frags eq " -666" )
			{
				$frags = "spect";
			}
			#                             chan  ip   pl ping frags ent name 
			out irc => 1, sprintf 'PRIVMSG %s :%-21s %2i %4i %5s #%-3u %s', $chan, $s->{ip}, $s->{pl}, $s->{ping}, $frags, $slot, color_dp2irc $s->{name};
			++$found;
			flood_sleep($found+1);
		}
		++$foundany;
	}
	
	if(!$foundany)
	{
		out irc => 0, "PRIVMSG $chan :no player found";
	}
	
	my ($map,$game) = map_n_gametype();
	my ($real_active, $real_spect, $bots,$player_total) = count_players();
	out irc => 1, "PRIVMSG $chan :Players: \00304$real_active\017 active, \00304$real_spect\017 spectators, \00304$bots\017 bots, \00304$player_total\017/$store{slots_max} total";
	out irc => 1, "PRIVMSG $chan :Map: \00304$map\017, Game: \00304$game\017, Nades: \00304".($g_nades?"on":"off")."\017, Zombie: \00304".($g_za?"on":"off")."\017";

}

# Show player status
# @param $1 output channel
sub player_status_lite
{
	my ($chan) = @_;
	
	my $found = 0;
	for my $slot(@{$store{playerslots_active} || []})
	{
		my $s = $store{"playerslot_$slot"};
		next unless $s;
		
		out irc => 1, sprintf 'PRIVMSG %s :%s', $chan, color_dp2irc $s->{name};
		++$found;
		flood_sleep($found+1);
		
	}
	
	if(!$found)
	{
		out irc => 0, "PRIVMSG $chan :the server is empty D:";
	}
	
}

sub admin_commands
{
	my ($hostmask, $nick, $command, $chan) = @_;
	
	#available to everyone
	if ( $command =~ /^maps(?: (.*))?$/ )
	{
		my $regex = $1;
		if ( $regex eq "" )
		{
			out irc => 0, "PRIVMSG $chan :\00304".(scalar @g_maplist)."\017 maps";
		}
		else
		{
			my @matches = grep /$regex/, @g_maplist;
			my $floodcount = 0;
			out irc => 1, "PRIVMSG $chan :\00304".(scalar @matches)."\017/".(scalar @g_maplist)." maps match";
			flood_sleep($floodcount);
			if ( scalar @matches <= 5 )
			{
				for ( 0..($#matches) )
				{
					out irc => 1, "PRIVMSG $chan :\00303".$matches[$_]."\017";
					flood_sleep(++$floodcount);
				}
			}
		}
		return 1;
	}
	
	if ( $command eq "userscomplainus" )
	{
		player_status_lite($chan);
		return 1;
	}
	
	return 0 unless ($config{irc_admin_password} ne '' || $store{irc_quakenet_users});

	my $dpnick = color_dpfix $nick;

	if(($store{logins}{$hostmask} || 0) < time())
	{
		# get info so the next time it may work if the user is authorized
		$store{quakenet_hosts}->{$nick} = $hostmask;
		out irc => 0, "PRIVMSG Q :whois $nick"; # get auth for single user
		#let the default handle give feedback
		return 0;
	}
	
	if($command =~ /^status(?: (.*))?$/)
	{
		player_status($chan,$1);
		return 1;
	}
	
	if($command =~ /^kick (?:# )?(\d+)(?: (.*))?$/)
	{
		my ($id, $reason) = ($1, $2);
		$reason = "no reason" if ( not defined $reason or $reason eq "" );
		my $dpreason = dp_esc("[IRC] $dpnick: $reason");
		out dp => 0, "kick # $id $dpreason";
		my $slotnik = "playerslot_$id";
		out irc => 1, "PRIVMSG $chan :kicked #$id (@{[color_dp2irc $store{$slotnik}{name}]}\017 @ $store{$slotnik}{ip}) ($reason)";
		return 1;
	}

	if($command eq "banlist")
	{
		my $found = 0;
		for (my $ban = 0; $ban < @{$store{bans_new}}; $ban++ )
		{
			if ( defined $store{bans_new}[$ban]{ip} && $store{bans_new}[$ban]{ip} != "" )
			{
				$found++;
				out irc => 1, "PRIVMSG $chan :#$ban: $store{bans_new}[$ban]{ip} for $store{bans_new}[$ban]{time} seconds";
				flood_sleep($found);
			}
		}
		if ( $found == 0 )
		{
			out irc => 1, "PRIVMSG $chan :(no bans)";
		}
		else
		{
			out irc => 1, "PRIVMSG $chan :(end ban list)";
		}
		return 1;
	}
	
	if($command =~ /^ban ([^ ]+)(?: (\d+|inf)(?: (.*))?)?$/)
	{
		my ($ip, $bantime, $reason) = ($1, $2, $3);
		$reason = "no reason" if ( not defined $reason or $reason eq "" );
		$bantime = "inf" if ( not defined $bantime or $bantime eq "" );
		my $dpreason = dp_esc("[IRC] $dpnick: $reason");
		out dp => 0, "ban $ip $bantime $dpreason";
		out irc => 1, "PRIVMSG $chan :banned \00304$ip\017 for $bantime seconds ($reason)";
		$store{bans_new} = [];
		out dp => 0, "banlist";
		return 1;
	}
	
	if($command =~ /^unban (\d+)$/)
	{
		my $id = $1;
		out dp => 0, "unban $id";
		out irc => 1, "PRIVMSG $chan :Removed ban #$id";
		$store{bans_new} = [];
		out dp => 0, "banlist";
		return 1;
	}
	
	if($command =~ /^(endmatch|restart)$/)
	{
		my $cmd = $1;
		out dp => 0, $cmd;
		return 1;
	}

	if($command =~ /^((?:un)?mute) (\d+)$/)
	{
		my ($cmd,$id) = ($1, $2);
		out dp => 0, "$cmd $id";
		my $slotnik = "playerslot_$id";
		out irc => 1, "PRIVMSG $chan :${cmd}d $id (@{[color_dp2irc $store{$slotnik}{name}]}\017 @ $store{$slotnik}{ip})";
		return 1;
	}

	
	if($command =~ /^vcall (.+)$/)
	{
		dp_cmd_as ($dpnick, "vcall ".dp_esc($1));
		return 1;
	}
	
	if($command eq "vote stop")
	{
		dp_cmd_as ($dpnick, "vote stop");
		return 1;
	}

	if ($command  eq "reload")
	{
		out dp => 0, "reload_config";
		return 1;
	}

	out irc => 1, "PRIVMSG $chan :Unknown command: \00304$command\017";

	return 1;
}

sub reircnick
{
	my $nick = $store{irc_nick};
	my $text = "\Q$nick\E";
	return $text;
	#return "\Q".$store{irc_nick}."\E";
}

################################################
#             Here be commands                 #
################################################

# status
[ irc => q{:(([^! ]*)![^ ]*) (?i:PRIVMSG) (?i:(??{$config{irc_channel}})) :(?i:(??{ reircnick() }))(?: |: ?|, ?)(.*)} => sub {
	my ($hostmask, $nick, $command) = @_;
	return admin_commands($hostmask, $nick, $command,$config{irc_channel});
} ],

# IRC admin commands -- private
[ irc => q{:(([^! ]*)![^ ]*) (?i:PRIVMSG) (?i:(??{ reircnick() })) :(.*)} => sub {
	my ($hostmask, $nick, $command) = @_;
	return admin_commands($hostmask, $nick, $command,$nick);
} ],

# update cvars when a vote ends
[ dp => q{:vote:v(yes|no|timeout):(\d+):(\d+):(\d+):(\d+):(-?\d+)} => sub {
	update_cvars();
	return 0;
}],

# update cvars when a game starts
[ dp => q{:gamestart:(.*):[0-9.]*} => sub {
	update_cvars();
	$map = $1;
	return 0;
} ],

# Read cvar changes
[ dp => q{"([^"]+)" is "([^"]*)".*} => sub {
	my ($cvar,$value) = @_;
	if ( $cvar eq "g_nades" )
	{
		$g_nades = $value;
	}
	if ( $cvar eq "g_za" )
	{
		$g_za = $value;
	}
	if ( $cvar eq "g_maplist" )
	{
		if ( $value ne "" )
		{
			@g_maplist = split(" ",$value);
		}
	}
	if ( $cvar eq "sv_adminnick" )
	{
		if ( $value eq "" )
		{
			$sv_adminnick = "(console)";
		}
		else
		{
			$sv_adminnick = $value;
		}
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
[ irc => q{:([^! ]*)![^ ]* (?i:PRIVMSG) (?i:(??{$config{irc_channel}})) :(?i:(??{ reircnick() })(?: |: ?|, ?))?([^[].*)} => sub {
	my ($nick, $message) = @_;
	$message = dp_esc($message);
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

[ irc => q{:([^! ]*)![^ ]* (?i:PART) (?i:(??{$config{irc_channel}})).*} => sub {
	my $nick = $1;
	out dp => 0, "_ircmessage \"$nick \" ^3has Left";
	return 0;
}],

[ irc => q{:([^! ]*)![^ ]* (?i:QUIT) .*} => sub {
	my $nick = $1;
	out dp => 0, "_ircmessage \"$nick \" ^3has Left";
	return 0;
}],

[ irc => q{:([^! ]*)![^ ]* (?i:KICK) (?i:(??{$config{irc_channel}})) ([^! ]*).*} => sub {
	out dp => 0, "_ircmessage \"$1 \" ^3has kicked $2";
	return 0;
}],



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


# chat: Xonotic server -> IRC channel, vote call
[ dp => q{:vote:vcall:(\d+):(.*)} => sub {
	my ($id, $command) = @_;
	$command = color_dp2irc $command;
	my $oldnick = $id ? $store{"playernick_byid_$id"} : $sv_adminnick;
	out irc => 0, "PRIVMSG $config{irc_channel} :* $oldnick\017 calls a vote for \"$command\017\"";
	return 1;
} ],


# chat: Xonotic server -> IRC channel, vote stop
[ dp => q{:vote:vstop:(\d+)} => sub {
	my ($id) = @_;
	my $oldnick = $id ? $store{"playernick_byid_$id"} : $sv_adminnick;
	out irc => 0, "PRIVMSG $config{irc_channel} :* $oldnick\017 stopped the vote";
	return 1;
} ],


# server error
[ dp => q{Host_Error:(.*)} => sub {
	my ($msg) = @_;
	my $fullmsg="\00304SERVER ERROR\017: (\00304$map\017) $msg";
	out irc => 1, "PRIVMSG $config{irc_channel} :$fullmsg";
	my $i = 1;
	foreach (@admin_highlighs)
	{
		flood_sleep($i++);
		out irc => 1, "PRIVMSG $_ :$fullmsg";
	}
	return 1;
} ],


# !admin
[ dp => q{\001(.*?)\^7:\s*!admin\s*(.*)} => sub {
	my ($nick, $message) = map { color_dp2irc $_ } @_;
	out irc => 1, "PRIVMSG $config{irc_channel} :<$nick\017> on \00304$map\017: \00304!admin\017 $message";
	my $i = 1;
	foreach (@admin_highlighs)
	{
		flood_sleep($i++);
		out irc => 1, "PRIVMSG $_ :$config{irc_channel} (\00304$map\017) <$nick\017> $message";
	}
	return 0;
} ],

# retrieve list of banned hosts
[ dp => q{\s*#(\d+): (\S+) is still banned for (\S+) seconds\s*} => sub {
	#return 0 unless $store{status_waiting} < 0;
	my ($id, $ip, $time) = @_;
	$store{bans_new} = [] if $id == 0;
	$store{bans_new}[$id] = { ip => $ip, 'time' => $time };
	# out irc => 1, "PRIVMSG $config{irc_channel} :detected ban #$id: $ip for $time seconds";
	return 0;
} ],
