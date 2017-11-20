#!/usr/bin/perl -w 
use strict;
use lib ('/sonas-hs/ware/hpc/home/mcampbel/lib');
use PostData;
use Getopt::Std;
use vars qw($opt_i $opt_e $opt_g $opt_p $opt_c $opt_m $opt_u);
getopts('iegpcmu');
use FileHandle;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "\n\n\t
Splits the file by chromosome, filters out lowqual, non-variant, and multialleleic sites

split_vcf_by_contig_and_filter.pl <mulit_vcf.vcf>

The input vcf file has to be either in the same directory you are running this script in or softlinked to the same directory. I use part of the input file as the output file name and a reletive or absolute path will mess it up.

\n\n";

my $FILE = $ARGV[0];
die($usage) unless $ARGV[0];

my ($header_ar, $output_files_hr) = parse_header($FILE);
#PostData($output_files_hr);
print_header($header_ar, $output_files_hr);
print_the_varint_entries($FILE, $output_files_hr);

#-----------------------------------------------------------------------------
#---------------------------------- SUBS -------------------------------------
#-----------------------------------------------------------------------------
sub print_the_varint_entries{
    print STDERR "printing variants\n";
    my $file = shift;
    my $out_files_hr = shift;

    my $fh = new FileHandle;
    $fh->open($file);

    while (defined(my $line = <$fh>)){
        chomp($line);
	
	next if $line =~ /^\#/;
	my @cols = split(/\t/, $line);
	next if $cols[6] eq 'LowQual';
	next if $cols[4] eq '.'; #exclude non-variant loci
	my @alt = split(//, $cols[4]); 
	my $alt_count = @alt;
	#print $alt_count ."\n";
	next if $alt_count > 1; #don't print if multialleleic
	print {$out_files_hr->{$cols[0]}} "$line\n";
	

    }
    $fh->close();
}
#-----------------------------------------------------------------------------
sub print_header{
    print STDERR "printing header\n";
    my $header_ar       = shift;
    my $out_files_hr = shift;
    #PostData($output_files_hr);    
    
    foreach my $seqid (keys %{$output_files_hr}){
	foreach my $line (@{$header_ar}){
	    unless ($line =~ /^\#\#contig/ && 
		    $line !~ /^\#\#contig=<ID=$seqid,/){
		#skip the contig lines that don't match the seqid
		print {$out_files_hr->{$seqid}} "$line\n"; 
		#the extra brackets in the print are important for printing 
		#to filehandles in hashes
	    }	    
	}
    }
}
#-----------------------------------------------------------------------------
sub parse_header{

    my $file = shift;       
    my @header;
    my %output_files;
    my $fh = new FileHandle;
    $fh->open($file);
    
    while (defined(my $line = <$fh>)){
	chomp($line);
	last if $line !~ /^\#/; #stop when you get to the end of the header
	push(@header, $line); #add each line of the header to the header array
	if ($line =~ /^\#\#contig=<ID=(\S+?),/){ #this could be modified to 
	    my $seqid = $1;                           #get the length as well
	    my $base = 'none';
	    if ($file =~ /^\.\.\/(\S+)/ || $file =~ /^\.\/(\S+)/ || $file =~ /\/(\S+)$/){
		$base = $1;
	    }
	    else{
		$base = $file;
	    }
	    my $outfile = $seqid ."_". $base; 
	    #print $outfile , "\n";
	    my $fh_alt = new FileHandle;
	    $fh_alt->open(">>$outfile");
	    $output_files{$seqid} = $fh_alt;
	    #print $fh_alt "test\n";
	}
	
    }
    $fh->close();
    return (\@header, \%output_files);
}
#-----------------------------------------------------------------------------

