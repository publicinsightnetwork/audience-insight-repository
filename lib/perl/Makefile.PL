use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'AIR2';
all_from 'AIR2.pm';

requires 'Algorithm::C3' => '0.08';
requires 'Any::Moose' => '0.10';
requires 'Apache::AuthTkt' => '2.1';
requires 'Bit::Vector' => '6.6';
requires 'CHI' => '0.28';
requires 'Clone' => '0.31';
requires 'Clone::PP' => '1.02';
requires 'Compress::Raw::Zlib' => '2.02';
requires 'Config::General' => '2.43';
requires 'Config::IniFiles' => '2.57';
requires 'Crypt::CBC' => '2.30';
requires 'Crypt::Rijndael' => 0;
requires 'DBD::mysql' => '4.013';
requires 'DBI' => '1.609';
requires 'Data::Dump' => '1.15';
requires 'Data::Dumper' => '2.121_17';
requires 'Data::OptList' => '0.104';
requires 'Data::Transformer' => '0.04';
requires 'Data::UUID' => '1.202';
requires 'DateTime' => '0.65';
requires 'DateTime::Format::Builder' => '0.7901';
requires 'DateTime::Format::MySQL' => '0.04';
requires 'DateTime::Locale' => '0.43';
requires 'DateTime::TimeZone' => '1.23';
requires 'Devel::GlobalDestruction' => '0.02';
requires 'Module::Pluggable' => '0.3';
requires 'Dezi'              => 0.002002;
requires 'Dezi::Client'      => 0;
requires 'Dezi::Stats'       => '0.001003';
requires 'Dezi::UI'          => 0;
requires 'DBIx::InsertHash'  => 0;
requires 'Config::Any'       => 0;
requires 'Plack::Handler::Starman' => 0;
requires 'Plack::Middleware::Deflater' => 0;
requires 'Digest::JHash' => '0.05';
requires 'Digest::MD5' => '2.37';
requires 'Digest' => '1.00';
requires 'Email::Address' => 0;
requires 'File::NFSLock' => '1.20';
requires 'File::Path' => '2.07_02';
requires 'File::Slurp' => '9999.13';
requires 'File::Temp' => '0.22';
requires 'Filesys::Notify::Simple' => 0;
requires 'Getopt::Long' => '2.37';
requires 'HTTP::Engine' => '0';
requires 'HTTP::Headers::Fast' => '0.11';
requires 'IO' => '1.23';
requires 'JSON::XS' => '2.27';
requires 'Lucy' => '0.003000';
requires 'Lingua::Stem::Snowball' => '0.952';
requires 'List::MoreUtils' => '0.24';
requires 'Locale::Maketext' => '1.13';
requires 'Locale::Maketext::Lexicon' => '0.77';
requires 'Locale::Maketext::Simple' => '0.20';
requires 'Log::Any' => '0.04';
requires 'MIME::Base64' => '3.07';
requires 'MIME::Types' => '1.27';
requires 'MRO::Compat' => '0.11';
requires 'Module::Load' => '0.16';
requires 'Module::Load::Conditional' => '0.30';
requires 'Moose' => '0.88';
requires 'MooseX::Types' => '0.16';
requires 'Params::Check' => '0.26';
requires 'Params::Util' => '1.00';
requires 'Params::Validate' => '0.91';
requires 'Path::Class' => '0.17';
requires 'Path::Class::File::Lockable' => '0.02';
requires 'Path::Class::File::Stat' => '0.02';
requires 'Pod::Parser' => '1.3';
requires 'Rose::Object' => '0.854';
requires 'Rose::DB' => '0.758';
requires 'Rose::DB::Object' => '0.786';
requires 'Rose::DBx::AutoReconnect' => '0.03';
requires 'Rose::DBx::Object::Indexed' => '0.009';
requires 'Rose::DBx::Object::MoreHelpers' => '0.06';
requires 'Rose::DateTime' => '0.50';
requires 'Rose::ObjectX::CAF' => '0.03';
requires 'SQL::ReservedWords' => '0.7';
requires 'SWISH::Prog::Lucy' => '0.07';
requires 'Safe' => '2.16';
requires 'Search::OpenSearch' => '0.17';
requires 'Search::OpenSearch::Engine::Lucy' => '0.10';
requires 'Search::Query' => '0.18';
requires 'Search::Query::Dialect::Lucy' => '0.01';
requires 'Search::Tools' => '0.84';
requires 'Storable' => '2.20';
requires 'Sub::Exporter' => '0.982';
requires 'Sub::Install' => '0.925';
requires 'Sub::Name' => '0.04';
requires 'Template' => '2.24';
requires 'Term::ProgressBar::Simple' => 0;
requires 'Text::ParseWords' => '3.27';
requires 'Time::Clock' => '0.12';
requires 'Time::Duration' => '1.06';
requires 'Time::Duration::Parse' => '0.06';
requires 'Time::HiRes' => '1.9715';
requires 'Time::Local' => '1.1901';
requires 'URI' => '1.54';
requires 'Unix::PID::Tiny' => '0.5';
requires 'Variable::Magic' => '0.36';
requires 'WWW::Mailchimp' => '0.007';
requires 'XML::Simple' => '2.18';

perl_version '5.8.3';
license 'GPL';
homepage 'http://code.google.com/p/publicinsight/';
bugtracker 'http://code.google.com/p/publicinsight/issues/list';
repository 'http://publicinsight.googlecode.com/svn/trunk/';

auto_install(
    #make_args   => '--hello',   # option(s) for CPAN::Config
    #force       => 1,           # pseudo-option to force install
    do_once     => 1,           # skip previously failed modules
);

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean    => {
        FILES => join( ' ', qw())
    }
);

