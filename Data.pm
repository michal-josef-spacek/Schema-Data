package Schema::Data;

use strict;
use warnings;

use English;
use Error::Pure qw(err);

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# db user password.
	$self->{'db_password'} = undef;

	# db user name.
	$self->{'db_user'} = undef;

	# db options.
	$self->{'db_options'} = {};

	# DSN.
	$self->{'dsn'} = undef;

	# Schema module.
	$self->{'schema_module'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'dsn'}) {
		err "Parameter 'dsn' is required.";
	}

	eval "require $self->{'_schema_module'}";
	if ($EVAL_ERROR) {
		err 'Cannot load Schema module.',
			'Module name', $self->{'_schema_module'},
			'Error', $EVAL_ERROR,
		;
	}
	$self->{'_schema'} = eval {
		$self->{'schema_module'}->connect(
			$self->{'dsn'},
			$self->{'user'},
			$self->{'password'},
			$self->{'db_options'},
		);
	};
	if ($EVAL_ERROR) {
		err 'Cannot connect to Schema database.',
			'Error', $EVAL_ERROR,
		;
	}
	if (! $self->{'_schema'}->isa('DBIx::Class::Schema')) {
		err "Instance of schema must be a 'DBIx::Class::Schema' object.",
			'Reference', $self->{'_schema'}->isa,
		;
	}

	return $self;
}

sub insert {
	my $self = shift;

	my $data_hr = $self->data;
	foreach my $source ($self->{'_schema'}->sources) {
		my $rs = $self->{'_schema'}->source($source);

		# Skip source table without data.
		if (! exists $data_hr->{$rs->name}) {
			next;
		}

		# Insert.
		foreach my $data_hr (@{$data_hr->{$rs->name}}) {
			$self->{'_schema'}->resultset($source)->create($data_hr);
		}
	}

	return;
}

sub data {
	err 'Package __PACKAGE__ is abstract class. data() method must be '.
		'defined in inherited class.';
}

1;


__END__
