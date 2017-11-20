#!/usr/bin/perl -w 
use strict;
use lib ('/sonas-hs/ware/hpc/home/mcampbel/applications/tabix/perl/blib/lib');
#use PostData;
use Getopt::Std;
use vars qw($opt_v $opt_l $opt_g $opt_p $opt_c $opt_m $opt_u);
getopts('v:l:gpcmu');
use FileHandle;
use Tabix;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "\n\n\t
takes a bgzipped and tabix indexed VCF file and a list of seqids and there lengths and 
prints out the allele frequencies by varint site to be plotted in R.
example seqid file line \"Contig0 6331610\"

plotting_allele_frequency.pl <list_of_seqids.txt> <sample.vcf|*.vcf>

Note: the tabix perl module/API is a dependency
\n\n";

die($usage) unless $ARGV[1];

my $LUF = shift @ARGV;
my @VCFS = @ARGV;

my $lu = parse_lu($LUF);
foreach my $vcffile (@VCFS){
    parse_vcf($vcffile, $lu);
    
}
#-----------------------------------------------------------------------------
#---------------------------------- SUBS -------------------------------------
#-----------------------------------------------------------------------------
sub parse_lu{

    my $file = shift;       
    my %lu;
    my $fh = new FileHandle;
    $fh->open($file);
    
    while (defined(my $line = <$fh>)){
        chomp($line);
	my @cols = split(/\s/, $line);
	$lu{$cols[0]} = $cols[1];
    }
    $fh->close();
    return(\%lu);
}
#-----------------------------------------------------------------------------
sub parse_vcf{

    my $file = shift;  
    my $lu   = shift;

    foreach my $seqid (keys %$lu){
	my $end = $lu->{$seqid};
	my $outfile = $file;
	$outfile =~ s/\.vcf\.gz/_$seqid/;
	$outfile .= '_af.txt';
	$outfile =~ s/\-/_/g;
	$outfile =~ s/\.\.\///g;

	my $fho = new FileHandle;
	$fho->open(">>$outfile");

	my $t_object = Tabix->new(-data=>$file);

	my $iter = $t_object->query($seqid, 1, $end);

	while (my $line = $t_object->read($iter)){
	    chomp($line);
	    #print "$line\n";
	    next if $line =~ /^\#/;
	    my $alt_freq = 0;
	    my @cols = split(/\t/, $line);
	    if ($cols[9] ne './.'){
		my @gts  = split(/:/, $cols[9]);
		my @acs  = split(/,/, $gts[1]);
		my $tot  = $acs[0] + $acs[1];

		if ($acs[1] != 0){
		    $alt_freq = $acs[1]/$tot;
		}
	    }
	    else{
		$alt_freq = 0;
	    }
	    print $fho "$cols[1]\t$alt_freq\n";
	}

	$fho->close();
    }
#    my $fh   = new FileHandle;
#    $fh->open($file);
#    
#    while (defined(my $line = <$fh>)){
#	chomp($line);
#	next if $line =~ /^\#/;
#	my $alt_freq = 0;
#	my @cols = split(/\t/, $line);
#	if ($cols[9] ne './.'){
#	    my @gts  = split(/:/, $cols[9]);
#	    my @acs  = split(/,/, $gts[1]); 
#	    my $tot  = $acs[0] + $acs[1];
#	    
#	    if ($acs[1] != 0){
#		$alt_freq = $acs[1]/$tot;
#	    }
#	}
#	else{
#	    $alt_freq = 0;
#	}
#	print $cols[1],"\t",$alt_freq,"\n";
#    }
#    $fh->close();
    
}
#-----------------------------------------------------------------------------

