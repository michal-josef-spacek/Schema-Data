package Schema::Data;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use Perl6::Slurp qw(slurp);

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Version.
	$self->{'version'} = undef;

	# Process parameters.
	set_params($self, @params);

	# Load file with versions.
	$self->{'_versions_file'} = $self->_versions_file;
	my @versions = slurp($self->{'_versions_file'}, {'chomp' => 1});
	$self->{'_versions'} = \@versions;

	# Set version to last if isn't defined.
	if (! defined $self->{'version'}) {
		$self->{'version'} = $self->{'_versions'}->[-1];
	}

	if ($self->{'version'} !~ /^([0-9]+)\.([0-9]+)\.([0-9]+)$/) {
		err 'Schema version has bad format.',
			'Schema version', $self->{'version'},
		;
	}

	# Load schema.
	$self->{'_schema_data_module'} = $class.'::'."$1\_$2\_$3";
	eval 'require '.$self->{'_schema_data_module'};
	if ($EVAL_ERROR) {
		err 'Cannot load Schema data module.',
			'Module name', $self->{'_schema_data_module'},
			'Error', $EVAL_ERROR,
		;
	}

	return $self;
}

sub list_versions {
	my $self = shift;

	return sort @{$self->{'_versions'}};
}

sub schema_data {
	my $self = shift;

	return $self->{'_schema_data_module'};
}

sub version {
	my $self = shift;

	return $self->{'version'};
}

sub _versions_file {
	my $self = shift;

	err "We need to implement distribution file with Schema versions.";

	return;
}

1;


__END__
