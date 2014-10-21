<?php

if (count($argv) != 2)
{
	echo __FILE__ . ": Incorrect number of arguments";
	return;
}

$dotfile = $argv[1] . ".dot";
$resultfile = $argv[1] . ".json";

if (!file_exists($dotfile))
{
  echo __FILE__ . ": File not found: " . $dotfile . "<br/>";
  echo getcwd() . "<br/>";
  return;
}

$ComponentsDir = dirname($argv[1]) . "/" . basename($argv[1], ".functionfile");
mkdir($ComponentsDir, 0777, true);

// Determine the number of components

$NumComponents = explode(' ', trim(exec("gc -c " . $dotfile)));
$NumComponents = $NumComponents[0];

$Ignored = system("ccomps -x -o " . $ComponentsDir . "/component " . $dotfile);
$Ignored = system("mv " . $ComponentsDir . "/component " . $ComponentsDir . "/component_0");

$TotalSize = trim(exec("grep -c label " . $dotfile . ' 2>/dev/null'));

$NumFixedPoints = 0;
$NumCycles = 0;
$HaveCycles = false;
$Components = array();

for ($i = 0; $i < $NumComponents; $i++)
{
  $Component = array();
  
  $Component['size'] = trim(exec("grep -c label " . $ComponentsDir . "/component_" . $i . ' 2>/dev/null'));
  $Component['graph'] = file_get_contents($ComponentsDir . "/component_" . $i);
  
  $Ignored = system("sccmap " . $ComponentsDir . "/component_" . $i . " -o " . $ComponentsDir . "/cycle_" . $i . ' >/dev/null');
  $Component['cycleLength'] = trim(exec("grep -c label " .  $ComponentsDir . "/cycle_" . $i . ' 2>/dev/null'));

  if ($Component['cycleLength'] <= 1)
  {
    $Ignored = system("sccmap -d " . $ComponentsDir . "/component_" . $i . " -o " . $ComponentsDir . "/cycle_" . $i . ' >/dev/null');
    $Component['cycleLength'] = 1;
    $NumFixedPoints++;
  } 
  else
  {
    $NumCycles++;
  }

  $Component['cycleGraph'] = file_get_contents($ComponentsDir . "/cycle_" . $i);
  $Components[] = $Component;
  
  unlink($ComponentsDir . "/component_" . $i);
  unlink($ComponentsDir . "/cycle_" . $i);
}

$StateSpaceAnalysis = array();
$StateSpaceAnalysis['size'] = $TotalSize;
$StateSpaceAnalysis['numFixPoints'] = $NumFixedPoints;
$StateSpaceAnalysis['numLimitCycles'] = $NumCycles;
$StateSpaceAnalysis['graph'] = file_get_contents($dotfile);
$StateSpaceAnalysis['components'] = $Components;

unlink($dotfile);
rmdir($ComponentsDir);

file_put_contents($resultfile, json_encode($StateSpaceAnalysis));

?>