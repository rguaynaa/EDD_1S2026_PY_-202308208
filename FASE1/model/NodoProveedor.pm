package NodoProveedor;
use strict;
use warnings;

sub new {
    my ($class, $proveedor) = @_;

    my $self = {
        dato      => $proveedor,
        siguiente => undef
    };

    bless $self, $class;
    return $self;
}

sub get_dato      { $_[0]->{dato} }
sub get_siguiente { $_[0]->{siguiente} }
sub set_siguiente { $_[0]->{siguiente} = $_[1] }

1;