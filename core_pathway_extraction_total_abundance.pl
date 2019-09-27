#!/anaconda2/bin/perl

#We define a ‘core’ pathway at a particular CST as one that was detected with relative abundance >10−4 in at least 75% of subject-unique samples

use strict;
use Getopt::Long;
use Statistics::Basic qw(:all);

#pathway ID used for setting boolean in subroutine "parsehumman2" and for storing core pathways as final output
my $check;

my $humman2;
my $ratio;
my $outfile;

GetOptions (
    "humann2=s" =>  \$humman2,
    "coreRatio=f" =>  \$ratio,
    "outFile=s" =>  \$outfile)
or die ("Error in command line arguments\n");

#parsing command line arguments
if (($humman2) && ($ratio) && ($outfile)) {
    #create the output file header
    open (my $fh, '>>', $outfile);
    print $fh "Core pathway\tMean abundance\tMedian abundance\n";
    close $fh;

    #start the actual work
    &parsehumman2;
}
else {
    &usage;
}


sub parsehumman2 {
    my %pathway_abuns;
    my %onesample;
    my $samples;
    my $bool = 1;
    my $total = 0;
    my $pathway_sum_one_sample;
    my @summed_pathway_abundance;
    #marker for taxa specific pathway listing
    my $char = "|";
    #just for testing purposes
    my $total_path_count = 0;

    open HUMANN2, "$humman2" or die "cannot open $humman2 for reading \n";
    my $headers=<HUMANN2>;

    while (<HUMANN2>) {
        chomp;
        my @split = split ("\t", $_);

        #skip taxa specific pathway listings... for now
        my $taxa_specific_path = index($split[0], $char);
        if ($taxa_specific_path > 0) {
            next;
        }
        #just for testing purposes
        $total_path_count += 1;
        print "$split[0]::::::: $total_path_count\n";

        my $len = scalar (@split);
        #will change, current settings are for dummy file - next two lines not needed for HMP humann2 output file
        my $pathway1 = shift @split;

        $samples = scalar (@split);

        if ($pathway1 eq $check) {
            $bool = 1;
        }
        #new pathway, new beginning
        else {
            $bool = 0;
        }

        if ($bool == 1) {
            #add taxa with associated function abundance data as long as you do not encounter a new pathway
            $pathway_abuns{$pathway1} = \@split;

            $check = $pathway1;
        }
        elsif ($bool == 0) {
            for (my $i=0; $i < $samples; $i++) {
                for (keys %pathway_abuns) {
                    my @value_array = @{$pathway_abuns{$_}};
                    #take all pathway values for one sample (column) at the time
                    $onesample{$_} = $value_array[$i];
                }

                foreach my $key (keys %onesample) {
                    my $pathwayrow = "$check\t$key\t$onesample{$key}\t";
                    $pathway_sum_one_sample += $onesample{$key};
                    print "$pathwayrow\n";

                }
                #store the sum of a pathway abundance for one sample
                print "total for $check: $pathway_sum_one_sample\n";
                push @summed_pathway_abundance, $pathway_sum_one_sample;
                $pathway_sum_one_sample = 0;
            }

            &identify_core(\@summed_pathway_abundance, $check);
            @summed_pathway_abundance = ();

            undef %onesample;
            undef %pathway_abuns;

            #start new pathway
            $pathway_abuns{$pathway1} = \@split;
            $check = $pathway1;
        }
    }

    #process the last pathway
    for (my $i=0; $i < $samples; $i++) {
        for (keys %pathway_abuns) {
            my @value_array = @{$pathway_abuns{$_}};
            #take all pathway values for one sample at the time
            $onesample{$_} = $value_array[$i];
        }

        foreach my $key (keys %onesample) {
            my $pathwayrow = "$check\t$key\t$onesample{$key}\t";
            $pathway_sum_one_sample += $onesample{$key};
            print "$pathwayrow\n";

        }
        print "total for $check: $pathway_sum_one_sample\n";
        push @summed_pathway_abundance, $pathway_sum_one_sample;
        $pathway_sum_one_sample = 0;

    }
    &identify_core(\@summed_pathway_abundance, $check);
    @summed_pathway_abundance = ();

}

sub identify_core {
    my @single_pathway = @{$_[0]};
    my $pathway_id = $_[1];
    my @core_pathways;

    #calculate average and median pathway abundance
    my $pathway_mean = mean(@single_pathway);
    my $accurate_mean = sprintf("%.8f", $pathway_mean);
    my $pathway_median = median(@single_pathway);
    my $accurate_median = sprintf("%.8f", $pathway_median);

    #core pathway cut-off is abundance values present in 75% of samples
    my $percent = (scalar @single_pathway * $ratio);
    #sort values numerically
    my @ordered = sort {$a <=> $b} @single_pathway;
    #grab the top 75%
    my @top = splice(@ordered, (scalar @ordered - $percent));

    #print "lower limit: $top[0]\n";
    #print "higher limit: $top[-1]\n";
    #core pathway abundance lower limit
    if ($top[0] > 1E-04) {
        push @core_pathways, $pathway_id;
      }

    open (my $fh, '>>', $outfile);
    foreach my $pathway (@core_pathways) {
        print $fh "$pathway\t$accurate_mean\t$accurate_median\n";
    }
    close $fh;
}

sub usage {
    print STDERR "\n Usage:  perl $0 -humann2 <HUMANN2 output file> -coreRatio <ratio for core pathway inclusion... value between 0 and 1> -outFile <output file> \n";
    exit;
}
