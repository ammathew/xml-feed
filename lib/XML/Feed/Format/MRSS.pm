package XML::Feed::Format::MRSS;
use strict;
use warnings;

use base qw( XML::Feed::Format::RSS );

use XML::Feed::Entry::Format::MRSS;

use XML::FeedPP;

sub format { 'MRSS' }

sub identify {
    my $class   = shift;
    my $xml     = shift;

    my $feed = XML::FeedPP->new( $$xml );
    my $is_mrss = 1;
    if ( index($$xml, "xmlns:media=\"http://search.yahoo.com/mrss/\"" ) < 0 ) {
        $is_mrss = 0;
    }

    foreach my $item ( $feed->get_item() ) {
        if ( ! $item->{'media:content'}  )  {
            $is_mrss = 0;
            if ( ! $item->{'media:content'}->{'-url'} ) {
                $is_mrss = 0;
            }
        }
    }

    return ($is_mrss);
}


sub init_string {
    my $feed = shift;
    my($str) = @_;
    #Create XML::Feed object using both XML::Feed->parse and equivalent method in FeedPP
    #Channel fields populated by XML::Feed output.
    #Item fields populated by FeedPP output ( handles media:* fields )

    $feed->init_empty;
    my $feed_copy = $feed;
    my $parsed_feed = $feed_copy->{rss}->parse( $$str );
    my $feedpp_output = XML::FeedPP->new( $$str );
    $feed->init_empty;

    foreach my $key ( keys $parsed_feed->{channel}   ) { 
        $feed->{rss}->channel( $key => $parsed_feed->{channel}->{ $key } ); 
    }

    my $parsed_feed_items = $parsed_feed->{items};
    foreach my $feedpp_item (  $feedpp_output->get_item() ) {
        my $guid = $feedpp_item->{guid}->{'#text' };
        $feedpp_item->{guid} = $guid; # replace guid hash created by FeedPP with just guid string
        foreach my $parsed_feed_item ( @$parsed_feed_items ) {
            if ( $parsed_feed_item->{'guid'} eq $guid ) {
                $feed->{rss}->add_item( %$feedpp_item );
            }
        }
    };

    return $feed
}


sub entries {
    my $rss = $_[0]->{rss};
    my @entries;
    for my $item (@{ $rss->{items} }) {
        push @entries, XML::Feed::Entry::Format::MRSS->wrap($item);
    }
    @entries;
}

1;
