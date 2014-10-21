<?php

if (count($argv) != 2)
{
 echo __FILE__ . ": Incorrect number of arguments";
 return;
}

$jsonfile = $argv[1] . ".json";

$r = json_decode(file_get_contents($jsonfile), true);

?>

Number of components <?php echo count($r['components']) ?>

Number of fixed points <?php echo $r['numFixPoints'] ?>

Number of cycles <?php echo $r['numLimitCycles'] ?> <br/>

<?php if ($r['numFixPoints'] >0 ) 
{ ?>
Fixed point, component size, length
<?php
  foreach ($r['components'] as $c) 
  {
    if ($c['cycleLength'] == 1) 
    { 
      preg_match('/(node[0-9]+) -> (node[0-9]+)/', $c['cycleGraph'], $Matches);
      preg_match('/' . $Matches[1] . '\\s+\\[label="([\\s0-9]+)"./', $c['cycleGraph'], $Matches);
    
      echo '(' . trim($Matches[1]) . '), ' . $c['size'] . ', ' . $c['cycleLength'] . '
';
    }
  }
} ?>

<?php if ($r['numLimitCycles'] >0 )
{ ?>
Limit cycle, component size, length
<?php
  foreach ($r['components'] as $c) 
  {
    if ($c['cycleLength'] > 1) 
    { 
      preg_match('/(node[0-9]+) -> (node[0-9]+)/', $c['cycleGraph'], $Matches);
      preg_match('/' . $Matches[1] . '\\s+\\[label="([\\s0-9]+)"./', $c['cycleGraph'], $Matches);
    
      echo '(' . trim($Matches[1]) . '), ' . $c['size'] . ', ' . $c['cycleLength'] . '
';
    }
  }
} ?>

<?php 
if ($r['size'] < 1000)
{
  $dotfile = $argv[1] . ".dot";
  $giffile =  $argv[1] . ".gif";
  file_put_contents($dotfile, $r['graph']);
  system("dot -Tgif -o " . $giffile . " " . $dotfile);
  unlink($dotfile);
?>

<a href="<?php echo $giffile ?>" target="_blank">Click to view the state space graph.</a>
<?php } ?>
Click to view the dependency graph.