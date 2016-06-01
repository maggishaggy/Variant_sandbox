#!/usr/bin/perl -w 
use strict;
#use lib ('/home/mcampbell/lib');
#use PostData;
use Getopt::Std;
use vars qw($opt_l $opt_h);
getopts('l:h:');
use FileHandle;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "\n\n
This script takes a vcf file and filters out lines based on depth of coverage

USAGE:
filtering_vcf_based_on_depth_and_completenes.pl -l <int> -h <int> file.vcf

Options: -l <int> : minimum depth of coverage.
         -h <int> : maximum depth of coverage.

EXAMPLE:
./filtering_vcf_based_on_depth_and_completenes.pl -l 20 -h 45 srw_4s_3na_1np_contig0_only.vcf > srw_4s_3na_1np_contig0_only_filtered_l20_h45.vcf
\n\n";

my $FILE = $ARGV[0];
die($usage) unless $ARGV[0] && $opt_l && $opt_h;

parse($FILE);

#-----------------------------------------------------------------------------
#---------------------------------- SUBS -------------------------------------
#-----------------------------------------------------------------------------
sub parse{

    my $file = shift;       
    my $num_headings = 0;
    my $num_samples = 0; #number of samples in the file. Gets populated later.
    
    my $fh = new FileHandle;
    $fh->open($file);
    
    while (defined(my $line = <$fh>)){
	chomp($line);
	if ($line =~ /^\#\#/){
	    print "$line\n";
	}

	elsif ($line =~ /^#CH/){
	    print "$line\n";
	    #parse the column headings
	    my @headings = split(/\t/, $line);
	    
	    $num_headings = @headings; 
            #gets the numner of elements in the array
	    
	    $num_samples = $num_headings - 9; 
	    #vcf has 9 colums before the samples so subtracting 9 from the 
	    #total number of colums will give the number of samples in the 
	    #file.
	}
	
	else{
	    #check to make sure that the header is present
	    die "The header apears to be malformed make sure the #CHROM line is present\n" if $num_samples == 0;
	    #it has to be a data line so parse it
	    my @cols = split(/\t/, $line);
	    my @format = split(/:/, $cols[8]);
	    my $num_fields = @format;
	    my $number_passed = 0;

	    for (my $i = 9; $i < $num_headings; $i++){
		my @genotype_entry = split(/:/, $cols[$i]);
		next if $genotype_entry[0] eq './.'; #skip nocalls

		#figure out if the line is hozygous reference or variant
		if ($num_fields > 2){
		    #this is a varinat line
		    if ($format[1] ne 'AD' || $format[2] ne 'DP'){
			die ("unexpected genotpe format order\n");
			#this just makes sure that I am getting 
			#the allele depth and total depth in the 
			#feilds that I am expecting them in. I might
			#add some code later that usese the format 
			#line to get the right values no matter 
			#what order they are in
		    }
		    my @ad = split(/,/, $genotype_entry[1]);
		    my $dp = $genotype_entry[2];
		    if ($dp > $opt_h || $dp < $opt_l){
			#either depth is too high or too low
			next;
		    }
		    else{
			#met the depth requirements
			$number_passed++;
		    }
		}

		else{
		    #there is some duplicate code in here but I might do 
		    #something more to the varinat lines and it might
		    #help to have these reference only entries alone.
		    if ($format[1] ne 'DP'){
                        die ("unexpected genotpe format order $format[1]\n")
                    }
		    my $dp = $genotype_entry[1];
		    if ($dp > $opt_h || $dp < $opt_l){
                        #either depth is too high or too low                                               next;
                    }
                    else{
                        #met the depth requirements
			$number_passed++;
                    }
		}
	    } 
	    #if ($number_passed == 8){ 
            #this was a hard coded sample number that is more usefull as a variable 

	    if ($number_passed == $num_samples){
		#all of the samples passed the depth cutoffs
		print $line, "\n";
	    }
	}
    }
    $fh->close();
}
#-----------------------------------------------------------------------------

