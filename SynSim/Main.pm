package Simulation::Tools::SynSim::Main;

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

Module to support script for simulation automation.
The function &main() is called from the innermost loop of
SynSimLoops.pm; the latter is generated on the fly by
SynSimGen.pm.

This module is generic.

$Id: SynSim.pm,v 1.7 2002/10/16 15:27:40 wim Exp $

=cut

use sigtrap qw(die untrapped normal-signals
               stack-trace any error-signals); 
use strict;
use Cwd;
use FileHandle;
use Exporter;

@Simulation::Tools::SynSim::Main::ISA = qw(Exporter);
@Simulation::Tools::SynSim::Main::EXPORT = qw(
		     main
                  );

use lib '.','..';

use  Simulation::Tools::SynSim::Analysis;

##################################################################################

sub main {

use Cwd;

my $dataset=shift; 
my $count=shift;
my $dataref=shift;
my $flagsref=shift;
my ($batch,$interactive,$nosims,$plot,$verbose)=@{$flagsref};

(my $nsims, my $simdataref)=@{$dataref};

print STDERR '#',"-" x 79, "\n";## Simulation run $count\n";

my %simdata=%{$simdataref};
my @results=();
my $command=$simdata{COMMAND}||'perl inputfile outputfile'; 

my $pattern=$simdata{OUTPUT_FILTER_PATTERN}|| '.*';
my $simtype=$simdata{SIMTYPE}||'';
my $dirname= "${simtype}-$dataset";

my $devtype=$simdata{DEVTYPE}||'';
my $simtitle=$simdata{TITLE};
foreach my $key (keys %simdata) {
($key!~/^_/) && next;
($simtitle=~/$key/) && do {
$simtitle=~s/$key/$key:$simdata{$key}/;
};
}
my $title="#$simtitle\n"||"#$devtype $simtype simulation\n";
my $ext=$simdata{TEMPL}||'.templ';
my $extin=$simdata{EXT}||'.pl';
my $workingdir =cwd();
chdir  "$workingdir/$dirname";

## INPUT FILE CREATION

foreach my $simn (1..$nsims) {
  if($nsims==1){$simn=''} else {
    print STDERR "# Subrun $simn of $nsims \n";
  }
  my $inputfile= "${simtype}_${simn}$extin";
  my $outputfile= "${simtype}_C${count}_${simn}.out";
my $commandline=$command;
$commandline=~s/inputfile/$inputfile/i;
  $commandline=~s/outputfile/$outputfile/i;

  open (NEW, ">$inputfile");
  print NEW ("$title");

foreach my $type ($devtype,$simtype) {
  if($type) {
my $nsim=($simn eq '')?0:$simn;
  &gen_sim_script ($nsim-1,"$simtype$ext",\%simdata,\*NEW,$dataset);
  print NEW ("\n");
}
} # device and simulation templates
  close (NEW);
  
  if($nosims==0) {

    if($verbose) {

      system("$commandline");
      #      system("$command ${simtype}_$simn.pl ${simtype}_C${count}_$simn.out");
    } else { 
      print STDERR "\n";
      print STDERR grep /$pattern/,`$commandline >& simlog`;
#      print STDERR grep /$pattern/,`$command ${simtype}_$simn.pl ${simtype}_C${count}_${simn}.out >& simlog`;
      print STDERR "\n";
    }
  } # if simulations not disabled
    if($nsims>1) {
&egrep($pattern,"${simtype}_C${count}_${simn}.out",'>>',"${simtype}_C${count}_.out");
    }

    my $i=($nsims>1)?$simn-1:0;
    open(RES,"<${simtype}_C${count}_${simn}.out");
    $results[$i]=<RES>;
    my $another=<RES>;
    if($another){
      $results[$i]="${simtype}_C${count}_${simn}.out";
    }
    close RES;
  
} # nsims 

&egrep($pattern, "${simtype}_C${count}_.out", '>>', "${simtype}_C$count.res");
chdir "$workingdir";

return \@results;
} #END of main()

print STDERR "#" x 80,"\n#\t\t\tSynSim simulation automation tool\n#\n#\t\t\t(C) Wim Vanderbauwhede 2002\n#\n","#" x 80,"\n\n Module SynSim loaded\n\n";

#-------------------------------------------
# SUBROUTINES
#-------------------------------------------


#--------------------------------------
# GENERATION OF THE SIMULATION SCRIPT
#--------------------------------------

#WV What happens: the templates for _SIMTYPE  are read in
#WV and the variables are substituted with the values from the .data file

sub gen_sim_script {
my $nsim=shift;
my $templfilename=shift;
my $simdataref=shift;
my %simdata=%{$simdataref};
my $fh=shift; 
my $dataset=shift;

	# OPEN TEMPLATE
	open (TEMPL, "<$templfilename")||die "Can't open $templfilename\n";

	while (my $line = <TEMPL>) {
		  foreach my $key (keys %simdata) {
		    ($key!~/^_/) && next;
			my $ndata=@{$simdata{$key}};
			if($ndata>1) {
			  if($line =~ s/$key(?!\w)/$simdata{$key}->[$nsim]/g){
			  print STDERR "# $key = ",$simdata{$key}->[$nsim],"\n";
			}
			} else {
			  $line =~ s/$key(?!\w)/$simdata{$key}->[0]/g;
			} # if..else

		      } # foreach 

		  # check for not_defined variables
		if($line=~/\b(_\w+?)\b/&&$line!~/$1\$/) {
		  my $nondefvar=$1;
		  $line=~s/$nondefvar/0/;
		  print STDERR "\nWarning: $nondefvar ($templfilename) not defined in $dataset.\n"; #Substituted by 0.\n";
		} # if some parameter is still there
		print $fh $line;
	} # while
close TEMPL;
} # END OF gen_sim_script 

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
