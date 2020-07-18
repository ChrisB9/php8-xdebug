<?php

declare(strict_types=1);

$profilerHeader = '/home/application/.composer/vendor/perftools/php-profiler/external/header.php';
if ((isset($_COOKIE['XDEBUG_PROFILE']) || getenv('PROFILING_ENABLED')) && file_exists($profilerHeader)) {
    require_once $profilerHeader;
}
