package Asterisk::Manager;

# Asterisk PBX monitoring module
# Author: Jean-Denis Girard <jd-girard@esoft.pf> http://www.esoft.pf/

require 5.004;

use Asterisk;
use IO::Socket;

use strict;
use warnings;

my $EOL = "\015\012";
my $BLANK = $EOL x 2;

my $VERSION = '0.01';

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{_CONN} = undef;
	$self->{_PROTOVERS} = undef;
	$self->{_ERRORSTR} = undef;
	$self->{HOST} = 'localhost';
	$self->{PORT} = 5038;
	$self->{USER} = undef;
	$self->{SECRET} = undef;
	bless $self, ref $class || $class;
	return $self;
}

sub DESTROY { }

sub user {
	my ($self, $user) = @_;

	if ($user) {
		$self->{USER} = $user;
	}

	return $self->{USER};
}

sub secret {
	my ($self, $secret) = @_;

	if ($secret) {
		$self->{SECRET} = $secret;
	}

	return $self->{SECRET};
}

sub host {
	my ($self, $host) = @_;

	if ($host) {
		$self->{HOST} = $host;
	}

	return $self->{HOST};
}

sub port {
	my ($self, $port) = @_;

	if ($port) {
		$self->{PORT} = $port;
	}

	return $self->{PORT};
}

sub _read_response {
	my( $conn ) = @_;
	my @resp = ();
	while( <$conn> ) {
		last if $_ eq $EOL;
		s/$EOL//g;
		chomp;
		push @resp, $_ if $_;
	}
	return wantarray ? @resp:$resp[0];
}

sub error {
	my ($self, $error) = @_;

	if ($error) {
		$self->{_ERRORSTR} = $error;
		return '';
	}
	return $self->{_ERRORSTR};
}

# connect( $host, $port, $user, $secret)
# Make connection to Asterisk server $host on port $port
# and login with username $user, password $secret
sub connect {
	my ($self) = @_;

	my $host = $self->host;
	my $port = $self->port;
	my $user = $self->user;
	my $secret = $self->secret;
	# Connect...
	my $conn = new IO::Socket::INET( Proto => "tcp",
					   PeerAddr  => $host,
					   PeerPort  => $port
					 ) or return $self->error("Connection refused ($host:$port)\n");
	$conn->autoflush(1);

	my $in = <$conn>;
	$in =~ s/$EOL//g;
	my( $manager, $version ) = split '/',  $in;
	return $self->error("Unknown protocol\n") unless $manager eq 'Asterisk Call Manager';

	$self->{_PROTOVERS} = $version;
	$self->{_CONN} = $conn;

	# Login...
#	print $conn "Action: Login${EOL}Username: $user${EOL}Secret: $secret$BLANK";
#	my %resp = map { split(': ', $_); } _read_response $conn;
#	my %resp = map { split(': ', $_); } $self->action("Login${EOL}Username: $user${EOL}Secret: $secret");
	my %resp = $self->action("Login${EOL}Username: $user${EOL}Secret: $secret",1);

	return $self->error("Authentication failed for user $user\n") 
		unless $resp{Response} eq 'Success' && 
			$resp{Message} eq 'Authentication accepted';
	return 1;
}

sub action {
	my ($self, $command, $hash) = @_;

	return if (!$command);
	my $conn = $self->{_CONN};
	print $conn "Action: $command$BLANK";
	my @resp = _read_response($conn);

#	return wantarray ? @resp:$resp[0];
	if ( $hash ) {
		return map { split(': ', $_) } @resp;
	} elsif (wantarray) {
		return @resp;
	} else {
		return $resp[0];
	}
}

sub logoff {
	my( $self ) = @_;
	my $conn = $self->{_CONN};
#	print $conn "Action: Logoff$BLANK";
#	my %resp = map { split(': ', $_); } _read_response $conn;
	my %resp = $self->action("Logoff",1);
	return 0 unless $resp{Response} eq 'Goodbye';
	return 1;
}

# Queues Status: return a hash reference: 
# 			queue_name 	=>	[active_calls,
# 									[member1, member2... ],
# 									[call1, call2... ]
# 								]
sub queues {
	my( $self ) = @_;
	my $conn = $self->{_CONN};
#	print $conn "Action: Queues$BLANK";
#	my @lines = _read_response $conn;
	my @lines = $self->action("Queues");

	# Sample response (to explain how parsing of @lines to %queues is done)
	#queue        has 1 calls (max unlimited)
	#   Members:
	#      IAX/jdg
	#      IAX/fpo
	#   Callers:
	#      1. Zap/2-1 (wait: 0:02)
	#queue_op1    has 0 calls (max unlimited)
	#   Members:
	#      IAX/jdg
	#   No Callers
	my %queues;
	for( my $i=0; $i<@lines; ) {
		my( $l, @members, @callers );
		$l = $lines[$i++];
		my( $q, undef, $n ) = split /\s+/, $l; # Queue name

		unless( $l =~ /No\sMembers/ ) { # Scan callers
			$i++; # Forget 'Members:' line
			for( ; $i<@lines; ){
				$l=$lines[$i++];
	 			last if $l =~ /Callers/;
				$l =~ s/^\s+//;
				push @members, $l;
			}
		}

		unless( $l =~ /No\sCallers/ ) { # Scan callers
			for( ; $i<@lines; ){
				$l=$lines[$i++];
 				last if $l =~ /^\S/;
				$l =~ s/^\s+//;
				push @callers, $l;
			}
			$i--;
		}
		$queues{$q} = [ $n, \@members, \@callers]
	}

	return \%queues;
}

# IAX peers: return a hash reference: 
# 			peer_name 	=>	[ username, host, dynamic, mask, port ]
sub iax_peers {
	my( $self ) = @_;
	my $conn = $self->{_CONN};
#	print $conn "Action: IAXpeers$BLANK";
	my %peers = map { 
			  my @p = split( /\s+/, $_);
			  my $k = shift @p;
			  $p[1] = undef if $p[1] eq '(Unspecified)';
			  $p[2] = 0 if $p[2] eq '(S)';
			  $p[2] = 1 if $p[2] eq '(D)';
			  ($k, \@p );
	} $self->action("IAXpeers");
#	} _read_response $conn;

# Sample response (to explain how %peers is built)
#Name             Username         Host                 Mask             Port
#jdg              jdg              192.168.10.100  (D)  255.255.255.255  5036
#fpo              fpo              (Unspecified)   (D)  255.255.255.255  0
	delete $peers{Name};
	return \%peers;
}

# Send event status to a callback routine that should be accept a hash
# reference as argument.
# If successfull, this function never returns...
sub status {
	my( $self, $callback ) = @_;
	my $conn = $self->{_CONN};
#	print $conn "Action: Status$BLANK";
#	my %resp = map { split(': ', $_); } _read_response $conn;
	my %resp = $self->action("Status");
	return 0	unless $resp{Response} eq 'Success' && 
			$resp{Message} eq 'Channel status will follow';

	while( 1 ) {
		%resp = map { split(': ', $_); } _read_response $conn;
		&$callback( \%resp );
	}
}
1;

