package Proveedor;
use strict;
use warnings;

# Cada proveedor tiene sus datos basicos
# y una lista simple de entregas (cada entrega es un hashref)

sub new {
    my ($class, $args) = @_;
    my $self = {
        nit      => $args->{nit}      // '',
        nombre   => $args->{nombre}   // '',
        contacto => $args->{contacto} // '',
        telefono => $args->{telefono} // '',
        direccion => $args->{direccion} // '',
        entregas => [],   # lista de hashrefs: {fecha, factura, codigo_med, cantidad}
    };
    bless $self, $class;
    return $self;
}

# --- Getters ---
sub get_nit      { $_[0]->{nit}      }
sub get_nombre   { $_[0]->{nombre}   }
sub get_contacto { $_[0]->{contacto} }
sub get_telefono { $_[0]->{telefono} }
sub get_direccion{ $_[0]->{direccion}}
sub get_entregas { $_[0]->{entregas} }

# Agrega una entrega al historial del proveedor
sub agregar_entrega {
    my ($self, $entrega) = @_;
    # $entrega = { fecha, factura, codigo_med, cantidad }
    push @{ $self->{entregas} }, $entrega;
}

sub to_string {
    my ($self) = @_;
    my $n_entregas = scalar @{ $self->{entregas} };
    return sprintf("[NIT: %s] %s | Tel: %s | Entregas: %d",
        $self->{nit}, $self->{nombre}, $self->{telefono}, $n_entregas);
}

1;
