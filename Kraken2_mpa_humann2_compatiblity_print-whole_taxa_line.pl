#! /usr/bin/perl

use strict;

my $mpafile = shift;
my $total_bacteria = 0;
my $relative_ab = 0;
my $rel_ab_rounded = 0;
my %tax_table;

my $altid_mpafile;

#open the taxonomic profile file
open MPA, "$mpafile" or die "cannot open $mpafile for reading \n";

my @split_file = split(/\./, $mpafile);
open(my $outfh, ">", "$split_file[0].krakenmetaphlan");
print $outfh "#SampleID\tMetaphlan2_Analysis\n";

while (<MPA>) {
    chomp;
    my @split = split ("\t", $_);
    my @taxa_split = split (/\|/, $split[0]);
    #print "$taxa_split[-1] and $split[0]\n";

    #disregard eukaryotic DNA
    if ($split[0] =~ /^d__Eukaryota/) {
        next;
    }
    #capture the total number of classified bacterial reads
    elsif ($split[0] =~ /^d__Bacteria$/m) {
        $total_bacteria = $split[1];
    }
    #grab bacterial species level data
    elsif (($taxa_split[-1] =~ /s__/m) && ($split[0] =~ /^d__Bacteria/)) {
        $relative_ab = ($split[1] / $total_bacteria) * 100;
        $rel_ab_rounded = sprintf("%.3f", $relative_ab);

        #make format compatible with Humann2
        $split[0] =~ s/d__Bacteria/k__Bacteria/g;
        $split[0] =~ s/\s/_/g;
        #some Propionibacterium got reclassified as Cutibacterium, calling them all Propionibacterium for now....
        $split[0] =~ s/Cutibacterium/Propionibacterium/g;
        $tax_table{$split[0]} = $rel_ab_rounded;
    }
}

#sort bacterial species from large to small based on relative abundance
foreach my $taxa (sort { $tax_table{$b} <=> $tax_table{$a} } keys %tax_table) {
    print $outfh "$taxa\t$tax_table{$taxa}\n";
}
close $outfh;
