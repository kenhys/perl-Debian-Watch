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

