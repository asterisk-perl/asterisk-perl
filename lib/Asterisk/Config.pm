package Asterisk::Config;

require 5.004;

use Asterisk;

$VERSION = '0.01';

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

sub _addcontext {
	my ($self, $context, $order) = @_;

	$self->{contextorder}[$order] = $context;
}

sub _contextorder {
	my ($self) = @_;

	return @{$self->{contextorder}};
}

sub readconfig {
	my ($self) = @_;

	my $context = '';
	my $line = '';

	my $configfile = $self->configfile();
	my $order = 0;

	open(CF,"<$configfile") || die "Error loading $configfile: $!\n";
	while ($line = <CF>) {
		chop($line);
		# comments begin with ; in asterisk configs
		next if ($line =~ /^;/);
		$line =~ s/;.*$//;
		$line =~ s/\s*$//;

		if ($line =~ /^\[(\w+)\]$/) {
			$context = $1;
			$self->_addcontext($context, $order);
			$order++;
		} elsif ($line =~ /^(\w+)\s*[=>]+\s*(.*)/) {
			$self->_setvar($context, $1, $2);
		} else {
			print STDERR "Unknown line: $line\n" if ($DEBUG);
		}
	}
	close(CF);
	return %config;
}

sub writeconfig {
	my ($self) = @_;

	$fh = \*STDERR;

	foreach $context ($self->_contextorder) {
		print $fh "[$context]\n";
		foreach $key (keys %{$self->{config}{$context}}) {
			print $fh "$key => " . $self->{config}{$context}{$key} . "\n";
		}
		print $fh "\n";
	}
}


1;

