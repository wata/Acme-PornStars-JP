use inc::Module::Install;
name 'Acme-PornStars-JP';
all_from 'lib/Acme/PornStars/JP.pm';

requires 'Lingua::JA::Moji' => 0.08;
requires 'Cache::FileCache' => 1.06;
requires 'XML::Simple'      => 2.18;
requires 'URI'              => 1.58;
requires 'Furl'             => 0.32;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
