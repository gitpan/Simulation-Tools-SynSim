package Simulation::Tools::SynSim::PostProcessors;

use vars qw( $VERSION );
$VERSION = '0.9.1';

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

my $npack=${$simdata{'_NPACK'}}[0]||1;
my $unitpl=${$simdata{'_UNITPL'}}[0];
my $col=$datacol+1;
my $samplfreq=$simdata{_SAMPL}[0];
my $nbufs=$simdata{_NBUFS}[0];
my @sweepvarvals=@{$simdata{$sweepvar}};

#this is to combine the values for different buffers into 1 file

if($verylast==0) {
open(HEAD,">${simtempl}-${anatempl}-${sweepvals}.res");
open(IN,"<${simtempl}_C$count.res");
while(<IN>) {
/\#/ && !/Parameters|_NBUFS/ && do {print HEAD $_};
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
#set nologscale x
#set logscale y
#set xtics 16
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 
set key box

set title "$title" "Helvetica,14"
set xlabel "$sweepvartitle"
#set ylabel "log(Packet Loss)"
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

my $plotlinetempl=q["\'$filename\' using (\$1*1):(\$_DATACOL/_NPACK) title \"$legend\" with lines"];
$plotlinetempl=~s/_NPACK/$npack/;
$plotlinetempl=~s/_DATACOL/$col/;
#$plotlinetempl=~s/_UNITPL/$unitpl/;
my $xtics=10*$unitpl;
my $firstplotline=<<"ENDH";
set terminal postscript landscape enhanced  color solid "Helvetica" 12
set output "${simtempl}-${anatempl}.ps"

$logscale
#set nologscale x
#set logscale y
#set xtics $xtics
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title" "Helvetica,14"
set xlabel "$sweepvartitle"
#set ylabel "log(Packet Loss)"
set ylabel "$ylabel"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);
}

} #END of SweepVar()
#------------------------------------------------------------------------------
sub ErrorFlags {
my @args=@_;
&prepare_plot(@args);

my $npack=${$simdata{'_NPACK'}}[0];
my $samplfreq=$simdata{_SAMPL}[0];
my $nbufs=$simdata{_NBUFS}[0];

#this is to combine the values for different buffers into 1 file
$sweepvals=~s/\-_NBUFS\-\d+//;

if($verylast==0){
# calc average after every $count

my $par='LOSS';
my %stats=%{&calc_statistics("${simtempl}_C$count.res",[$par, $datacol])};

my $avg=$stats{$par}{AVG}/$npack;
my $stdev=$stats{$par}{STDEV}/$npack;
my $minerr=$avg-1.96*$stdev; # 2 sigma = 95%
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
  if($line!~/_NBUFS/){
print STAT $line;
}
}
print STAT "$nbufs\t$avg\t$minerr\t$maxerr\n";
close STAT;
} else {
open(STAT,">>${simtempl}-${anatempl}-$sweepvals.res");
print STAT "$nbufs\t$avg\t$minerr\t$maxerr\n";
close STAT;
}


if($last) {

if($interactive) {
my $gnuplotscript=<<"ENDS";
set terminal X11

set nologscale x
set logscale y
set xtics 16
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 
set key box

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

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

set nologscale x
set logscale y
set xtics 16
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);
}

} #END of ErrorFlags()

#------------------------------------------------------------------------------
# This is in fact a very generic module to generate plots from any sweep that is not the buffer depth
# but the references to packet length make it too specific

sub VarFixedPacketLength {
my @args=@_;
&prepare_plot(@args);

my $npack=${$simdata{'_NPACK'}}[0];
my $unitpl=${$simdata{'_UNITPL'}}[0];
my $samplfreq=$simdata{_SAMPL}[0];
my $nbufs=$simdata{_NBUFS}[0];
my @mingapwidths=@{$simdata{$sweepvar}};

#this is to combine the values for different buffers into 1 file

if($verylast==0){
#if(not(-e "${simtempl}-${anatempl}-${newsweepvals}.res")) {
open(HEAD,">${simtempl}-${anatempl}-${sweepvals}.res");
open(IN,"<${simtempl}_C$count.res");
while(<IN>) {
/\#/ && !/Parameters|_NBUFS/ && do {print HEAD $_};
}
close IN;
close HEAD;
#}

my $i=0;
foreach my $mingw ( @mingapwidths ) {
#create the header
#my $newsweepvals=$sweepvals;
open(RES,">>${simtempl}-${anatempl}-${sweepvals}.res");
print RES "$mingw\t$results[$i]";
close RES;
$i++;
}

if($last) {

if($interactive) {

foreach my $mingw ( @mingapwidths ) {
#create the header
my $newsweepvals=$sweepvals;

my $gnuplotscript=<<"ENDS";
set terminal X11

set nologscale x
set logscale y
set xtics 16
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 
set key box

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Packet Length"
set ylabel "log(Packet Loss)"

plot '${simtempl}-${anatempl}-$newsweepvals.res'  using (\$1*$unitpl):5 title "$legend"  with lines
!sleep 1
ENDS

#&gnuplot($gnuplotscript);
#&gnuplot($gnuplotscript,'-persist');
}
}
} # if last

} else {
### On the very last run, collect the results into one nice plot

#this is very critical. The quotes really matter!
# as a rule, quotes inside gnuplot commands must be escaped

my $plotlinetempl=q["\'$filename\' using (\$1*_UNITPL):(\$5/_NPACK) title \"$legend\" with lines"];
$plotlinetempl=~s/_NPACK/$npack/;
$plotlinetempl=~s/_UNITPL/$unitpl/;
my $xtics=10*$unitpl;
my $firstplotline=<<"ENDH";
set terminal postscript landscape enhanced  color solid "Helvetica" 12
set output "${simtempl}-${anatempl}.ps"

set nologscale x
set logscale y
set xtics $xtics
#set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Packet Length"
set ylabel "log(Packet Loss)"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);
}

} #END of VarFixedPacketLength()

#==============================================================================
sub VarPacketLengthRatio {
my @args=@_;
&prepare_plot(@args);

my $npack=${$simdata{'_NPACK'}}[0];
my $samplfreq=$simdata{_SAMPL}[0];
my $nbufs=$simdata{_NBUFS}[0];
my @mingapwidths=@{$simdata{_FRACT_MIN}};

#this is to combine the values for different buffers into 1 file

if($verylast==0){
#if(not(-e "${simtempl}-${anatempl}-${newsweepvals}.res")) {
open(HEAD,">${simtempl}-${anatempl}-${sweepvals}.res");
open(IN,"<${simtempl}_C$count.res");
while(<IN>) {
/\#/ && !/Parameters|_NBUFS/ && do {print HEAD $_};
}
close IN;
close HEAD;
#}

my $i=0;
foreach my $mingw ( @mingapwidths ) {
#create the header
#my $newsweepvals=$sweepvals;
open(RES,">>${simtempl}-${anatempl}-${sweepvals}.res");
print RES "$mingw\t$results[$i]";
close RES;
$i++;
}

if($last) {

if($interactive) {

foreach my $mingw ( @mingapwidths ) {
#create the header
my $newsweepvals=$sweepvals;

my $gnuplotscript=<<"ENDS";
set terminal X11

set nologscale x
set logscale y
set xtics 16
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 
set key box

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

plot '${simtempl}-${anatempl}-$newsweepvals.res'  using 2:5 title "$legend"  with lines
!sleep 1
ENDS

&gnuplot($gnuplotscript);
#&gnuplot($gnuplotscript,'-persist');
}
}
} # if last

} else {
### On the very last run, collect the results into one nice plot

#this is very critical. The quotes really matter!
# as a rule, quotes inside gnuplot commands must be escaped

my $plotlinetempl=q["\'$filename\' using 1:(\$5/_NPACK) title \"$legend\" with lines"];
$plotlinetempl=~s/_NPACK/$npack/;

my $firstplotline=<<"ENDH";
set terminal postscript landscape enhanced  color solid "Helvetica" 12
set output "${simtempl}-${anatempl}.ps"

set nologscale x
set logscale y
set xtics 8
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);
}

} #END of VarPacketLengthRatio()

#==============================================================================

sub VarMinGapWidth {
my @args=@_;
&prepare_plot(@args);

my $npack=${$simdata{'_NPACK'}}[0];
my $samplfreq=$simdata{_SAMPL}[0];
my $nbufs=$simdata{_NBUFS}[0];
my @mingapwidths=@{$simdata{_MINGW}};

#this is to combine the values for different buffers into 1 file

if($verylast==0){
#just copy the files to the long names
#system("cp ${simtempl}_C$count.res ${simtempl}-${anatempl}-$sweepvals.res");

#better:
#replace reference to _NBUFS 
$sweepvals=~s/\-*_NBUFS\-\d+//;
#carp "RES:\n",join("",@results),"ENDRES\n";
my $i=0;
foreach my $mingw ( @mingapwidths ) {
#create the header
my $newsweepvals="${sweepvals}_MINGW-$mingw";
if(not(-e "${simtempl}-${anatempl}-${newsweepvals}.res")) {
open(HEAD,">${simtempl}-${anatempl}-${newsweepvals}.res");
open(IN,"<${simtempl}_C$count.res");
while(<IN>) {
/\#/ && !/Parameters|_NBUFS/ && do {print HEAD $_};
}
close IN;
close HEAD;
}

open(RES,">>${simtempl}-${anatempl}-${newsweepvals}.res");
print RES "$mingw\t$results[$i]";
close RES;
$i++;
}

if($last) {

if($interactive) {

foreach my $mingw ( @mingapwidths ) {
#create the header
my $newsweepvals="${sweepvals}_MINGW-$mingw";

my $gnuplotscript=<<"ENDS";
set terminal X11

set nologscale x
set logscale y
set xtics 16
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 
set key box

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

plot '${simtempl}-${anatempl}-$newsweepvals.res'  using 2:5 title "$legend"  with lines
!sleep 1
ENDS

&gnuplot($gnuplotscript);
#&gnuplot($gnuplotscript,'-persist');
}
}
} # if last

} else {
### On the very last run, collect the results into one nice plot

#this is very critical. The quotes really matter!
# as a rule, quotes inside gnuplot commands must be escaped

my $plotlinetempl=q["\'$filename\' using 2:(\$5/_NPACK) title \"$legend\" with lines"];
$plotlinetempl=~s/_NPACK/$npack/;

my $firstplotline=<<"ENDH";
set terminal postscript landscape enhanced  color solid "Helvetica" 12
set output "${simtempl}-${anatempl}.ps"

set nologscale x
set logscale y
set xtics 8
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);
}

} #END of VarMinGapWidth()

#==============================================================================

sub Histogram {
##WV20082002: IS JUST A COPY OF FillState!
my @args=@_;
&prepare_plot(@args);

my $nbufs=${$simdata{'_NBUFS'}}[0];
my $npack=${$simdata{'_NPACK'}}[0];
my $samplfreq=$simdata{_SAMPL}[0];

#if HISTS
if (${$simdata{'_HISTS'}}[0]==1) {

  if($verylast==0) {
my $par='DATA';
my %hists=%{&build_histograms("${simtempl}_C$count.res",[$par,$datacol],$title,'',$nbufs)};
system("grep '#' ${simtempl}_C$count.res > ${simtempl}-${anatempl}-$sweepvals.res");
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

set nologscale xy

set xtics 2
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);

}
} #HISTS

} #END of Histogram()
#------------------------------------------------------------------------------

sub FillState {
my @args=@_;
&prepare_plot(@args);

my $nbufs=${$simdata{'_NBUFS'}}[0];
my $npack=${$simdata{'_NPACK'}}[0];
my $samplfreq=$simdata{_SAMPL}[0];

#if HISTS
if (${$simdata{'_HISTS'}}[0]==1) {

  if($verylast==0) {
my $par='DATA';
my %hists=%{&build_histograms("${simtempl}_C$count.res",[$par,$datacol],$title,'',$nbufs)};
system("grep '#' ${simtempl}_C$count.res > ${simtempl}-${anatempl}-$sweepvals.res");
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

set nologscale xy

set xtics 2
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);

}
} #HISTS

} #END of FillState()

#------------------------------------------------------------------------------

sub VarLoad {
my @args=@_;
&prepare_plot(@args);

my $npack=$simdata{_NPACK}[0];
my $samplfreq=$simdata{_SAMPL}[0];

if($verylast==0) {
#just copy the files to the long names
system("cp ${simtempl}_C$count.res ${simtempl}-${anatempl}-$sweepvals.res");
#a very simple plot
if($interactive) {

my $gnuplotscript=<<"ENDS";
set terminal X11

set nologscale x
set logscale y
set xtics 16
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "Packet Loss vs Buffer Depth (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

plot '${simtempl}-${anatempl}-$sweepvals.res' using 1:4 title  "$legend" with linespoints
!sleep 1
ENDS
&gnuplot($gnuplotscript);

}

} else {

#this is very critical. The quotes really matter!
# as a rule, quotes inside gnuplot commands must be escaped

my $plotlinetempl=q("\'$filename\' using 1:4 title \"$legend\" with linespoints");

# headers for the combined plot
my $firstplotline=<<"ENDH";
set terminal postscript landscape enhanced  color solid "Helvetica" 12
set output "${simtempl}-${anatempl}.ps"

set nologscale x
set logscale y
set xtics 16
set mxtics 2
set grid xtics ytics mxtics mytics

set key right top box 
set key title "$legendtitle" 

set title "$title (sampl. freq $samplfreq, $npack packets)" "Helvetica,14"
set xlabel "Buffer Depth"
set ylabel "log(Packet Loss)"

ENDH

&gnuplot_combined($firstplotline,$plotlinetempl);

} #verylast

} #END of VarLoad()

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


