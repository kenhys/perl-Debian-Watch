package Parse::Debian::Watch;
use 5.010;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use constant CURRENT_WATCHFILE_VERSION => 5;
use base 'LWP::UserAgent';

our $VERSION = "0.01";


sub new {
    my $class = shift;
    my $self = bless {
	path => "debian/watch",
	package => "",
	version => "",
	watch_version => 0,
	component => "",
	compression => "",
	repack => 0,
	mode => "",
	pretty => "",
	date => "",
	gitmode => "",
	pgpmode => "",
	decompress => "",
	bare => 0,
	user_agent => "",
	pasv => 0,
	passive => 0,
	active => 0,
	nopasv => 0,
	unzipopt => "",
	dversionmangle => "",
	dirversionmangle => "",
	pagemangle => "",
	uversionmangle => "",
	versionmangle => "",
	hrefdecode => "",
	downloadurlmangle => "",
	filenamemangle => "",
	pgpsigurlmangle => "",
	oversionmangle => "",
	@_
    }, $class;

    my $path = $self->{path};
    if (-r $path) {
	$self->_parse_watchfile;
    } else {
        croak "Can't read file '$path'";
    }
    return $self;
}

sub version {
    my $self = shift;
    return $self->{watch_version};
}

sub component {
    my $self = shift;
    return $self->{component};
}

sub compression {
    my $self = shift;
    return $self->{compression};
}

sub repack {
    my $self = shift;
    return $self->{repack};
}

sub mode {
    my $self = shift;
    return $self->{mode};
}

sub pretty {
    my $self = shift;
    return $self->{pretty};
}

sub date {
    my $self = shift;
    return $self->{date};
}

sub gitmode {
    my $self = shift;
    return $self->{gitmode};
}

sub pgpmode {
    my $self = shift;
    return $self->{pgpmode};
}

sub decompress {
    my $self = shift;
    return $self->{decompress};
}

sub bare {
    my $self = shift;
    return $self->{bare};
}

sub user_agent {
    my $self = shift;
    return $self->{user_agent};
}

sub pasv {
    my $self = shift;
    return $self->{pasv};
}

sub passive {
    my $self = shift;
    return $self->{passive};
}

sub active {
    my $self = shift;
    return $self->{active};
}

sub nopasv {
    my $self = shift;
    return $self->{nopasv};
}

sub unzipopt {
    my $self = shift;
    return $self->{unzipopt};
}

sub dversionmangle {
    my $self = shift;
    return $self->{dversionmangle};
}

sub dirversionmangle {
    my $self = shift;
    return $self->{dirversionmangle};
}

sub pagemangle {
    my $self = shift;
    return $self->{pagemangle};
}

sub uversionmangle {
    my $self = shift;
    return $self->{uversionmangle};
}

sub versionmangle {
    my $self = shift;
    return $self->{versionmangle};
}

sub hrefdecode {
    my $self = shift;
    return $self->{hrefdecode};
}

sub downloadurlmangle {
    my $self = shift;
    return $self->{downloadurlmangle};
}

sub filenamemangle {
    my $self = shift;
    return $self->{filenamemangle};
}

sub pgpsigurlmangle {
    my $self = shift;
    return $self->{pgpsigurlmangle};
}

sub oversionmangle {
    my $self = shift;
    return $self->{oversionmangle};
}

sub uscan_warn {
    # FIXME
}

sub uscan_verbose {
    # FIXME
}

sub uscan_msg {
    # FIXME
}

sub uscan_debug {
    # FIXME
}

sub uscan_die {
    # FIXME
}

sub _parse_watchfile {
    my $self = shift;
    my $watchfile = $self->{path};
    my $package = $self->{package};
    my $version = $self->{version};
    my $status=0;
    my $nextline;

    unless (open WATCH, $watchfile) {
	uscan_warn "could not open $watchfile: $!\n";
	return 1;
    }

    while (<WATCH>) {
	next if /^\s*\#/;
	next if /^\s*$/;
	s/^\s*//;

    CHOMP:
	chomp;
	if (s/(?<!\\)\\$//) {
	    if (eof(WATCH)) {
		uscan_warn "$watchfile ended with \\; skipping last line\n";
		$status=1;
		last;
	    }
	    if ($self->{watch_version} > 3) {
	        # drop leading \s only if version 4
		$nextline = <WATCH>;
		$nextline =~ s/^\s*//;
		$_ .= $nextline;
	    } else {
		$_ .= <WATCH>;
	    }
	    goto CHOMP;
	}

	if (! $self->{watch_version}) {
	    if (/^version\s*=\s*(\d+)(\s|$)/) {
		$self->{watch_version} = $1;
		if ($self->{watch_version} < 2 or
		    $self->{watch_version} > CURRENT_WATCHFILE_VERSION) {
		    uscan_warn "$watchfile version number is unrecognised; skipping watch file\n";
		    last;
		}
		next;
	    } else {
		uscan_warn "$watchfile is an obsolete version 1 watch file;\n   please upgrade to a higher version\n   (see uscan(1) for details).\n";
		$self->{watch_version} = 1;
	    }
	}

	# Are there any warnings from this part to give if we're using dehs?
	#dehs_output if $dehs;

	# Handle shell \\ -> \
	s/\\\\/\\/g if $self->{watch_version}==1;

	# Handle @PACKAGE@ @ANY_VERSION@ @ARCHIVE_EXT@ substitutions
	my $any_version = '[-_]?(\d[\-+\.:\~\da-zA-Z]*)';
	my $archive_ext = '(?i)\.(?:tar\.xz|tar\.bz2|tar\.gz|zip|tgz|tbz|txz)';
	my $signature_ext = $archive_ext . '\.(?:asc|pgp|gpg|sig|sign)';
	s/\@PACKAGE\@/$package/g;
	s/\@ANY_VERSION\@/$any_version/g;
	s/\@ARCHIVE_EXT\@/$archive_ext/g;
	s/\@SIGNATURE_EXT\@/$signature_ext/g;

	$status +=
	    $self->_process_watchline($_, $self->{watch_version}, $package, $version, $watchfile);
    }

    close WATCH or
	$status=1, uscan_warn "problems reading $watchfile: $!\n";

    return $status;
}

sub _get_compression
{
    my ($self, $compression) = @_;
    my $canonical_compression;
    # be liberal in what you accept...
    my %opt2comp = (
        gz => 'gzip',
        gzip => 'gzip',
        bz2 => 'bzip2',
        bzip2 => 'bzip2',
        lzma => 'lzma',
        xz => 'xz',
        zip => 'zip',
    );

    # Normalize compression methods to the names used by Dpkg::Compression
    if (exists $opt2comp{$compression}) {
        $canonical_compression = $opt2comp{$compression};
    } else {
        uscan_die "invalid compression, $compression given.\n";
    }
    return $canonical_compression;
}

sub _process_watchline ($$$$$)
{
#######################################################################
# {{{ code 3.0: initializer and watchline parser
#######################################################################
    my ($self, $line, $watch_version, $pkg, $pkg_version, $watchfile) = @_;
    # $line		watch line string (concatenated line over the tailing \ )
    # $watch_version	usually 4 (or 3)
    # $pkg_dir		usually .
    # $pkg		the source package name found in debian/changelog
    # $pkg_version	the last source package version found in debian/changelog
    # $watchfile	usually debian/watch

    my $compression;
    my %dehs_tags;
    my $opt_user_agent;
    my $opt_compression;
    my $minversion;
    my @components = ();
    my $orig;
    my $origcount = 0;
    my $common_newversion;
    my $common_mangled_newversion;
    my $previous_newversion;
    my $previous_newfile_base;
    my $previous_sigfile_base;
    my $previous_download_available;
    my $uscanlog;
    my $repack = 0;
    #my $user_agent = LWP::UserAgent::UscanCatchRedirections->new(env_proxy => 1);
    my $origline = $line;
    my ($base, $site, $dir, $filepattern, $pattern, $lastversion, $action);
    my $basedir;
    my (@patterns, @sites, @redirections, @basedirs);
    my %options = (
	'repack' => $repack,
	'mode' => 'LWP',
	'gitmode' => 'shallow',
	'pgpmode' => 'default',
	'decompress' => 0,
	'versionmode' => 'newer',
	'pretty' => '0.0~git%cd.%h',
	'date' => '%Y%m%d',
	); # non-persistent variables
    my ($request, $response);
    my ($newfile, $newversion);
    my $style='new';
    my $versionless = 0;
    # Working repository used only within uscan.
    my $gitrepo_dir = "$pkg-temporary.$$.git";
    my $urlbase;
    my $headers = HTTP::Headers->new;

    # Need to clear remembered redirection URLs so we don't try to build URLs
    # from previous watch files or watch lines
    #$user_agent->clear_redirections;

    # Comma-separated list of features that sites being queried might
    # want to be aware of
    $headers->header('X-uscan-features' => 'enhanced-matching');
    $headers->header('Accept' => '*/*');
    %dehs_tags = ('package' => $pkg);

    # Start parsing the watch line
    if ($watch_version == 1) {
	($site, $dir, $filepattern, $lastversion, $action) = split ' ', $line, 5;

	if (! defined $lastversion or $site =~ /\(.*\)/ or $dir =~ /\(.*\)/) {
	    uscan_warn "there appears to be a version 2 format line in\n  the version 1 watch file $watchfile;\n  Have you forgotten a 'version=2' line at the start, perhaps?\n  Skipping the line: $line\n";
	    return 1;
	}
	if ($site !~ m%\w+://%) {
	    $site = "ftp://$site";
	    if ($filepattern !~ /\(.*\)/) {
		# watch_version=1 and old style watch file;
		# pattern uses ? and * shell wildcards; everything from the
		# first to last of these metachars is the pattern to match on
		$filepattern =~ s/(\?|\*)/($1/;
		$filepattern =~ s/(\?|\*)([^\?\*]*)$/$1)$2/;
		$filepattern =~ s/\./\\./g;
		$filepattern =~ s/\?/./g;
		$filepattern =~ s/\*/.*/g;
		$style='old';
		uscan_warn "Using very old style of filename pattern in $watchfile\n  (this might lead to incorrect results): $3\n";
	    }
	}

	# Merge site and dir
	$base = "$site/$dir/";
	$base =~ s%(?<!:)//%/%g;
	$base =~ m%^(\w+://[^/]+)%;
	$site = $1;
	$pattern = $filepattern;

	# Check $filepattern is OK
	if ($filepattern !~ /\(.*\)/) {
	    uscan_warn "Filename pattern missing version delimiters ()\n  in $watchfile, skipping:\n  $line\n";
	    return 1;
	}
    } else {
	# version 2/3/4 watch file
	if ($line =~ s/^opt(?:ion)?s\s*=\s*//) {
	    my $opts;
	    if ($line =~ s/^"(.*?)"(?:\s+|$)//) {
		$opts=$1;
	    } elsif ($line =~ s/^([^"\s]\S*)(?:\s+|$)//) {
		$opts=$1;
	    } else {
		uscan_warn "malformed opts=... in watch file, skipping line:\n$origline\n";
		return 1;
	    }
	    # $opts	string extracted from the argument of opts=
	    uscan_verbose "opts: $opts\n";
	    # $line watch line string without opts=... part
	    uscan_verbose "line: $line\n";
	    # user-agent strings has ,;: in it so special handling
	    if ($opts =~ /^\s*user-agent\s*=\s*(.+?)\s*$/ or
		$opts =~ /^\s*useragent\s*=\s*(.+?)\s*$/) {
		my $user_agent_string = $1;
		$user_agent_string = $opt_user_agent if defined $opt_user_agent;
		#$user_agent->agent($user_agent_string);
		uscan_verbose "User-agent: $user_agent_string\n";
		$opts='';
	    }
	    my @opts = split /,/, $opts;
	    foreach my $opt (@opts) {
    		uscan_verbose "Parsing $opt\n";
		if ($opt =~ /^\s*pasv\s*$/ or $opt =~ /^\s*passive\s*$/) {
		    $options{'pasv'}=1;
		} elsif ($opt =~ /^\s*active\s*$/ or $opt =~ /^\s*nopasv\s*$/
		       or $opt =~ /^s*nopassive\s*$/) {
		    $options{'pasv'}=0;
		} elsif ($opt =~ /^\s*bare\s*$/) {
		    # persistent $bare
		    $self->{bare} = 1;
		} elsif ($opt =~ /^\s*component\s*=\s*(.+?)\s*$/) {
			$options{'component'} = $1;
		} elsif ($opt =~ /^\s*mode\s*=\s*(.+?)\s*$/) {
			$options{'mode'} = $1;
		} elsif ($opt =~ /^\s*pretty\s*=\s*(.+?)\s*$/) {
			$options{'pretty'} = $1;
		} elsif ($opt =~ /^\s*date\s*=\s*(.+?)\s*$/) {
			$options{'date'} = $1;
		} elsif ($opt =~ /^\s*gitmode\s*=\s*(.+?)\s*$/) {
			$options{'gitmode'} = $1;
		} elsif ($opt =~ /^\s*pgpmode\s*=\s*(.+?)\s*$/) {
			$options{'pgpmode'} = $1;
		} elsif ($opt =~ /^\s*decompress\s*$/) {
		    $options{'decompress'}=1;
		} elsif ($opt =~ /^\s*repack\s*$/) {
		    # non-persistent $options{'repack'}
		    $options{'repack'} = 1;
		} elsif ($opt =~ /^\s*compression\s*=\s*(.+?)\s*$/) {
		    $options{'compression'} = $self->_get_compression($1);
		} elsif ($opt =~ /^\s*repacksuffix\s*=\s*(.+?)\s*$/) {
		    $options{'repacksuffix'} = $1;
		} elsif ($opt =~ /^\s*unzipopt\s*=\s*(.+?)\s*$/) {
		    $options{'unzipopt'} = $1;
		} elsif ($opt =~ /^\s*dversionmangle\s*=\s*(.+?)\s*$/) {
		    @{$options{'dversionmangle'}} = split /;/, $1;
		} elsif ($opt =~ /^\s*pagemangle\s*=\s*(.+?)\s*$/) {
		    @{$options{'pagemangle'}} = split /;/, $1;
		} elsif ($opt =~ /^\s*dirversionmangle\s*=\s*(.+?)\s*$/) {
		    @{$options{'dirversionmangle'}} = split /;/, $1;
		} elsif ($opt =~ /^\s*uversionmangle\s*=\s*(.+?)\s*$/) {
		    $self->{uversionmangle} = [split /;/, $1];
		} elsif ($opt =~ /^\s*versionmangle\s*=\s*(.+?)\s*$/) {
		    $self->{uversionmangle} = [split /;/, $1];
		    $self->{dversionmangle} = [split /;/, $1];
		} elsif ($opt =~ /^\s*hrefdecode\s*=\s*(.+?)\s*$/) {
		    $self->{hrefdecode} = $1;
		} elsif ($opt =~ /^\s*downloadurlmangle\s*=\s*(.+?)\s*$/) {
		    $self->{downloadurlmangle} = [split /;/, $1];
		} elsif ($opt =~ /^\s*filenamemangle\s*=\s*(.+?)\s*$/) {
		    $self->{filenamemangle} = [split /;/, $1];
		} elsif ($opt =~ /^\s*pgpsigurlmangle\s*=\s*(.+?)\s*$/) {
		    $self->{pgpsigurlmangle} = [split /;/, $1];
		    $self->{pgpmode} = 'mangle';
		} elsif ($opt =~ /^\s*oversionmangle\s*=\s*(.+?)\s*$/) {
		    @{$options{'oversionmangle'}} = split /;/, $1;
		} else {
		    uscan_warn "unrecognised option $opt\n";
		}
	    }
	    # $line watch line string when no opts=...
	    uscan_verbose "line: $line\n";
	} elsif ($line =~ s/^type\s*=\s*(.+?),\s*owner\s*=\s*(.+?),\s*project\s*=\s*(.+)//) {
	    if ($watch_version < 5) {
		uscan_warn "type=...,owner=...,project=... notation requires version=5 or later\n";
		return 1;
	    }
	    uscan_verbose "Scan type: $1 owner: $2 project: $3\n";
	    uscan_msg "watch version=5 is used. Scan type: $1 owner: $2 project: $3\n";
	    my $watch_type = $1;
	    my $watch_owner = $2;
	    my $watch_project = $3;
	    if ($watch_type eq "github") {
		@{$options{'filenamemangle'}} = "s/.+\\/v?(\\d\\S+)\\.tar\\.gz/$3-\$1\\.tar\\.gz/";
		$line = "https://github.com/$2/$3/tags .*/v?(\\d\\S*)\\.tar\\.gz";
	    } else {
		uscan_warn "Unrecognized type=$watch_type\n";
	    }
	}

	if ($line eq '') {
	    uscan_verbose "watch line only with opts=\"...\" and no URL\n";
	    return 0;
	}

	# 4 parameter watch line
	($base, $filepattern, $lastversion, $action) = split /\s+/, $line, 4;

	# 3 parameter watch line (override)
	if ($base =~ s%/([^/]*\([^/]*\)[^/]*)$%/%) {
	    # Last component of $base has a pair of parentheses, so no
	    # separate filepattern field; we remove the filepattern from the
	    # end of $base and rescan the rest of the line
	    $filepattern = $1;
	    (undef, $lastversion, $action) = split /\s+/, $line, 3;
	}
	# Always define "" if not defined
	$lastversion //= '';
	$action //= '';
	if ($options{'mode'} eq 'LWP') {
	    if ($base =~ m%^https?://%) {
		$options{'mode'} = 'http';
	    } elsif ($base =~ m%^ftp://%) {
		$options{'mode'} = 'ftp';
	    } else {
		uscan_warn "unknown protocol for LWP: $base\n";
		return 1;
	    }
	}
	# compression is persistent
	if ($options{'mode'} eq 'http' or $options{'mode'} eq 'ftp') {
	    $compression //= $self->_get_compression('gzip'); # keep backward compat.
	} else {
	    $compression //= $self->_get_compression('xz');
	}
	$compression = $self->_get_compression($options{'compression'}) if exists $options{'compression'};
	$compression = $self->_get_compression($opt_compression) if defined $opt_compression;

	# Set $lastversion to the numeric last version
	# Update $options{'versionmode'} (its default "newer")
	if (!length($lastversion) or $lastversion eq 'debian') {
	    if (! defined $pkg_version) {
		uscan_warn "Unable to determine the current version\n  in $watchfile, skipping:\n  $line\n";
		return 1;
	    }
	    $lastversion = $pkg_version;
	} elsif ($lastversion eq 'ignore') {
	    $options{'versionmode'}='ignore';
	    $lastversion = $minversion;
	} elsif ($lastversion eq 'same') {
	    $options{'versionmode'}='same';
	    $lastversion = $minversion;
	} elsif ($lastversion =~ m/^prev/) {
	    $options{'versionmode'}='previous';
	    # set $lastversion = $previous_newversion later
	}

	# Check $filepattern has ( ...)
	if ( $filepattern !~ /\([^?].*\)/) {
	    if ($options{'mode'} eq 'git' and $filepattern eq 'HEAD') {
		$versionless = 1;
	    } elsif ($options{'mode'} eq 'git' and $filepattern =~ m&^heads/&) {
		$versionless = 1;
	    } elsif ($options{'mode'} eq 'http' and exists $options{'filenamemangle'}) {
		$versionless = 1;
	    } else {
		uscan_warn "Tag pattern missing version delimiters () in $watchfile, skipping:\n  $line\n";
		return 1;
	    }
	}

	# Check validity of options
	if ($options{'mode'} eq 'ftp' and exists $options{'downloadurlmangle'}) {
	    uscan_warn "downloadurlmangle option invalid for ftp sites,\n  ignoring downloadurlmangle in $watchfile:\n  $line\n";
		return 1;
	}

	# Limit use of opts="repacksuffix" to the single upstream package
	if (defined $options{'repacksuffix'} and @components) {
	    uscan_warn "repacksuffix is not compatible with the multiple upstream tarballs;  use oversionmangle\n";
	    return 1
	}

	# Allow 2 char shorthands for opts="pgpmode=..." and check
	if ($options{'pgpmode'} =~ m/^au/) {
	    $options{'pgpmode'} = 'auto';
	    if (exists $options{'pgpsigurlmangle'}) {
		uscan_warn "Ignore pgpsigurlmangle because pgpmode=auto\n";
		delete $options{'pgpsigurlmangle'};
	    }
	} elsif ($options{'pgpmode'} =~ m/^ma/) {
	    $options{'pgpmode'} = 'mangle';
	    if (not defined $options{'pgpsigurlmangle'}) {
		uscan_warn "Missing pgpsigurlmangle.  Setting pgpmode=default\n";
		$options{'pgpmode'} = 'default';
	    }
	} elsif ($options{'pgpmode'} =~ m/^no/) {
	    $options{'pgpmode'} = 'none';
	} elsif ($options{'pgpmode'} =~ m/^ne/) {
	    $options{'pgpmode'} = 'next';
	} elsif ($options{'pgpmode'} =~ m/^pr/) {
	    $options{'pgpmode'} = 'previous';
	    $options{'versionmode'} = 'previous'; # no other value allowed
	    # set $lastversion = $previous_newversion later
	} elsif ($options{'pgpmode'} =~ m/^se/) {
	    $options{'pgpmode'} = 'self';
	} else {
	    $options{'pgpmode'} = 'default';
	}

	# If PGP used, check required programs and generate files
	if (exists $options{'pgpsigurlmangle'}) {
	    my $pgpsigurlmanglestring = join(";", @{$options{'pgpsigurlmangle'}});
	    uscan_debug "\$options{'pgpmode'}=$options{'pgpmode'}, \$options{'pgpsigurlmangle'}=$pgpsigurlmanglestring\n";
	} else {
	    uscan_debug "\$options{'pgpmode'}=$options{'pgpmode'}, \$options{'pgpsigurlmangle'}=undef\n";
	}

	# Check component for duplication and set $orig to the proper extension string
	if ($options{'pgpmode'} ne 'previous') {
	    if (defined $options{'component'}) {
		if ( grep {$_ eq $options{'component'}} @components ) {
		    uscan_warn "duplicate component name: $options{'component'}\n";
		    return 1;
		}
		push @components, $options{'component'};
		$orig = "orig-$options{'component'}";
	    } else {
		$origcount++ ;
		if ($origcount > 1) {
		    uscan_warn "more than one main upstream tarballs listed.\n";
		    # reset variables
		    @components = ();
		    $common_newversion = undef;
		    $common_mangled_newversion = undef;
		    $previous_newversion = undef;
		    $previous_newfile_base = undef;
		    $previous_sigfile_base = undef;
		    $previous_download_available = undef;
		    $uscanlog = undef;
		}
		$orig = "orig";
	    }
	}

	# Allow 2 char shorthands for opts="gitmode=..." and check
	if ($options{'gitmode'} =~ m/^sh/) {
	    $options{'gitmode'} = 'shallow';
	} elsif ($options{'gitmode'} =~ m/^fu/) {
	    $options{'gitmode'} = 'full';
	} else {
	    uscan_warn "Override strange manual gitmode '$options{'gitmode'}' --> 'shallow'";
	    $options{'gitmode'} = 'shallow';
	}

	# Handle sf.net addresses specially
	if (! $self->{bare} and $base =~ m%^https?://sf\.net/%) {
	    uscan_verbose "sf.net redirection to qa.debian.org/watch/sf.php\n";
	    $base =~ s%^https?://sf\.net/%https://qa.debian.org/watch/sf.php/%;
	    $filepattern .= '(?:\?.*)?';
	}
	# Handle pypi.python.org addresses specially
	if (! $self->{bare} and $base =~ m%^https?://pypi\.python\.org/packages/source/%) {
	    uscan_verbose "pypi.python.org redirection to pypi.debian.net\n";
	    $base =~ s%^https?://pypi\.python\.org/packages/source/./%https://pypi.debian.net/%;
	}
	# Handle pkg-ruby-extras gemwatch addresses specially
	if ($base =~ m%^https?://pkg-ruby-extras\.alioth\.debian\.org/cgi-bin/gemwatch%) {
	  uscan_warn "redirecting DEPRECATED pkg-ruby-extras.alioth.debian.org/cgi-bin/gemwatch to gemwatch.debian.net\n";
	  $base =~ s%^https?://pkg-ruby-extras\.alioth\.debian\.org/cgi-bin/gemwatch%https://gemwatch.debian.net%;
	}

    }
    # End parsing the watch line for all version=1/2/3/4
    # all options('...') variables have been set

    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Parse::Debian::Watch - It's new $module

=head1 SYNOPSIS

    use Parse::Debian::Watch;

=head1 DESCRIPTION

Parse::Debian::Watch is ...

=head1 LICENSE

Copyright (C) Kentaro Hayashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as devscripts/uscan.pl

=head1 AUTHOR

Kentaro Hayashi E<lt>kenhys@gmail.comE<gt>

=cut

