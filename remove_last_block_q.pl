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
    print "remove_last_block_q.pl v$VERSION\n";
    exit 0;
}

if (@ARGV < 1) {
    pod2usage(1);
}

my $infile = shift;
my $outfile = shift || substr($infile, 0, -4) . "_out.pdf";
my $first_page = shift || 1;
my $last_page = shift || -1;

my $doc = CAM::PDF->new($infile) || die "$CAM::PDF::errstr\n";

my $num_pages = $doc->numPages();
if ($last_page < 0) {
    $last_page = $num_pages;
}

# обход всех страниц
print "NumPages: $num_pages\n";
print "Start from $first_page\n" if $first_page > 1;
print "Last $last_page\n" if $last_page != $num_pages;

for my $pagenum ($first_page .. $last_page) {
    my $ctx = $doc->getPageContent($pagenum);

    # remove last q...Q block
    my $ctxlen = length($ctx);

    # check ended with double Q - nested blocks
    my $qq = rindex $ctx, "Q\nQ\n";
    my $q = rindex $ctx, "q\n";
    my $ctxSpace = 0;
    if ($q < 0) {
        $q = rindex $ctx, "q ";
        $ctxSpace = 1;
    }

    print "$pagenum - en: $ctxlen index QQ: $qq last q index: $q\n";
    # print "$ctx";
    if ( $q >= 0 )
    {
        my $newctx = substr $ctx, 0, $q;
        # if ($ctxSpace == 1) {
        #
        # } else {
        #     if ($qq == $ctxlen - 4) {
        #         $newctx .= "Q\n";
        #     }
        #     elsif ($newctx =~ /BT\nET\n$/) {
        #         # remove last empty BTET block
        #         $newctx = substr($newctx, 0, -6);
        #     }
        #     # check double block qq...QQ
        #     if ($newctx =~ /^q\nq\n/) {
        #         print "qq\n";
        #         if ($newctx =~ /Q\nQ\n$/) {
        #             print "QQ\n";
        #             $newctx = substr($newctx, 2, -2);
        #         }
        #     }
        # }
        # print $newctx;
        $doc->setPageContent ( $pagenum, "$newctx"  )
    }
}

#$doc->cleanse();
#$doc->cleanoutput($outfile);
$doc->output($outfile);

__END__

=for stopwords remove_last_block_q.pl

=head1 NAME

remove_last_block_q.pl - Remove conent added to the pages

=head1 SYNOPSIS

 remove_last_block_q.pl [options] infile.pdf [outfile.pdf] [first_page]

 Options:
   -h --help           verbose help message
   -V --version        print CAM::PDF version

=head1 DESCRIPTION

Outputs to out.pdf.

=head1 AUTHOR

L<sv99@inbox.ru>

=cut
