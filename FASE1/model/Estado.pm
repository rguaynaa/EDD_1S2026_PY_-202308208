package Estado;
use strict;
use warnings;

use ListaDoble;
use ListaCircularDoble;
use ListaCircular;
use MatrizDispersa;

# ---------------------------------------------------------------
# SINGLETON: una sola instancia compartida por todos
# ---------------------------------------------------------------
my $instancia;

sub get_instancia {
    my ($class) = @_;
    unless (defined $instancia) {
        $instancia = bless {
            inventario  => ListaDoble->new(),         # medicamentos
            solicitudes => ListaCircularDoble->new(),  # solicitudes de reabastecimiento
            proveedores => ListaCircular->new(),       # proveedores con historial
            matriz      => MatrizDispersa->new(),      # laboratorio x medicamento

            # Usuario departamental logueado actualmente
            usuario_actual => undef,   # hashref: { departamento, contrasena }

            # Historial de solicitudes por departamento (para que el usuario las vea)
            # { departamento => [ lista de Solicitudes ] }
            historial_solicitudes => {},
        }, $class;
    }
    return $instancia;
}

# Accesores rapidos
sub inventario  { $_[0]->{inventario}  }
sub solicitudes { $_[0]->{solicitudes} }
sub proveedores { $_[0]->{proveedores} }
sub matriz      { $_[0]->{matriz}      }

sub get_usuario_actual { $_[0]->{usuario_actual} }
sub set_usuario_actual { $_[0]->{usuario_actual} = $_[1] }

# Guardar solicitud en el historial del departamento
sub agregar_historial {
    my ($self, $solicitud) = @_;
    my $dep = $solicitud->get_departamento();
    push @{ $self->{historial_solicitudes}{$dep} }, $solicitud;
}

# Obtener historial de un departamento
sub get_historial {
    my ($self, $dep) = @_;
    return $self->{historial_solicitudes}{$dep} // [];
}

1;
