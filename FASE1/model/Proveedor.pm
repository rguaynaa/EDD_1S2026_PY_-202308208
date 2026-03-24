package Proveedor;
use strict;
use warnings;

sub new {
    my ($class, $args) = @_;

    #definicion de los atributos del proveedor

    my $self = {
        id => $args->{id},
        nombre => $args->{nombre},
        direccion => $args->{direccion},
        telefono => $args->{telefono},
        medicamentos => []
    };

    bless $self, $class;
    return $self;
}

#getters
sub get_id {
    $_[0]->{id}}
sub get_nombre {
    $_[0]->{nombre}}
sub get_lista{
    $_[0]->{medicamentos}}

sub agregar_medicamento{
    my ($self, $codigo) = @_;
    push @{$self->{medicamentos}}, $codigo;
}

1;