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

sub updatePageContent2 {
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
        my $streamdata = $self->decodeOne(CAM::PDF::Node->new('dictionary', $contents));
        my $str_len = length($streamdata);
        # replace "/Lang (en-US)"
        $streamdata =~ s/\/Lang \(en-US\)//g;
        my $str_len2 = length($streamdata);
        # doesn't matter if it's not encoded...
        print "$pagenum: Content Len: $str_len -> $str_len2\n";
        if ($str_len != $str_len2) {
            $doc->setPageContent($pagenum, "$streamdata\n")
        }
        return $streamdata;
    }
    elsif ((ref $contents) eq 'ARRAY') {
        print "$pagenum: Content Array\n";
        return $contents;
    }
    else {
        die "Unexpected content type for page contents\n";
    }
}

for my $pagenum (1 .. $num_pages) {
    updatePageContent2($doc, $pagenum);
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
