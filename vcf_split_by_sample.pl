#!/usr/bin/perl -w 
use strict;
#use lib ('/home/mcampbell/lib');
#use PostData;
use Getopt::Std;
use vars qw($opt_s);
getopts('s:');
use FileHandle;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "\n\n\t
This script spits a multi vcf file into ingel vcf files for individuals

vcf_split_by_sample.pl [options] <multivcf.vcf>

Options -s <string> optional suffex to add to the output files defualt <.vcf>

\n\n";

my $FILE = $ARGV[0];
die($usage) unless $ARGV[0];

my $samples = parse_header($FILE);
split_file($FILE, $samples);
#-----------------------------------------------------------------------------
#---------------------------------- SUBS -------------------------------------
#-----------------------------------------------------------------------------
sub split_file{
    my $file    = shift;
    my $samples = shift;
    my @file_handles;
    my $count=0;
    foreach my $sample (@$samples){
	my $file_name = $sample;
	my $suf = $opt_s ? $opt_s : '.vcf';
	$file_name .= $suf;
#	print "$file_name\n";
	$count++;
	
	open(my $fh, '>', $file_name) or die "can open $file_name\n";
	push (@file_handles, $fh);
    } 

    my $fhv = new FileHandle;
    $fhv->open($file);
    
    while (defined(my $line = <$fhv>)){
	chomp($line);
	if ($line =~ /^\#\#/){
	    foreach my $fhs (@file_handles){
		print $fhs "$line\n";
	    }
	  #start printing the header here
	}
	else {
	    my @cols = split(/\t/, $line);
	    my @static = splice(@cols, 0, 9);
	    my $counter = 0;
	    foreach my $samples (@cols){
		my $fhs = $file_handles[$counter];
		print $fhs join("\t", @static);
		print $fhs "\t$samples\n";
		$counter++;	    
	    }
	}
    }	
    foreach my $fhs (@file_handles){
	close($fhs);
    }
}
#-----------------------------------------------------------------------------
sub parse_header{

    my $file = shift;       
    
    my $fh = new FileHandle;
    $fh->open($file);
    
    while (defined(my $line = <$fh>)){
	chomp($line);
	last if $line !~ /^\#/;
	if ($line =~ /^\#CHROM/){
	    my @all_cols = split(/\t/, $line);
	    my @discard = splice(@all_cols, 0, 9);
	    $fh->close();
	    return \@all_cols;
	}
    }
    print " I souldn't have gotten here\n";
}
#-----------------------------------------------------------------------------

