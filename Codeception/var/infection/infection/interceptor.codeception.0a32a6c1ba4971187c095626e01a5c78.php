<?php



require_once '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/vendor/infection/include-interceptor/src/IncludeInterceptor.php';

use Infection\StreamWrapper\IncludeInterceptor;

IncludeInterceptor::intercept('/Users/tfidry/Project/Humbug/testFrameworks/Codeception/src/Covered/LoggerTrait.php', '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/var/infection/infection/mutant.0a32a6c1ba4971187c095626e01a5c78.infection.php');
IncludeInterceptor::enable();
