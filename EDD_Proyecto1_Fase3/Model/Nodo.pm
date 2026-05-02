package Nodo;
use strict;
use warnings;

# Este nodo sirve para CUALQUIER tipo de lista:
#   - Lista doble         (siguiente + anterior)
#   - Lista circular      (siguiente del ultimo apunta al primero)
#   - Lista circular doble (siguiente + anterior, circular)

sub new {
    my ($class, $dato) = @_;
    my $self = {
        dato      => $dato,  # cualquier objeto: Medicamento, Proveedor, Solicitud...
        siguiente => undef,
        anterior  => undef,
    };
    bless $self, $class;
    return $self;
}

sub get_dato      { $_[0]->{dato}      }
sub get_siguiente { $_[0]->{siguiente} }
sub get_anterior  { $_[0]->{anterior}  }

sub set_dato      { $_[0]->{dato}      = $_[1] }
sub set_siguiente { $_[0]->{siguiente} = $_[1] }
sub set_anterior  { $_[0]->{anterior}  = $_[1] }

1;
