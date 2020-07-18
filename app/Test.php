<?php

declare(strict_types=1);

final class Test
{
    public function __construct(
        private int|float $test
    )
    {

    }

    public function getTest(): float|int
    {
        return $this->test;
    }

    public function test(): mixed
    {
        return fn () => $this->test > 2 ? true : throw new Exception('has to be above 5');
    }
}
