# Part of get-flash-videos. See get_flash_videos for copyright.
package FlashVideo::Site::Fliqz;

use strict;
use FlashVideo::Utils;

sub find_video {
  my ($self, $browser, $embed_url) = @_;

  # Get the video ID.
  my $id;
  if ($browser->content =~ /<param name=["']flashvars["'] value=["']file=([a-f0-9]{32})/) {
    $id = $1;
  }

  # This can sometimes pull out the incorrect ID, which causes a SOAP fault to
  # be returned, so we do the other check first.
  if (!$id and $browser->content =~ /\Q$embed_url\E.*?([a-f0-9]{32})/) {
    $id = $1;
  }

  $browser->post("http://services.fliqz.com/mediaassetcomponentservice/20071201/service.svc",
    Content_Type => "text/xml; charset=utf-8",
    SOAPAction   => '"urn:fliqz.s.mac.20071201/IMediaAssetComponentService/ad"',
    Referer      => $embed_url,
    Content      => _get_soap_xml($id)
  );

  my $flv_url  = ($browser->content =~ />(http:[^<]+\.flv)</)[0];

  # If we can't get the FLV URL, try posting our SOAP request to a different
  # URL. Don't know how they decide which server to use - would be good if we could
  # find out.
  if (!$flv_url) {
    # Try posting to a different URL
    $browser->post("http://services.fliqz.com/LegacyServices/Services/MediaAsset/Component/R20071201/service.svc",
      Content_Type => "text/xml; charset=utf-8",
      SOAPAction   => '"urn:fliqz.s.mac.20071201/IMediaAssetComponentService/ad"',

      # For the record, it seems that Fliqz don't care about the referer
      # anyway.
      Referer      => $embed_url,

      Content      => _get_soap_xml($id)
    );

    $flv_url = ($browser->content =~ />(http:[^<]+\.flv)</)[0];
  }

  my $filename = ($browser->content =~ /<t [^>]+>([^<]+)/)[0];
  $filename = title_to_filename($filename);

  # I want to follow redirects now.
  $browser->allow_redirects;

  return $flv_url, $filename;
}

sub _get_soap_xml {
  my $id = shift;

  return <<EOF
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<SOAP-ENV:Body>
  <i0:ad xmlns:i0="urn:fliqz.s.mac.20071201">
  <i0:rq>
    <i0:a>$id</i0:a>
    <i0:pu></i0:pu>
    <i0:pid>1F866AF1-1DB0-4864-BCA1-6236377B518F</i0:pid>
  </i0:rq>
</i0:ad> 
</SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF
}

1;
