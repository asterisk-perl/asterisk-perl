package Asterisk;

require 5.004;

$VERSION = '0.02';

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	bless $self, ref $class || $class;
	return $self;
}

sub DESTROY { }

1;
