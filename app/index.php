<?php

declare(strict_types=1);

require __DIR__ . DIRECTORY_SEPARATOR . 'Test.php';

$a = new Test(12.1);
$b = new Test(1);
var_dump($a->getTest(), $b->getTest());

var_dump($a->test()());

var_dump(str_contains($b::class, 'T') === true);
var_dump(get_debug_type($b));
