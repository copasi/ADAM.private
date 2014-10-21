<?php

if (count($argv) != 3)
{
  echo __FILE__ . ": Incorrect number of arguments";
  return;
}

$states = $argv[1];
$infile = $argv[2] . ".txt";
$dotfile = $argv[2] . ".dot";
$cycIn = $argv[2] . ".cyclone";

if (!file_exists($infile))
{
  echo __FILE__ . ": File not found: " . $infile . "<br/>";
  echo getcwd() . "<br/>";
  return;
}

$IN = file($infile, FILE_SKIP_EMPTY_LINES);
$NumVariables = count($IN);

$OUT = fopen($cycIn, 'w');

/*
MODEL NAME: PDS Test
SIMULATION NAME: State Space
NUMBER OF VARIABLES: 10
VARIABLE NAMES: x1 x2 x3 x4 x5 x6 x7 x8 x9 x10
NUMBER OF STATES: 2 2 2 2 2 2 2 2 2 3 
*/
fwrite($OUT, "MODEL NAME: PDS\n");
fwrite($OUT, "SIMULATION NAME: State Space\n");
fwrite($OUT, "NUMBER OF VARIABLES: " . $NumVariables . "\n");
fwrite($OUT, "VARIABLE NAMES:" );

$i = 0;

while ($i < $NumVariables)
{
  $i++;
  fwrite($OUT, " x" . $i);
}

fwrite($OUT, "\n");

fwrite($OUT, "NUMBER OF STATES:" );

$i = 0;

while ($i < $NumVariables)
{
  $i++;
  fwrite($OUT, " " . $states);
}

fwrite($OUT, "\n");
fwrite($OUT, "\n");

foreach($IN as $p)
{
  fwrite($OUT, $p);
}

fclose($OUT);

$Ignored = exec("bin/cyclone " . $cycIn . " -PDS -edges -f " . $dotfile . ' 2>/dev/null');

unlink($cycIn);
?>