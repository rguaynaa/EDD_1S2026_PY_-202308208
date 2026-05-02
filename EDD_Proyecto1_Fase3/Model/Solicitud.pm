package Solicitud;
use strict;
use warnings;

# ============================================================
# Solicitud de Reabastecimiento
# Almacenada en la Lista Circular Doblemente Enlazada
# y registrada en el Arbol de Merkle para trazabilidad
# ============================================================

my $contador_global = 0;

sub new {
    my ($class, $args) = @_;
    $contador_global++;
    my $self = {
        id              => $args->{id}              // "SOL-" . sprintf("%04d", $contador_global),
        departamento    => $args->{departamento}    // '',
        tipo_item       => $args->{tipo_item}       // '',   # MEDICAMENTO/EQUIPO/SUMINISTRO
        codigo          => $args->{codigo}          // '',
        nombre          => $args->{nombre}          // '',
        cantidad        => $args->{cantidad}        // 0,
        motivo          => $args->{motivo}          // '',
        solicitante_col => $args->{solicitante_col} // '',
        timestamp       => $args->{timestamp}       // _ahora(),
        estado          => $args->{estado}          // 'PENDIENTE',  # PENDIENTE/APROBADA/RECHAZADA
    };
    bless $self, $class;
    return $self;
}

sub _ahora {
    my @t = localtime(time);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);
}

# --- Getters ---
sub get_id              { $_[0]->{id}              }
sub get_departamento    { $_[0]->{departamento}    }
sub get_tipo_item       { $_[0]->{tipo_item}       }
sub get_codigo          { $_[0]->{codigo}          }
sub get_nombre          { $_[0]->{nombre}          }
sub get_cantidad        { $_[0]->{cantidad}        }
sub get_motivo          { $_[0]->{motivo}          }
sub get_solicitante_col { $_[0]->{solicitante_col} }
sub get_timestamp       { $_[0]->{timestamp}       }
sub get_estado          { $_[0]->{estado}          }

# --- Setters ---
sub set_estado { $_[0]->{estado} = $_[1] }

# Serializar para Merkle
sub serializar {
    my ($self) = @_;
    return join('|',
        $self->{id}, $self->{departamento}, $self->{tipo_item},
        $self->{codigo}, $self->{cantidad}, $self->{timestamp},
        $self->{solicitante_col}
    );
}

sub to_string {
    my ($self) = @_;
    return sprintf("[%s] Dep: %s | %s | %s - %s | Cant: %d | %s | %s",
        $self->{id}, $self->{departamento}, $self->{tipo_item},
        $self->{codigo}, $self->{nombre}, $self->{cantidad},
        $self->{timestamp}, $self->{estado});
}

1;
