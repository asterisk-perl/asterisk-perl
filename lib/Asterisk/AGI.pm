package Asterisk::AGI;

require 5.004;

use Asterisk;

@ISA = ( 'Asterisk' );

=head1 NAME

Asterisk::AGI - Simple Asterisk Gateway Interface Class

=head1 SYNOPSIS

use Asterisk::AGI;

$AGI = new Asterisk::AGI;

# pull AGI variables into %input

	%input = $AGI->ReadParse();   

# say the number 1984

	$AGI->say_number(1984);

=head1 DESCRIPTION

This module should make it easier to write scripts that interact with the
asterisk open source pbx via AGI (asterisk gateway interface)

=over 4

=cut

sub new {
	my ($class, %args) = @_;
	my $self = {};
	$self->{'callback'} = undef;
	$self->{'status'} = undef;
	bless $self, ref $class || $class;
	return $self;
}

sub ReadParse {
	my ($self, $fh) = @_;

	my %input = ();

	$fh = STDIN if (!$fh);

	select($fh);
	$| = 1;
	
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

sub setcallback {
	my ($self, $function) = @_;

	if (defined($function) && ref($function) eq 'CODE') {
		$self->{'callback'} = $function;
	} 
}

sub callback {
	my ($self, $result) = @_;

	if (defined($self->{'callback'}) && ref($self->{'callback'}) eq 'CODE') {
		&{$self->{'callback'}}($result);
	}
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

	select($fh);
	$| = 1;

	return -1 if (!defined($command));

	return print $fh "$command\n";
}

sub _readresponse {
	my ($self, $fh) = @_;

	my $response = undef;
	$fh = STDIN if (!$fh);
	$response = <$fh> || return '200 result=-1 (noresponse)';
	chomp($response);
	return $response;
}

sub _checkresult {
	my ($self, $response) = @_;

	return undef if (!defined($response));
	my $result = undef;

	if ($response =~ /^200/) {
		if ($response =~ /result=(-?\d+)/) {
			$result = $1;
		}
	} elsif ($response =~ /\(noresponse\)/) {
		$self->_status('noresponse');
	} else {
		print STDERR "Unexpected result '$response'\n" if ($DEBUG);
	}
	print STDERR "_checkresult($response) = $result\n" if ($DEBUG>3);

	return $result;				
}

sub _status {
	my ($self, $status) = @_;

	if (defined($status)) {
		$self->{'status'} = $status;
	} else {
		return $self->{'status'};
	}
}

sub stream_file {
	my ($self, $filename, $digits) = @_;

	my $ret = 0;

	$digits = '""' if (!defined($digits));

	return -1 if (!defined($filename));
	$ret =  $self->execute("STREAM FILE $filename $digits");

	$self->callback($ret) if ($ret == -1);

	return $ret;
}

sub send_text {
	my ($self, $text) = @_;

	my $ret = 0;

	return $ret if (!defined($text));
	$ret = $self->execute("SEND TEXT \"$text\"");
	$self->callback($ret) if ($ret == -1);

	return $ret;
}

sub send_image {
	my ($self, $image) = @_;

	my $ret = 0;
	return -1 if (!defined($image));

	$ret = $self->execute("SEND IMAGE $image");
	$self->callback($ret) if ($ret == -1);

	return $ret;
}

sub say_number {
	my ($self, $number, $digits) = @_;

	my $ret = 0;

	$digits = '""' if (!defined($digits));

	return -1 if (!defined($number));
	$ret = $self->execute("SAY NUMBER $number $digits");

	$self->callback($ret) if ($ret == -1);

	return $ret;
}

sub say_digits {
        my ($self, $number, $digits) = @_;

	my $ret = 0;
	$digits = '""' if (!defined($digits));

	return -1 if (!defined($number));
	$ret = $self->execute("SAY DIGITS $number $digits");
	$self->callback($ret) if ($ret == -1);

	return $ret;
}

sub answer {
	my ($self) = @_;

	my $ret = 0;
	$ret = $self->execute('ANSWER');
	$self->callback($ret) if ($ret == -1);

	return $ret;

}

sub get_data {
	my ($self, $filename, $timeout, $maxdigits) = @_;

	my $ret = undef;

	return -1 if (!defined($filename));
	$ret = $self->execute("GET DATA $filename $timeout $maxdigits");
	$self->callback($ret) if ($ret == -1);

	return $ret;
}

sub set_callerid {
	my ($self, $number) = @_;

	return if (!defined($number));
	return $self->execute("SET CALLERID $number");
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

	my $ret = 0;
#wait forever if timeout is not set. is this the prefered default?
	$timeout = 0 if (!defined($timeout));
	$ret = $self->execute("RECEIVE CHAR $timeout");
	$self->callback($ret) if ($ret == -1);

	return $ret;

}

sub tdd_mode {
	my ($self, $mode) = @_;

	return 0 if (!defined($mode));
	return $self->execute("TDD MODE $mode");
}


sub wait_for_digit {
	my ($self, $timeout) = @_;

	my $ret = 0;
	$timeout = -1 if (!defined($timeout));
	$ret = $self->execute("WAIT FOR DIGIT $timeout");

	$self->callback($ret) if ($ret == -1);

	return $ret;
}

sub record_file {
	my ($self, $filename, $format, $digits, $timeout, $beep) = @_;

	my $ret = 0;

	return -1 if (!defined($filename));
	$digits = '""' if (!defined($digits));
	$ret = $self->execute("RECORD FILE $filename $format $digits $timeout");

	$self->callback($ret) if ($ret == -1);

	return $ret;
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

sub exec {
	my ($self, $app, $options) = @_;
	return -1 if (!defined($app));
	$options = '""' if (!defined($options));
	return $self->execute("EXEC $app $options");
}

sub channel_status {
	my ($self) = @_;

	return $self->execute("CHANNEL STATUS");
}


1;

__END__
