package ListaProveedores;
use strict;
use warnings;
use NodoProveedor;

sub new {
    my ($class) = @_;
    my $self = {
        primero => undef
    };
    bless $self, $class;
    return $self;
}

sub agregar {
    my ($self, $proveedor) = @_;
    my $nuevo = NodoProveedor->new($proveedor);

    if (!$self->{primero}) {
        $nuevo->set_siguiente($nuevo);
        $self->{primero} = $nuevo;
    } else {
        my $actual = $self->{primero};
        while ($actual->get_siguiente() != $self->{primero}) {
            $actual = $actual->get_siguiente();
        }
        $actual->set_siguiente($nuevo);
        $nuevo->set_siguiente($self->{primero});
    }
}

sub obtener_primero {
    return $_[0]->{primero};
}

1;