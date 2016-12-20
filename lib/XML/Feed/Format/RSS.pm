package XML::Feed::Format::RSS;
use strict;
use warnings;

our $VERSION = '0.53';

use base qw( XML::Feed );
use DateTime::Format::Mail;
use DateTime::Format::W3CDTF;
use XML::Atom::Util qw(iso2dt);
use XML::Feed::Enclosure;
use XML::Feed::Entry::Format::RSS;

use XML::FeedPP;

our $PREFERRED_PARSER = "XML::RSS";


sub identify {
    my $class   = shift;
    my $xml     = shift;
    my $tag     = $class->_get_first_tag($xml);
    return ($tag eq 'rss' || $tag eq 'RDF');
}

sub init_empty {
    my ($feed, %args) = @_;
    $args{'version'} ||= '2.0';
    eval "use $PREFERRED_PARSER"; die $@ if $@;
    $feed->{rss} = $PREFERRED_PARSER->new(%args);
    $feed->{rss}->add_module(prefix => "content", uri => 'http://purl.org/rss/1.0/modules/content/');
    $feed->{rss}->add_module(prefix => "dcterms", uri => 'http://purl.org/dc/terms/');    
    $feed->{rss}->add_module(prefix => "atom", uri => 'http://www.w3.org/2005/Atom');
    $feed->{rss}->add_module(prefix => "geo", uri => 'http://www.w3.org/2003/01/geo/wgs84_pos#');
    $feed->{rss}->add_module(prefix => "media", uri => 'http://search.yahoo.com/mrss');
    
    $feed;
}

sub init_string {
    my $feed = shift;
    my($str) = @_;
    $feed->init_empty;
    my $opts = {
         hashrefs_instead_of_strings => 1,
    };
    $opts->{allow_multiple} = [ 'enclosure' ] if $XML::Feed::MULTIPLE_ENCLOSURES;
    if ($str) {
        $feed->{rss}->parse($$str, $opts );
    }
    $feed;
}

sub init_string_mrss {

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

    return $feed
}

sub format { 'RSS ' . $_[0]->{rss}->{'version'} }

## The following elements are the same in all versions of RSS.
sub title       { shift->{rss}->channel('title', @_) }
sub link        {
    my $link = shift->{rss}->channel('link', @_);
    $link =~ s/^\s+//;
    $link =~ s/\s+$//;
    return $link;
}
sub description { shift->{rss}->channel('description', @_) }
sub updated     { shift->modified(@_) }

# This doesn't exist in RSS
sub id          { }

## This is RSS 2.0 only--what's the equivalent in RSS 1.0?
sub copyright   { shift->{rss}->channel('copyright', @_) }

sub base {
    my $feed = shift;
    if (@_) {
        $feed->{rss}->{'xml:base'} = $_[0];
    } else {
        $feed->{rss}->{'xml:base'};
    }
}

## The following all work transparently in any RSS version.
sub language {
    my $feed = shift;
    if (@_) {
        $feed->{rss}->channel('language', $_[0]);
        $feed->{rss}->channel->{dc}{language} = $_[0];
    } else {
        $feed->{rss}->channel('language') ||
        $feed->{rss}->channel->{dc}{language};
    }
}

sub self_link {
    my $feed = shift;

    if (@_) {
        my $uri = shift;

        $feed->{rss}->channel->{'atom'}{'link'} =
        {
            rel => "self",
            href => $uri,
            type => "application/rss+xml",
        };
    }

    return $feed->{rss}->channel->{'atom'}{'link'};
}

# This doesn't exist in RSS
sub first_link { };
sub last_link { };
sub previous_link { };
sub next_link { };
sub current_link { };
sub prev_archive_link { };
sub next_archive_link { };

sub generator {
    my $feed = shift;
    if (@_) {
        $feed->{rss}->channel('generator', $_[0]);
        $feed->{rss}->channel->{'http://webns.net/mvcb/'}{generatorAgent} =
            $_[0];
    } else {
        $feed->{rss}->channel('generator') ||
        $feed->{rss}->channel->{'http://webns.net/mvcb/'}{generatorAgent};
    }
}

sub author {
    my $feed = shift;
    if (@_) {
        $feed->{rss}->channel('webMaster', $_[0]);
        $feed->{rss}->channel->{dc}{creator} = $_[0];
    } else {
        $feed->{rss}->channel('webMaster') ||
        $feed->{rss}->channel->{dc}{creator};
    }
}

sub modified {
    my $rss = shift->{rss};
    if (@_) {
        $rss->channel('pubDate',
            DateTime::Format::Mail->format_datetime($_[0]));
        ## XML::RSS is so weird... if I set this, it will try to use
        ## the value for the lastBuildDate, which I don't want--because
        ## this date is formatted for an RSS 1.0 feed. So it's commented out.
        #$rss->channel->{dc}{date} =
        #    DateTime::Format::W3CDTF->format_datetime($_[0]);
    } else {
        my $date;
        eval {
            if (my $ts = $rss->channel('pubDate')) {
                $ts =~ s/^\s+//;
                $ts =~ s/\s+$//;
                $date = DateTime::Format::Mail->parse_datetime($ts);
            } elsif ($ts = $rss->channel->{dc}{date}) {
                $ts =~ s/^\s+//;
                $ts =~ s/\s+$//;
                $date = DateTime::Format::W3CDTF->parse_datetime($ts);
            }
        };
        return $date;
    }
}

sub image {
    my $self = shift;
    my $rss = $self->{rss};

    return @_ ? $rss->image(@_) : $rss->image('url');
}

sub entries {
    my $rss = $_[0]->{rss};
    my @entries;
    for my $item (@{ $rss->{items} }) {
        push @entries, XML::Feed::Entry::Format::RSS->wrap($item);
		$entries[-1]->{_version} = $rss->{'version'};		
    }
    @entries;
}

sub add_entry {
    my $feed  = shift;
    my $entry = shift || return;
    $entry    = $feed->_convert_entry($entry);
    $feed->{rss}->add_item(%{ $entry->unwrap });
}

sub as_xml { $_[0]->{rss}->as_string }

sub media {
    my $item = shift->{entry};

    my $media_url = $item->{'media:group'}{'media:content'}[1]{'-url'};
    return $media_url;
}

1;

