#!/usr/bin/perl -w 
use strict;
use lib ('/home/mcampbell/lib');
use PostData;
use Getopt::Std;
use vars qw($opt_i $opt_e $opt_g $opt_p $opt_c $opt_m $opt_u);
getopts('iegpcmu');
use FileHandle;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "\n\n\t
This script takes a vcf file and parses out the sample columns so I can filter
based on that data.

UG_vcf_parser.pl ug_file.vcf

\n\n";

my $FILE = $ARGV[0];
die($usage) unless $ARGV[0];

parse($FILE);

#-----------------------------------------------------------------------------
#---------------------------------- SUBS -------------------------------------
#-----------------------------------------------------------------------------
sub parse{

    my $file = shift;       
    
    my $fh = new FileHandle;
    $fh->open($file);
    next unless $line =~ /^\#CHROM\t/ || $line =~ /^Contig/;
    while (defined(my $line = <$fh>)){
	chomp($line);
	if ($line =~ /^\#CHROM\t/){
	    $line =~ s/\#//;
	    my @header = split(/\t/, $line);
	    
	}

    }
    $fh->close();
}
#-----------------------------------------------------------------------------

