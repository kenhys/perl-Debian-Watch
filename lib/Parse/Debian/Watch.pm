package Parse::Debian::Watch;
use 5.010;
use strict;
use warnings;

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
it under the same terms as Perl itself.

=head1 AUTHOR

Kentaro Hayashi E<lt>hayashi@clear-code.comE<gt>

=cut

