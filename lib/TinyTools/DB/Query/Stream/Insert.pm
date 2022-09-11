package TinyTools::DB::Query::Stream::Insert;
{
    use Moose;
    use Data::Dumper;
    use feature 'say';
    use SQL::Abstract;
    use Carp 'confess';
    use IO::Async::Function;
    use MooseX::ClassAttribute;
    use SQL::Abstract::Plugin::InsertMulti;

    extends 'TinyTools::DB::Query::Stream::Basic';

    class_has 'supported_events' => (
        is      => 'rw',
        isa     => 'ArrayRef[Str]',
        default => sub { return [qw( error insert end )]; },
    );

    has "max_store_size" => ( is => 'rw', isa => 'Int', default => 5_000 );

    has "locked" => ( is => 'rw', isa => 'Bool', default => 0 );

    has "items" => (
        is      => 'rw',
        isa     => 'ArrayRef[HashRef]',
        default => sub { [] },
    );

    has "table" => ( is => 'ro', isa => 'Str' );

    has "function" => (
        is      => 'ro',
        isa     => 'IO::Async::Function',
        lazy    => 1,
        default => sub {
            my $self     = shift;
            my $function = IO::Async::Function->new(
                code => sub {
                    my @rows = @_;

                    if ( @rows > 0 ) {
                        my $dbh = $self->dbh->();

                        my ( $stmt, @bind )
                            = SQL::Abstract->new->insert_multi(
                            $self->table, \@rows );
                        my $sth = $dbh->prepare($stmt);

                        eval { $sth->execute(@bind) };

                        if ($@) {
                            confess $@;
                        }

                        $dbh->disconnect;
                    }

                }
            );

            $self->loop->add($function);

            $function->start;

            return $function;
        }
    );

    has 'timer' => ( isa => 'IO::Async::Timer::Periodic', is => 'rw' );

    sub new {
        my $cls  = shift;
        my $self = $cls->SUPER::new(@_);

        $self->timer(
            IO::Async::Timer::Periodic->new(
                interval => 1,

                on_tick => sub {
                    $self->_write;
                },
            )
        );

        $self->timer->start;
        $self->loop->add( $self->timer );

        return $self;
    }

    sub _write {
        my $self  = shift;
        my @items = @{ $self->items };

        $self->items( [] );

        if ( scalar(@items) > 0 && !$self->locked ) {
            $self->locked(1);

            eval {
                $self->function->call( args => \@items )->on_fail(
                    sub {
                        my $error = shift;

                        $self->emit( 'error', $error );
                    }
                )->on_done(
                    sub {
                        $self->emit( 'insert', scalar(@items) );
                    }
                )->get;
            };

            $self->locked(0);

            $self->emit( 'error', $@ ) if $@;
        }
    }

    sub push {
        my $self = shift;
        my @data = @_;

        push( @{ $self->items }, @_ );

        if ( scalar( @{ $self->items } ) >= $self->max_store_size ) {
            $self->_write;
        }
    }

    sub end {
        my $self = shift;

        $self->timer->stop;
        $self->_write;
        $self->function->stop;

        $self->emit( 'end', $self );
    }
};
1;
