# Part of get-flash-videos. See get_flash_videos for copyright.
package FlashVideo::Site::Ehow;

use strict;
use FlashVideo::Utils;
use URI::Escape;

sub find_video {
  my ($self, $browser) = @_;

  # Get the video ID
  my $video_id;
  if ($browser->content =~ /flashvars=(?:&quot;|'|")id=(.*?)[ &]/) {
    $video_id = $1;
  }
  else {
    die "Couldn't extract video ID from page";
  }

  my $title;
  if ($browser->content =~ /(?:<div\ class="DetailHeader">)?
                            <h1\ class="(?:Heading1a|SubHeader)"[^>]*>(.*?)<\/h1>/x) {
    $title = $1;
  }

  if($video_id =~ /^http:/) {
    return $video_id, title_to_filename($title);
  }
  else {
    # Get the embedding page
    my $embed_url =
      "http://www.ehow.com/embedvars.aspx?isEhow=true&show_related=true&" .
      "from_url=" . uri_escape($browser->uri->as_string) .
      "&id=" . $video_id;

    $browser->get($embed_url);

    if ($browser->content =~ /&source=(http.*?flv)&/) {
      return uri_unescape($1), title_to_filename($title);
    }
    else {
      die "Couldn't extract Flash video URL from embed page";
    }
  }
}


1;
