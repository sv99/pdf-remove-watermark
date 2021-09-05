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
    print "remove_lanit.pl v$VERSION\n";
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

sub getPageContent2 {
    my $self = shift;
    my $pagenum = shift;

    my $page = $self->getPage($pagenum);
    if (!$page || !exists $page->{Contents}) {
        return q{};
    }

    my $contents = $self->getValue($page->{Contents});

    if (!ref $contents) {
        return $contents;
    }
    elsif ((ref $contents) eq 'HASH') {
        # doesn't matter if it's not encoded...
        return $self->decodeOne(CAM::PDF::Node->new('dictionary', $contents));
    }
    elsif ((ref $contents) eq 'ARRAY') {
        # Ланит массив
        my @ctx = @{$contents};
        my $ctx_len = @ctx;
        print "ContentArrayLen: $ctx_len\n";
        my $stream = q{};
        if ($ctx_len == 3) {
            # 2 element - data
            my $streamdata = $self->getValue($ctx[1]);
            $stream = $self->decodeOne(CAM::PDF::Node->new('dictionary', $streamdata));
        }
        else {
            for my $arrobj (@{$contents}) {
                my $streamdata = $self->getValue($arrobj);
                if (!ref $streamdata) {
                    $stream .= $streamdata;
                }
                elsif ((ref $streamdata) eq 'HASH') {
                    $stream .= $self->decodeOne(CAM::PDF::Node->new('dictionary', $streamdata)); # doesn't matter if it's not encoded...
                }
                else {
                    die "Unexpected content type for page contents\n";
                }
            }
        }
        return $stream;
    }
    else {
        die "Unexpected content type for page contents\n";
    }
}

for my $pagenum (1 .. $num_pages) {
    my $ctx = getPageContent2($doc, $pagenum);
    $doc->setPageContent($pagenum, "$ctx\n")
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
