<?php



require_once '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/vendor/infection/include-interceptor/src/IncludeInterceptor.php';

use Infection\StreamWrapper\IncludeInterceptor;

IncludeInterceptor::intercept('/Users/tfidry/Project/Humbug/testFrameworks/Codeception/src/SourceClass.php', '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/var/infection/infection/mutant.061e1d8a3f8a130dde6c04407df331bd.infection.php');
IncludeInterceptor::enable();
