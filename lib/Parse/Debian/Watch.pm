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

