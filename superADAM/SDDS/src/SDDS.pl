# Authors: Seda Arat & David Murrugarra
# Name: Script for Stochastic Discrete Dynamical Systems (SDDS)
# Revision Date: October 22, 2014

#!/usr/bin/perl

use strict;
use warnings;

############################################################
###### REQUIRED PERL MODULES before running the code #######
############################################################

use Getopt::Euclid;
use JSON::Parse;
use JSON;
# use Data::Dumper;

############################################################

 # TO_DO: use the transition table information if available

############################################################

=head1 NAME

perl SDDS.pl - Simulate a model from a possible initialization.

=head1 USAGE

perl SDDS.pl -i <input-file> -o <output-file>

=head1 SYNOPSIS

perl SDDS.pl -i <input-file> -o <output-file>

=head1 DESCRIPTION

SDDS.pl - Simulate a model from a possible initialization.

=head1 REQUIRED ARGUMENTS

=over

=item -i[nput-file] <input-file>

The JSON file containing the input information (.json). 

=for Euclid:

network-file.type: readable

=item -o[utput-file] <output-file>

The JSON file containing the average trajectories of variables of interest.

=for Euclid:

file.type: writable

=back

=head1 AUTHOR

Seda Arat

=cut

# it is for random number generator
srand ();

# input
my $inputFile = $ARGV{'-i'};

# output
my $outputFile = $ARGV{'-o'};

# converts input.json to Perl format
my $task = JSON::Parse::json_file_to_perl ($inputFile);
my $input = $task->{'task'}->{'input'}->[0];
my $arguments = $task->{'task'}->{'method'}->{'arguments'}->[0];

# sets the update rules/functions (array)
my $updateRules = $input->{'updateRules'};
my $num_rules = scalar @$updateRules;

# sets the number of variables in the model (array)
my $variables = $input->{'variables'};
my $num_variables = scalar @$variables;

# sets the unified (maximum prime) number that each state can take values up to (scalar)
my $num_states = $input->{'fieldCardinality'};

# sets the number of simulations that the user has specified (scalar)
my $num_simulations = $arguments->{'numberofSimulations'};

# sets the number of steps that the user has specified (scalar)
my $num_steps = $arguments->{'numberofTimeSteps'};

# sets the initial states that the user has specified for simulations (array)
my $initialState = $arguments->{'initialState'};

# sets the propensities (array);
my $propensities = $arguments->{'propensities'};
my $num_propensities = scalar @$propensities;

my $stochFlag = 0;

# upper limits
my $max_num_simulations = 10**6;
my $max_num_steps = 100;

errorCheck ();
my ($polyFuncs, $tranTables) = get_updateRules ();
my $propensitiesTable = get_propensities ();
my $allTrajectories = get_allTrajectories ();
my $averageTrajectories = get_averageTrajectories ();
my $output = format_output ();

my $json = JSON->new->indent ();
open (OUT," > $outputFile") or die ("<br>ERROR: Cannot open the file for output. <br>");
print OUT $json->encode ($output);
close (OUT) or die ("<br>ERROR: Cannot close the file for output. <br>");

# print Dumper ($allTrajectories);
# print ("\n*********************************\n");
# print Dumper ($averageTrajectories);

exit;

############################################################

############################################################
####################### SUBROUTINES ########################
############################################################

=pod

errorCheck ();

Checks if the user enters the options/parameters correctly and there is any interna errors

=cut

sub errorCheck {
  
  # num_rules, num_variables and num_propensities
  unless (($input->{"numberVariables"} == $num_variables) || ($num_rules == $num_variables)) {
    print ("<br>INTERNAL ERROR: There is inconsistency betwen the number of variables ($num_variables) and numberVariables (", $input->{"numberVariables"}, ") OR the number of update rules ($num_rules). <br>");
    exit;
  }

  unless ($num_variables == $num_propensities) {
    print ("<br>ERROR: There must be propensity entries for all $num_variables variables. It seems there are propensity entries for only $num_propensities variables. <br>");
    exit;
  }

  unless ($num_variables == scalar @$initialState) {
     print ("<br>ERROR: There must be $num_variables variables in the initial state. Please check the initial state entry. <br>");
    exit;
  }

  # num_simulations
  if (isnot_number ($num_simulations) || $num_simulations < 1 || $num_simulations > $max_num_simulations) {
    print ("<br>ERROR: The number of simulations must be a number between 1 and $max_num_simulations. <br>");
    exit;
  }

  # num_steps
  if (isnot_number ($num_steps) || $num_steps < 1 || $num_steps > $max_num_steps) {
    print ("<br>ERROR: The number of steps must be a number between 1 and $max_num_steps. <br>");
    exit;
  }

  # propensities
  foreach my $p (@$propensities) {
    my $actProp = $p->{"activation"};
    unless (($actProp >= 0) && ($actProp <= 1)) {
      print ("<br>ERROR: The activation propensities for stochastic simulations must be a number between 0 and 1. <br>");
      exit;
    }
    if ($actProp != 1) {
      $stochFlag = 1;
    }

    my $degProp = $p->{"degradation"};
    unless (($degProp >= 0) && ($degProp <= 1)) {
      print ("<br>ERROR: The degradation propensities for stochastic simulations must be a number between 0 and 1. <br>");
      exit;
    }
    if ($actProp != 1) {
      $stochFlag = 1;
    }

  }

}

############################################################

=pod

get_updateRules ();

Returns 2 hash tables one of which is for polynomial functions and another is for transition tables

=cut

sub get_updateRules {
  my $polyFuncs = {};
  my $tranTables = {};

  foreach my $i (@$updateRules) {
    my $key = $i->{"target"};
    $polyFuncs->{$key} = $i->{"functions"}->[0]->{"polynomialFunction"};

    my $value_tt = {};
    foreach my $j (@{$i->{"functions"}->[0]->{"transitionTable"}}) {
      my $k = join (' ', $j->[0]);
      $value_tt->{$k} = $j->[1];
    }
    
    $tranTables->{$key} = $value_tt;
  }
  
  return ($polyFuncs, $tranTables);
}

############################################################

=pod

get_propensities ();

Returns a hash table whose keys are the ids and values are a hash table containing activation and degradation propensities

=cut

sub get_propensities {
  my $propensitiesTable = {};

  foreach my $i (@$propensities) {
    my $key = $i->{"id"};

    my $value = {
		 "activation" => $i->{"activation"}, 
		 "degradation" => $i->{"degradation"}
		};
    
    $propensitiesTable->{$key} = $value;
  }
  
  return $propensitiesTable;
}

############################################################

=pod

get_allTrajectories ();

Stores all trajectories into a hash table whose keys are the order of 
the trajectories and the values are the trajectories at the initial state 
and length is num_steps+1.
Returns a reference of the all trajectories hash.

=cut

sub get_allTrajectories {
  my %alltrajectories = ();

  for (my $i = 1; $i <= $num_simulations; $i++) {
    my %table = ();
    my @is = @$initialState;

    for (my $k = 1; $k <= $num_variables; $k++) {
      push (@{$table{"x$k"}}, $is[$k - 1]);
    }
    
    for (my $j = 1; $j <= $num_steps; $j++) {
      my @ns = @{get_nextstate (\@is)};
      
      for (my $r = 1; $r <= $num_variables; $r++) {
	push (@{$table{"x$r"}}, $ns[$r - 1]);
      }
      @is = @ns;
    }
    $alltrajectories{$i} = \%table;
  }
  return \%alltrajectories;
}

############################################################

=pod

get_averageTrajectories ();

Stores average trajectories of all variables into a hash.
Returns a reference of average trajectory hash.

=cut

sub get_averageTrajectories {
  my @averageTrajectories;

  for (my $v = 1; $v <= $num_variables; $v++) {
    my @aveTraj;
    for (my $t = 0; $t <= $num_steps; $t++) {
      my $sum = 0;
      
      for (my $s = 1; $s <= $num_simulations; $s++) {
	$sum += $allTrajectories->{$s}->{"x$v"}->[$t];
      }
      
      $aveTraj[$t] = $sum / $num_simulations;
    }
    my %hash = (
		"id" => "x$v",
		"aveTraj" => \@aveTraj
	       );
    push (@averageTrajectories, \%hash);
  }
  
  return \@averageTrajectories;
}

############################################################

=pod

format_output ();

Returns a hash table containing proper output for this code.

=cut

sub format_output {
  my $simType = "";
  if ($stochFlag) {
    $simType = "stochastic";
  }
  else {
    $simType = "deterministic";
  }

  my $output = {"output" => [{
			      "type" => "simulationOutput",
			      "description" => "average trajectory of each variable in the sytem is obtained by simulation using SDDS",
			      "fieldCardinality" => $num_states,
			      "numberVariables" => $num_variables,
			      "numberofTimeSteps" => $num_steps,
			      "numberofSimulations" => $num_simulations,
			      "initialState" => $initialState,
			      "simulationType" => $simType,
			      "averageTrajectories" => $averageTrajectories
			     }]
	       };
  
  return $output;
}

############################################################

=pod

isnot_number ($n);

Returns true if the input is not a number, false otherwise

=cut

sub isnot_number {
  my $n = shift;

  if ($n =~ m/\D/) {
    return 1;
  }
  else {
    return 0;
  }
}

############################################################

=pod

get_nextstate ($state);

Returns the next state (as a reference of an array) of a given state 
(as a reference of an array) using update functions and propensity parameters.

=cut

sub get_nextstate {
  my $currentState = shift;
  my $nextState;
  if ($stochFlag) {
    $nextState = get_nextstate_stoch ($currentState);
  }
  else {
    $nextState = get_nextstate_det ($currentState);
  }

  return $nextState;
}

############################################################

=pod

get_nextstate_stoch ($state);

Returns the next state (as a reference of an array) of a given state 
(as a reference of an array) using update functions and propensity parameters.

=cut

sub get_nextstate_stoch {
  my $state = shift;
  my $z = get_nextstate_det ($state);

  my @nextsstateStoch;
  
  for (my $j = 0; $j < $num_variables; $j++) {
    my $r = rand ();
    my $i = $j + 1;
    my $prop = $propensitiesTable->{"x$i"};
    
    if ($state->[$j] < $z->[$j]) {
      if ($r < $prop->{"activation"}) {
 	$nextsstateStoch[$j] = $z->[$j];
      }
      else{
 	$nextsstateStoch[$j] = $state->[$j];
      }
    }
    elsif ($state->[$j] > $z->[$j]) {
      if ($r < $prop->{"degradation"}) {
 	$nextsstateStoch[$j] = $z->[$j];
      }
      else{
 	$nextsstateStoch[$j] = $state->[$j];
      }
    }
    else {
      $nextsstateStoch[$j] = $state->[$j];
    }
  }

  return \@nextsstateStoch;
 }

############################################################

=pod

get_nextstate_det ($state);

Returns the next state (as a reference of an array) of a given state using 
update functions.

=cut

sub get_nextstate_det {
  my $currState = shift;
  my @nextState;
  
  for (my $i = 1; $i <= @$currState; $i++) {
    my $func = $polyFuncs->{"x$i"};
    my $tt = $tranTables->{"x$i"};

    if ($func) {
      for (my $j = 1; $j <= @$currState; $j++) {
	$func =~ s/x[$j]/\($currState->[$j - 1]\)/g;
      }
      
      $nextState[$i - 1] = eval ($func) % $num_states;
    }
    elsif ($tt) {

      # TO_DO: use the transition table information if available

    }
    else {
      print ("<br>INTERNAL ERROR: Neither polynomial function or transition table is available as an update rule for x$i. <br>");
      exit;
    }
  }
  
  return \@nextState;
}

############################################################
