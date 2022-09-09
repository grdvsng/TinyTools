#! /usr/bin/env perl
package BasicClass;
{
    use strict;
    use warnings;
    use feature 'say';
    use TinyTools::Class::Accessor;
    
    my $category = TinyTools::Class::Accessor
        ->new
        ->default( "Other" )
        ->static
        ->build;

    my $title = TinyTools::Class::Accessor
        ->new
        ->public
        ->readonly
        ->default( "Item" )
        ->build;
    
    my $description = TinyTools::Class::Accessor
        ->new
        ->public
        ->readonly
        ->build;
   
    my $price = TinyTools::Class::Accessor
        ->new
        ->public
        ->default( 1 )
        ->non_nullable
        ->build;
    
    my $count = TinyTools::Class::Accessor
        ->new
        ->private
        ->static
        ->default( 0 )
        ->non_nullable
        ->build;

    sub new
    {
        return bless( { }, shift );
    }

    sub set_count
    {
        my $cls = shift;

        $cls->count( shift );
    }

    sub get_count
    {
        my $cls = shift;

        return $cls->count;
    }
};

package Test;
{
    use strict;
    use warnings;
    use Test::More;
    use Data::Dumper;
    use feature 'say';
    use Test::Exception;
    use Test::Exception;

    lives_ok { BasicClass->category } 'Category is static';

    is( BasicClass->category, "Other", "Check Category value" );

    lives_ok { BasicClass->category("New") } 'Update Category';

    is( BasicClass->category, "New", "Check Category value" );

    dies_ok { BasicClass->title } 'Title is non static';
    dies_ok { BasicClass->description } 'Description is non static';
    dies_ok { BasicClass->price } 'Price is non static';
    dies_ok { BasicClass->count } 'Count is private';

    lives_ok { BasicClass->set_count(10) } 'Set Count';
    is( BasicClass->get_count, 10, "Check Count value" );

    lives_ok { BasicClass->set_count(22) } 'Set Count';
    is( BasicClass->get_count, 22, "Check Count value" );

    my $instance = BasicClass->new;

    dies_ok { $instance->category } 'Category is static';

    is( $instance->title,       "Item", "Check Title value" );
    is( $instance->price,       1,      "Check Price value" );
    is( $instance->description, undef,  "Check Description value" );

    dies_ok { $instance->count } 'Count is private';

    lives_ok { $instance->description("New item") }
    'Set description before instalized';
    lives_ok { $instance->price(10) } 'Set price';

    dies_ok { $instance->title("New") } 'Title is read only';
    dies_ok { $instance->description("New") } 'Description is read only';
    dies_ok { $instance->price(undef) } 'Price is non nullable';

    lives_ok { $instance->price(12) } 'Update Price';

    is( $instance->price, 12, "Check Price value" );

    &done_testing;
}
