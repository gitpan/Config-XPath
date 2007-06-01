#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2005-2007 -- leonerd@leonerd.org.uk

package Config::XPath;

use strict;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
   get_service_config

   get_config_string
   get_config_attrs
   get_config_list
   get_config_map

   get_sub_config
   get_sub_config_list

   read_default_config
);

our $VERSION = '0.09';

use XML::XPath;
use XML::XPath::XMLParser;

use Carp;

=head1 NAME

C<Config::XPath> - a module for retrieving configuration data from XML files
by using XPath queries

=head1 DESCRIPTION

This module provides easy access to configuration data stored in an XML file.
Configuration is retrieved using XPath keys; various functions exist to
convert the result to a variety of convenient forms. If the functions are
called as static functions (as opposed to as object methods) then they access
data stored in the default configuration file (details given below).

The functions are also provided as methods of objects in the C<Config::XPath>
class. They take the same parameters as for the static functions. This allows
access to other XML configuration files.

=cut

=head2 Subconfigurations

By default, the XPath context is at the root node of the XML document. If some
other context is required, then a subconfiguration object can be used. This is
a child C<Config::XPath> object, built from an XPath query on the parent.
Whatever node the query matches becomes the context for the new object. The
functions C<get_sub_config()> and C<get_sub_config_list()> perform this task;
the former returning a single child, and the latter returning a list of all
matches.

=cut

my $default_config;

=head2 Default Configuration File

In the case of calling as static functions, the default configuration is
accessed. When the module is loaded no default configuration exists, but one
can be loaded by calling the C<read_default_config()> function. This makes
programs simpler to write in cases where only one configuration file is used
by the program.

=cut

=head1 FUNCTIONS

=cut

=head2 read_default_config( $file )

This function reads the default configuration file, from the location given.
If the file is not found, or an error occurs while reading it, then an
exception of C<Config::XPath::Exception> is thrown.

The default configuration is cached, so multiple calls to this function will
not result in multiple reads of the file; subsequent requests will be silently
ignored, even if a different filename is given.

=over 8

=item $file

The filename of the default configuration to load

=item Throws

C<Config::XPath::Exception>

=back

=cut

sub read_default_config($)
{
   my ( $file ) = @_;

   last if defined $default_config;
   
   $default_config = Config::XPath->new( filename => $file );
}

=head2 $conf = Config::XPath->new( %args )

This function returns a new instance of a C<Config::XPath> object, containing
the configuration in the named XML file. If the given file does not exist, or
an error occured while reading it, an exception C<Config::XPath::Exception>
is thrown.

The C<%args> hash takes the following keys:

=over 8

=item filename => $file

The filename of the XML file to read

=item xml => $xml

A string containing XML data

=back

=head2 $conf = Config::XPath->new( $filename )

This form is now deprecated; please use the C<filename> named argument
instead. This form may be removed in some future version.

=cut

sub new
{
   my $class = shift;

   my %args;

   # Cope with now-deprecated constructor form
   if( @_ == 1 ) {
      carp 'Use of '.__PACKAGE__.'->new( $file ) is deprecated; use ->new( filename => $file ) instead';
      %args = ( filename => $_[0] );
   }
   else {
      %args = @_;
   }

   my $self = bless { 
   }, $class;
   
   if( defined $args{filename} ) {
      $self->{filename} = $args{filename};
      $self->_reload_file;
   }
   elsif( defined $args{xml} ) {
      my $xp = XML::XPath->new( xml => $args{xml} );
      throw Config::XPath::Exception( "Cannot parse string", undef ) unless $xp;
      $self->{xp} = $xp;
   }
   else {
      throw Config::XPath::Exception( "Expected 'filename' or 'xml' argument" );
   }

   return $self;
}

# Internal-only constructor
sub newContext($$)
{
   my $class = shift;
   my ( $parent, $context ) = @_;

   my $self = {
      parent   => $parent,
      context  => $context
   };

   return bless $self, $class;
}

sub find
{
   my $self = shift;
   my ( $path, %args ) = @_;

   my $toplevel = $self;
   $toplevel = $toplevel->{parent} while !exists $toplevel->{xp};

   my $xp = $toplevel->{xp};

   my $context = $args{context} || $self->{context};

   if ( defined $context ) {
      return $xp->find( $path, $context );
   }
   else {
      return $xp->find( $path );
   }
}

sub get_config_nodes
{
   my $self = shift;
   my ( $path ) = @_;

   my $nodeset = $self->find( $path );

   unless( $nodeset->isa( "XML::XPath::NodeSet" ) ) {
      throw Config::XPath::BadConfigException( "Expected result to be a nodeset", $path );
   }

   return $nodeset->get_nodelist;
}

sub get_config_node
{
   my $self = shift;
   my ( $path ) = @_;

   my @nodes = $self->get_config_nodes( $path );

   if ( scalar @nodes == 0 ) {
      throw Config::XPath::ConfigNotFoundException( "No config found", $path );
   }

   if ( scalar @nodes > 1 ) {
      throw Config::XPath::BadConfigException( "Found more than one node", $path );
   }

   return shift @nodes;
}

sub get_node_attrs($)
# Get a hash of the attributes, putting the node name in "+"
{
   my ( $node ) = @_;

   my %attrs = ( '+' => $node->getName() );

   foreach my $attr ( $node->getAttributes() ) {
      $attrs{$attr->getName} = $attr->getValue;
   }

   return \%attrs;
}

sub convert_string
{
   my $self = shift;
   my ( $nodeset, $path, %args ) = @_;

   if( !$nodeset->isa( "XML::XPath::NodeSet" ) ) {
      return $nodeset->string_value();
   }

   my @nodes = $nodeset->get_nodelist;
   if ( scalar @nodes == 0 ) {
      return $args{default} if exists $args{default};

      throw Config::XPath::ConfigNotFoundException( "No config found", $path );
   }

   if ( scalar @nodes > 1 ) {
      throw Config::XPath::BadConfigException( "Found more than one node", $path );
   }

   my $node = $nodes[0];

   if ( $node->isa( "XML::XPath::Node::Element" ) ) {
      my @children = $node->getChildNodes();

      if( !@children ) {
         # No child nodes - treat this as an empty string
         return "";
      }
      elsif ( scalar @children == 1 ) {
         my $child = shift @children;

         if ( ! $child->isa( "XML::XPath::Node::Text" ) ) {
            throw Config::XPath::BadConfigException( "Result is not a plain text value", $path );
         }

         return $child->string_value();
      }
      else {
         throw Config::XPath::BadConfigException( "Found more than one child node", $path );
      }
   }
   elsif( $node->isa( "XML::XPath::Node::Text" ) ) {
      return $node->getValue();
   }
   elsif( $node->isa( "XML::XPath::Node::Attribute" ) ) {
      return $node->getValue();
   }
   else {
      my $t = ref( $node );
      throw Config::XPath::BadConfigException( "Cannot return string representation of node type $t", $path );
   }
}

=head1 METHODS

Each of the following can be called either as a static function, or as a
method of an object returned by the C<new()> constructor, or either of the
C<get_sub_config> functions.

=cut

=head2 $str = get_config_string( $path, %args )

=head2 $str = $config->get_string( $path, %args )

This function retrieves the string value of a single item in the XML file.
This item should either be a text-valued element with no sub-elements, an
attribute, or an XPath expression that returns a string, integer or boolean
value.

If no suitable node was found matching the XPath query but a C<default> key
was passed in the C<%args> hash, then the value of that key is returned
instead.

If no suitable node was found matching the XPath query and no C<default>
argument was passed, then an exception of
C<Config::XPath::ConfigNotFoundException> class is thrown. If more than one
node matched, or the returned node is not either a plain-text content
containing no child nodes, or an attribute, then an exception of class
C<Config::XPath::BadConfigException> class is thrown.

=over 8

=item $path

The XPath to the required configuration node

=item %args

A hash that may contain extra options to control the operation. Supports the
following keys:

=over 4

=item C<default>

If no XML node is found matching the path, return this value rather than
throwing a C<Config::XPath::ConfigNotFoundException>.

=back

=item Throws

C<Config::XPath::ConfigNotFoundException>,
C<Config::XPath::BadConfigException>,
C<Config::XPath::NoDefaultConfigException>

=back

=cut

sub get_config_string($%)
{
   my $self = ( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) ? shift : $default_config;

   throw Config::XPath::NoDefaultConfigException( $_[0] ) unless defined $self;

   $self->get_string( @_ );
}

sub get_string
{
   my $self = shift;
   my ( $path, %args ) = @_;

   my $nodeset = $self->find( $path, context => $args{context} );

   return $self->convert_string( $nodeset, $path, %args );
}

=head2 $attrs = get_config_attrs( $path )

=head2 $attrs = $config->get_attrs( $path )

This function retrieves the attributes of a single element in the XML file.
The attributes are returned in a hash, along with the name of the element
itself, which is returned in a special key named C<'+'>. This name is not
valid for an XML attribute, so this key will never clash with an actual value
from the XML file.

If no suitable node was found matching the XPath query, then an exception of
C<Config::XPath::ConfigNotFoundException> class is thrown. If more than one
node matched, or the returned node is not an element, then an exception of
class C<Config::XPath::BadConfigException> class is thrown.

=over 8

=item C<I<$path>>

The XPath to the required configuration node

=item Throws

C<Config::XPath::ConfigNotFoundException>,
C<Config::XPath::BadConfigException>,
C<Config::XPath::NoDefaultConfigException>

=back

=cut

sub get_config_attrs($)
{
   my $self = ( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) ? shift : $default_config;

   throw Config::XPath::NoDefaultConfigException( $_[0] ) unless defined $self;

   $self->get_attrs( @_ );
}

sub get_attrs
{
   my $self = shift;
   my ( $path ) = @_;

   my $node = $self->get_config_node( $path );

   unless( $node->isa( "XML::XPath::Node::Element" ) ) {
      throw Config::XPath::BadConfigException( "Node is not an element", $path );
   }

   return get_node_attrs( $node );
}

=head2 @values = get_config_list( $path )

=head2 @values = $config->get_list( $path )

This function obtains a list of nodes matching the given XPath query. Unlike
the other functions, it is not an error for no nodes to match. The list
contains one entry for each match of the XPath query, depending on what that
match is. Attribute nodes return their value as a plain string. Element nodes
return a hashref, identical to that which C<get_config_attrs()> returns.

If any other node type is found in the response, then an exception of 
C<Config::XPath::BadConfigException> class is thrown.

=over 8

=item $path

The XPath for the required configuration

=item Throws

C<Config::XPath::BadConfigException>,
C<Config::XPath::NoDefaultConfigException>

=back

=cut

sub get_config_list($)
{
   my $self = ( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) ? shift : $default_config;

   throw Config::XPath::NoDefaultConfigException( $_[0] ) unless defined $self;

   $self->get_list( @_ );
}

sub get_list
{
   my $self = shift;
   my ( $path ) = @_;

   my @nodes = $self->get_config_nodes( $path );

   my @ret;

   foreach my $node ( @nodes ) {
      my $val;
      if ( $node->isa( "XML::XPath::Node::Element" ) ) {
         $val = get_node_attrs( $node );
      }
      elsif ( $node->isa( "XML::XPath::Node::Text" ) ) {
         $val = $node->getValue();
      }
      elsif ( $node->isa( "XML::XPath::Node::Attribute" ) ) {
         $val = $node->getValue();
      }
      else {
         my $t = ref( $node );
         throw Config::XPath::BadConfigException( "Cannot return string representation of node type $t", $path );
      }

      push @ret, $val;
   }

   return @ret;
}

=head2 $map = get_config_map( $listpath, $keypath, $valuepath )

=head2 $map = $config->get_map( $listpath, $keypath, $valuepath )

This function obtains a map, returned as a hash, containing one entry for each
node returned by the C<$listpath> search, where the key and value are given by
the C<$keypath> and C<$valuepath> within each node. It is not an error for no
nodes to match the C<$listpath>.

The result of the C<$listpath> query must be a nodeset. The result of the
C<$keypath> and C<$valuepath> queries for each node in the list must be
convertable to a string, by the same rules as the C<get_string()> method.

=over 8

=item $listpath

The XPath to generate the nodeset

=item $keypath

The XPath within each node to generate the key

=item $valuepath

The XPath within each node to generate the value

=item Throws

C<Config::XPath::ConfigNotFoundException>,
C<Config::XPath::BadConfigException>,
C<Config::XPath::NoDefaultConfigException>

=back

=cut

sub get_config_map($$$)
{
   my $self = ( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) ? shift : $default_config;

   throw Config::XPath::NoDefaultConfigException( $_[0] ) unless defined $self;

   $self->get_map( @_ );
}

sub get_map
{
   my $self = shift;
   my ( $listpath, $keypath, $valuepath ) = @_;

   my @nodes = $self->get_config_nodes( $listpath );

   my %ret;

   foreach my $node ( @nodes ) {
      my $keynode = $self->find( $keypath, context => $node );
      my $key = $self->convert_string( $keynode, $keypath );

      my $valuenode = $self->find( $valuepath, context => $node );
      my $value = $self->convert_string( $valuenode, $valuepath );

      $ret{$key} = $value;
   }

   return \%ret;
}

=head2 $subconfig = get_sub_config( $path )

=head2 $subconfig = $config->get_sub_config( $path )

This function constructs a new C<Config::XPath> object whose context is at
the single node selected by the XPath query. The newly constructed child
object is then returned.

If no suitable node was found matching the XPath query, then an exception of
C<Config::XPath::ConfigNotFoundException> class is thrown. If more than one
node matched, then an exception of class C<Config::XPath::BadConfigException>
is thrown.

=over 8

=item $path

The XPath to the required configuration node

=item Throws

C<Config::XPath::ConfigNotFoundException>,
C<Config::XPath::BadConfigException>,
C<Config::XPath::NoDefaultConfigException>

=back

=cut

sub get_sub_config($)
{
   my $self = ( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) ? shift : $default_config;
   my $class = ref( $self );
   my ( $path ) = @_;

   throw Config::XPath::NoDefaultConfigException( $path ) unless defined $self;

   my $node = $self->get_config_node( $path );

   return $class->newContext( $self, $node );
}

=head2 @subconfigs = get_sub_config_list( $path )

=head2 @subconfigs = $config->get_sub_config_list( $path )

This function constructs a list of new C<Config::XPath> objects whose context
is at each node selected by the XPath query. The array of newly constructed
objects is then returned. Unlike other functions, it is not an error for no
nodes to match.

=over 8

=item $path

The XPath for the required configuration

=item Throws

C<Config::XPath::NoDefaultConfigException>

=back

=cut

sub get_sub_config_list($)
{
   my $self = ( ref( $_[0] ) && $_[0]->isa( __PACKAGE__ ) ) ? shift : $default_config;
   my $class = ref( $self );
   my ( $path ) = @_;

   throw Config::XPath::NoDefaultConfigException( $path ) unless defined $self;

   my @nodes = $self->get_config_nodes( $path );

   my @ret;

   foreach my $node ( @nodes ) {
      push @ret, $class->newContext( $self, $node );
   }

   return @ret;
}

# Private methods
sub _reload_file
{
   my $self = shift;

   # Recurse down to the toplevel object
   return $self->{parent}->reload() if exists $self->{parent};

   my $file = $self->{filename};

   my $xp = XML::XPath->new( filename => $file );

   throw Config::XPath::Exception( "Cannot read config file $file", undef ) unless $xp;

   # If we threw an exception, this line never gets run, so the old {xp} is
   # preserved. If not, then we know that $xp at least contains valid XML data
   # so we store it, replacing the old value.

   $self->{xp} = $xp;
}

# Keep perl happy; keep Britain tidy
1;

# Some exception classes

=head1 EXCEPTIONS

=cut

package Config::XPath::Exception;

use base qw( Error );

=head2 Config::XPath::Exception

This exception is used as a base class for config-related exceptions. It is
derived from C<Error>, and stores the config path involved.

 $e = Config::XPath::Exception->new( $message; $path )

The path is optional, and will only be stored if defined. It can be accessed
using the C<path> method.

 $path = $e->path

=cut

sub new
{
   my $class = shift;
   my ( $message, $path ) = @_;

   local $Error::Depth = $Error::Depth + 1;

   my $self = $class->SUPER::new( -text => $message );
   $self->{path} = $path if( defined $path );

   $self;
}

sub path
{
   my $self = shift;
   return $self->{path};
}

sub stringify
{
   my $self = shift;
   if ( exists $self->{path} ) {
      return $self->SUPER::stringify() . " at path $self->{path}";
   }
   else {
      return $self->SUPER::stringify();
   }
}

1;

package Config::XPath::ConfigNotFoundException;

=head2 Config::XPath::ConfigNotFoundException

This exception indicates that the requested configuration was not found. It is
derived from C<Config::XPath::Exception> and is constructed and accessed in
the same way.

=cut

use base qw( Config::XPath::Exception );
1;

package Config::XPath::BadConfigException;

=head2 Config::XPath::BadConfigException

This exception indicates that configuration found at the requested path was
not of a type suitable for the request made. It is derived from
C<Config::XPath::Exception> and is constructed and accessed in the same way.

=cut

use base qw( Config::XPath::Exception );
1;

package Config::XPath::NoDefaultConfigException;

use base qw( Config::XPath::Exception );

=head2 Config::XPath::NoDefaultConfigException

This exception indicates that no default configuration has yet been loaded 
when one of the accessor functions is called directly. It is derived from
C<Config::XPath::Exception>.

 $e = Config::XPath::NoDefaultConfigException->new( $path )

=cut

sub new
{
   my $class = shift;
   my ( $path ) = @_;

   local $Error::Depth = $Error::Depth + 1;

   $class->SUPER::new( "No default configuration loaded", $path );
}

1;

__END__

=head1 SEE ALSO

=over 4

=item *

L<XML::XPath> - Perl XML module that implements XPath queries

=item *

L<Error> - Base module for exception-based error handling

=back

=head1 AUTHOR

Paul Evans E<lt>leonerd@leonerd.org.ukE<gt>
