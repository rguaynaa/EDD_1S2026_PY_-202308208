package ListaSolicitudes;
use strict;
use warnings;

# ============================================================
# Lista Circular Doblemente Enlazada de Solicitudes
# Usada para la cola de solicitudes de reabastecimiento
# El administrador aprueba/rechaza desde el frente
# ============================================================

package NodoSol;
use strict;
use warnings;

sub new {
    my ($class, $dato) = @_;
    return bless {
        dato      => $dato,
        siguiente => undef,
        anterior  => undef,
    }, $class;
}
sub get_dato      { $_[0]->{dato}      }
sub get_siguiente { $_[0]->{siguiente} }
sub get_anterior  { $_[0]->{anterior}  }
sub set_siguiente { $_[0]->{siguiente} = $_[1] }
sub set_anterior  { $_[0]->{anterior}  = $_[1] }

# ============================================================
package ListaSolicitudes;
use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless { primero => undef, tamanio => 0 }, $class;
}

sub get_tamanio { $_[0]->{tamanio} }
sub esta_vacia  { !defined $_[0]->{primero} }

# ---------------------------------------------------------------
# AGREGAR solicitud al final
# ---------------------------------------------------------------
sub agregar {
    my ($self, $solicitud) = @_;
    my $nuevo = NodoSol->new($solicitud);

    if ($self->esta_vacia()) {
        $nuevo->set_siguiente($nuevo);
        $nuevo->set_anterior($nuevo);
        $self->{primero} = $nuevo;
    } else {
        my $ultimo = $self->{primero}->get_anterior();
        $ultimo->set_siguiente($nuevo);
        $nuevo->set_anterior($ultimo);
        $nuevo->set_siguiente($self->{primero});
        $self->{primero}->set_anterior($nuevo);
    }
    $self->{tamanio}++;
    return 1;
}

# ---------------------------------------------------------------
# VER primera solicitud (sin eliminar)
# ---------------------------------------------------------------
sub primera {
    my ($self) = @_;
    return undef if $self->esta_vacia();
    return $self->{primero}->get_dato();
}

# ---------------------------------------------------------------
# ELIMINAR primera solicitud (aprobada/rechazada)
# ---------------------------------------------------------------
sub eliminar_primera {
    my ($self) = @_;
    return 0 if $self->esta_vacia();

    if ($self->{tamanio} == 1) {
        $self->{primero} = undef;
    } else {
        my $ultimo = $self->{primero}->get_anterior();
        my $nuevo_primero = $self->{primero}->get_siguiente();
        $ultimo->set_siguiente($nuevo_primero);
        $nuevo_primero->set_anterior($ultimo);
        $self->{primero} = $nuevo_primero;
    }
    $self->{tamanio}--;
    return 1;
}

# ---------------------------------------------------------------
# BUSCAR solicitud por ID
# ---------------------------------------------------------------
sub buscar_por_id {
    my ($self, $id) = @_;
    return undef if $self->esta_vacia();

    my $actual = $self->{primero};
    do {
        return $actual->get_dato() if $actual->get_dato()->get_id() eq $id;
        $actual = $actual->get_siguiente();
    } while ($actual != $self->{primero});

    return undef;
}

# ---------------------------------------------------------------
# LISTAR todas las solicitudes
# ---------------------------------------------------------------
sub todas {
    my ($self) = @_;
    return () if $self->esta_vacia();

    my @lista;
    my $actual = $self->{primero};
    do {
        push @lista, $actual->get_dato();
        $actual = $actual->get_siguiente();
    } while ($actual != $self->{primero});

    return @lista;
}

# Solicitudes por departamento
sub por_departamento {
    my ($self, $dep) = @_;
    return grep { $_->get_departamento() eq $dep } $self->todas();
}

1;
