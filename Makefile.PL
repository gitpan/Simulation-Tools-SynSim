use ExtUtils::MakeMaker qw( prompt WriteMakefile );
use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Simulation::Tools::SynSim',
    'VERSION_FROM'	=> 'SynSim.pm', # finds $VERSION
   ($] >= 5.005 ?   ## Add these new keywords supported since 5.005
    ('ABSTRACT' => 'Simulation Automation Tool', 
    'AUTHOR'   => 'Wim Vanderbauwhede <wim@motherearth.org>') : ()),

);

sub MY::postamble {
  return "setup :\n\t\@\$(PERL)".' "-I$(INST_LIB)" -e "use SynSim;use Simulation::Tools::SynSim; &Simulation::Tools::SynSim::setup();"'."\n";
}
