package Asterisk;

require 5.004;

$VERSION = '0.03';

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{configfile} = undef;
	$self->{config} = {};
	bless $self, ref $class || $class;
	return $self;
}

sub DESTROY { }

sub configfile {
	my($self, $configfile) = @_;

print STDERR "CONFIGFILE $configfile\n";
	if (defined($configfile)) {
		$self->{'configfile'} = $configfile;
	} else {
		$self->{'configfile'} = $CONFIGFILE if (!defined($self->{'configfile'}));
	}

	return $self->{'configfile'};
}

sub _setvar {
	my ($self, $context, $var, $val) = @_;

	$self->{config}{$context}{$var} = $val;
}

sub readconfig {
	my ($self) = @_;

	my $context = '';
	my $line = '';

	my $configfile = $self->configfile();

	open(CF,"<$configfile") || die "Error loading $configfile: $!\n";
	while ($line = <CF>) {
		chop($line);
		# comments begin with ; in asterisk configs
		next if ($line =~ /^;/);
		$line =~ s/;.*$//;
		$line =~ s/\s*$//;

		if ($line =~ /^\[(\w+)\]$/) {
			$context = $1;
		} elsif ($line =~ /^(\w+)\s*[=>]+\s*(.*)/) {
			$self->_setvar($context, $1, $2);
		} else {
			print STDERR "Unknown line: $line\n" if ($DEBUG);
		}
	}
	close(CF);
	return %config;
}

sub dumpconfig {
	my ($self) = @_;

	$fh = \*STDERR;

	foreach $context (keys %{$self->{config}}) {
		print $fh "[$context]m\n";
		foreach $key (keys %{$self->{config}{$context}}) {
			print $fh "$key => " . $self->{config}{$context}{$key} . "\n";
		}
	}
}


1;
