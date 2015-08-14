#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use Term::ProgressBar;
use File::stat;

my $ret = GetOptions(
    'r|srand=i' => \(my $srand_init),
    '1|reads=s' => \(my $reads),
    '2|mates=s' => \(my $mates),
    'single=s'  => \(my $single),
);

# here a the block information how to store the data
my $format_block = "LLLL";
my $len_block = length(pack($format_block, 0, 0, 0, 0));

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

my ($reads_out, $mates_out);

$reads_out = $reads."_out";
unless ($single)
{
    $mates_out = $mates."_out";
}

# initialze random generator
if (defined $srand_init)
{
    srand($srand_init);
} else {
    $srand_init = srand();
}

print STDERR "Randomgenerator was initialized with $srand_init\n";

my ($reads_fh, $mates_fh, $reads_out_fh, $mates_out_fh);

my ($reads_file, $mates_file) = ("", "");

my ($reads_size, $mates_size) = (0, 0);

open($reads_fh, "<", $reads) || die "Unable to open read file '$reads': $!\n";
open($reads_out_fh, ">", $reads_out) || die "Unable to open read file '$reads_out': $!\n";
$reads_size = stat($reads)->size;

unless ($single)
{
    open($mates_fh, "<", $mates) || die "Unable to open second read file '$mates': $!\n";
    open($mates_out_fh, ">", $mates_out) || die "Unable to open second read file '$mates_out': $!\n";
    $mates_size = stat($mates)->size;
}

my $pb = Term::ProgressBar->new({
    name  => "Reading input positions",
    count => $reads_size+$mates_size,
    ETA   => 'linear',
				});
my $next_update = 0;


my ($count_reads, $count_mates) = (0, 0);

my $position_information = "";

while (!( eof($reads_fh) && eof($mates_fh)) )
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

    $reads_file .= $r_header.$r_seq.$r_header2.$r_qual;

    my ($m_start, $m_len, $m_end) = (0, 0, 0);
    unless ($single || eof($mates_fh))
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
	$m_end = tell($mates_fh)-1;

	# calculate length
	$m_len = $m_end - $m_start + 1;

	$count_mates++;

	$mates_file .= $m_header.$m_seq.$m_header2.$m_qual;
    }


    if ($m_end+$r_end > $next_update)
    {
	$next_update = $pb->update($m_end+$r_end);
    }

    # store the information about the block
    $position_information .= pack($format_block, $r_start, $r_len, $m_start, $m_len);
}

# set the progressbar
$pb->update($reads_size+$mates_size);

# reopen reads/mates from memory
open($reads_fh, "<", \$reads_file) || die "$!\n";
open($mates_fh, "<", \$mates_file) || die "$!\n";

## now we need to shuffle

printf STDERR "Positions of %d read and %d mate blocks was determined. Now I need to shuffle those blocks...\n", $count_reads, $count_mates;

## initialize the progress bar again
$pb = Term::ProgressBar->new({
    name  => "Shuffling dataset",
    count => $count_reads,
    ETA   => 'linear',
			     });
$next_update = 0;

for (my $i=0; $i<$count_reads; $i++)
{
    # we want to start from upper border
    my $index = $count_reads-$i;

    # generate a index for a block to exchange those two blocks
    my $swap_with = int(rand($index));

    # the position of those blocks (0-based counted) is:
    my $swap_with_start = ($swap_with-1)*$len_block;
    my $index_start = ($index-1)*$len_block;

    # get the strings
    my $first = substr($position_information, $index_start, $len_block);
    my $second = substr($position_information, $swap_with_start, $len_block);

    # set the new string
    substr($position_information, $index_start, $len_block, $second);
    substr($position_information, $swap_with_start, $len_block, $first);

    # update progressbar
    if ($i > $next_update)
    {
	$next_update = $pb->update($i);
    }
}

$pb->update($count_reads);

printf STDERR "Shuffling finished... Writing output files...\n";

## initialize the progress bar again
$pb = Term::ProgressBar->new({
    name  => "Shuffling dataset",
    count => $count_reads,
    ETA   => 'linear',
			     });
$next_update = 0;

for (my $i=0; $i<$count_reads; $i++)
{

    my ($r_start, $r_len, $m_start, $m_len) = unpack($format_block, substr($position_information, $i*$len_block, $len_block));

    # seek to the position of the input data, read the dataset and write it to the outputfile
    my $dataset = "";
    seek($reads_fh, $r_start, 0) || die;
    read $reads_fh, $dataset, $r_len;
    print $reads_out_fh $dataset;
    unless ($single)
    {
	$dataset = "";
	seek($mates_fh, $m_start, 0) || die;
	read $mates_fh, $dataset, $m_len;
	print $mates_out_fh $dataset;
    }

    # update progressbar
    if ($i > $next_update)
    {
	$next_update = $pb->update($i);
    }
}

$next_update = $pb->update($count_reads);

close($reads_fh) || die "Unable to close read file '$reads': $!\n";
close($reads_out_fh) || die "Unable to close read file '$reads_out': $!\n";

unless ($single)
{
    close($mates_fh) || die "Unable to close second read file '$mates': $!\n";
    close($mates_out_fh) || die "Unable to close second read file '$mates_out': $!\n";
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
