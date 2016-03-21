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
        META_MERGE => {
            'meta_spec' => { version => 2},
             resources => {
                 repository => {
                     type => 'git',
                     url  =>  'https://github.com/asterisk-perl/asterisk-perl.git',
                     web  =>  'https://github.com/asterisk-perl/asterisk-perl'
                 },
             },
        },
);

