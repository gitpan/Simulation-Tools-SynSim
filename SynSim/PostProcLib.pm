package Simulation::Tools::SynSim::PostProcLib;

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

Module to support synsim script for simulation automation.
This module contains a set of utility functions for use in the
PostProcessors.pm module.
This module is generic.

$Id: PostProcLib.pm,v 1.4 2002/10/16 15:27:39 wim Exp $

=cut

use sigtrap qw(die untrapped normal-signals
               stack-trace any error-signals); 
use strict;
use Carp;
use FileHandle;
use Exporter;
use lib '.','..';

use Simulation::Tools::SynSim::Analysis;
use Simulation::Tools::SynSim::Dictionary;

@Simulation::Tools::SynSim::PostProcLib::ISA = qw(Exporter);
@Simulation::Tools::SynSim::PostProcLib::EXPORT = qw(
			   &prepare_plot
			   &gnuplot
			   &gnuplot_combined
			   &copy_results
			   &create_legend
			   %simdata
			   $last
			   $verylast
			   $sweepvals
			   $sweepvar
			   $normvar
			   $sweepvartitle
			   $plot
			   $interactive
			   $title
			   $datacol
			   $count
			   $simtempl
			   $anatempl
			   $dirname
			   $legend
			   $legendtitle
			  $ylabel
			  $logscale
			  @results
			  );


##################################################################################


sub AUTOLOAD {
my $subref=$Simulation::Tools::SynSim::PostProcLib::AUTOLOAD;
$subref=~s/.*:://;
print STDERR "
There is no script for this analysis in the PostProcLib.pm module.
This might not be what you intended.
You can add your own subroutine $subref to the PostProcLib.pm module.
";

}

#------------------------------------------------------------------------------

sub prepare_plot {
  use Cwd;
  
  my $dataset=shift;
  $Simulation::Tools::SynSim::PostProcLib::count=shift;
  my $dataref=shift;
  my $flagsref=shift;
  my $verylast=shift;
  # $Simulation::Tools::SynSim::PostProcLib::verylast=shift;
  
  if($verylast!=1){
    @Simulation::Tools::SynSim::PostProcLib::results=@{$verylast};
    $Simulation::Tools::SynSim::PostProcLib::verylast=0;
  } else {
    @Simulation::Tools::SynSim::PostProcLib::results=();
    $Simulation::Tools::SynSim::PostProcLib::verylast=1;
  }

  (my $batch,$Simulation::Tools::SynSim::PostProcLib::interactive,my $nosims,$Simulation::Tools::SynSim::PostProcLib::plot,my $verbose)=@{$flagsref};
  my $copy_results=1;
  (my $nsims, my $simdataref,my $sweepedref,my $lastref)=@{$dataref};
  
  %Simulation::Tools::SynSim::PostProcLib::simdata=%{$simdataref};

  my %sweeped=%{$sweepedref};
$Simulation::Tools::SynSim::PostProcLib::sweepvals='';
foreach my $key (sort keys %sweeped) {
  $Simulation::Tools::SynSim::PostProcLib::sweepvals.="${key}-".$sweeped{$key}.'-';
}
$Simulation::Tools::SynSim::PostProcLib::sweepvals=~s/-$//;
  my @sweeped=sort keys %sweeped;
  my $setvar=$Simulation::Tools::SynSim::PostProcLib::simdata{SETVAR}||'none';
  my $sweepval=${$Simulation::Tools::SynSim::PostProcLib::simdata{$setvar}}[0];

  my %last=%{$lastref};
$Simulation::Tools::SynSim::PostProcLib::last=($setvar ne 'none' && $sweepval==$last{$setvar});

  my $pattern=$Simulation::Tools::SynSim::PostProcLib::simdata{OUTPUT_FILTER_PATTERN}|| '.*';
my $devtype=$Simulation::Tools::SynSim::PostProcLib::simdata{DEVTYPE};
    my $ext=$Simulation::Tools::SynSim::PostProcLib::simdata{TEMPL};
$Simulation::Tools::SynSim::PostProcLib::sweepvar=$Simulation::Tools::SynSim::PostProcLib::simdata{SWEEPVAR}||'none';
$Simulation::Tools::SynSim::PostProcLib::normvar=$Simulation::Tools::SynSim::PostProcLib::simdata{NORMVAR}||'none';

$Simulation::Tools::SynSim::PostProcLib::datacol=$Simulation::Tools::SynSim::PostProcLib::simdata{DATACOL}||1;

$Simulation::Tools::SynSim::PostProcLib::simtempl=$Simulation::Tools::SynSim::PostProcLib::simdata{SIMTYPE};
$Simulation::Tools::SynSim::PostProcLib::dirname= "${Simulation::Tools::SynSim::PostProcLib::simtempl}-$dataset";
$Simulation::Tools::SynSim::PostProcLib::anatempl=$Simulation::Tools::SynSim::PostProcLib::simdata{ANALYSIS_TEMPLATE};

$Simulation::Tools::SynSim::PostProcLib::title=$Simulation::Tools::SynSim::PostProcLib::simdata{TITLE}||"$devtype $Simulation::Tools::SynSim::PostProcLib::simtempl simulation";
my $simtitle=$Simulation::Tools::SynSim::PostProcLib::title;
foreach my $key (keys %Simulation::Tools::SynSim::PostProcLib::simdata) {
($key!~/^_/) && next;
($simtitle=~/$key/) && do {
my $val=$Simulation::Tools::SynSim::PostProcLib::simdata{$key};
my $nicekey=$make_nice{$key}{title};
my $niceval=$make_nice{$key}{$val}||join(',',@{$val});
$simtitle=~s/$key/$nicekey:\ $niceval/;
};
$Simulation::Tools::SynSim::PostProcLib::title=$simtitle;
}

# XTICS, YTICS, XSTART, XSTOP, YSTART, YSTOP
$Simulation::Tools::SynSim::PostProcLib::ylabel=$Simulation::Tools::SynSim::PostProcLib::simdata{YLABEL}||"$Simulation::Tools::SynSim::PostProcLib::title";
$Simulation::Tools::SynSim::PostProcLib::logscale=($Simulation::Tools::SynSim::PostProcLib::simdata{LOGSCALE})?"set nologscale xy\nset logscale ".lc($Simulation::Tools::SynSim::PostProcLib::simdata{LOGSCALE}):'set nologscale xy';


$Simulation::Tools::SynSim::PostProcLib::sweepvartitle=$make_nice{$Simulation::Tools::SynSim::PostProcLib::sweepvar}{title};
( $Simulation::Tools::SynSim::PostProcLib::legendtitle, $Simulation::Tools::SynSim::PostProcLib::legend)=@{&create_legend($Simulation::Tools::SynSim::PostProcLib::sweepvals,\%make_nice)};

}

#------------------------------------------------------------------------------

sub gnuplot {
my $commands=shift;
my $persist=shift;
if($Simulation::Tools::SynSim::PostProcLib::plot) {
open GNUPLOT,"| gnuplot $persist";
print GNUPLOT $commands;
close GNUPLOT;
}
}
#------------------------------------------------------------------------------
sub gnuplot_combined {
my $firstplotline=shift;
my $plotlinetempl=shift;
my $col=$Simulation::Tools::SynSim::PostProcLib::datacol;
#my %make_nice=%{shift(@_)};
### On the very last run, collect the results 
#1. get a list of all plot files

my @plotfiles=glob("${Simulation::Tools::SynSim::PostProcLib::simtempl}-${Simulation::Tools::SynSim::PostProcLib::anatempl}-*.res");

#2. create a gnuplot script 
#this should be a full script, but with room for additional feature
my @lines=();
my $legendtitle='';
my $lt=0;
foreach my $filename (@plotfiles) {
$lt++;
my $title=$filename;
$title=~s/${Simulation::Tools::SynSim::PostProcLib::simtempl}-${Simulation::Tools::SynSim::PostProcLib::anatempl}-//;
$title=~s/\.res//;
my %title=split('-',$title);

my $legend='';
$legendtitle='';
foreach my $key (sort keys %title) {
$legendtitle.=',';
$legendtitle.=$make_nice{$key}{title}||$key;
$legend.=$make_nice{$key}{$title{$key}}||$title{$key};
$legend.=',';
}
$legend=~s/,$//;
$legendtitle=~s/^,//;

my $plotline;
#carp '$plotline='.$plotlinetempl;
eval('$plotline='.$plotlinetempl);
#carp "PLOTLINE:$plotline";
push @lines, $plotline
}
$firstplotline=~s/set\s+key\s+title.*/set key title "$legendtitle"/;

my $line=$firstplotline."\nplot ".join(",\\\n",@lines);
#carp "COMBINED: $line";
#die;
if($Simulation::Tools::SynSim::PostProcLib::plot) {
open GNUPLOT,"| gnuplot";
print GNUPLOT $line;
close GNUPLOT;
}
open GNUPLOT,">${Simulation::Tools::SynSim::PostProcLib::simtempl}-${Simulation::Tools::SynSim::PostProcLib::anatempl}.gnuplot";
print GNUPLOT $line;
close GNUPLOT;

if($Simulation::Tools::SynSim::PostProcLib::interactive) {
system("gv ${Simulation::Tools::SynSim::PostProcLib::simtempl}-${Simulation::Tools::SynSim::PostProcLib::anatempl}.ps &");
}
} # END of gnuplot_combined()
#------------------------------------------------------------------------------
sub copy_results {
use Cwd;
my $workingdir=cwd();
  if(not(-e "$workingdir/../../Results")) {
mkdir  "$workingdir/../../Results";
}
  if(not(-e "$workingdir/../../Results/$Simulation::Tools::SynSim::PostProcLib::simtempl")) {
mkdir  "$workingdir/../../Results/$Simulation::Tools::SynSim::PostProcLib::simtempl";
}

  if(not(-e "$workingdir/../../Results/$Simulation::Tools::SynSim::PostProcLib::simtempl/$Simulation::Tools::SynSim::PostProcLib::anatempl")) {
mkdir  "$workingdir/../../Results/$Simulation::Tools::SynSim::PostProcLib::simtempl/$Simulation::Tools::SynSim::PostProcLib::anatempl";
}
system("cp ${Simulation::Tools::SynSim::PostProcLib::simtempl}-${Simulation::Tools::SynSim::PostProcLib::anatempl}.* $workingdir/../../Results/$Simulation::Tools::SynSim::PostProcLib::simtempl/$Simulation::Tools::SynSim::PostProcLib::anatempl");

} #END of copy_results()
#------------------------------------------------------------------------------
sub create_legend {
my $title=shift;
my %make_nice=%{shift(@_)};
my %title=split('-',$title);

my $legend='';
my $legendtitle='';
foreach my $key (sort keys %title) {
my $titlepart=$make_nice{$key}{title}||$key;
$legendtitle.=','.$titlepart;
my $legendpart=$make_nice{$key}{$title{$key}}||$title{$key};
$legend.=','.$legendpart;
}
$legend=~s/^,//;
$legendtitle=~s/^,//;
return [$legendtitle,$legend];
}
#------------------------------------------------------------------------------
print STDERR "#" x 80,"\n#\t\t\tSynSim simulation automation tool\n#\n#\t\t\t(C) Wim Vanderbauwhede 2002\n#\n","#" x 80,"\n\n Module Simulation::Tools::SynSim::PostProcLib loaded\n\n";


