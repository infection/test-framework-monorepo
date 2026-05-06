<?php



require_once '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/vendor/infection/include-interceptor/src/IncludeInterceptor.php';

use Infection\StreamWrapper\IncludeInterceptor;

IncludeInterceptor::intercept('/Users/tfidry/Project/Humbug/testFrameworks/Codeception/src/Covered/UserService.php', '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/var/infection/infection/mutant.ea520d3283665806b42fc21ee7155574.infection.php');
IncludeInterceptor::enable();
