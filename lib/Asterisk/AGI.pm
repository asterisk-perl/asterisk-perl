package Asterisk::AGI;

require 5.004;

=head1 NAME

Asterisk::AGI - Simple Asterisk Gateway Interface Class

=head1 SYNOPSIS

use Asterisk::AGI;

$AGI = new AGI;

# pull AGI variables into %input

	%input = $AGI->ReadParse();   

# say the number 1984

	$AGI->say_number(1984);

=head1 DESCRIPTION

This module should make it easier to write scripts that interact with the
asterisk open source pbx via AGI (asterisk gateway interface)

=over 4

=cut

$VERSION = '0.01';

$DEBUG = 0;

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	bless $self, ref $class || $class;
#        while (my ($key,$value) = each %args) { $self->set($key,$value); }
	return $self;
}

sub DESTROY { }

sub ReadParse {
	my ($self, $fh) = @_;

	my %input = ();

	$fh = STDIN if (!$fh);
	
	while (<$fh>) {
		chomp;
		last unless length($_);
		if (/^agi_(\w+)\:\s+(.*)$/) {
			$input{$1} = $2;
		}
	}
	

	if (defined($DEBUG)&&($DEBUG>0)) {
		print STDERR "AGI Environment Dump:\n";
		foreach $i (sort keys %input) {
			print STDERR " -- $i = $input{$i}\n";
		}
	}

	return %input;
}

sub execute {
	my ($self, $command) = @_;

	$self->_execcommand($command);
	my $res = $self->_readresponse();

	return $self->_checkresult($res);
}

sub _execcommand {
	my ($self, $command, $fh) = @_;

	$fh = STDOUT if (!$fh);
	return -1 if (!defined($command));

	return print $fh "$command\n";
}

sub _readresponse {
	my ($self, $fh) = @_;

	my $response = '';
	$fh = STDIN if (!$fh);
	$response = <$fh>;
	chomp($response);
	return $response;
}

sub _checkresult {
	my ($self, $response) = @_;


	return -1 if (!defined($response));
	my $result = -1;

	if ($response =~ /^200/) {
		if ($response =~ /result=(-?\d+)/) {
			$result = $1;
		}
	} else {
		print STDERR "Unexpected result '$response'\n" if ($DEBUG);
	}

	return $result;				
}

sub stream_file {
	my ($self, $filename, $digits) = @_;

	$digits = '""' if (!defined($digits));

	return -1 if (!defined($filename));
	return $self->execute("STREAM FILE $filename $digits");
}

sub send_text {
#SEND TEXT "text to send"\n
	my ($self, $text) = @_;

	return 0 if (!defined($text));
	return $self->execute("SEND TEXT \"$text\"");
}

sub send_image {
#SEND IMAGE imagefilename\n
	my ($self, $image) = @_;
	return -1 if (!defined($image));

	return $self->execute("SEND IMAGE $image");
}

sub say_number {
	my ($self, $number, $digits) = @_;

	$digits = '""' if (!defined($digits));

	return -1 if (!defined($number));
	return $self->execute("SAY NUMBER $number $digits");
}

sub say_digits {
        my ($self, $number, $digits) = @_;

	$digits = '""' if (!defined($digits));

	return -1 if (!defined($number));
	return $self->execute("SAY DIGITS $number $digits");
#        foreach $tempdig (split('', $digits)) {
#                $self->say_number($tempdig);
#        }
}

sub answer {
	my ($self) = @_;

	return $self->execute('ANSWER');
}

sub get_data {
	my ($self, $filename, $timeout, $maxdigits) = @_;
#Needs to be tested to see if timeout and maxdigits are optional or what

	return -1 if (!defined($filename));
	return $self->execute("GET DATA $filename $timeout $maxdigits");
}

sub set_context {
	my ($self, $context) = @_;

	return -1 if (!defined($context));
	return $self->execute("SET CONTEXT $context");
}

sub set_extension {
	my ($self, $extension) = @_;

	return -1 if (!defined($extension));
	return $self->execute("SET EXTENSION $extension");
}

sub set_priority {
	my ($self, $priority) = @_;

	return -1 if (!defined($priority));
	return $self->execute("SET PRIORITY $priority");
}

sub receive_char {
	my ($self, $timeout) = @_;

#wait forever if timeout is not set
	$timeout = 0 if (!defined($timeout));
	return $self->execute("RECEIVE CHAR $timeout");
}

sub tdd_mode {
	my ($self, $mode) = @_;

	return 0 if (!defined($mode));
	return $self->execute("TDD MODE $mode");
}


sub wait_for_digit {
#WAIT FOR DIGIT timeout
	my ($self, $timeout) = @_;

	$timeout = -1 if (!defined($timeout));
	return $self->execute("WAIT FOR DIGIT $timeout");
}

sub record_file {
	my ($self, $filename, $format, $digits, $timeout, $beep) = @_;

	return -1 if (!defined($filename));
	$digits = '""' if (!defined($digits));
	return $self->execute("RECORD FILE $filename $format $digits $timeout");
}

sub set_autohangup {
	my ($self, $time) = @_;

	$time = 0 if (!defined($time));
	return $self->execute("SET AUTOHANGUP $time");
}

sub hangup {
	my ($self) = @_;

	return $self->execute("HANGUP");
}

sub dial_channel {
	my ($self, $channel, $digits, $timeout) = @_;

	return -1 if (!defined($channel));
	$digits = '""' if (!defined($digits));
	$timeout = 0 if (!defined($timeout));

	return $self->execute("DIAL CHANNEL $channel $digits $timeout");
}

1;
