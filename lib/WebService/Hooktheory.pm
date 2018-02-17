package WebService::Hooktheory;

# ABSTRACT: Access to the Hooktheory API

our $VERSION = '0.0202';

use Moo;
use strictures 2;
use namespace::clean;

use Carp;
use Mojo::UserAgent;
use Mojo::JSON::MaybeXS;
use Mojo::JSON qw( decode_json );

=head1 SYNOPSIS

  use WebService::Hooktheory;
  my $w = WebService::Hooktheory->new( username => 'foo', password => 'bar' );
  # Or:
  $w = WebService::Hooktheory->new( activkey => '1234567890abcdefghij' );
  my $r = $w->fetch( endpoint => 'trends/nodes', query => { cp => '4,1' } );
  print Dumper $r;

=head1 DESCRIPTION

C<WebService::Hooktheory> provides access to the L<https://www.hooktheory.com> API.

=head1 ATTRIBUTES

=head2 username

=cut

has username => (
    is => 'ro',
);

=head2 password

=cut

has password => (
    is => 'ro',
);

=head2 activkey

Your authorized access key.

=cut

has activkey => (
    is => 'ro',
);

=head2 base

The base URL.  Default: https://api.hooktheory.com/v1/

=cut

has base => (
    is      => 'ro',
    default => sub { 'https://api.hooktheory.com/v1/' },
);

=head1 METHODS

=head2 new()

  $w = WebService::Hooktheory->new(%arguments);

Create a new C<WebService::Hooktheory> object.

=head2 BUILD()

Authenticate and set the B<activkey> attribute if given the right credentials.

Skip this step if given an B<activkey> in the constructor.

=cut

sub BUILD {
    my ( $self, $args ) = @_;

    if ( !$args->{activkey} && $args->{username} && $args->{password} ) {
        my $ua = Mojo::UserAgent->new;

        my $tx = $ua->post(
            $self->base . 'users/auth',
            { 'Content-Type' => 'application/json' },
            json => { username => $args->{username}, password => $args->{password} },
        );

        my $data = _handle_response($tx);

        $self->{activkey} = $data->{activkey}
            if $data && $data->{activkey};
    }
}

=head2 fetch()

  $r = $w->fetch(%arguments);

Fetch the results given the B<endpoint> and optional B<query> arguments.

=cut

sub fetch {
    my ( $self, %args ) = @_;

    my $query;
    if ( $args{query} ) {
        $query = join '&', map { "$_=$args{query}->{$_}" } keys %{ $args{query} };
    }

    my $ua = Mojo::UserAgent->new;

    my $url = $self->base . $args{endpoint};
    $url .= '?' . $query
        if $query;

    my $tx = $ua->get( $url, { Authorization => 'Bearer ' . $self->activkey } );

    my $data = _handle_response($tx);

    return $data;
}

sub _handle_response {
    my ($tx) = @_;

    my $data;

    if ( my $res = $tx->success ) {
        my $body = $res->body;
        if ( $body =~ /{/ ) {
            $data = decode_json( $res->body );
        }
        else {
            croak $body, "\n";
        }
    }
    else {
        my $err = $tx->error;
        croak "$err->{code} response: $err->{message}"
            if $err->{code};
        croak "Connection error: $err->{message}";
    }

    return $data;
}

1;
__END__

=head1 THANK YOU

Dan Book (DBOOK)

=head1 SEE ALSO

L<https://www.hooktheory.com/api/trends/docs>

L<Moo>

L<Mojo::UserAgent>

L<Mojo::JSON::MaybeXS>

L<Mojo::JSON>

=cut
