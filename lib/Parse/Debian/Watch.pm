package Parse::Debian::Watch;
use 5.010;
use strict;
use warnings;
use Carp;

our $VERSION = "0.01";


sub new {
    my $class = shift;
    my %params = @_;
    my $self = bless {
	path => "debian/watch",
	version => 1,
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
	oversionmangle => ""
    }, $class;

    my $path = $self->{path};
    if (-r $path) {
        open FILE, $path;
        $self->{contents} = decode('utf-8', join("", <FILE>));
        close FILE;
    } else {
        croak "Can't read file '$path'";
    }
    return $self;
}

sub version {
    my $self = shift;
    return $self->{version};
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

sub _parse_watchfile {
    my $self = shift;
    my $watchfile = $self->{path};
    my $package = $self->{package};
    my $watch_version=0;
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
	    if ($watch_version > 3) {
	        # drop leading \s only if version 4
		$nextline = <WATCH>;
		$nextline =~ s/^\s*//;
		$_ .= $nextline;
	    } else {
		$_ .= <WATCH>;
	    }
	    goto CHOMP;
	}

	if (! $watch_version) {
	    if (/^version\s*=\s*(\d+)(\s|$)/) {
		$watch_version=$1;
		if ($watch_version < 2 or
		    $watch_version > $self->{current_watchfile_version}) {
		    uscan_warn "$watchfile version number is unrecognised; skipping watch file\n";
		    last;
		}
		next;
	    } else {
		uscan_warn "$watchfile is an obsolete version 1 watch file;\n   please upgrade to a higher version\n   (see uscan(1) for details).\n";
		$watch_version=1;
	    }
	}

	# Are there any warnings from this part to give if we're using dehs?
	#dehs_output if $dehs;

	# Handle shell \\ -> \
	s/\\\\/\\/g if $watch_version==1;

	# Handle @PACKAGE@ @ANY_VERSION@ @ARCHIVE_EXT@ substitutions
	my $any_version = '[-_]?(\d[\-+\.:\~\da-zA-Z]*)';
	my $archive_ext = '(?i)\.(?:tar\.xz|tar\.bz2|tar\.gz|zip|tgz|tbz|txz)';
	my $signature_ext = $archive_ext . '\.(?:asc|pgp|gpg|sig|sign)';
	s/\@PACKAGE\@/$package/g;
	s/\@ANY_VERSION\@/$any_version/g;
	s/\@ARCHIVE_EXT\@/$archive_ext/g;
	s/\@SIGNATURE_EXT\@/$signature_ext/g;

=pod
	$status +=
	    process_watchline($_, $watch_version, $pkg_dir, $package, $version,
			      $watchfile);
	dehs_output if $dehs;
=cut
    }

    close WATCH or
	$status=1, uscan_warn "problems reading $watchfile: $!\n";

    return $status;
}

sub process_watchline ($$$$$$)
{
#######################################################################
# {{{ code 3.0: initializer and watchline parser
#######################################################################
    my ($line, $watch_version, $pkg_dir, $pkg, $pkg_version, $watchfile) = @_;
    # $line		watch line string (concatenated line over the tailing \ )
    # $watch_version	usually 4 (or 3)
    # $pkg_dir		usually .
    # $pkg		the source package name found in debian/changelog
    # $pkg_version	the last source package version found in debian/changelog
    # $watchfile	usually debian/watch

    my $repack = 0;
    my $user_agent = LWP::UserAgent::UscanCatchRedirections->new(env_proxy => 1);
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
    $user_agent->clear_redirections;

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
		$user_agent->agent($user_agent_string);
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
		    $bare = 1;
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
		    $options{'compression'} = get_compression($1);
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
		    @{$options{'uversionmangle'}} = split /;/, $1;
		} elsif ($opt =~ /^\s*versionmangle\s*=\s*(.+?)\s*$/) {
		    @{$options{'uversionmangle'}} = split /;/, $1;
		    @{$options{'dversionmangle'}} = split /;/, $1;
		} elsif ($opt =~ /^\s*hrefdecode\s*=\s*(.+?)\s*$/) {
		    $options{'hrefdecode'} = $1;
		} elsif ($opt =~ /^\s*downloadurlmangle\s*=\s*(.+?)\s*$/) {
		    @{$options{'downloadurlmangle'}} = split /;/, $1;
		} elsif ($opt =~ /^\s*filenamemangle\s*=\s*(.+?)\s*$/) {
		    @{$options{'filenamemangle'}} = split /;/, $1;
		} elsif ($opt =~ /^\s*pgpsigurlmangle\s*=\s*(.+?)\s*$/) {
		    @{$options{'pgpsigurlmangle'}} = split /;/, $1;
		    $options{'pgpmode'} = 'mangle';
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
	    $compression //= get_compression('gzip'); # keep backward compat.
	} else {
	    $compression //= get_compression('xz');
	}
	$compression = get_compression($options{'compression'}) if exists $options{'compression'};
	$compression = get_compression($opt_compression) if defined $opt_compression;

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
	if (! $bare and $base =~ m%^https?://sf\.net/%) {
	    uscan_verbose "sf.net redirection to qa.debian.org/watch/sf.php\n";
	    $base =~ s%^https?://sf\.net/%https://qa.debian.org/watch/sf.php/%;
	    $filepattern .= '(?:\?.*)?';
	}
	# Handle pypi.python.org addresses specially
	if (! $bare and $base =~ m%^https?://pypi\.python\.org/packages/source/%) {
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

    # Override the last version with --download-debversion
    if (defined $opt_download_debversion) {
	$lastversion = $opt_download_debversion;
	$lastversion =~ s/-[^-]+$//;  # revision
	$lastversion =~ s/^\d+://;    # epoch
	uscan_verbose "specified --download-debversion to set the last version: $lastversion\n";
    } elsif($options{'versionmode'} eq 'previous') {
	$lastversion = $previous_newversion;
	uscan_verbose "Previous version downloaded: $lastversion\n";
    } else {
	uscan_verbose "Last orig.tar.* tarball version (from debian/changelog): $lastversion\n";
    }

    # And mangle it if requested
    my $mangled_lastversion = $lastversion;
    if (mangle($watchfile, \$line, 'dversionmangle:',
	    \@{$options{'dversionmangle'}}, \$mangled_lastversion)) {
	return 1;
    }
    # Set $download_version etc. if already known
    if(defined $opt_download_version) {
	$download_version = $opt_download_version;
	$download = 2 if $download == 1; # Change default 1 -> 2
	$badversion = 1;
	uscan_verbose "Download the --download-version specified version: $download_version\n";
    } elsif (defined $opt_download_debversion) {
	$download_version = $mangled_lastversion;
	$download = 2 if $download == 1; # Change default 1 -> 2
	$badversion = 1;
	uscan_verbose "Download the --download-debversion specified version (dversionmangled): $download_version\n";
    } elsif(defined $opt_download_current_version) {
	$download_version = $mangled_lastversion;
	$download = 2 if $download == 1; # Change default 1 -> 2
	$badversion = 1;
	uscan_verbose "Download the --download-current-version specified version: $download_version\n";
    } elsif($options{'versionmode'} eq 'same') {
	unless (defined $common_newversion) {
	    uscan_warn "Unable to set versionmode=prev for the line without opts=pgpmode=prev\n  in $watchfile, skipping:\n  $line\n";
	    return 1;
	}
	$download_version = $common_newversion;
	$download = 2 if $download == 1; # Change default 1 -> 2
	$badversion = 1;
	uscan_verbose "Download secondary tarball with the matching version: $download_version\n";
    } elsif($options{'versionmode'} eq 'previous') {
	unless ($options{'pgpmode'} eq 'previous' and defined $previous_newversion) {
	    uscan_warn "Unable to set versionmode=prev for the line without opts=pgpmode=prev\n  in $watchfile, skipping:\n  $line\n";
	    return 1;
	}
	$download_version = $previous_newversion;
	$download = 2 if $download == 1; # Change default 1 -> 2
	$badversion = 1;
	uscan_verbose "Download the signature file with the previous tarball's version: $download_version\n";
    } else {
	# $options{'versionmode'} should be debian or ignore
	if (defined $download_version) {
	    uscan_die "\$download_version defined after dversionmangle ... strange\n";
	} else {
	    uscan_verbose "Last orig.tar.* tarball version (dversionmangled): $mangled_lastversion\n";
	}
    }

    if ($watch_version != 1) {
	if ($options{'mode'} eq 'http' or $options{'mode'} eq 'ftp') {
	    if ($base =~ m%^(\w+://[^/]+)%) {
		$site = $1;
	    } else {
		uscan_warn "Can't determine protocol and site in\n  $watchfile, skipping:\n  $line\n";
		return 1;
	    }

	    # Find the path with the greatest version number matching the regex
	    $base = recursive_regex_dir($base, \%options, $watchfile, \$line);
	    if ($base eq '') { return 1; }

	    # We're going to make the pattern
	    # (?:(?:http://site.name)?/dir/path/)?base_pattern
	    # It's fine even for ftp sites
	    $basedir = $base;
	    $basedir =~ s%^\w+://[^/]+/%/%;
	    $pattern = "(?:(?:$site)?" . quotemeta($basedir) . ")?$filepattern";
	} else {
	    # git tag match is simple
            $site = $base; # dummy
	    $basedir = ''; # dummy
	    $pattern = $filepattern;
	}
    }

    push @sites, $site;
    push @basedirs, $basedir;
    push @patterns, $pattern;

    my $match = '';
    # Start Checking $site and look for $filepattern which is newer than $lastversion
    uscan_debug "watch file has:\n"
	. "    \$base        = $base\n"
	. "    \$filepattern = $filepattern\n"
	. "    \$lastversion = $lastversion\n"
	. "    \$action      = $action\n"
	. "    mode         = $options{'mode'}\n"
	. "    pgpmode      = $options{'pgpmode'}\n"
	. "    versionmode  = $options{'versionmode'}\n"
	. "    \$site        = $site\n"
	. "    \$basedir     = $basedir\n";
    # What is the most recent file, based on the filenames?
    # We first have to find the candidates, then we sort them using
    # Devscripts::Versort::upstream_versort (if it is real upstream version string) or
    # Devscripts::Versort::versort (if it is suffixed upstream version string)
#######################################################################
# }}} code 3.0: initializer and watchline parser
#######################################################################

#######################################################################
# {{{ code 3.1: search $newfile and $newversion
#######################################################################
# $newfile:    URL/tag pointing to the file to be downloaded
# $newversion: version number to be used for the downloaded file
#              This is for http
#
if ($options{'mode'} eq 'http') {
#######################################################################
# {{{ code 3.1.1: search $newversion (http mode)
#######################################################################
# $content:    web page to be scraped to find the URLs to be downloaded
	if (defined($1) and !$haveSSL) {
	    uscan_die "you must have the liblwp-protocol-https-perl package installed\nto use https URLs\n";
	}
	uscan_verbose "Requesting URL:\n   $base\n";
	$request = HTTP::Request->new('GET', $base, $headers);
	$response = $user_agent->request($request);
	if (! $response->is_success) {
	    uscan_warn "In watchfile $watchfile, reading webpage\n  $base failed: " . $response->status_line . "\n";
	    return 1;
	}

	@redirections = @{$user_agent->get_redirections};

	uscan_verbose "redirections: @redirections\n" if @redirections;

	foreach my $_redir (@redirections) {
	    my $base_dir = $_redir;

	    $base_dir =~ s%^\w+://[^/]+/%/%;
	    if ($_redir =~ m%^(\w+://[^/]+)%) {
		my $base_site = $1;

		push @patterns, "(?:(?:$base_site)?" . quotemeta($base_dir) . ")?$filepattern";
		push @sites, $base_site;
		push @basedirs, $base_dir;

		# remove the filename, if any
		my $base_dir_orig = $base_dir;
		$base_dir =~ s%/[^/]*$%/%;
		if ($base_dir ne $base_dir_orig) {
		    push @patterns, "(?:(?:$base_site)?" . quotemeta($base_dir) . ")?$filepattern";
		    push @sites, $base_site;
		    push @basedirs, $base_dir;
		}
	    }
	}

	my $content = $response->decoded_content;
	uscan_debug "received content:\n$content\n[End of received content] by HTTP\n";

	# pagenmangle: should not abuse this slow operation
	if (mangle($watchfile, \$line, 'pagemangle:\n',
		\@{$options{'pagemangle'}}, \$content)) {
	    return 1;
	}
	if (! $bare and
	    $content =~ m%^<[?]xml%i and
	    $content =~ m%xmlns="http://s3.amazonaws.com/doc/2006-03-01/"% and
	    $content !~ m%<Key><a\s+href%) {
	    # this is an S3 bucket listing.  Insert an 'a href' tag
	    # into the content for each 'Key', so that it looks like html (LP: #798293)
	    uscan_warn "*** Amazon AWS special case code is deprecated***\nUse opts=pagemangle rule, instead\n";
	    $content =~ s%<Key>([^<]*)</Key>%<Key><a href="$1">$1</a></Key>%g ;
	    uscan_debug "processed content:\n$content\n[End of processed content] by Amazon AWS special case code\n";
	}

	# We need this horrid stuff to handle href=foo type
	# links.  OK, bad HTML, but we have to handle it nonetheless.
	# It's bug #89749.
	$content =~ s/href\s*=\s*(?=[^\"\'])([^\s>]+)/href="$1"/ig;
	# Strip comments
	$content =~ s/<!-- .*?-->//sg;
	# Is there a base URL given?
	if ($content =~ /<\s*base\s+[^>]*href\s*=\s*([\"\'])(.*?)\1/i) {
	    # Ensure it ends with /
	    $urlbase = "$2/";
	    $urlbase =~ s%//$%/%;
	} else {
	    # May have to strip a base filename
	    ($urlbase = $base) =~ s%/[^/]*$%/%;
	}
	uscan_debug "processed content:\n$content\n[End of processed content] by fix bad HTML code\n";

	# search hrefs in web page to obtain a list of uversionmangled version and matching download URL
	{
	    local $, = ',';
	    uscan_verbose "Matching pattern:\n   @patterns\n";
	}
	my @hrefs;
	while ($content =~ m/<\s*a\s+[^>]*href\s*=\s*([\"\'])(.*?)\1/sgi) {
	    my $href = $2;
	    my $mangled_version;
	    $href = fix_href($href);
	    if (exists $options{'hrefdecode'}) {
		if ($options{'hrefdecode'} eq 'percent-encoding') {
		    uscan_debug "... Decoding from href: $href\n";
		    $href =~ s/%([A-Fa-f\d]{2})/chr hex $1/eg ;
		} else {
		    uscan_warn "Illegal value for hrefdecode: "
			     . "$options{'hrefdecode'}\n";
		    return 1;
	        }
	    }
	    uscan_debug "Checking href $href\n";
	    foreach my $_pattern (@patterns) {
		if ($href =~ m&^$_pattern$&) {
		    if ($watch_version == 2) {
			# watch_version 2 only recognised one group; the code
			# below will break version 2 watch files with a construction
			# such as file-([\d\.]+(-\d+)?) (bug #327258)
			$mangled_version = $1;
		    } else {
			# need the map { ... } here to handle cases of (...)?
			# which may match but then return undef values
			if ($versionless) {
			    # exception, otherwise $mangled_version = 1
			    $mangled_version = '';
			} else {
			    $mangled_version =
				join(".", map { $_ if defined($_) }
				    $href =~ m&^$_pattern$&);
			}

			if (mangle($watchfile, \$line, 'uversionmangle:',
				\@{$options{'uversionmangle'}}, \$mangled_version)) {
			    return 1;
			}
		    }
		    $match = '';
		    if (defined $download_version) {
			if ($mangled_version eq $download_version) {
			    $match = "matched with the download version";
			}
		    }
		    my $priority = $mangled_version . '-' . get_priority($href);
		    push @hrefs, [$priority, $mangled_version, $href, $match];
		}
	    }
	}
	if (@hrefs) {
	    @hrefs = Devscripts::Versort::versort(@hrefs);
	    my $msg = "Found the following matching hrefs on the web page (newest first):\n";
	    foreach my $href (@hrefs) {
		$msg .= "   $$href[2] ($$href[1]) index=$$href[0] $$href[3]\n";
	    }
	    uscan_verbose $msg;
	}
	if (defined $download_version) {
	    # extract ones which has $match in the above loop defined
	    my @vhrefs = grep { $$_[3] } @hrefs;
	    if (@vhrefs) {
		(undef, $newversion, $newfile, undef) = @{$vhrefs[0]};
	    } else {
		uscan_warn "In $watchfile no matching hrefs for version $download_version"
		    . " in watch line\n  $line\n";
		return 1;
	    }
	} else {
	    if (@hrefs) {
	    	(undef, $newversion, $newfile, undef) = @{$hrefs[0]};
	    } else {
		uscan_warn "In $watchfile no matching files for watch line\n  $line\n";
		return 1;
	    }
	}
#######################################################################
# }}} code 3.1.1: search $newfile $newversion (http mode)
#######################################################################
    } elsif ($options{'mode'} eq 'ftp') {
#######################################################################
# {{{ code 3.1.2: search $newfile $newversion (ftp mode)
#######################################################################
	# FTP site
	if (exists $options{'pasv'}) {
	    $ENV{'FTP_PASSIVE'}=$options{'pasv'};
	}
	uscan_verbose "Requesting URL:\n   $base\n";
	$request = HTTP::Request->new('GET', $base);
	$response = $user_agent->request($request);
	if (exists $options{'pasv'}) {
	    if (defined $passive) {
		$ENV{'FTP_PASSIVE'}=$passive;
	    } else {
		delete $ENV{'FTP_PASSIVE'};
	    }
	}
	if (! $response->is_success) {
	    uscan_warn "In watch file $watchfile, reading FTP directory\n  $base failed: " . $response->status_line . "\n";
	    return 1;
	}

	my $content = $response->content;
	uscan_debug "received content:\n$content\n[End of received content] by FTP\n";

	# FTP directory listings either look like:
	# info info ... info filename [ -> linkname]
	# or they're HTMLised (if they've been through an HTTP proxy)
	# so we may have to look for <a href="filename"> type patterns
	uscan_verbose "matching pattern $pattern\n";
	my (@files);

	# We separate out HTMLised listings from standard listings, so
	# that we can target our search correctly
	if ($content =~ /<\s*a\s+[^>]*href/i) {
	    uscan_verbose "HTMLized FTP listing by the HTTP proxy\n";
	    while ($content =~
		m/(?:<\s*a\s+[^>]*href\s*=\s*\")((?-i)$pattern)\"/gi) {
		my $file = fix_href($1);
		my $mangled_version = join(".", $file =~ m/^$pattern$/);
		if (mangle($watchfile, \$line, 'uversionmangle:',
			\@{$options{'uversionmangle'}}, \$mangled_version)) {
		    return 1;
		}
		$match = '';
		if (defined $download_version) {
		    if ($mangled_version eq $download_version) {
			$match = "matched with the download version";
		    }
		}
		my $priority = $mangled_version . '-' . get_priority($file);
		push @files, [$priority, $mangled_version, $file, $match];
	    }
	} else {
	    uscan_verbose "Standard FTP listing.\n";
	    # they all look like:
	    # info info ... info filename [ -> linkname]
	    for my $ln (split(/\n/, $content)) {
		$ln =~ s/^d.*$//; # FTP listing of directory, '' skiped by if ($ln...
		$ln =~ s/\s+->\s+\S+$//; # FTP listing for link destination
		$ln =~ s/^.*\s(\S+)$/$1/; # filename only
		if ($ln and $ln =~ m/^($filepattern)$/) {
		    my $file = $1;
		    my $mangled_version = join(".", $file =~ m/^$filepattern$/);
		    if (mangle($watchfile, \$line, 'uversionmangle:',
			    \@{$options{'uversionmangle'}}, \$mangled_version)) {
			return 1;
		    }
		    $match = '';
		    if (defined $download_version) {
			if ($mangled_version eq $download_version) {
			    $match = "matched with the download version";
			}
		    }
		    my $priority = $mangled_version . '-' . get_priority($file);
		    push @files, [$priority, $mangled_version, $file, $match];
		}
	    }
	}
	if (@files) {
	    @files = Devscripts::Versort::versort(@files);
	    my $msg = "Found the following matching files on the web page (newest first):\n";
	    foreach my $file (@files) {
		$msg .= "   $$file[2] ($$file[1]) index=$$file[0] $$file[3]\n";
	    }
	    uscan_verbose $msg;
	}
	if (defined $download_version) {
	    # extract ones which has $match in the above loop defined
	    my @vfiles = grep { $$_[3] } @files;
	    if (@vfiles) {
		(undef, $newversion, $newfile, undef) = @{$vfiles[0]};
	    } else {
		uscan_warn "In $watchfile no matching files for version $download_version"
		    . " in watch line\n  $line\n";
		return 1;
	    }
	} else {
	    if (@files) {
	    	(undef, $newversion, $newfile, undef) = @{$files[0]};
	    } else {
		uscan_warn "In $watchfile no matching files for watch line\n  $line\n";
		return 1;
	    }
	}
#######################################################################
# }}} code 3.1.2: search $newfile $newversion (ftp mode)
#######################################################################
    } elsif ($options{'mode'} eq 'git' and $versionless) {
#######################################################################
# {{{ code 3.1.1: search $newfile $newversion (git mode/versionless)
#######################################################################
	$newfile = $filepattern; # HEAD or heads/<branch>
	if ($options{'pretty'} eq 'describe') {
	    $options{'gitmode'} = 'full';
	}
	if ($options{'gitmode'} eq 'shallow' and $filepattern eq 'HEAD') { 
	    uscan_verbose "Execute: git clone --bare --depth=1 $base $destdir/$gitrepo_dir\n";
	    system('git', 'clone', '--bare', '--depth=1', $base, "$destdir/$gitrepo_dir");
	    $gitrepo_state=1;
	} elsif ($options{'gitmode'} eq 'shallow' and $filepattern ne 'HEAD') { # heads/<branch>
	    $newfile =~ s&^heads/&& ; # Set to <branch>
	    uscan_verbose "Execute: git clone --bare --depth=1 -b $newfile $base $destdir/$gitrepo_dir\n";
	    system('git', 'clone', '--bare', '--depth=1', '-b', "$newfile", $base, "$destdir/$gitrepo_dir");
	    $gitrepo_state=1;
	} else {
	    uscan_verbose "Execute: git clone --bare $base $destdir/$gitrepo_dir\n";
	    system('git', 'clone', '--bare', $base, "$destdir/$gitrepo_dir");
	    $gitrepo_state=2;
	}
	if ($options{'pretty'} eq 'describe') {
	    # use unannotated tags to be on safe side
	    $newversion=`git --git-dir=$destdir/$gitrepo_dir describe --tags`;
	    $newversion =~ s/-/./g ;
	    chomp($newversion);
	    if (mangle($watchfile, \$line, 'uversionmangle:',
		    \@{$options{'uversionmangle'}}, \$newversion)) {
		return 1;
	    }
	} else {
	    $newversion=`git --git-dir=$destdir/$gitrepo_dir log -1 --date=format:$options{'date'} --pretty="$options{'pretty'}"`;
	    chomp($newversion);
	}
#######################################################################
# }}} code 3.1.1: search $newfile $newversion (git mode/versionless)
#######################################################################
    } elsif ($options{'mode'} eq 'git') {
#######################################################################
# {{{ code 3.1.2: search $newfile $newversion (git mode w/tag)
#######################################################################
	uscan_verbose "Execute: git ls-remote $base\n";
 	open(REFS, "-|", 'git', 'ls-remote', $base) ||
 	    uscan_die "$progname: you must have the git package installed\n";
	my @refs;
	my $ref;
	my $version;
	while (<REFS>) {
	    chomp;
	    uscan_debug "$_\n";
	    if (m&^\S+\s+([^\^\{\}]+)$&) {
		$ref = $1; # ref w/o ^{}
		foreach my $_pattern (@patterns) {
		    $version = join(".", map { $_ if defined($_) }
			    $ref =~ m&^$_pattern$&);
		    if (mangle($watchfile, \$line, 'uversionmangle:',
			    \@{$options{'uversionmangle'}}, \$version)) {
			return 1;
		    }
		    push @refs, [$version, $ref];
		}
	    }
	}
	if (@refs) {
	    @refs = Devscripts::Versort::upstream_versort(@refs);
	    my $msg = "Found the following matching refs:\n";
	    foreach my $ref (@refs) {
		$msg .= "     $$ref[1] ($$ref[0])\n";
	    }
	    uscan_verbose "$msg";
	    if (defined $download_version) {
		# extract ones which has $version in the above loop matched with $download_version
		my @vrefs = grep { $$_[0] eq $download_version } @refs;
		if (@vrefs) {
		    ($newversion, $newfile) = @{$vrefs[0]};
		} else {
		    uscan_warn "$progname warning: In $watchfile no matching"
			 . " refs for version $download_version"
			 . " in watch line\n  $line\n";
		    return 1;
		}

	    } else {
		($newversion, $newfile) = @{$refs[0]};
	    }
	} else {
	    uscan_warn "$progname warning: In $watchfile,\n" .
	         " no matching refs for watch line\n" .
		 " $line\n";
		 return 1;
	}
#######################################################################
# }}} code 3.1.3: search $newfile $newversion (git mode w/ tag)
#######################################################################
    } else {
#######################################################################
# {{{ code 3.1.4: search $newfile $newversion (non-existing mode)
#######################################################################
	uscan_warn "Unknown mode=$options{'mode'} set in $watchfile\n";
	return 1;
#######################################################################
# }}} code 3.1.4: search $newfile $newversion (non-existing mode)
#######################################################################
    }
    uscan_verbose "Looking at \$base = $base with\n"
	. "    \$filepattern = $filepattern found\n"
	. "    \$newfile     = $newfile\n"
	. "    \$newversion  = $newversion which is newer than\n"
	. "    \$lastversion = $lastversion\n";
#######################################################################
# }}} code 3.1: search $newfile $newversion
#######################################################################

#######################################################################
# {{{ code 3.2: watchfile version=1 and older backward compatibility
#######################################################################
    # The original version of the code didn't use (...) in the watch
    # file to delimit the version number; thus if there is no (...)
    # in the pattern, we will use the old heuristics, otherwise we
    # use the new.

    if ($style eq 'old') {
        # Old-style heuristics
	if ($newversion =~ /^\D*(\d+\.(?:\d+\.)*\d+)\D*$/) {
	    $newversion = $1;
	} else {
	    uscan_warn <<"EOF";
$progname warning: In $watchfile, couldn\'t determine a
  pure numeric version number from the file name for watch line
  $line
  and file name $newfile
  Please use a new style watch file instead!
EOF
	    return 1;
	}
    }
#######################################################################
# }}} code 3.2: watchfile version=1 and older backward compatibility
#######################################################################

#######################################################################
# {{{ code 3.3: determine $upstream_url
#######################################################################
    # Determine download URL for tarball or signature
    my $upstream_url;
    # Upstream URL?  Copying code from below - ugh.
    if ($options{'mode'} eq 'git' or $options{'mode'} eq 'git-dumb') {
#######################################################################
# {{{ code 3.3.1: determine $upstream_url (git/git-dumb mode)
#######################################################################
	$upstream_url = "$base $newfile";
#######################################################################
# }}} code 3.3.1: determine $upstream_url (git/git-dumb mode)
#######################################################################
    } elsif ($site =~ m%^https?://%) {
#######################################################################
# {{{ code 3.3.2: determine $upstream_url (http mode)
#######################################################################
	# http is complicated due to absolute/relative URL issue
	if ($newfile =~ m%^\w+://%) {
	    $upstream_url = $newfile;
	} elsif ($newfile =~ m%^//%) {
	    $upstream_url = $site;
	    $upstream_url =~ s/^(https?:).*/$1/;
	    $upstream_url .= $newfile;
	} elsif ($newfile =~ m%^/%) {
	    # absolute filename
	    # Were there any redirections? If so try using those first
	    if ($#patterns > 0) {
		# replace $site here with the one we were redirected to
		foreach my $index (0 .. $#patterns) {
		    if ("$sites[$index]$newfile" =~ m&^$patterns[$index]$&) {
			$upstream_url = "$sites[$index]$newfile";
			last;
		    }
		}
		if (!defined($upstream_url)) {
		    uscan_verbose "Unable to determine upstream url from redirections,\n" .
			    "defaulting to using site specified in watch file\n";
		    $upstream_url = "$sites[0]$newfile";
		}
	    } else {
		$upstream_url = "$sites[0]$newfile";
	    }
	} else {
	    # relative filename, we hope
	    # Were there any redirections? If so try using those first
	    if ($#patterns > 0) {
		# replace $site here with the one we were redirected to
		foreach my $index (0 .. $#patterns) {
		    # skip unless the basedir looks like a directory
		    next unless $basedirs[$index] =~ m%/$%;
		    my $nf = "$basedirs[$index]$newfile";
		    if ("$sites[$index]$nf" =~ m&^$patterns[$index]$&) {
			$upstream_url = "$sites[$index]$nf";
			last;
		    }
		}
		if (!defined($upstream_url)) {
		    uscan_verbose "Unable to determine upstream url from redirections,\n" .
			    "defaulting to using site specified in watch file\n";
		    $upstream_url = "$urlbase$newfile";
		}
	    } else {
		$upstream_url = "$urlbase$newfile";
	    }
	}

	# mangle if necessary
	$upstream_url =~ s/&amp;/&/g;
	uscan_verbose "Matching target for downloadurlmangle: $upstream_url\n";
	if (exists $options{'downloadurlmangle'}) {
	    if (mangle($watchfile, \$line, 'downloadurlmangle:',
		    \@{$options{'downloadurlmangle'}}, \$upstream_url)) {
		return 1;
	    }
	}
#######################################################################
# }}} code 3.3.2: determine $upstream_url (http mode)
#######################################################################
    } else {
#######################################################################
# {{{ code 3.3.3: determine $upstream_url (ftp mode)
#######################################################################
	$upstream_url = "$base$newfile";
#######################################################################
# }}} code 3.3.3: determine $upstream_url (ftp mode)
#######################################################################
    }
    uscan_verbose "Upstream URL(+tag) to download is identified as"
	. "    $upstream_url\n";
#######################################################################
# }}} code 3.3: determine $upstream_url
#######################################################################

#######################################################################
# {{{ code 3.4: determine $newfile_base
#######################################################################
    my $newfile_base;
    if ($options{'mode'} eq 'git') {
	# git tarball name
	my $zsuffix = get_suffix($compression);
	$newfile_base = "$pkg-$newversion.tar.$zsuffix";
    } elsif (exists $options{'filenamemangle'}) {
	# HTTP or FTP site (with filenamemangle)
	if ($versionless) {
	    $newfile_base = $upstream_url;
	} else {
	    $newfile_base = $newfile;
	}
	uscan_verbose "Matching target for filenamemangle: $newfile_base\n";
	if (mangle($watchfile, \$line, 'filenamemangle:',
		\@{$options{'filenamemangle'}}, \$newfile_base)) {
	    return 1;
	}
	unless ($newversion) {
	    # uversionmanglesd version is '', make best effort to set it
	    $newfile_base =~ m/^.+?[-_]?(\d[\-+\.:\~\da-zA-Z]*)(?:\.tar\.(gz|bz2|xz)|\.zip)$/i;
	    $newversion = $1;
	    unless ($newversion) {
		uscan_warn "Fix filenamemangle to produce a filename with the correct version\n";
		return 1;
	    }
	    uscan_verbose "Newest upstream tarball version from the filenamemangled filename: $newversion\n";
	}
    } else {
	# HTTP or FTP site (without filenamemangle)
	$newfile_base = basename($newfile);
	if ($options{'mode'} eq 'http') {
	    # Remove HTTP header trash
	    $newfile_base =~ s/[\?#].*$//; # PiPy
	    # just in case this leaves us with nothing
	    if ($newfile_base eq '') {
		uscan_warn "No good upstream filename found after removing tailing ?... and #....\n   Use filenamemangle to fix this.\n";
		return 1;
	    }
        }
    }
    uscan_verbose "Filename (filenamemangled) for downloaded file: $newfile_base\n";
#######################################################################
# }}} code 3.4: determine $newfile_base
#######################################################################

#######################################################################
# {{{ code 3.5: compare $newversion against $mangled_lastversion
#######################################################################
    unless (defined $common_newversion) {
	$common_newversion = $newversion;
    }

    $dehs_tags{'debian-uversion'} = $lastversion;
    $dehs_tags{'debian-mangled-uversion'} = $mangled_lastversion;
    $dehs_tags{'upstream-version'} = $newversion;
    $dehs_tags{'upstream-url'} = $upstream_url;

    my $mangled_ver = Dpkg::Version->new("1:${mangled_lastversion}-0", check => 0);
    my $upstream_ver = Dpkg::Version->new("1:${newversion}-0", check => 0);
    my $compver;
    if ($mangled_ver == $upstream_ver) {
	$compver = 'same';
    } elsif ($mangled_ver > $upstream_ver) {
	$compver = 'older';
    } else {
	$compver = 'newer';
    }

    # Version dependent $download adjustment
    if (defined $download_version) {
	# Pretend to found a newer upstream version to exit without error
	uscan_msg "Newest version of $pkg on remote site is $newversion, specified download version is $download_version\n";
	$found++;
    } elsif ($options{'versionmode'} eq 'newer') {
	if ($compver eq 'newer') {
	    uscan_msg "Newest version of $pkg on remote site is $newversion, local version is $lastversion\n" .
		($mangled_lastversion eq $lastversion ? "" : " (mangled local version is $mangled_lastversion)\n");
	    # There's a newer upstream version available, which may already
	    # be on our system or may not be
	    uscan_msg "   => Newer package available from\n" .
		      "      $upstream_url\n";
	    $dehs_tags{'status'} = "newer package available";
	    $found++;
	} elsif ($compver eq 'same') {
	    uscan_verbose "Newest version of $pkg on remote site is $newversion, local version is $lastversion\n" .
		($mangled_lastversion eq $lastversion ? "" : " (mangled local version is $mangled_lastversion)\n");
	    uscan_verbose "   => Package is up to date for from\n" .
		      "      $upstream_url\n";
	    $dehs_tags{'status'} = "up to date";
	    if ($download > 1) {
		# 2=force-download or 3=overwrite-download
		uscan_verbose "   => Forcing download as requested\n";
		$found++;
	    } else {
		# 0=no-download or 1=download
		$download = 0;
	    }
	} else { # $compver eq 'old'
	    uscan_verbose "Newest version of $pkg on remote site is $newversion, local version is $lastversion\n" .
		($mangled_lastversion eq $lastversion ? "" : " (mangled local version is $mangled_lastversion)\n");
	    uscan_verbose "   => Only older package available from\n" .
		      "      $upstream_url\n";
	    $dehs_tags{'status'} = "only older package available";
	    if ($download > 1) {
		uscan_verbose "   => Forcing download as requested\n";
		$found++;
	    } else {
		$download = 0;
	    }
	}
    } elsif ($options{'versionmode'} eq 'ignore') {
	uscan_msg "Newest version of $pkg on remote site is $newversion, ignore local version\n";
	$dehs_tags{'status'} = "package available";
	$found++;
    } else { # same/previous -- secondary-tarball or signature-file
	uscan_die "strange ... <version> stanza = same/previous should have defined \$download_version\n";
    }

    # If we're not downloading or performing signature verification, we can
    # stop here
    if (!$download || $signature == -1)
    {
	return 0;
    }
#######################################################################
# }}} code 3.5: compare $newversion against $mangled_lastversion
#######################################################################

#######################################################################
# {{{ code 3.6: download tarball
#######################################################################
    my $download_available = 0;
    my $signature_available = 0;
    my $sigfile;
    my $sigfile_base = $newfile_base;
    if ($options{'pgpmode'} ne 'previous') {
	# try download package
	if ( $download == 3 and -e "$destdir/$newfile_base") {
	    uscan_verbose "Downloading and overwriting existing file: $newfile_base\n";
	    $download_available = downloader($upstream_url, "$destdir/$newfile_base", \%options, $base, $pkg_dir);
	    if ($download_available) {
		dehs_verbose "Successfully downloaded package: $newfile_base\n";
	    } else {
		dehs_verbose "Failed to download upstream package: $newfile_base\n";
	    }
	} elsif ( -e "$destdir/$newfile_base") {
	    $download_available = 1;
	    dehs_verbose "Not downloading, using existing file: $newfile_base\n";
	} elsif ($download >0) {
	    uscan_verbose "Downloading upstream package: $newfile_base\n";
	    $download_available = downloader($upstream_url, "$destdir/$newfile_base", \%options, $base, $pkg_dir);
	    if ($download_available) {
		dehs_verbose "Successfully downloaded package: $newfile_base\n";
	    } else {
		dehs_verbose "Failed to download upstream package: $newfile_base\n";
	    }
	} else { # $download = 0,
	    $download_available = 0;
	    dehs_verbose "Not downloading upstream package: $newfile_base\n";
	}
    }
    if ($options{'pgpmode'} eq 'self') {
	$gpghome = tempdir(CLEANUP => 1);
	$sigfile_base =~ s/^(.*?)\.[^\.]+$/$1/; # drop .gpg, .asc, ...
	if ($signature == -1) {
	    uscan_warn("SKIP Checking OpenPGP signature (by request).\n");
	    $download_available = -1; # can't proceed with self-signature archive
	    $signature_available = 0;
	} elsif (! defined $keyring) {
	    uscan_die("FAIL Checking OpenPGP signature (no keyring).\n");
	} elsif ($download_available == 0) {
	    uscan_warn "FAIL Checking OpenPGP signature (no signed upstream tarball downloaded).\n";
	    return 1;
	} else {
	    uscan_verbose "Verifying OpenPGP self signature of $newfile_base and extract $sigfile_base\n";
	    unless (system($havegpg, '--homedir', $gpghome,
		    '--no-options', '-q', '--batch', '--no-default-keyring',
		    '--keyring', $keyring, '--trust-model', 'always', '--decrypt', '-o',
		    "$destdir/$sigfile_base", "$destdir/$newfile_base") >> 8 == 0) {
		uscan_die("OpenPGP signature did not verify.\n");
	    }
	    # XXX FIXME XXX extract signature as detached signature to $destdir/$sigfile
	    $sigfile = $newfile_base; # XXX FIXME XXX place holder
	    $newfile_base = $sigfile_base;
	    $signature_available = 3;
	}
    }
    if ($options{'pgpmode'} ne 'previous') {
	# Decompress archive if requested and applicable
	if ($download_available == 1 and $options{'decompress'}) {
	    my $suffix_gz = $sigfile_base;
	    $suffix_gz =~ s/.*?(\.gz|\.xz|\.bz2|\.lzma)?$/$1/;
	    if ($suffix_gz eq '.gz') {
		if ( -x '/bin/gunzip') {
		    system('/bin/gunzip', "--keep", "$destdir/$sigfile_base") == 0 or uscan_die("gunzip $destdir/$sigfile_base failed\n");
		    $sigfile_base =~ s/(.*?)\.gz/$1/;
		} else {
		    uscan_warn("Please install gzip.\n");
		    return 1;
		}
	    } elsif ($suffix_gz eq '.xz') {
		if ( -x '/usr/bin/unxz') {
		    system('/usr/bin/unxz', "--keep", "$destdir/$sigfile_base") == 0 or uscan_die("unxz $destdir/$sigfile_base failed\n");
		    $sigfile_base =~ s/(.*?)\.xz/$1/;
		} else {
		    uscan_warn("Please install xz-utils.\n");
		    return 1;
		}
	    } elsif ($suffix_gz eq '.bz2') {
		if ( -x '/bin/bunzip2') {
		    system('/bin/bunzip2', "--keep", "$destdir/$sigfile_base") == 0 or uscan_die("bunzip2 $destdir/$sigfile_base failed\n");
		    $sigfile_base =~ s/(.*?)\.bz2/$1/;
		} else {
		    uscan_warn("Please install bzip2.\n");
		    return 1;
		}
	    } elsif ($suffix_gz eq '.lzma') {
		if ( -x '/usr/bin/unlzma') {
		    system('/usr/bin/unlzma', "--keep", "$destdir/$sigfile_base") == 0 or uscan_die("unlzma $destdir/$sigfile_base failed\n");
		    $sigfile_base =~ s/(.*?)\.lzma/$1/;
		} else {
		    uscan_warn "Please install xz-utils or lzma.\n";
		    return 1;
		}
	    } else {
		uscan_warn "Unknown type file to decompress: $sigfile_base\n";
		exit 1;
	    }
	}
    }
#######################################################################
# }}} code 3.6: download tarball
#######################################################################

#######################################################################
# {{{ code 3.7: download signature
#######################################################################
    my $pgpsig_url;
    my $suffix_sig;
    if (($options{'pgpmode'} eq 'default' or $options{'pgpmode'} eq 'auto') and $signature == 1) {
	uscan_verbose "Start checking for common possible upstream OpenPGP signature files\n";
	foreach $suffix_sig (qw(asc gpg pgp sig sign)) {
	    my $sigrequest = HTTP::Request->new('HEAD' => "$upstream_url.$suffix_sig");
	    my $sigresponse = $user_agent->request($sigrequest);
	    if ($sigresponse->is_success()) {
		if ($options{'pgpmode'} eq 'default') {
		    uscan_warn "Possible OpenPGP signature found at:\n   $upstream_url.$suffix_sig\n * Add opts=pgpsigurlmangle=s/\$/.$suffix_sig/ or opts=pgpmode=auto to debian/watch\n * Add debian/upstream/signing-key.asc.\n See uscan(1) for more details\n";
		    $options{'pgpmode'} = 'none';
		} else { # auto
		    $options{'pgpmode'} = 'mangle';
		    $options{'pgpsigurlmangle'} = [ 's/$/.' . $suffix_sig . '/', ];
		}
		last;
	    }
	}
	uscan_verbose "End checking for common possible upstream OpenPGP signature files\n";
	$signature_available = 0;
    }
    if ($options{'pgpmode'} eq 'mangle') {
	$pgpsig_url = $upstream_url;
	if (mangle($watchfile, \$line, 'pgpsigurlmangle:',
		\@{$options{'pgpsigurlmangle'}}, \$pgpsig_url)) {
	    return 1;
	}
	if (! $suffix_sig) {
	    $suffix_sig = $pgpsig_url;
	    $suffix_sig =~ s/^.*\.//;
	    if ($suffix_sig and $suffix_sig !~ m/^[a-zA-Z]+$/) { # strange suffix
		$suffix_sig = "pgp";
	    }
	    uscan_debug "Add $suffix_sig suffix based on $pgpsig_url.\n";
	}
	$sigfile = "$sigfile_base.$suffix_sig";
	if ($signature == 1) {
	    uscan_verbose "Downloading OpenPGP signature from\n   $pgpsig_url (pgpsigurlmangled)\n   as $sigfile\n";
	    $signature_available = downloader($pgpsig_url, "$destdir/$sigfile", \%options, $base, $pkg_dir);
	} else { # -1, 0
	    uscan_verbose "Not downloading OpenPGP signature from\n   $pgpsig_url (pgpsigurlmangled)\n   as $sigfile\n";
	    $signature_available = (-e "$destdir/$sigfile") ? 1 : 0;
	}
    } elsif ($options{'pgpmode'} eq 'previous') {
	$pgpsig_url = $upstream_url;
	$sigfile = $newfile_base;
	if ($signature == 1) {
	    uscan_verbose "Downloading OpenPGP signature from\n   $pgpsig_url (pgpmode=previous)\n   as $sigfile\n";
	    $signature_available = downloader($pgpsig_url, "$destdir/$sigfile", \%options, $base, $pkg_dir);
	} else { # -1, 0
	    uscan_verbose "Not downloading OpenPGP signature from\n   $pgpsig_url (pgpmode=previous)\n   as $sigfile\n";
	    $signature_available = (-e "$destdir/$sigfile") ? 1 : 0;
	}
	$download_available = $previous_download_available;
	$newfile_base = $previous_newfile_base;
	$sigfile_base = $previous_sigfile_base;
	uscan_verbose "Use $newfile_base as upstream package (pgpmode=previous)\n";
    }
#######################################################################
# }}} code 3.7: download signature
#######################################################################

#######################################################################
# {{{ code 3.8: signature verification (pgpmode)
#######################################################################
    if ($options{'pgpmode'} eq 'mangle' or $options{'pgpmode'} eq 'previous') {
	if ($signature == -1) {
	    uscan_verbose("SKIP Checking OpenPGP signature (by request).\n");
	} elsif (! defined $keyring) {
	    uscan_die("FAIL Checking OpenPGP signature (no keyring).\n");
	} elsif ($download_available == 0) {
	    uscan_warn "FAIL Checking OpenPGP signature (no upstream tarball downloaded).\n";
	    return 1;
	} elsif ($signature_available == 0) {
	    uscan_die("FAIL Checking OpenPGP signature (no signature file downloaded).\n");
	} else {
	    if ($signature ==0) {
		uscan_verbose "Use the existing file: $sigfile\n";
	    }
	    uscan_verbose "Verifying OpenPGP signature $sigfile for $sigfile_base\n";
	    unless(system($havegpgv, '--homedir', '/dev/null',
		    '--keyring', $keyring,
		    "$destdir/$sigfile", "$destdir/$sigfile_base") >> 8 == 0) {
		uscan_die("OpenPGP signature did not verify.\n");
	    }
	}
	$previous_newfile_base = undef;
	$previous_sigfile_base = undef;
	$previous_newversion = undef;
	$previous_download_available = undef;
    } elsif ($options{'pgpmode'} eq 'none' or $options{'pgpmode'} eq 'default') {
	uscan_verbose "Missing OpenPGP signature.\n";
	$previous_newfile_base = undef;
	$previous_sigfile_base = undef;
	$previous_newversion = undef;
	$previous_download_available = undef;
    } elsif ($options{'pgpmode'} eq 'next') {
	uscan_verbose "Defer checking OpenPGP signature to the next watch line\n";
	$previous_newfile_base = $newfile_base;
	$previous_sigfile_base = $sigfile_base;
	$previous_newversion = $newversion;
	$previous_download_available = $download_available;
	uscan_verbose "previous_newfile_base = $newfile_base\n";
	uscan_verbose "previous_sigfile_base = $sigfile_base\n";
	uscan_verbose "previous_newversion = $newversion\n";
	uscan_verbose "previous_download_available = $download_available\n";
    } elsif ($options{'pgpmode'} eq 'self') {
	$previous_newfile_base = undef;
	$previous_sigfile_base = undef;
	$previous_newversion = undef;
	$previous_download_available = undef;
    } elsif ($options{'pgpmode'} eq 'auto') {
	uscan_verbose "Don't check OpenPGP signature\n";
    } else {
	uscan_warn "strange ... unknown pgpmode = $options{'pgpmode'}\n";
	return 1;
    }
    my $mangled_newversion = $newversion;
    if (mangle($watchfile, \$line, 'oversionmangle:',
	    \@{$options{'oversionmangle'}}, \$mangled_newversion)) {
	return 1;
    }

    if (! defined $common_mangled_newversion) {
    	# $mangled_newversion = version used for the new orig.tar.gz (a.k.a oversion)
    	uscan_verbose "New orig.tar.* tarball version (oversionmangled): $mangled_newversion\n";
	# MUT package always use the same $common_mangled_newversion
	# MUT disables repacksuffix so it is safe to have this before mk-origtargz
	$common_mangled_newversion = $mangled_newversion;
    }
    if ($options{'pgpmode'} eq 'next') {
	uscan_verbose "Read the next watch line (pgpmode=next)\n";
	return 0;
    }
    if ($safe) {
	uscan_verbose "SKIP generation of orig.tar.* and running of script/uupdate (--safe)\n";
	return 0;
    }
    if ($download_available == 0) {
	uscan_warn "No upstream tarball downloaded.  No further processing with mk_origtargz ...\n";
	return 1;
    }
    if ($download_available == -1) {
	uscan_warn "No upstream tarball unpacked from self signature file.  No further processing with mk_origtargz ...\n";
	return 1;
    }
    if ($signature_available == 1 and $options{'decompress'}) {
	$signature_available = 2;
    }
#######################################################################
# }}} code 3.8: signature verification (pgpmode)
#######################################################################

#######################################################################
# {{{ code 3.9: call mk-origtargz
#######################################################################
    #########################################################################
    # upstream tar file and, if available, signature file are downloaded
    # by parsing a watch file line.
    #########################################################################
    # upstream tarball: $destdir/$newfile_base   -- original tar.gz-like
    # upstream tarball: $destdir/$sigfile_base   -- decompressed tar if requested
    #  * for pgpmode=self                        -- the tarball as gpg extracted
    #  * for other cases                         -- the tarball as downloaded
    # signature file:   $destdir/$sigfile"
    #  * for $signature_available = 0            -- no signature file
    #  * for $signature_available = 1            -- normal signature file
    #  * for $signature_available = 2            -- signature file on decompressed
    #  * for $signature_available = 3            -- non-detached signature (XXX FIXME XXX)
    #      If pgpmode=self case in the above is fixed, below
    #      " and ($options{'pgpmode'} ne 'self')" may be dropped.
    # New version after making the new orig[-component].tar.gz:
    #     $common_mangled_newversion
    #         -- this is true when repacksuffix isn't used.
    #########################################################################
    # Call mk-origtargz (renames, repacks, etc.)
    #########################################################################
    my $mk_origtargz_out;
    my $path = "$destdir/$newfile_base";
    my $target = $newfile_base;
    unless ($symlink eq "no") {
	my @cmd = ("mk-origtargz");
	push @cmd, "--package", $pkg;
	push @cmd, "--version", $common_mangled_newversion;
	push @cmd, '--repack-suffix', $options{repacksuffix} if defined $options{repacksuffix};
	push @cmd, "--rename" if $symlink eq "rename";
	push @cmd, "--copy"   if $symlink eq "copy";
	push @cmd, "--signature", $signature_available
            if ($signature_available != 0);
	push @cmd, "--signature-file", "$destdir/$sigfile"
            if ($signature_available != 0);
	push @cmd, "--repack" if $options{'repack'};
	push @cmd, "--component", $options{'component'} if defined $options{'component'};
	push @cmd, "--compression", $compression;
	push @cmd, "--directory", $destdir;
	push @cmd, "--copyright-file", "debian/copyright"
	    if ($exclusion && -e "debian/copyright");
	push @cmd, "--copyright-file", $copyright_file
	    if ($exclusion && defined $copyright_file);
	push @cmd, "--unzipopt", $options{'unzipopt'} if defined $options{'unzipopt'};
	push @cmd, $path;

	my $actioncmd = join(" ", @cmd);
	uscan_verbose "Executing internal command:\n   $actioncmd\n";
	spawn(exec => \@cmd,
	      to_string => \$mk_origtargz_out,
	      wait_child => 1);
	chomp($mk_origtargz_out);
	$path = $1 if $mk_origtargz_out =~ /Successfully .* (?:to|as) ([^,]+)(?:,.*)?\.$/;
	$path = $1 if $mk_origtargz_out =~ /Leaving (.*) where it is/;
	$target = basename($path);
	$common_mangled_newversion = $1 if $target =~ m/[^_]+_(.+)\.orig(?:-.+)?\.tar\.(?:gz|bz2|lzma|xz)$/;
	uscan_verbose "New orig.tar.* tarball version (after mk-origtargz): $common_mangled_newversion\n";
    }
    push @origtars, $target;

    if ($opt_log) {
	# Check pkg-ver.tar.gz and pkg_ver.orig.tar.gz
	if (! defined $uscanlog) {
	    $uscanlog = "${destdir}/${pkg}_${common_mangled_newversion}.uscan.log";
	    if (-e "$uscanlog.old") {
		unlink "$uscanlog.old" or uscan_die "Can\'t remove old backup log $uscanlog.old: $!";
		uscan_warn "Old backup uscan log found.  Remove: $uscanlog.old\n";
	    }
	    if (-e $uscanlog) {
		move($uscanlog, "$uscanlog.old");
		uscan_warn "Old uscan log found.  Moved to: $uscanlog.old\n";
	    }
	    open(USCANLOG, ">> $uscanlog") or uscan_die "$progname: could not open $uscanlog for append: $!\n";
	    print USCANLOG "# uscan log\n";
	} else {
	    open(USCANLOG, ">> $uscanlog") or uscan_die "$progname: could not open $uscanlog for append: $!\n";
	}
	if ($symlink ne "rename") {
	    my $umd5sum = Digest::MD5->new;
	    my $omd5sum = Digest::MD5->new;
	    open (my $ufh, '<', "${destdir}/${newfile_base}") or uscan_die "Can't open '${destdir}/${newfile_base}': $!";
	    open (my $ofh, '<', "${destdir}/${target}") or uscan_die "Can't open '${destdir}/${target}': $!";
	    $umd5sum->addfile($ufh);
	    $omd5sum->addfile($ofh);
	    close($ufh);
	    close($ofh);
	    my $umd5hex = $umd5sum->hexdigest;
	    my $omd5hex = $omd5sum->hexdigest;
	    if ($umd5hex eq $omd5hex) {
		print USCANLOG "# == ${newfile_base}\t-->\t${target}\t(same)\n";
	    } else {
		print USCANLOG "# !! ${newfile_base}\t-->\t${target}\t(changed)\n";
	    }
	    print USCANLOG "$umd5hex  ${newfile_base}\n";
	    print USCANLOG "$omd5hex  ${target}\n";
	}
	close USCANLOG or uscan_die "$progname: could not close $uscanlog: $!\n";
    }

    dehs_verbose "$mk_origtargz_out\n" if defined $mk_origtargz_out;
    $dehs_tags{target} = $target;
    $dehs_tags{'target-path'} = $path;
#######################################################################
# }}} code 3.9: call mk-origtargz
#######################################################################

#######################################################################
# {{{ code 3.10: call uupdate
#######################################################################
    # Do whatever the user wishes to do
    if ($action) {
	my @cmd = shellwords($action);

	# script invocation changed in $watch_version=4
	if ($watch_version > 3) {
	    if ($cmd[0] eq "uupdate") {
		push @cmd, "-f";
		if ($verbose) {
		    push @cmd, "--verbose";
		}
		if ($badversion) {
		    push @cmd, "-b";
	        }
	    }
	    push @cmd, "--upstream-version", $common_mangled_newversion;
	    if (abs_path($destdir) ne abs_path("..")) {
		foreach my $origtar (@origtars) {
		    copy(catfile($destdir, $origtar), catfile("..", $origtar));
		}
	    }
	} elsif ($watch_version > 1) {
	    # Any symlink requests are already handled by uscan
	    if ($cmd[0] eq "uupdate") {
		push @cmd, "--no-symlink";
		if ($verbose) {
		    push @cmd, "--verbose";
		}
		if ($badversion) {
		    push @cmd, "-b";
	        }
	    }
	    push @cmd, "--upstream-version", $common_mangled_newversion, $path;
	} else {
	    push @cmd, $path, $common_mangled_newversion;
	}
	my $actioncmd = join(" ", @cmd);
	my $actioncmdmsg = `$actioncmd 2>&1`;
	$? == 0 or uscan_die "$progname: Failed to Execute user specified script:\n   $actioncmd\n" . $actioncmdmsg;
	dehs_verbose "Executing user specified script:\n   $actioncmd\n" . $actioncmdmsg;
    }

    return 0;
#######################################################################
# }}} code 3.10: call uupdate
#######################################################################
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

