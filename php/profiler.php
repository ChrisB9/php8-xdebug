<?php

declare(strict_types=1);

use Xhgui\Profiler\Profiler;
use Xhgui\Profiler\ProfilingFlags;

if (!file_exists('/home/application/.composer/vendor/autoload.php')) {
    return;
}

require '/home/application/.composer/vendor/autoload.php';

if (!class_exists(Profiler::class)) {
    return false;
}

$config = [
    // If defined, use specific profiler
    // otherwise use any profiler that's foundy
    'profiler' => Profiler::PROFILER_TIDEWAYS_XHPROF,
    'profiler.flags' => [
        ProfilingFlags::CPU,
        ProfilingFlags::MEMORY,
        ProfilingFlags::NO_BUILTINS,
        ProfilingFlags::NO_SPANS,
    ],

    'save.handler' => Profiler::SAVER_FILE,
    'save.handler.file' => array(
        // Appends jsonlines formatted data to this path
        'filename' => getenv('PROFILING_FILE') ?: '/opt/docker/profiler/xhgui.data.jsonl',
    ),

    // Environment variables to exclude from profiling data
    'profiler.exclude-env' => [
        'APP_DATABASE_PASSWORD',
        'PATH',
    ],

    'profiler.options' => [
    ],

    /**
     * Determine whether profiler should run.
     * This default implementation just disables the profiler.
     * Override this with your custom logic in your config
     * @return bool
     */
    'profiler.enable' => function () {
        return (isset($_COOKIE['XDEBUG_PROFILE']) || getenv('PROFILING_ENABLED'));
    },

    /**
     * Creates a simplified URL given a standard URL.
     * Does the following transformations:
     *
     * - Remove numeric values after =.
     *
     * @param string $url
     * @return string
     */
    'profile.simple_url' => function($url) {
        return preg_replace('/=\d+/', '', $url);;
    },
];

try {
    /**
     * The constructor will throw an exception if the environment
     * isn't fit for profiling (extensions missing, other problems)
     */
    $profiler = new Profiler($config);

    // The profiler itself checks whether it should be enabled
    // for request (executes lambda function from config)
    $profiler->enable();

    // shutdown handler collects and stores the data.
    $profiler->registerShutdownHandler();
} catch (Exception $e){
    // throw away or log error about profiling instantiation failure
}
