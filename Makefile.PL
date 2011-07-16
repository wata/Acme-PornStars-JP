use inc::Module::Install;
name 'Acme-PornStars-JP';
all_from 'lib/Acme/PornStars/JP.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
