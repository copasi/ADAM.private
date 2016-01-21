for ($i=0;$i<1000;$i++) {
        $line = "echo \"J=$i;load \\\"rev-eng-gfan.m2\\\";J\"|M2";
        print "$line\J";
        system($line);
}