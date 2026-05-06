<?php



require_once '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/vendor/infection/include-interceptor/src/IncludeInterceptor.php';

use Infection\StreamWrapper\IncludeInterceptor;

IncludeInterceptor::intercept('/Users/tfidry/Project/Humbug/testFrameworks/Codeception/src/Inner/InnerSourceClass.php', '/Users/tfidry/Project/Humbug/testFrameworks/Codeception/var/infection/infection/mutant.d3d87dfe17f47e18a225d2d5b50307b3.infection.php');
IncludeInterceptor::enable();
