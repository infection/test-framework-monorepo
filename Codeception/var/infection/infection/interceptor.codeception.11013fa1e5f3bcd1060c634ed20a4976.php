<?php



require_once '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/vendor/infection/include-interceptor/src/IncludeInterceptor.php';

use Infection\StreamWrapper\IncludeInterceptor;

IncludeInterceptor::intercept('/Users/tfidry/Project/Humbug/testFrameworks/Codeception/src/Covered/Calculator.php', '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/var/infection/infection/mutant.11013fa1e5f3bcd1060c634ed20a4976.infection.php');
IncludeInterceptor::enable();
