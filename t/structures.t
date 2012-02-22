#!perl

use Test::Most;
use English '-no_match_vars';
use SVN::Core;
use SVN::Repos;
use File::Temp;

use SVN::Tree;

my $repos_dir = File::Temp->newdir();
my $repos     = SVN::Repos::create( "$repos_dir", (undef) x 4 );
my $fs        = $repos->fs;
my $svn_tree
    = SVN::Tree->new( root => $fs->revision_root( $fs->youngest_rev ) );

my $txn      = $fs->begin_txn( $fs->youngest_rev );
my $txn_root = $txn->root;
for my $project ( map {"proj$ARG"} ( 1 .. 3 ) ) {
    $txn_root->make_dir($project);
    for (qw(trunk branches tags)) { $txn_root->make_dir("$project/$ARG") }
}
$txn->commit;

$svn_tree->root( $fs->revision_root( $fs->youngest_rev ) );
cmp_bag( [ map { $ARG->value->stringify } @{ $svn_tree->projects } ],
    [qw(proj1 proj2 proj3)], 'projects' );
cmp_bag(
    [ keys %{ $svn_tree->branches } ],
    [ map { $ARG->value->stringify } @{ $svn_tree->projects } ],
    'branches keys match project values',
);

cmp_bag(
    [   map     { $ARG->path->stringify }
            map { @{ $svn_tree->branches->{$ARG} } }
            keys %{ $svn_tree->branches },
    ],
    [ map {"proj$ARG/trunk"} ( 1 .. 3 ) ],
    'branch paths',
);

done_testing();
