package Medicamento;
use strict;
use warnings;

sub new {
    my ($class, $args) = @_;

    #definicion de los atributos del medicamento

    my $self = {
        codigo => $args->{codigo},
        nombre => $args->{nombre},
        principioActivo => $args->{principioActivo},
        laboratorio => $args->{laboratorio},
        cantidad => $args->{cantidad} // 0,
        fechaVencimiento => $args->{fechaVencimiento},
        precio => $args->{precio} // 0,
        nivelMinimo => $args->{nivelMinimo} // 0,
    };

    bless $self, $class;
    return $self;
}

#getters y setters
sub get_codigo {
    $_[0]->{codigo}}
sub get_nombre {
    $_[0]->{nombre}}
sub get_principioActivo {
    $_[0]->{principioActivo}}
sub get_laboratorio {
    $_[0]->{laboratorio}}
sub get_cantidad {
    $_[0]->{cantidad}}
sub get_fechaVencimiento {
    $_[0]->{fechaVencimiento}}
sub get_precio {
    $_[0]->{precio}}
sub get_nivelMinimo {
    $_[0]->{nivelMinimo}}


sub setCantidad{
    my ($self, $cantidad) = @_;
    $self->{cantidad} = $cantidad;
}

sub incrementarCantidad{
    my ($self, $cantidad) = @_;
    $self->{cantidad} += $cantidad;
}

sub disminuirCantidad{
    my ($self, $cantidad) = @_;
    $self->{cantidad} -= $cantidad if $self->{cantidad} >= $cantidad;
}

#reglas

sub bajoStock {
    my ($self) = @_;
    return $self->{cantidad} < $self->{nivelMinimo};
}

1;