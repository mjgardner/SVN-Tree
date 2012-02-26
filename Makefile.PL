
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "SVN::Fs + Tree::Path::Class",
  "AUTHOR" => "Mark Gardner <mjgardner\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Carp" => 0,
    "English" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Scalar::Util" => 0,
    "Test::More" => "0.94",
    "Test::Most" => 0,
    "Test::Requires" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "SVN-Tree",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "SVN::Tree",
  "PREREQ_PM" => {
    "List::MoreUtils" => 0,
    "Modern::Perl" => 0,
    "Moose" => 0,
    "MooseX::Has::Options" => 0,
    "MooseX::MarkAsMethods" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "Path::Class" => 0,
    "SVN::Core" => "0.0.0",
    "SVN::Fs" => 0,
    "SVN::Repos" => 0,
    "Tree::Path::Class" => 0,
    "Try::Tiny" => 0,
    "strict" => 0,
    "utf8" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



