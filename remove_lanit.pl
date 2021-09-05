#!/usr/bin/env perl -w

package main;

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '0.1';

my %opts = (
            help       => 0,
            version    => 0,
            );

Getopt::Long::Configure('bundling');
GetOptions('h|help'     => \$opts{help},
           'V|version'  => \$opts{version},
           ) or pod2usage(1);
if ($opts{help})
{
   pod2usage(-exitstatus => 0, -verbose => 2);
}
if ($opts{version})
{
   print "remove_lanit.pl v$VERSION\n";
   exit 0;
}

if (@ARGV < 1)
{
   pod2usage(1);
}

my $infile = shift;
my $outfile = shift || substr($infile, 0, -4) . "_out.pdf";

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

my $num_pages = $doc->numPages();

# обход всех страниц
print "NumPages: $num_pages\n";

for my $pagenum (1 .. $num_pages)
{
    my $ctx = $doc->getPageContent($pagenum);
    my $r = rindex $ctx, "ET";
    print "$pagenum - index: $r\n";
    # print "$ctx";
    if ( $r > 0 )
    {
        my $newctx = substr $ctx, 0, $r + 2;
        $doc->setPageContent ( $pagenum, "$newctx\n"  )
    }
}

$doc->cleanse();
$doc->cleanoutput($outfile);

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
