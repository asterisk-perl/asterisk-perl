package Asterisk::Astman;

require 5.004;

=head1 NAME

Asterisk::Astman - Interface to the astman port

=head1 SYNOPSIS

stuff goes here

=head1 DESCRIPTION

description

=over 4

=cut

$VERSION = '0.01';

$DEBUG = 5;

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{'configfile'} = undef;
	$self->{'PORT'} = undef;
	$self->{'USER'} = undef;
	$self->{'SECRET'} = undef;
	$self->{'vars'} = {};
	bless $self, ref $class || $class;
#        while (my ($key,$value) = each %args) { $self->set($key,$value); }
	return $self;
}

sub DESTROY { }

sub port {
	my ($self, $port) = @_;

	if (defined($port)) {
		$self->{'PORT'} = $port;
	} else {
		$self->{'PORT'} = 5038 if (!defined($self->{'PORT'}));
	}

	return $self->{'PORT'};
}

sub user {
	my ($self, $user) = @_;

	if (defined($user)) {
		$self->{'USER'} = $user;
	}

	return $self->{'USER'};
}		

sub secret {
	my ($self, $secret) = @_;

	if (defined($secret)) {
		$self->{'SECRET'} = $secret;
	}

	return $self->{'SECRET'};
}

sub configfile {
	my ($self, $configfile) = @_;

	if (defined($configfile)) {
		$self->{'configfile'} = $configfile;
	} else {
		$self->{'configfile'} = '/etc/asterisk/manager.conf' if (!defined($self->{'configfile'}));
	}

	return $self->{'configfile'};
}

sub setvar {
	my ($self, $context, $var, $val) = @_;

	$self->{'vars'}{$context}{$var} = $val;
}

sub readconfig {
	my ($self) = @_;

	my $context = '';
	my $line = '';

	my $configfile = $self->configfile();

	open(CF, "<$configfile") || die "Error loading $configfile: $!\n";
	while ($line = <CF>) {
		chop($line);

		$line =~ s/;.*$//;
		$line =~ s/\s*$//;

		if ($line =~ /^;/) {
			next;
		} elsif ($line =~ /^\s*$/) {
			next;
		} elsif ($line =~ /^\[(\w+)\]$/) {
			$context = $1;
			print STDERR "Context: $context\n" if ($DEBUG>3);
		} elsif ($line =~ /^port\s*[=>]+\s*(\d+)/) {
			$self->port($1);
		} elsif ($line =~ /^(\w+)\s*[=>]+\s*(.*)/) {
			$self->setvar($context, $1, $2);
		} else {
			print STDERR "Unknown line: $line\n" if ($DEBUG);
		}

	}
	close(CF);

return 1;
}

1;
