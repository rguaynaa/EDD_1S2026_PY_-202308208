package Usuario;
use strict;
use warnings;

# Usuario departamental - almacenado en el Arbol AVL
# Clave de ordenamiento: numero_colegio

sub new {
    my ($class, $args) = @_;
    my $self = {
        numero_colegio  => $args->{numero_colegio}  // '',
        nombre_completo => $args->{nombre_completo} // '',
        tipo_usuario    => $args->{tipo_usuario}    // '',   # TIPO-01 .. TIPO-05
        departamento    => $args->{departamento}    // '',   # DEP-MED, DEP-CIR, etc.
        especialidad    => $args->{especialidad}    // '',
        contrasena      => $args->{contrasena}      // '',
    };
    bless $self, $class;
    return $self;
}

# --- Getters ---
sub get_numero_colegio  { $_[0]->{numero_colegio}  }
sub get_nombre_completo { $_[0]->{nombre_completo} }
sub get_tipo_usuario    { $_[0]->{tipo_usuario}    }
sub get_departamento    { $_[0]->{departamento}    }
sub get_especialidad    { $_[0]->{especialidad}    }
sub get_contrasena      { $_[0]->{contrasena}      }

# --- Setters (solo nombre y contrasena son editables) ---
sub set_nombre_completo { $_[0]->{nombre_completo} = $_[1] }
sub set_contrasena      { $_[0]->{contrasena}      = $_[1] }

# Tabla de permisos: que inventario puede ver cada departamento
my %PERMISOS = (
    'DEP-ADM' => ['MEDICAMENTO', 'EQUIPO', 'SUMINISTRO'],
    'DEP-MED' => ['MEDICAMENTO', 'SUMINISTRO'],
    'DEP-CIR' => ['EQUIPO',      'SUMINISTRO'],
    'DEP-LAB' => ['EQUIPO'],
    'DEP-FAR' => ['MEDICAMENTO'],
);

sub puede_ver {
    my ($self, $tipo) = @_;
    my $permisos = $PERMISOS{ $self->{departamento} } // [];
    return grep { $_ eq $tipo } @$permisos;
}

sub get_permisos {
    my ($self) = @_;
    return $PERMISOS{ $self->{departamento} } // [];
}

sub to_string {
    my ($self) = @_;
    return sprintf("[%s] %s | %s | %s | %s",
        $self->{numero_colegio},
        $self->{nombre_completo},
        $self->{tipo_usuario},
        $self->{departamento},
        $self->{especialidad} || 'N/A'
    );
}

1;
