#!/usr/bin/env perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '0.1';

my %opts = (
    help    => 0,
    version => 0,
);

Getopt::Long::Configure('bundling');
GetOptions('h|help' => \$opts{help},
    'V|version'     => \$opts{version},
) or pod2usage(1);
if ($opts{help}) {
    pod2usage(-exitstatus => 0, -verbose => 2);
}
if ($opts{version}) {
    print "remove_lang_from_content.pl v$VERSION\n";
    exit 0;
}

if (@ARGV < 1) {
    pod2usage(1);
}

my $infile = shift;
my $outfile = shift || substr($infile, 0, -4) . "_out.pdf";

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

my $num_pages = $doc->numPages();

# обход всех страниц
print "NumPages: $num_pages\n";

sub removeLastModified {
    my $self = shift;
    my $pagenum = shift;

    my $page = $self->getPage($pagenum);
    if ($page && exists $page->{LastModified}) {
        # remove link
        delete $page->{LastModified};
        my ($objnum, $gennum) = $self->getPageObjnum($pagenum);
        $self->{changes}->{$objnum} = 1;
        print "$pagenum: remove LastModified\n";
    }
}

for my $pagenum (1 .. $num_pages) {
    removeLastModified($doc, $pagenum);
}

#updatePageContent2($doc, 3);

# $doc->cleanse();
$doc->output($outfile);

__END__

=for stopwords removelan.pl

=head1 NAME

remove_lanit.pl - Remove conent added to the pages

=head1 SYNOPSIS

 remove_lanit.pl [options] infile.pdf [outfile.pdf]

 Options:
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Outputs to out.pdf.

=head1 AUTHOR

L<sv99@inbox.ru>

=cut
