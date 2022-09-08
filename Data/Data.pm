package Schema::Data::Data;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use List::Util qw(none);

our $VERSION = 0.03;

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

	if (! defined $self->{'schema_module'}) {
		err "Parameter 'schema_module' is required.";
	}

	# Load schema.
	eval 'require '.$self->{'schema_module'};
	if ($EVAL_ERROR) {
		err 'Cannot load Schema module.',
			'Module name', $self->{'schema_module'},
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
	my %sources = map { ($self->{'_schema'}->source($_)->name => $_ ) }
		$self->{'_schema'}->sources;

	# Explicit order.
	my @order;
	if ($data_hr->{'_order'}) {
		@order = @{$data_hr->{'_order'}};
		foreach my $db_name (keys %sources) {
			if (none { $_ eq $db_name } @order) {
				push @order, $db_name;
			}
		}
	# Random DB names as order.
	} else {
		@order = keys %sources;
	}

	# Insert.
	foreach my $db_name (@order) {

		# Skip db table without data.
		if (! exists $data_hr->{$db_name}) {
			next;
		}

		foreach my $data_hr (@{$data_hr->{$db_name}}) {
			$self->{'_schema'}->resultset($sources{$db_name})->create($data_hr);
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
