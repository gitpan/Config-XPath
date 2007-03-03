#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006 -- leonerd@leonerd.org.uk

package Config::XPath::Reloadable;

use strict;
use base qw( Config::XPath );

our $VERSION = '0.07';

=head1 NAME

C<Config::XPath::Reloadable> - a subclass of C<Config::XPath> that supports
reloading

=head1 DESCRIPTION

This subclass of C<Config::XPath> supports reloading the underlying XML file
and updating the containing program's data structures. This is achieved by
taking control of the lifetimes of the program's data structures that use it.

Where a simple C<name=value> config file could be reloaded just by reapplying
string values, a whole range of new problems occur with the richer layout
afforded to XML-based files. New nodes can appear, old nodes can move, change
their data, or disappear. All these changes may involve data structure changes
within the containing program. To cope with these types of events, callbacks
in the form of closures can be registered that are called when various changes
happen to the underlying XML data.

As with the non-reloadable parent class, configuration is generally processed
by forming a tree of objects which somehow maps onto the XML data tree. The
way this is done in this class, is to use the $node parameter passed in to the
C<add> and C<keep> event callbacks. This parameter will hold a child
C<Config::XPath::Reloadable> object with its XPath context pointing at the
corresponding node in the XML data, much like the C<get_sub_config()> method
does.

Because of the dynamically-reloadable nature of objects in this class, the
C<get_sub_config()> and C<get_sub_config_list()> methods are no longer
allowed. They will instead throw exceptions of C<Config::XPath::Exception>
type. The event callbacks should be used instead, to obtain subconfigurations.

=cut

=head1 CONSTRUCTOR

=cut

=head2 $conf = Config::XPath::Reloadable->new( %args )

This function returns a new instance of a C<Config::XPath::Reloadable> object,
initially containing the configuration in the named XML file. The file is
closed by the time this method returns, so any changes of the file itself will
not be noticed until the C<reload> method is called.

The C<%args> hash takes the following keys

=over 8

=item filename => $file

The filename of the XML file to read

=back

=head2 $conf = Config::XPath->new( $filename )

This form is now deprecated; please use the C<filename> named argument
instead. This form may be removed in some future version.

=cut

sub new
{
   my $class = shift;
   my $self = $class->SUPER::new( @_ );

   $self->{nodelists} = [];

   $self;
}

=head1 METHODS

=cut

=head2 $conf->reload()

This method requests that the configuration object reloads the configuration
data that constructed it.

If called on the root object, the XML file that was named in the constructor
is reopened and reparsed. The file is re-opened by name, rather than by
rereading the filehandle that was opened in the constructor. (This distinction
is only of significance for systems that allow open files to be renamed). If
called on a child object, the stored XPath data tree is updated from the
parent.

In either case, after the data is reloaded, each nodelist stored by the object
is reevlauated, by requerying the XML nodeset using the stored XPaths, and the
event callbacks being invoked as appropriate.

=cut

sub reload
{
   my $self = shift;
   if( exists $self->{filename} ) {
      $self->_reload_file;
   }
   else {
      $self->{xp} = $self->{parent}->{xp};
      $self->{context} = $self->get_config_node( $self->{path} );
   }

   $self->_run_nodelist( $_ ) foreach @{ $self->{nodelists} };
}

# Override - no POD
sub get_sub_config
{
   throw Config::XPath::Exception( "Can't generate subconfig of a " . __PACKAGE__ );
}

# Override - no POD
sub get_sub_config_list
{
   throw Config::XPath::Exception( "Can't generate subconfig list of a " . __PACKAGE__ );
}

=head2 $conf->associate_nodeset( $listpath, $namepath, %events )

This function associates callback closures with events that happen to a given
nodeset in the XML data. When the function is first called, and every time the
C<< $conf->reload() >> method is called, the nodeset given by the XPath string
$listpath is obtained. For each node in the set, the value given by $namepath
is obtained, by using the get_string() method (so it must be a plain text node
or attribute value). The name for each node is then used to determine whether
the nodes have been added, or kept since the last time. The C<add> or C<keep>
callback is then called as appropriate on each node, in the order they appear
in the current XML data.

Finally, the list of nodes that were present last time which no longer exist
is determined, and the C<remove> callback called for those, in no particular
order.

The signature for each callback is as follows:

 $add->( $name, $node )

 $keep->( $name, $node )

 $remove->( $name )

The $name parameter will contain the string value returned by the $namepath
path on each node, and the $node parameter will contain a
C<Config::XPath::Reloadable> object reference, with the XPath context at the
respective XML data node.

=cut

sub associate_nodeset
{
   my $self = shift;
   my ( $listpath, $namepath, %events ) = @_;

   my %nodelistitem = (
      listpath => $listpath,
      namepath => $namepath,
   );

   foreach (qw( add keep remove )) {
      $nodelistitem{$_} = $events{$_} if exists $events{$_};
   }

   push @{ $self->{nodelists} }, \%nodelistitem;

   $self->_run_nodelist( \%nodelistitem );
}

sub _run_nodelist
{
   my $self = shift;
   my ( $nodelist ) = @_;

   my $class = ref( $self );

   my %lastitems;
   %lastitems = %{ $nodelist->{items} } if defined $nodelist->{items};

   my %newitems;

   my $listpath = $nodelist->{listpath};
   my $namepath = $nodelist->{namepath};

   my @nodes = $self->get_config_nodes( $listpath );

   foreach my $n ( @nodes ) {
      my $name = $self->get_string( $namepath, context => $n );

      my $item;

      if( exists $lastitems{$name} ) {
         $item = delete $lastitems{$name};

         $item->{context} = $n;

         $nodelist->{keep}->( $name, $item ) if defined $nodelist->{keep};
      }
      else {
         $item = $class->newContext( $self, $n );

         # Escape quote marks and backslashes
         ( my $quotedname = $name ) =~ s{(['\\])}{\\$1}g;
         $item->{path} = $listpath . "[$namepath='$quotedname']";

         $nodelist->{add}->( $name, $item ) if defined $nodelist->{add};
      }

      $newitems{$name} = $item;
   }

   foreach my $name ( keys %lastitems ) {
      $nodelist->{remove}->( $name ) if defined $nodelist->{remove};
   }

   $nodelist->{items} = \%newitems;
}

1;

__END__

=head1 SEE ALSO

=over 4

=item *

C<XML::XPath> - Perl XML module that implements XPath queries

=item *

C<Error> - Base module for exception-based error handling

=head1 AUTHOR

Paul Evans E<lt>leonerd@leonerd.org.ukE<gt>

=back
