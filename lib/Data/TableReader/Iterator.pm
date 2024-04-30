package Data::TableReader::Iterator;
use strict;
use warnings;
use Try::Tiny;
use Carp;
use Scalar::Util 'refaddr';

# ABSTRACT: Base class for iterators (blessed coderefs)
# VERSION

=head1 SYNOPSIS

  my $iter= $record_reader->iterator;
  while (my $rec= $iter->()) {
    ...
    my $position= $iter->tell;
    print "Marking position $position"; # position stringifies to human-readable
    ...
    $iter->seek($position);
  }
  if ($iter->next_dataset) {
    # iterate some more
    while ($rec= $iter->()) {
      ...
      printf "Have processed %3d %% of the file", $iter->progress*100;
    }
  }

=head1 DESCRIPTION

This is the abstract base class for iterators used in Data::TableReader,
which are blessed coderefs that return records on each call.

The coderef should support a single argument of a "slice" to extract from the record, in case
not all of the record is needed.

=head1 ATTRIBUTES

=head2 position

Return a human-readable string describing the current location within the source file.
This will be something like C<"$filename row $row"> or C<"$filename $worksheet:$cell_id">.

=head2 row

A numeric 1-based row number for the current position of the current dataset.  This is not
affected by which row the header was found on.

=head2 dataset_idx

A numeric 0-based dataset number.  For Decoders which only support a single dataset, this is
always C<0>.

=head2 progress

An estimate of how much of the data has already been returned.  If the stream
is not seekable this may return undef.

=head1 METHODS

=head2 new

  $iter= Data::TableReader::Iterator->new( \&coderef, \%fields );

The iterator is a blessed coderef.  The first argument is the coderef to be blessed,
and the second argument is the magic hashref of fields to be made available as
C<< $iter->_fields >>.

=head2 tell

If seeking is supported, this will return some value that can be passed to
seek to come back to this point in the stream.  This value will always be
true. If seeking is not supported this will return undef.

=head2 seek

  $iter->seek($pos);

Seek to a point previously reported by L</tell>.  If seeking is not supported
this will die.  If C<$pos> is any false value it means to seek to the start of
the stream.

=head2 next_dataset

If a file format supports more than one tabular group of data, this method allows you to jump
to the next.  Returns true if it moved to a new dataset, and false at the end of iteration.

=cut

our %_iterator_fields;
sub new {
	my ($class, $sub, $fields)= @_;
	ref $sub eq 'CODE' and ref $fields eq 'HASH'
		or croak "Expected new(CODEREF, HASHREF)";
	$_iterator_fields{refaddr $sub}= $fields;
	return bless $sub, $class;
}

sub _fields {
	$_iterator_fields{refaddr shift};
}

sub DESTROY {
	delete $_iterator_fields{refaddr shift};
}

sub progress {
	undef;
}

sub row {
	croak "Unimplemented";
}

sub dataset_idx {
	0
}

sub tell {
	undef;
}

sub seek {
	croak "Unimplemented";
}

sub next_dataset {
	undef;
}

1;
