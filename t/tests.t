#!perl

use Test::Most;
use SVN::Core;
use SVN::Repos;
use File::Temp;

use SVN::Tree;

my $repos_dir = File::Temp->newdir();
my $repos     = SVN::Repos::create( "$repos_dir", (undef) x 4 );
my $fs        = $repos->fs;

my $svntree = new_ok(
    'SVN::Tree' => [ root => $fs->revision_root( $fs->youngest_rev ) ] );
is( $svntree->tree->path->stringify, '/', 'empty repo tree' );

done_testing();
