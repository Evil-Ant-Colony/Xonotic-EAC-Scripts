use Time::HiRes qw/usleep/;

#nicer color
our @color_dp2irc_table = (-1, 4, 9, 7, 12, 11, 13, -1, -1, -1); # not accurate, but legible

#admins
my @admin_highlighs=('Melanosuchus', 'Floris', 'KproxaPy', 'Cesy', 'IRC-Love');

#status
my $g_nades = 1;

sub update_cvars {
	out dp => 1, "rcon2irc_eval g_nades";
}


my %gametypes = (
	"dm" => "deathmatch",
	"tdm" => "team deathmatch",
	"duel" => "duel",
	"ft" => "freezetag",
	"ctf" => "capture the flag",
	"inf" => "infection",
);

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
			usleep($found*100000);
		}
		++$foundany;
	}
	
	if(!$foundany)
	{
		out irc => 0, "PRIVMSG $chan :no nicknames match";
	}
	
	my $game = "?";
	my $map = "?";
	if ( $store{map} =~ /([^_]+)_(.*)/ )
	{
		($game,$map) = @_;
		if ( exists($gametypes{$game}) )
		{
			$game=$gametypes{$game};
		}
		$map = $2;
	}
	out irc => 1, "PRIVMSG $chan :Players: \00304$store{slots_active}\017/$store{slots_max}, Map: \00304$map\017";
	out irc => 1, "PRIVMSG $chan :Game: \00304$game\017, Nades: \00304".($g_nades?"on":"off")."\017";

}
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

[ dp => q{:vote:v(yes|no|timeout):(\d+):(\d+):(\d+):(\d+):(-?\d+)} => sub {
        update_cvars();
        return 0;
}],


[ dp => q{:gamestart:(.*):[0-9.]*} => sub {
	update_cvars();
	return 0;
} ],

[ dp => q{"([^"]+)" is "([^"]*)".*} => sub {
        my ($cvar,$value) = @_;
        if ( $cvar eq "g_nades" )
        {
                $g_nades = $value;
        }
        #out irc => 0, "PRIVMSG $config{irc_channel} :CVAR:$cvar=$value";
        return 0;
} ],


# IRC messages to RCON

[ irc => q{:([^! ]*)![^ ]* (?i:PRIVMSG) (?i:(??{$config{irc_channel}})) :(?i:(??{$store{irc_nick}})(?: |: ?|, ?))?(.*)} => sub {
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


#admin
[ dp => q{\001(.*?)\^7:\s*!admin\s*(.*)} => sub {
	my ($nick, $message) = map { color_dp2irc $_ } @_;
	foreach (@admin_highlighs)
	{
		out irc => 0, "PRIVMSG $_ :$config{irc_channel} <$nick\017> $message";
	}
	return 0;
} ],

