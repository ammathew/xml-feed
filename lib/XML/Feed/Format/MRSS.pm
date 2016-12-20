package XML::Feed::Format::MRSS;
use strict;
use warnings;

use base qw( XML::Feed::Format::RSS );

use XML::FeedPP;

sub init_string {

    my $feed = shift;
    my($str) = @_;

    #here, convert feedPP to XML::RSS feed
    $feed->init_empty;

    my $feed_copy = $feed;

    my $parsed_feed = $feed_copy->{rss}->parse( $$str );
    my $parsed_feed_items = $parsed_feed->{items};
    
    my $blah = XML::FeedPP->new( $$str );
    
    $feed->init_empty;

    foreach my $key ( keys $parsed_feed->{channel}   ) { 

        $feed->{rss}->channel( $key => $parsed_feed->{channel}->{ $key } ); 
    }


    foreach my $item ( $blah->get_item() ) { 
   
        my $guid = $item->{guid}->{'#text' };

        $item->{guid} = $guid; # this needs to be fixed ... $item->{guid} should already come in as a string


        foreach my $parsed_feed_item ( @$parsed_feed_items ) {

            if ( $parsed_feed_item->{'guid'} eq $guid ) {

                $feed->{rss}->add_item( %$item ) 
          
            }
            
        }

    };

    warn "\n made it to end of mrss init string \n";

    return $feed
}


1;
