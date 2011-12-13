package Cirque::API::Email;
use Cirque::Pragmas;
use Mouse;
use Mouse::Util::TypeConstraints;
use Email::Address::Loose;
use Email::Send;
use Email::Simple;
use Encode ();

subtype 'Data::Email::Send'
    => as 'Email::Send'
;

coerce 'Data::Email::Send'
    => from 'HashRef' => via { Email::Send->new( $_ ) } ;

has add_headers => ( 
    is      => 'rw', 
    isa     => 'HashRef', 
    default => sub { {} },
);

has encodings => ( 
    is      => 'ro', 
    isa     => 'HashRef', 
    default => sub { {
        subject => 'MIME-Header-ISO_2022_JP',
        body    => 'iso-2022-jp',
    } }, 
);

has sender => (
    is      => 'rw',
    isa     => 'Data::Email::Send',
    coerce  => 1,
);

sub send_message {
    my ( $self, $message, $to, $cc, @arg ) = @_;

    my $encodings = $self->encodings;
    my $email = Email::Simple->new( $message );
    
    for my $key ( keys %{ $self->add_headers } ) {
        $email->header_set( "$key", $self->add_headers->{"$key"} );
    }
    $email->header_set( 'To', join( ', ', $self->extract_valid_addresses( @$to ) ) );
    if ( defined $cc ) {
        $email->header_set( 'Cc', join( ', ', $self->extract_valid_addresses( @$cc ) ) ) if @$cc > 0;
    }
    
    my $subject = $email->header( 'Subject' );
    $subject = Encode::encode( $encodings->{subject}, $subject );
    $email->header_set( 'Subject', $subject );

    my $body = $email->body;
    $body = Encode::encode( $encodings->{body}, $body );
    $email->body_set( $body );

    $self->sender->send( $email->as_string, @arg );
}

sub extract_valid_addresses {
    my ( $self, @addr ) = @_;
    my %valid;
    foreach my $addr ( @addr ) {
        foreach my $obj ( Email::Address::Loose->parse( $addr ) ) {
            $valid{ $obj->address }++;
        }
    }
    return keys %valid;
}

no Mouse;
no Mouse::Util::TypeConstraints;

1;

__END__
