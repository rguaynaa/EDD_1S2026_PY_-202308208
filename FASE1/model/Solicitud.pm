package Solicitud;
use strict;
use warnings;

my $contador = 1;  # auto-incremento para numero de solicitud

sub new {
    my ($class, $args) = @_;
    my $self = {
        numero      => $contador++,
        departamento => $args->{departamento} // '',
        codigo_med  => $args->{codigo_med}   // '',
        cantidad    => $args->{cantidad}     // 0,
        prioridad   => $args->{prioridad}    // 'media',  # urgente/alta/media/baja
        justificacion => $args->{justificacion} // '',
        fecha       => $args->{fecha}        // _fecha_hoy(),
        estado      => 'pendiente',   # pendiente / aprobada / rechazada
    };
    bless $self, $class;
    return $self;
}

# --- Getters ---
sub get_numero       { $_[0]->{numero}       }
sub get_departamento { $_[0]->{departamento} }
sub get_codigo_med   { $_[0]->{codigo_med}   }
sub get_cantidad     { $_[0]->{cantidad}     }
sub get_prioridad    { $_[0]->{prioridad}    }
sub get_fecha        { $_[0]->{fecha}        }
sub get_estado       { $_[0]->{estado}       }

sub set_estado { $_[0]->{estado} = $_[1] }

sub to_string {
    my ($self) = @_;
    return sprintf(
        "Solicitud #%d | Depto: %s | Med: %s | Cant: %d | Prior: %s | Estado: %s | Fecha: %s",
        $self->{numero}, $self->{departamento}, $self->{codigo_med},
        $self->{cantidad}, $self->{prioridad}, $self->{estado}, $self->{fecha}
    );
}

sub _fecha_hoy {
    my @t = localtime(time);
    return sprintf("%04d-%02d-%02d", $t[5]+1900, $t[4]+1, $t[3]);
}

1;
