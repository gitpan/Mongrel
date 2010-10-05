# ABSTRACT: A MongoDB Database Abstraction Layer

package Mongrel;
use strict;
use warnings;
use MongoDB;
use Oogly qw/Oogly/;

BEGIN {
    use Exporter();
    use vars qw( @ISA @EXPORT );
    @ISA    = qw( Exporter );
    @EXPORT = qw(
        table
    );
}

=head1 SYNOPSIS

    package MyDatabase::Users;
    use Mongrel;
    
    sub new {
        return table @_, {
            fields => {
                name     => {},
                email    => {},
                login    => {},
                password => {},
            }
        };
    }
    
    1;
    
    my $db = MyDatabase::Users->new( host => ... );
    $db->input({ name => 'Sum Yung Boi' });
    if ($db->input->validate) {
        $db->insert($db->input->{params});
    }

=head1 IMPORTANT NOTE

Important Note: Your namespace is important, your module name is automatically
converted into the MongoDB database and collection string, e.g.
MyDatabase::Users == mydatabase.users (in mongo speak)
likewise MyDatabase::Users::Locations == mydatabase.users.locations

=head1 DESCRIPTION

This module exists for a single, simple purpose, which is to provide a simple
database abstraction layer for MongoDB. MongoDB, or any other NoSQL database,
relies on the application layer to enforce data integrity, so Mongrel uses the
Oogly data validation framework to provide you with a simple way to create
codebased schemas that have data validation built-in, etc. See L<Oogly> on CPAN
for more details on how to define a more robust schema.

=cut

=method table


=cut

sub table {
    my $spec = pop @_;
    my $strg = lc shift;
    
    my ($name, $collection) = $strg =~ /^(\w+)::(.*)/;
    $collection = join '.', split /::/, $collection;
    
    my $conn = MongoDB::Connection->new(@_);
    my $dbse = $conn->$name;
    my $coll = $dbse->$collection;
    my $data = Oogly(mixins => $spec->{mixins}||{}, fields => $spec->{fields}||{});
    
    *{MongoDB::Collection::input} = sub {
        my $self = shift;
        if (@_) {
            $self->{oogly_input} = $data->setup(@_);
            return $self->{oogly_input};
        }
        else {
            unless (defined $self->{oogly_input}) {
                $self->{oogly_input} = $data->setup(@_);
            }
            return $self->{oogly_input};
        }
        
    };
    
    return $coll;
}

1;