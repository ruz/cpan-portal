use inc::Module::Install;

name        'CpanPortal';
version     '0.01';
requires    'Jifty' => '0.81208';

requires    'Pod::Usage';
requires    'File::Spec';
requires    'Getopt::Long';
requires    'CPAN::Mini';


WriteAll;
