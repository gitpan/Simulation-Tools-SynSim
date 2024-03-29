package Simulation::Tools::SynSim::Dictionary;

use vars qw( $VERSION );
$VERSION = '0.9.1';

#################################################################################
#                                                                              	#
#  Copyright (C) 2000,2002 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

=headers

Module to support SynSim simulation automation tool.
Simple dictionary to have meaningful annotations on the plots generated by PostProcessors.pm.
The contents of %make_nice  is specific to the type of simulations.
This module is only used by PostProcLib.pm

$Id: Dictionary.pm,v 1.3 2002/10/16 15:27:39 wim Exp $

=cut

use Exporter;

@Simulation::Tools::SynSim::Dictionary::ISA = qw(Exporter);
@Simulation::Tools::SynSim::Dictionary::EXPORT = qw(
		     %make_nice
                  );

# Translate the parameter names and values into something meaningful
%Simulation::Tools::SynSim::Dictionary::make_nice=(
_BUFTYPE => {
title=>'Buffer type',
	     0=>'Adjustable',
	     1=>'Fixed-length',
	     2=>'Multi-exit',
	    },
_TRAFDIST => {
title=>'Packet gap dist.',
	      0=>'Poisson', 
	      1=>'Pareto',
	      2=>'Uniform',
	     },
_PLDIST => {
title=>'Packet length dist.',
	      2=>'IP', 
	      1=>'Ethernet',
	      0=>'Uniform',
	     },
_KEEP_ORDER => {
title=>'Ordered',
0=>'No',
1=>'Yes',
	       },
_NMAXGAP => {
title=>'Max. gap width',
},

_NPACK => {
title=>'Number of packets',
},

_NPORTS => {
title=>'Number of ports',
},
_K_PARETO => {
title=>'Pareto constant',
},

_NBUFS => {
title => 'Number of buffers',
},

_BLOCKING => {
title => 'Buffer output mux blocking or not',
},
_UNITPL => {
title => 'Unit packet length',
},

_MINGW => {
title => 'Min. gap width',
},

_FRACT_MIN => {
title => 'Fraction of 40 byte to 1500 byte packets',
},

_NMAX => {
title => 'Max. number of units',
},
_SAMPL => {
title => 'Sampling freq.',
},

);

#==============================================================================
