package Medicamento;
use strict;
use warnings;

sub new {
    my ($class, $args) = @_;
    my $self = {
        codigo           => $args->{codigo}           // '',
        nombre           => $args->{nombre}           // '',
        principioActivo  => $args->{principioActivo}  // '',
        laboratorio      => $args->{laboratorio}      // '',
        cantidad         => $args->{cantidad}         // 0,
        fechaVencimiento => $args->{fechaVencimiento} // '',
        precio           => $args->{precio}           // 0,
        nivelMinimo      => $args->{nivelMinimo}      // 0,
    };
    bless $self, $class;
    return $self;
}

# --- Getters ---
sub get_codigo           { $_[0]->{codigo}           }
sub get_nombre           { $_[0]->{nombre}           }
sub get_principioActivo  { $_[0]->{principioActivo}  }
sub get_laboratorio      { $_[0]->{laboratorio}      }
sub get_cantidad         { $_[0]->{cantidad}         }
sub get_fechaVencimiento { $_[0]->{fechaVencimiento} }
sub get_precio           { $_[0]->{precio}           }
sub get_nivelMinimo      { $_[0]->{nivelMinimo}      }

# --- Setters ---
sub set_cantidad { $_[0]->{cantidad} = $_[1] }

# --- Reglas de negocio ---

# UN SOLO nombre: bajo_stock (antes habia bajoStock y bajo_stock mezclados)
sub bajo_stock {
    my ($self) = @_;
    return $self->{cantidad} < $self->{nivelMinimo};
}

# Util para reportes y consola
sub to_string {
    my ($self) = @_;
    my $alerta = $self->bajo_stock() ? " *** BAJO STOCK ***" : "";
    return sprintf(
        "[%s] %s | PA: %s | Lab: %s | Cant: %d | Vence: %s | Q%.2f | Min: %d%s",
        $self->{codigo},
        $self->{nombre},
        $self->{principioActivo},
        $self->{laboratorio},
        $self->{cantidad},
        $self->{fechaVencimiento},
        $self->{precio},
        $self->{nivelMinimo},
        $alerta
    );
}

1;
