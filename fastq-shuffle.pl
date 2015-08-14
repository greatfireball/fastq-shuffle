#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

my $ret = GetOptions(
    'r|srand=d' => \(my $srand_init),
    '1|reads=s' => \(my $reads),
    '2|mates=s' => \(my $mates),
    'single=s'  => \(my $singles),
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
