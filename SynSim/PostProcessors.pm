package Simulation::Tools::SynSim::PostProcessors;

use vars qw( $VERSION );
$VERSION = '0.9.2';

################################################################################
#                                                                              #
#  Copyright (C) 2000,2002 Wim Vanderbauwhede. All rights reserved.            #
#  This program is free software; you can redistribute it and/or modify it     #
#  under the same terms as Perl itself.                                        #
#                                                                              #
################################################################################

=headers

Module to support SynSim simulation automation tool.
This module contains all subroutines needed for postprocessing of the simulations results. 
Some routines are quite generic, but most are specific to the type of simulation.

$Id: Simulation::Tools::SynSim::PostProcessors.pm,v 1.5 2002/10/16 15:27:40 wim Exp $

=cut

use strict;
use Cwd;
use Carp;
#use lib '.','..';

use Simulation::Tools::SynSim::Analysis;
use Simulation::Tools::SynSim::PostProcLib;
##################################################################################
# This is a very generic module to generate plots from any sweep that is not the buffer depth

sub SweepVar {
my @args=@_;
&prepare_plot(@args);

my $norm=${$simdata{$normvar}}[0]||1; 
my $col=$datacol+1;

my @sweepvarvals=@{$simdata{$sweepvar}};

#this is to combine the values for different buffers into 1 file

if($verylast==0) {
open(HEAD,">${simtempl}-${anatempl}-${sweepvals}.res");
open(IN,"<${simtempl}_C$count.res");
while(<IN>) {
/\#/ && !/Parameters|$sweepvar/ && do {print HEAD $_};
}
close IN;
close HEAD;

my $i=0;
foreach my $sweepvarval ( @sweepvarvals ) {
open(RES,">>${simtempl}-${anatempl}-${sweepvals}.res");
print RES "$sweepvarval\t$results[$i]";
close RES;
$i++;
}

if($last) {

if($interactive) {

foreach my $sweepvarval ( @sweepvarvals ) {
#create the header
my $newsweepvals=$sweepvals;

my $gnuplotscript=<<"ENDS";
set terminal X11

$logscale
#set xtics 16
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 
set key box

set title "$title" "Helvetica,14"
set xlabel "$sweepvartitle"
set ylabel "$ylabel"

plot '${simtempl}-${anatempl}-$newsweepvals.res'  using (\$1*1):$col title "$legend"  with lines
!sleep 1
ENDS

&gnuplot($gnuplotscript);
}
}
} # if last

} else {
### On the very last run, collect the results into one nice plot

#this is very critical. The quotes really matter!
# as a rule, quotes inside gnuplot commands must be escaped

my $plotlinetempl=q["\'$filename\' using (\$1*1):(\$_DATACOL/_NORM) title \"$legend\" with lines"];
$plotlinetempl=~s/_NORM/$norm/;
$plotlinetempl=~s/_DATACOL/$col/;

my $xtics=2;#change later
my $firstplotline=<<"ENDH";
set terminal postscript landscape enhanced  color solid "Helvetica" 12
set output "${simtempl}-${anatempl}.ps"

$logscale

#set xtics $xtics
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title" "Helvetica,14"
set xlabel "$sweepvartitle"
set ylabel "$ylabel"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);
}

} #END of SweepVar()

#------------------------------------------------------------------------------
sub ErrorFlags {
my @args=@_;
&prepare_plot(@args);

my $norm=${$simdata{$normvar}}[0]||1;

my $sweepvarval=$simdata{$sweepvar}[0];

#this is to combine the values for different buffers into 1 file
$sweepvals=~s/\-$sweepvar\-\d+//;

if($verylast==0){
# calc average after every $count

my $par='LOSS';
my %stats=%{&calc_statistics("${simtempl}_C$count.res",[$par, $datacol])};

my $avg=$stats{$par}{AVG}/$norm;
my $stdev=$stats{$par}{STDEV}/$norm;
my $minerr=$avg-1.96*$stdev; # 2 sigma = 95% MAKE THIS A PARAMETER! CONFIDENCE
my $maxerr=$avg+1.96*$stdev; # 2 sigma = 95%

my @header=();
open(RES,"<${simtempl}_C$count.res")||carp "$!";
while(<RES>) {
/^\#/ && do {push @header,$_};
}
close RES;
if(not(-e "${simtempl}-${anatempl}-$sweepvals.res")) {
open(STAT,">${simtempl}-${anatempl}-$sweepvals.res");
foreach my $line (@header) {
  if($line!~/$sweepvar/){
print STAT $line;
}
}
print STAT "$sweepvarval\t$avg\t$minerr\t$maxerr\n";
close STAT;
} else {
open(STAT,">>${simtempl}-${anatempl}-$sweepvals.res");
print STAT "$sweepvarval\t$avg\t$minerr\t$maxerr\n";
close STAT;
}


if($last) {

if($interactive) {
my $gnuplotscript=<<"ENDS";
set terminal X11

$logscale
#set xtics 16
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 
set key box

set title "$title" "Helvetica,14"
set xlabel "$sweepvartitle"
set ylabel "$ylabel"

plot '${simtempl}-${anatempl}-$sweepvals.res' notitle with yerrorbars, '${simtempl}-${anatempl}-$sweepvals.res'  title "$legend" with lines
!sleep 1
ENDS

&gnuplot($gnuplotscript);
}
} # if last

} else {
### On the very last run, collect the results into one nice plot

#this is very critical. The quotes really matter!
# as a rule, quotes inside gnuplot commands must be escaped

my $plotlinetempl=q("\'$filename\' notitle with yerrorbars lt $lt, \'$filename\' title \"$legend\" with lines lt $lt");


my $firstplotline=<<"ENDH";
set terminal postscript landscape enhanced  color solid "Helvetica" 12
set output "${simtempl}-${anatempl}.ps"

$logscale

#set xtics 16
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title" "Helvetica,14"
set xlabel "$sweepvartitle"
set ylabel "$ylabel"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);
}

} #END of ErrorFlags()

#------------------------------------------------------------------------------

sub Histogram {

my @args=@_;
&prepare_plot(@args);

my $sweepvarval=${$simdata{$sweepvar}}[0];

  if($verylast==0) {
my $par='DATA';
my %hists=%{&build_histograms("${simtempl}_C$count.res",[$par,$datacol],$title,'',$sweepvarval)};

#system("grep '#' ${simtempl}_C$count.res > ${simtempl}-${anatempl}-$sweepvals.res");
&egrep('#',"${simtempl}_C$count.res",'>',"${simtempl}-${anatempl}-$sweepvals.res");

open HIST,">>${simtempl}-${anatempl}-$sweepvals.res";
foreach my $pair (@{$hists{$par}}) {
print HIST $pair->{BIN},"\t",$pair->{COUNT},"\n";
}
close HIST;
if($interactive) {
&gnuplot( "plot '${simtempl}-${anatempl}-$sweepvals.res' with boxes\n\!sleep 1\n");
}
} else {
my $plotlinetempl=q("\'$filename\' title \"$legend\" with boxes");

my $firstplotline=<<"ENDH";
set terminal postscript landscape enhanced  color solid "Helvetica" 12
set output "${simtempl}-${anatempl}.ps"

$logscale

#set xtics 2
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title" "Helvetica,14"
set xlabel "$sweepvartitle"
set ylabel "$ylabel"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);

}


} #END of Histogram()

#------------------------------------------------------------------------------
sub egrep {
my $pattern=shift;
my $infile=shift;
my $mode=shift;
my $outfile=shift;
open(IN,"<$infile");
open(OUT,"$mode$outfile");
print OUT grep /$pattern/,<IN>;

close IN;
close OUT;
}

#------------------------------------------------------------------------------

sub AUTOLOAD {
my $subref=$Simulation::Tools::SynSim::PostProcessors::AUTOLOAD;
$subref=~s/.*:://;
print STDERR "
There is no script for the analysis $subref in the PostProcessors.pm module.
This might not be what you intended.
You can add your own subroutine $subref to the PostProcessors.pm module.
";

}
#------------------------------------------------------------------------------
print STDERR "#" x 80,"\n#\t\t\tSynSim simulation automation tool\n#\n#\t\t\t(C) Wim Vanderbauwhede 2002\n#\n","#" x 80,"\n\n Module PostProcessors loaded\n\n";


