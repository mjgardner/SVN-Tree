use utf8;
use Modern::Perl;

package SVN::Tree;
use strict;

# VERSION
use English '-no_match_vars';
use List::MoreUtils 'any';
use Path::Class;
use SVN::Core;
use SVN::Fs;
use Tree::Path::Class;
use Moose;
use MooseX::Has::Options;
use MooseX::Types::Moose qw(ArrayRef HashRef Maybe);
use MooseX::MarkAsMethods autoclean => 1;

has root => ( qw(:ro :required), isa => '_p_svn_fs_root_t' );

has tree => (
    qw(:ro :required :lazy),
    isa      => 'Tree::Path::Class',
    writer   => '_set_tree',
    init_arg => undef,
    default  => sub { $ARG[0]->_root_to_tree( $ARG[0]->root ) },
);

has projects => (
    qw(:ro :required :lazy_build),
    isa => ArrayRef [ Maybe ['Tree::Path::Class'] ],
    writer   => '_set_projects',
    init_arg => undef,
);

has branches => (
    qw(:ro :required :lazy_build),
    isa => HashRef [ ArrayRef [ Maybe ['Tree::Path::Class'] ] ],
    writer   => '_set_branches',
    init_arg => undef,
);

sub _build_projects {
    my $self = shift;
    my $tree = $self->tree;
    given ( \&_match_svn_dirs ) {
        when ( $_->( _children_value($tree) ) ) { return [$tree] }
        when ( $_->( map { _children_value($ARG) } $tree->children ) ) {
            return [ $tree->children ];
        }
    }
    return [];
}

sub _build_branches {
    my $self = shift;
    my %branches;
    for my $project ( @{ $self->projects } ) {
        @{ $branches{$project} }
            = map { _trunk_or_branches($ARG) } $project->children;
    }
    return \%branches;
}

sub _trunk_or_branches {
    my $tree = shift;
    given ( $tree->value ) {
        when ('trunk')    { return $tree }
        when ('branches') { return $tree->children }
    }
    return;
}

sub _match_svn_dirs {
    return any { $_ ~~ [qw(trunk branches tags)] } @ARG;
}

sub _children_value {
    return map { $ARG->value } shift->children;
}

# recreate tree every time root is accessed
around root => sub {
    my ( $orig, $self ) = splice @ARG, 0, 2;
    my $root = $self->$orig(@ARG);
    $self->_set_tree( $self->_root_to_tree($root) );
    $self->_set_projects( $self->_build_projects );
    $self->_set_branches( $self->_build_branches );
    return $root;
};

sub _root_to_tree {
    my ( $self, $root ) = @ARG;
    my $tree        = Tree::Path::Class->new(q{/});
    my $entries_ref = $root->dir_entries(q{/});
    while ( my ( $name, $dirent ) = each %{$entries_ref} ) {
        $tree->add_child( $self->_dirent_to_tree( "/$name" => $dirent ) );
    }
    return $tree;
}

sub _dirent_to_tree {
    my ( $self, $entry_name, $dirent ) = @ARG;

    my $name = $dirent->name;
    my $tree = Tree::Path::Class->new();

    given ( $dirent->kind ) {
        ## no critic (Variables::ProhibitPackageVars)
        when ($SVN::Node::file) { $tree->set_value( file($name) ) }
        when ($SVN::Node::dir) {
            $tree->set_value( dir($name) );
            while ( my ( $child_name, $child_dirent )
                = each %{ $self->root->dir_entries($entry_name) } )
            {
                $tree->add_child(
                    $self->_dirent_to_tree(
                        "$entry_name/$child_name" => $child_dirent,
                    ),
                );
            }
        }
    }
    return $tree;
}

__PACKAGE__->meta->make_immutable();
no Moose;
1;

# ABSTRACT: SVN::Fs + Tree::Path::Class

=head1 SYNOPSIS

    use SVN::Tree;
    use SVN::Core;
    use SVN::Repos;
    use SVN::Fs;

    my $repos = SVN::Repos::open('/path/to/repository');
    my $fs = $repos->fs;

    my $tree = SVN::Tree->new(root => $fs->revision_root($fs->youngest_rev));
    print map {$_->path->stringify} $tree->tree->traverse;

=head1 DESCRIPTION

This module marries L<Tree::Path::Class|Tree::Path::Class> to the
L<Perl Subversion bindings|Alien::SVN>, enabling you to traverse the files and
directories of Subversion revisions and transactions, termed
L<roots|SVN::Fs/_p_svn_fs_root> in Subversion API parlance.

=attr root

Required read-only attribute referencing a L<_p_svn_fs_root|SVN::Fs/_p_svn_fs_root> object.

=attr tree

Read-only accessor for the L<Tree::Path::Class|Tree::Path::Class> object
describing the filesystem hierarchy contained in the C<root>.  Will be updated
every time the C<root> attribute is accessed.

=attr projects

Read-only accessor returning an array reference containing one or more
L<Tree::Path::Class|Tree::Path::Class> hierarachies for the top-level project
directories in the repository.  In the case of a repository with F<trunk>,
F<branches> and F<tags> at the top level, this will be one element referring
to the same hierarchy available through the C<tree> attribute.

Like C<tree> this will also be updated with C<root> accesses.

=attr branches

Read-only acccessor returning a hash reference of arrays containing
L<Tree::Path::Class|Tree::Path::Class> objects for each branch in each project
in the repository.  The hash keys are the names of the projects, and F<trunk>
counts as a branch.

Like C<tree> this will also be updated with C<root> accesses.
