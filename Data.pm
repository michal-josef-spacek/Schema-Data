package Schema::Data;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use Perl6::Slurp qw(slurp);

our $VERSION = 0.06;

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
		err 'Schema data version has bad format.',
			'Schema data version', $self->{'version'},
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

	err "We need to implement distribution file with Schema data versions.";

	return;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

Schema::Data - Abstract class for versioned DB schema datasets.

=head1 SYNOPSIS

 package Schema::Data::Foo;
 use base qw(Schema::Data);

 sub _versions_file {
         return 'versions.txt';
 }

 package main;

 my $obj = Schema::Data::Foo->new;
 my @versions = $obj->list_versions;
 my $schema_data = $obj->schema_data;
 my $version = $obj->version;

=head1 DESCRIPTION

This is abstract class for versioned schema dataset modules.

=head1 METHODS

=head2 C<new>

 my $obj = Schema::Data->new(%params);

Constructor.

Returns instance of object.

=over 8

=item * C<version>

Selected schema data version.

Default value is last version.

=back

=head2 C<list_versions>

 my @versions = $obj->list_versions;

Get sorted list of versions.

Returns array of versions.

=head2 C<schema_data>

 my $schema_data = $obj->schema_data;

Get schema data module name.

Returns string.

=head2 C<version>

 my $version = $obj->version;

Get version of schema data, which is actial set.

Returns string.

=head1 ERRORS

 new():
         Cannot load Schema data module.
                 Module name: %s
                 Error: %s
         Schema data version has bad format.
                 Schema data version: %s
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

         (only in this abstract class)
         We need to implement distribution file with Schema data versions.

=head1 EXAMPLE

=for comment filename=list_data_versions.pl

 use strict;
 use warnings;

 use File::Path qw(make_path);
 use File::Spec::Functions qw(catfile);
 use File::Temp qw(tempdir tempfile);
 use IO::Barf qw(barf);

 # Temp directory for generated module
 my $temp_dir = tempdir(CLEANUP => 1);

 # File with versions.
 my (undef, $versions_file) = tempfile();

 make_path(catfile($temp_dir, 'Schema', 'Data', 'Foo'));

 my $package_schema_foo = catfile($temp_dir, 'Schema', 'Data', 'Foo.pm');
 barf($package_schema_foo, <<"END");
 package Schema::Data::Foo;

 use base qw(Schema::Data);

 use IO::Barf qw(barf);

 sub _versions_file {
         barf('$versions_file', "0.2.0\\n0.1.0\\n0.1.1");

         return '$versions_file';
 }

 1;
 END
 
 my $package_schema_foo_0_1_0 = catfile($temp_dir, 'Schema', 'Data', 'Foo', '0_1_0.pm');
 barf($package_schema_foo_0_1_0, <<'END');
 package Schema::Data::Foo::0_1_0;

 1;
 END

 my $package_schema_foo_0_1_1 = catfile($temp_dir, 'Schema', 'Data', 'Foo', '0_1_1.pm');
 barf($package_schema_foo_0_1_1, <<'END');
 package Schema::Data::Foo::0_1_1;

 1;
 END

 my $package_schema_foo_0_2_0 = catfile($temp_dir, 'Schema', 'Data', 'Foo', '0_2_0.pm');
 barf($package_schema_foo_0_2_0, <<'END');
 package Schema::Data::Foo::0_2_0;

 1;
 END

 unshift @INC, $temp_dir;

 require Schema::Data::Foo;

 my $obj = Schema::Data::Foo->new;

 my @versions = $obj->list_versions;

 print join "\n", @versions;

 unlink $versions_file;

 # Output:
 # 0.1.0
 # 0.1.1
 # 0.2.0

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Perl6::Slurp>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Schema-Data>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
