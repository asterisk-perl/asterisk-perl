#
# $Id$
#
package Asterisk;

require 5.004;

use vars qw($VERSION);

$VERSION = '1.03';

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

1;
