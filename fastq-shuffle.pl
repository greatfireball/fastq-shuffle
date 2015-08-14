#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use Term::ProgressBar;

my ($input_first, $input_second, $output_first, $output_second, $random_seed);

GetOptions(
    'input1|1=s' => \$input_first,
    'input2|2=s' => \$input_second,
    'output1|o1=s' => \$output_first,
    'output2|o2=s' => \$output_second,
    'randomseed|seed|s=i' => \$random_seed
    );

# check if the first file is existing
unless (-e $input_first)
{
    die "First input file is required\n";
}

# check if the second file is existing
unless (-e $input_second)
{
    die "Second input file is required\n";
}

# check if a random seed is giving and set srand if a value is giving
if (defined $random_seed)
{
    $random_seed = srand($random_seed);
} else {
    $random_seed = srand;
}

# print the srand value as info
printf "Using %d as srand value for the inilation of the pseudo random generator\n", $random_seed;
    
# estimate the filesize of the first and the second input file
my ($input_first_filesize, $input_second_filesize) = (-s $input_first, -s $input_second);

my $input_data = "";
my $pos = 0;
my @sets = ();

my $progress = Term::ProgressBar->new({name  => 'Reading Input ',
				       count => $input_first_filesize+$input_second_filesize,
				       ETA   => 'linear', });
$progress->max_update_rate(1);
my $next_update = 0;

open(FIRST, "<", $input_first) || die "Unable to open input file '$input_first': $!";
open(SECOND, "<", $input_second) || die "Unable to open input file '$input_second': $!";

while (! (eof(FIRST) || eof(SECOND)))
{
    # read four lines from each file and combine them using a \0 as delimiter
    my $dataset = join("", scalar <FIRST>, scalar <FIRST>, scalar <FIRST>, scalar <FIRST>, scalar <SECOND>, scalar <SECOND>, scalar <SECOND>, scalar <SECOND>);
    
    my $len = length($dataset);
    
    push(@sets, [$pos, $len]);

    $pos+=$len;
    $input_data .= $dataset;

    $next_update = $progress->update($pos)
	if $pos > $next_update;

}

$progress->update($input_first_filesize+$input_second_filesize)
      if ($input_first_filesize+$input_second_filesize) >= $next_update;

close(FIRST) || die "Unable to close input file '$input_first': $!";
close(SECOND) || die "Unable to close input file '$input_second': $!";

printf "Number of input sets: %d\n", scalar @sets;

$progress = Term::ProgressBar->new({name  => 'Shuffling     ',
				       count => scalar @sets,
				       ETA   => 'linear', });
$progress->max_update_rate(1);
$next_update = 0;

for (my $i=0; $i<scalar @sets; $i++)
{

    my $j = int(rand(@sets));

    ($sets[$i], $sets[$j]) = ($sets[$j], $sets[$i]);

    $next_update = $progress->update($i)
	if $i > $next_update;

}

$progress->update(scalar @sets)
      if (scalar @sets) >= $next_update;

## writing output

print "Writing output files...\n";

$progress = Term::ProgressBar->new({name  => 'Writing Output',
				       count => scalar @sets,
				       ETA   => 'linear', });
$progress->max_update_rate(1);
$next_update = 0;

open(FIRST, ">", $output_first) || die "Unable to open output file '$output_first': $!";
open(SECOND, ">", $output_second) || die "Unable to open output file '$output_second': $!";

for (my $i=0; $i<scalar @sets; $i++)
{

    my @dat = split("\n", substr($input_data, $sets[$i][0], $sets[$i][1]));

    print FIRST $dat[0], "\n", $dat[1], "\n", $dat[2], "\n", $dat[3], "\n";
    print SECOND $dat[4], "\n", $dat[5], "\n", $dat[6], "\n", $dat[7], "\n";

    $next_update = $progress->update($i)
	if $i > $next_update;

}

$progress->update(scalar @sets)
      if (scalar @sets) >= $next_update;

close(FIRST) || die "Unable to close output file '$output_first': $!";
close(SECOND) || die "Unable to close output file '$output_second': $!";
