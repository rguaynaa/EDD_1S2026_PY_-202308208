package Suministro;
use strict;
use warnings;

# Suministro medico - almacenado en el Arbol B Orden 4
# Clave de ordenamiento: codigo (prefijo SUM)

sub new {
    my ($class, $args) = @_;
    my $self = {
        codigo            => $args->{codigo}            // '',
        nombre            => $args->{nombre}            // '',
        fabricante        => $args->{fabricante}        // '',
        precio            => $args->{precio}            // 0,
        cantidad          => $args->{cantidad}          // 0,
        fecha_vencimiento => $args->{fecha_vencimiento} // '',
        nivel_minimo      => $args->{nivel_minimo}      // 0,
    };
    bless $self, $class;
    return $self;
}

# --- Getters ---
sub get_codigo            { $_[0]->{codigo}            }
sub get_nombre            { $_[0]->{nombre}            }
sub get_fabricante        { $_[0]->{fabricante}        }
sub get_precio            { $_[0]->{precio}            }
sub get_cantidad          { $_[0]->{cantidad}          }
sub get_fecha_vencimiento { $_[0]->{fecha_vencimiento} }
sub get_nivel_minimo      { $_[0]->{nivel_minimo}      }

# --- Setters ---
sub set_cantidad { $_[0]->{cantidad} = $_[1] }

sub bajo_stock {
    my ($self) = @_;
    return $self->{cantidad} < $self->{nivel_minimo};
}

sub to_string {
    my ($self) = @_;
    my $alerta = $self->bajo_stock() ? " *** BAJO STOCK ***" : "";
    return sprintf("[%s] %s | Fab: %s | Cant: %d | Q%.2f | Vence: %s | Min: %d%s",
        $self->{codigo}, $self->{nombre}, $self->{fabricante},
        $self->{cantidad}, $self->{precio},
        $self->{fecha_vencimiento}, $self->{nivel_minimo}, $alerta);
}

1;
