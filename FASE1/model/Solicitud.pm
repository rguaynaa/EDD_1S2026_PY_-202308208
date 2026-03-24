package Solicitud;
use strict;
use warnings;

sub new {
    my ($class, $args) = @_;

    #definicion de los atributos de la solicitud

    my $self = {
        id => $args->{id},
        departamento => $args->{departamento},
        codigoMed => $args->{codigoMed},
        cantidad => $args->{cantidad},
        prioridad => $args->{prioridad},
        fecha=> $args->{fecha},
        estado => 'pendiente',
    };


    bless $self, $class;
    return $self;
}

#getters
sub get_id {
    $_[0]->{id}}
sub get_departamento {
    $_[0]->{departamento}}
sub get_codigoMed {
    $_[0]->{codigoMed}}
sub get_cantidad {
    $_[0]->{cantidad}}
sub get_prioridad {
    $_[0]->{prioridad}}
sub get_fecha {
    $_[0]->{fecha}}
sub get_estado {
    $_[0]->{estado}}

sub aprobar{ $_[0]->{estado} = 'aprobada'}
sub rechazar{ $_[0]->{estado} = 'rechazada'}

1;
