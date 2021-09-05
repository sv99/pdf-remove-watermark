#!/usr/bin/env perl -w

use warnings;
use strict;
use CAM::PDF;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '0.1';

#
# remove red URL www.allitebooks.com
# added additional stream in the Content
# original stream converted to array of stream
#
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
    print "remove_alitebooks.pl v$VERSION\n";
    exit 0;
}

if (@ARGV < 1) {
    pod2usage(1);
}

my $infile = shift;
my $outfile = shift || substr($infile, 0, -4) . "_out.pdf";
my $first_page = shift || 1;

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

my $num_pages = $doc->numPages();

# обход всех страниц
print "NumPages: $num_pages\n";
print "Start from $first_page\n" if $first_page > 1;

for my $pagenum ($first_page .. $num_pages) {

    my $page = $doc->getPage($pagenum);

    my $contents = $doc->getValue($page->{Contents});

    my $ctx;
    if ((ref $contents) eq 'HASH') {
        # doesn't matter if it's not encoded...
        $ctx = $doc->decodeOne(CAM::PDF::Node->new('dictionary', $contents));
    }
    elsif ((ref $contents) eq 'ARRAY') {
        # original content - second in the array
        my $stream_data = $doc->getValue(@{$contents}[1]);
        my $stream_len = $doc->getValue($stream_data->{Length});
        $ctx = $doc->decodeOne(CAM::PDF::Node->new('dictionary', $stream_data)); # doesn't matter if it's not encoded...
        if (defined($ctx)) {
            print "$pagenum - find array contents\n";
            $doc->setPageContent($pagenum, "$ctx\n");
        }
        if ($page->{Annots}) {
            # remove link
            delete $page->{Annots};
        }
    }
    else {
        die "Unexpected content type for page contents\n";
    }
}

#$doc->cleanse();
#$doc->cleanoutput($outfile);
$doc->output($outfile);

__END__

=for stopwords removelan.pl

=head1 NAME

removelan.pl - Remove conent added to the pages

=head1 SYNOPSIS

 remove_alitebooks.pl [options] infile.pdf [outfile.pdf] [first_page]

 Options:
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Outputs to out.pdf.

=head1 AUTHOR

L<sv99@inbox.ru>

=cut
