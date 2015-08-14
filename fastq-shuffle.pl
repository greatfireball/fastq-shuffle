#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use Term::ProgressBar;
use Term::ProgressBar::IO;

my $ret = GetOptions(
    'r|srand=i' => \(my $srand_init),
    '1|reads=s' => \(my $reads),
    '2|mates=s' => \(my $mates),
    'single=s'  => \(my $single),
);

# check if mates are set
if (defined $mates)
{
    # we need to have reads also set
    unless (defined $reads)
    {
	die "You need to provide reads and mates (-1 and -2). For single end sets use only -single or only -1 as parameter\n";
    }
}

# check if we have a single end set
if (defined $single || (defined $reads && ! defined $mates))
{
    $reads = $single; # we want to use reads for the input file
    $single = 1;
}

# initialze random generator
if (defined $srand_init)
{
    srand($srand_init);
} else {
    $srand_init = srand();
}

print STDERR "Randomgenerator was initialized with $srand_init\n";

my ($reads_fh, $mates_fh);
my ($reads_pb, $mates_pb);

open($reads_fh, "<", $reads) || die "Unable to open read file '$reads': $!\n";
$reads_pb = Term::ProgressBar::IO->new($reads_fh);

unless ($single)
{
    open($mates_fh, "<", $mates) || die "Unable to open second read file '$mates': $!\n";
    $mates_pb = Term::ProgressBar::IO->new($mates_fh);
}

my ($count_reads, $count_mates) = (0, 0);

my $position_information = "";

while (1)
{
    # Read first sequence block
    # store start position
    my $r_start = tell($reads_fh);

    # read four lines from reads
    my $r_header = <$reads_fh>;
    my $r_seq = <$reads_fh>;
    my $r_header2 = <$reads_fh>;
    my $r_qual = <$reads_fh>;

    # store end position
    my $r_end = tell($reads_fh)-1;

    # calculate length
    my $r_len = $r_end - $r_start + 1;

    $count_reads++;
    $reads_pb->update();

    my ($m_start, $m_len) = (0, 0);
    unless ($single)
    {
	# Read first sequence block
	# store start position
	$m_start = tell($mates_fh);

	# read four lines from reads
	my $m_header = <$mates_fh>;
	my $m_seq = <$mates_fh>;
	my $m_header2 = <$mates_fh>;
	my $m_qual = <$mates_fh>;

	# store end position
	my $m_end = tell($mates_fh)-1;

	# calculate length
	my $m_len = $m_end - $m_start + 1;

	$count_mates++;
	$mates_pb->update();
    }

    # store the information about the block
    $position_information .= pack("LLLL", $r_start, $r_len, $m_start, $m_len);
}

close($reads_fh) || die "Unable to close read file '$reads': $!\n";

unless ($single)
{
    close($mates_fh) || die "Unable to close second read file '$mates': $!\n";
}

=pod

=head1 Parameters

=head2 -r|--srand NUMBER

This is the inital value for the random generator. If not provided, it
will call srand to get the inital value and will print that value, if
verbose is activated.

=head2 -1|--reads FILENAME and -2|--mates FILENAME2

The location of the two input files for a paired end sequencing
result. If mates are set, one have to provide reads also. For single
end sequencing sets see --single parameter.

=head2 --single FILENAME

The location of the input file for a single end sequencing set.
