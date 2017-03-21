package XML::Feed::Entry::Format::MRSS;
use strict;
use warnings;

our $VERSION = '0.53';

sub format { 'MRSS' }

use XML::Feed::Content;

use base qw(  XML::Feed::Entry::Format::RSS );



1;

