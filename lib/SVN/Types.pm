use utf8;
use Modern::Perl;

package SVN::Types;
use strict;

# VERSION
use Try::Tiny;
use SVN::Core;
use SVN::Fs;
use SVN::Repos;
use MooseX::Types -declare => [qw(SvnRoot SvnFs SvnTxn SvnRepos)];
## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)
use MooseX::Types::Path::Class 'Dir';

class_type SvnRoot,  { class => '_p_svn_fs_root_t' };
class_type SvnFs,    { class => '_p_svn_fs_t' };
class_type SvnTxn,   { class => '_p_svn_fs_txn_t' };
class_type SvnRepos, { class => '_p_svn_repos_t' };

coerce SvnRoot,
    from SvnFs,  via { $_->revision_root( $_->youngest_rev ) },
    from SvnTxn, via { $_->root };

coerce SvnFs, from SvnRepos, via { $_->fs };
coerce SvnRepos, from Dir, via {
    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    my $dir = $_;
    my $repos;
    try { $repos = SVN::Repos::open("$dir") }
    catch {
        ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
        $repos = SVN::Repos::create( "$dir", (undef) x 4 );
    };
    return $repos;
};

1;

# ABSTRACT: Moose types for the Subversion Perl bindings

=head1 SYNOPSIS

    use Moose;
    use SVN::Types qw(SvnRoot SvnFs SvnTxn SvnRepos);

    has root => (
        is     => 'ro',
        isa    => SvnRoot,
        coerce => 1,
    );

=head1 DESCRIPTION

This is a L<Moose type library|MooseX::Types> for some of the classes provided
by the L<Subversion Perl bindings|Alien::SVN>.  Some of the types have
sensible coercions available to make it less tedious to move from one class to
another.

=type SvnRoot

Represents a L<_p_svn_fs_root|SVN::Fs/_p_svn_fs_root>, and can coerce from a
C<SvnFs> (retrieving the youngest revision root) or a C<SvnTxn> (retrieving
the transaction root).

=type SvnFs

Represents a L<_p_svn_fs_t|SVN::Fs/_p_svn_fs_t>, and can coerce from a
C<SvnRepos> by retrieving the repository filesystem object.

=type SvnTxn

Represents a L<_p_svn_fs_txn_t|SVN::Fs/_p_svn_txn_t>.

=type SvnRepos

Represents a L<_p_svn_repos_t|SVN::Repos/_p_svn_repos_t>, and can coerce from
a L<Path::Class::Dir|Path::Class::Dir> object by first trying to open, then
create a repository at the specified directory location.
