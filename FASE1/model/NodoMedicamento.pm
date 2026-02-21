package NodoMedicamento;
use strict;
use warnings;

sub new {

    #Atributos del nodo de la lista doblemente enlazada para el medicamento
    my($class, $medicamento) = @_;

    my $self = {
       dato => $medicamento, #indice para el medicamento
       anterior => undef,
         siguiente => undef,
    };
    bless $self, $class;
    return $self;





}

#getters y setters
sub get_dato {
    $_[0]->{dato}}
sub get_anterior {
    $_[0]->{anterior}}
sub get_siguiente {
    $_[0]->{siguiente}}


sub set_anterior{
    $_[0]->{anterior} = $_[1];
}
sub set_siguiente{
    $_[0]->{siguiente} = $_[1];
}

1;
