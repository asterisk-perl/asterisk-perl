use ExtUtils::MakeMaker;

WriteMakefile (
        NAME		=> 'asterisk-perl',
        VERSION_FROM	=> 'lib/Asterisk.pm',
        AUTHOR		=> 'James Golovich <james@gnuinter.net>',
        ABSTRACT	=> 'Asterisk Perl Interface',
	PMLIBDIRS	=> [ 'lib' ],
	PREREQ_PM	=> { 'IO::Socket' => 0, 
			     'Digest::MD5' => 0 },
	'dist'		=> {
				COMPRESS => 'gzip -9f', SUFFIX => 'gz',
				DIST_DEFAULT => 'tardist'
			   },
);

