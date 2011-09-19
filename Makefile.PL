use inc::Module::Install;
name 'WWW-CPANRatings';
all_from 'lib/WWW/CPANRatings.pm';

# requires '';

tests 't/*.t';

readme_markdown_from_pod 'lib/WWW/CPANRatings.pm';


author_tests 'xt';
# test_requires 'Test::More';
# auto_set_repository;
auto_include;
WriteAll;
