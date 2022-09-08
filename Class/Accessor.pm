package TinyTools::Class::Accessor;
{
    use File::Spec;
    use Data::Dumper;
    use feature 'say';
    use Carp 'confess';
    use TinyTools::File::Utils 'read_file_line';  
    use PadWalker qw/peek_my peek_our/;

    sub as_hash
    {
        my $self = shift;

        return { %$self };
    }

    sub new
    {
        my $cls    = shift;
        my %params = @_;

        my ($main_class,$path,$line) = caller;
        my ( $name )                 = read_file_line( $path, $line ) =~ m/my\s{1,}(.*?)\s{0,}=/;
        $name                        =~ s/^\$//;

        my $params = {};

        $params->{ master      } = $main_class;
        $params->{ name        } = $name || confess 'Attribute name not detected!';
        $params->{ is_static   } = ( exists $params{is_static}   ?  !!$params{is_static}   : 0 );
        $params->{ is_private  } = ( exists $params{is_private}  ?  !!$params{is_private}  : 0 );
        $params->{ is_readonly } = ( exists $params{is_readonly} ?  !!$params{is_readonly} : 0 );
        $params->{ is_nullable } = ( exists $params{is_nullable} ?  !!$params{is_nullable} : 1 );

        if (exists $params{default})
        {
            $params->{ default }    = $params{default};
            $params->{ didnt_init } = 0;
        } else {
            $params->{ didnt_init } = 1;
        }


        my $self = bless( $params, $cls );

        return $self;
    }    

    sub _change_params
    {
        my $self = shift;
        my $attr = shift;
        
        $self->{ $attr } = shift;

        return $self;
    }

    sub private
    {
        _change_params( shift, 'is_private',  1 )
    }

    sub public
    {
        _change_params( shift, 'is_private',  0 )
    }

    sub static
    {
        _change_params( shift, 'is_static',  1 )
    }

    sub non_static
    {
        _change_params( shift, 'is_static',  0 )
    }

    sub readonly
    {
        _change_params( shift, 'is_readonly',  1 )
    }

    sub readwrite
    {
        _change_params( shift, 'is_readonly',  0 )
    }

    sub default
    {
        _change_params( 
            _change_params( shift, 'default', shift ), 
            'didnt_init', 
            0 
        )
    }

    sub nullable
    {
        _change_params( shift, 'is_nullable', 1 )
    }

    sub non_nullable
    {
        _change_params( shift, 'is_nullable', 0 )
    }

    sub build
    {
        my $self          = shift;
        my $master        = $self->{master};
        my $name          = $self->{name};
        my $static        = $self->{is_static};
        my $nullable      = $self->{is_nullable};
        my $readonly      = $self->{is_readonly};
        my $didnt_init    = $self->{didnt_init};
        my $current_value = $self->{default};
        my $private       = $self->{is_private};

        eval '*' . $master . '::' . $name . ' = ' . '
        sub {
            my $wanna_set   = scalar( @_ ) == 2;
            my $self_or_cls = shift;
            my $value       = shift;
            my $non_static  = !ref $self_or_cls;
            my ($call_by)   = caller;
            
            if ($private && $call_by ne $master) 
            {
                confess "$name is private";
            } elsif ($non_static && !$static) {
                confess "$name is not static";
            } elsif (!$non_static && $static ) {
                confess "$name is static";
            } else {
                if ( $wanna_set )
                {
                    if ( !defined $value || $value eq "" && !$nullable)
                    {
                        confess "$name value is required";
                    } elsif ($readonly && !$didnt_init) {
                        confess "$name value is readonly";
                    } else {
                        $current_value = $value;
                        $didnt_init    = 0;
                    }

                    return $self_or_cls;
                } else {
                    return $current_value;
                }
            }
        }
        ';
    }
};
1;