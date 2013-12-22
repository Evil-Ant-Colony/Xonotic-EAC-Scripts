use Time::HiRes qw/usleep/;

sub out($$@);


[ irc => q{:([^! ]*)![^ ]* (?i:PRIVMSG) (?i:(??{$config{irc_channel}})) :(?i:(??{$store{irc_nick}}))(?: |: ?|, ?)status ?(.*)} => sub {
	
	my ($match) = $2;
	my $found = 0;
	my $foundany = 0;
	for my $slot(@{$store{playerslots_active} || []})
	{
		my $s = $store{"playerslot_$slot"};
		next unless $s;
		if(not defined $match or index(color_dp2none($s->{name}), $match) >= 0)
		{
			if ( !$found )
			{
				out irc => 1, sprintf 'PRIVMSG %s :'."\002".'%-21s %2s %4s %5s %-4s %s'."\017", $config{irc_channel}, "ip address", "pl", "ping", "frags", "num", "name";
			}
			my $frags = sprintf("%5i",$s->{frags});
			if ( $frags eq " -666" )
			{
				$frags = "spect";
			}
			#                             chan  ip   pl ping frags ent name 
			out irc => 1, sprintf 'PRIVMSG %s :%-21s %2i %4i %5s #%-3u %s', $config{irc_channel}, $s->{ip}, $s->{pl}, $s->{ping}, $frags, $slot, color_dp2irc $s->{name};
			++$found;
			usleep($found*100000);
		}
		++$foundany;
	}
	
	my $game = "?";
	my $map = "?";
	if ( $store{map} =~ /([^_]+)_(.*)/ )
	{
		$game = $1;
		$map = $2;
	}
	out irc => 1, "PRIVMSG $config{irc_channel} :Players: \00304$store{slots_active}\017/$store{slots_max}, Map: \00304$map\017, Game: \00304$game\017";

	
	if(!$found)
	{
		if(!$foundany)
		{
			out irc => 0, "PRIVMSG $config{irc_channel} :the server is empty";
		}
		else
		{
			out irc => 0, "PRIVMSG $config{irc_channel} :no nicknames match";
		}
	}
	return 1;
} ],


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