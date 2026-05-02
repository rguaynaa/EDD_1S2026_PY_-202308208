package Equipo;
use strict;
use warnings;

# Equipo medico - almacenado en el Arbol BST
# Clave de ordenamiento: codigo (prefijo EQU)

sub new {
    my ($class, $args) = @_;
    my $self = {
        codigo        => $args->{codigo}        // '',
        nombre        => $args->{nombre}        // '',
        fabricante    => $args->{fabricante}    // '',
        precio        => $args->{precio}        // 0,
        cantidad      => $args->{cantidad}      // 0,
        fecha_ingreso => $args->{fecha_ingreso} // '',
        nivel_minimo  => $args->{nivel_minimo}  // 0,
    };
    bless $self, $class;
    return $self;
}

# --- Getters ---
sub get_codigo        { $_[0]->{codigo}        }
sub get_nombre        { $_[0]->{nombre}        }
sub get_fabricante    { $_[0]->{fabricante}    }
sub get_precio        { $_[0]->{precio}        }
sub get_cantidad      { $_[0]->{cantidad}      }
sub get_fecha_ingreso { $_[0]->{fecha_ingreso} }
sub get_nivel_minimo  { $_[0]->{nivel_minimo}  }

# --- Setters ---
sub set_cantidad { $_[0]->{cantidad} = $_[1] }

sub bajo_stock {
    my ($self) = @_;
    return $self->{cantidad} < $self->{nivel_minimo};
}

sub to_string {
    my ($self) = @_;
    my $alerta = $self->bajo_stock() ? " *** BAJO STOCK ***" : "";
    return sprintf("[%s] %s | Fab: %s | Cant: %d | Q%.2f | Ingreso: %s | Min: %d%s",
        $self->{codigo}, $self->{nombre}, $self->{fabricante},
        $self->{cantidad}, $self->{precio},
        $self->{fecha_ingreso}, $self->{nivel_minimo}, $alerta);
}

1;
