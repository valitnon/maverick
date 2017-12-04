# To use: cpanm --installdeps .
requires 'perl' => '5.010001';
requires 'Autoload::AUTOCAN';
requires 'Carp';
requires 'Config::IniFiles' => '2.83';
requires 'DBM::Deep' => '2.0011';
requires 'Exporter';
requires 'File::Spec::Functions';
requires 'File::Path';
requires 'File::Temp';
requires 'FindBin';
requires 'Future::Mojo' => '0.003';
requires 'IRC::Utils' => '0.12';
requires 'List::Util';
requires 'Module::Runtime';
requires 'Mojolicious' => '7.31';
requires 'Mojo::IOLoop::Subprocess::Sereal' => '0.005';
requires 'Mojo::IRC' => '0.26';
requires 'Moo' => '2.000000';
requires 'Moo::Role' => '2.000000';
requires 'namespace::clean';
requires 'Parse::IRC' => '1.20';
requires 'Role::EventEmitter';
requires 'Scalar::Util';
requires 'Try::Tiny';
test_requires 'Test::More' => '0.88';
recommends 'IO::Socket::SSL' => '1.94';
recommends 'Mojo::JSON::MaybeXS';
