package Asterisk::Config::Zapata;

require 5.004;

=head1 NAME

Asterisk::Config::Zapata - Zapata configuration stuff

=head1 SYNOPSIS

stuff goes here

=head1 DESCRIPTION

description

=over 4

=cut

use Asterisk;
use Asterisk::Config;
@ISA = ('Asterisk::Config');

$VERSION = '0.01';

$DEBUG = 5;

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{'configfile'} = undef;
	$self->{'config'} = {};
	$self->{'configtemp'} = {};
	$self->{'contextorder'} = ();
	$self->{'channelgroup'} = {};

	bless $self, ref $class || $class;
#        while (my ($key,$value) = each %args) { $self->set($key,$value); }
	return $self;
}

sub DESTROY { }

sub configfilename {
	my ($self, $configfile) = @_;

	if (defined($configfile)) {
		$self->{'configfile'} = $configfile;
	} else {
		$self->{'configfile'} = '/etc/asterisk/zapata.conf' if (!defined($self->{'configfile'}));
	}

	return $self->{'configfile'};
}

sub _setvar {
	my ($self, $context, $var, $val, $order, $precomment, $postcomment) = @_;

	$self->{'configtemp'}{$context}{$var}{val} = $val;
	$self->{'configtemp'}{$context}{$var}{precomment} = $precomment;
	$self->{'configtemp'}{$context}{$var}{postcomment} = $postcomment;
	$self->{'configtemp'}{$context}{$var}{order} = $order;

}

sub _group {
	my ($self, $context, $channels) = @_;

	if ($channels) {
		push(@{$self->{channelgroup}{$context}}, $channels);
	} else {
		return @{$self->{channelgroup}{$context}};
	}
}

sub channels {
	my ($self, $context, $channels, $order, $precomment, $postcomment) = @_;

	my @chans = ();
	my $channel = '';
	my $x;

	$self->_group($context, $channels);
	if ($channels =~ /(\d+)\-(\d+)/) {
		my $beg = $1; my $end = $2;
		if ($end > $beg) {
			for ($x = $beg; $x <= $end; $x++) {
				push(@chans, $x);
			}
		}
	} elsif ($channels =~ /^(\d*)$/) {
		push(@chans, $channels);
	} elsif ($channels =~ /^\d*,/) {
		push(@chans, split(/,/, $channels));
	} else {
		print STDERR "channels got here: $channels\n" if ($DEBUG);
	}	
@chans = ( $channels );
	foreach $channel (@chans) {

#		$self->{'config'}{$context}{$channel}{'channel'} = $channel;
		foreach $var (keys %{$self->{'configtemp'}{$context}}) {
			$self->{'config'}{$context}{$channel}{$var}{precomment} = $self->{'configtemp'}{$context}{$var}{precomment};
			$self->{'config'}{$context}{$channel}{$var}{postcomment} = $self->{'configtemp'}{$context}{$var}{postcomment};
			$self->{'config'}{$context}{$channel}{$var}{val} = $self->{'configtemp'}{$context}{$var}{val};
			$self->{'config'}{$context}{$channel}{$var}{order} = $self->{'configtemp'}{$context}{$var}{order};
		}
	}

}

sub readconfig {
	my ($self) = @_;

	my $context = '';
	my $line = '';
	my $precomment = '';
	my $postcomment = '';

	my $configfile = $self->configfile();
	my $contextorder = 0;
	my $cfgorder = 0;

	open(CF, "<$configfile") || die "Error loading $configfile: $!\n";
	while ($line = <CF>) {
#		chop($line);


		#deal with comments
		if ($line =~ /^;/) {
			$precomment .= $line;
			next;
		} elsif ($line =~ /^;ACZ(\w*):\s*(.*)/) {
			print STDERR "ACZ Variable $1 = $2\n";
			next;
		} elsif ($line =~ /(;.*)$/) {
			$postcomment .= $1;
			$line =~ s/;.*$//;
		} elsif ($line =~ /^\s*$/) {
			$precomment = '';
			$postcomment = '';
			next;
		}

		chop($line);
		#strip off whitespace at the end of the line
		$line =~ s/\s*$//;


		if ($line =~ /^\[(\w+)\]$/) {
			$context = $1;
			$self->_addcontext($context, $contextorder);
			$contextorder++;
		} elsif ($line =~ /^channel\s*[=>]+\s*(.*)$/) {
			$channel = $1;
			$self->channels($context, $1, $order, $precomment, $postcomment);
			$precomment = '';
			$postcomment = '';
			$order++;
		} elsif ($line =~ /^(\w+)\s*[=>]+\s*(.*)/) {
			$self->_setvar($context, $1, $2, $order, $precomment, $postcomment);
			$precomment = '';
			$postcomment = '';
			$order++;
		} else {
			print STDERR "Unknown line: $line\n" if ($DEBUG);
		}

	}
	close(CF);

return 1;
}

sub writeconfig {
        my ($self) = @_;

        $fh = \*STDERR;


	foreach $context ($self->_contextorder()) {
		print $fh "[$context]\n";

		foreach $channelgroup ($self->_group($context)) {
			print $fh ";ACZGroup: $channelgroup\n";
		}

	        foreach $channel (sort {$a <=> $b} keys %{$self->{config}{$context}}) {
			foreach $key (keys %{$self->{config}{$context}{$channel}}) {
				print $fh $self->{config}{$context}{$channel}{$key}{'precomment'};
				print $fh "$key => " . $self->{config}{$context}{$channel}{$key}{val};
				if ($self->{config}{$context}{$channel}{$key}{postcomment}) {
					print $fh ' ' . $self->{config}{$context}{$channel}{$key}{postcomment};
				} else {
					print $fh "\n";
				}
			}
			print $fh "channel => $channel\n";
			print $fh "\n";
		}
	}
}

sub options {
	my ($self) = @_;

$self->{option} = { 
	'group' => { 'default' => '0',
			'regex' => '^\d*$'
			},
	'channel' => { 'default' => undef,
			'regex' => '^\d*$'
		},
}


}
		
			


1;
