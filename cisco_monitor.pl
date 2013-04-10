#!/usr/bin/perl

# Cisco C-Series XML API Fetch 

use strict;
use LWP;
use IO::Socket;
use XML::Simple;
use XML::LibXML;
use Getopt::Long;
use Carp qw(croak cluck confess);
my $PROGNAME=substr($0,0,rindex($0,'.'));
use Data::Dumper;

my $lDebug=0;

my $lServer = undef;
my $lPort = undef;
my $sock  = undef;

my $lUri = undef;
my $lUname = undef;
my $lPasswd = undef;
my $lClass = undef;
my $lfilter =undef;


# Specify the command line options and process the command line
my $options_okay = GetOptions (
    # Application specific options
    'server=s'      => \$lServer,     # Server address
    'port=s'        => \$lPort,         # Server port
    'uname=s'       => \$lUname,        # User name.
    'passwd=s'      => \$lPasswd,       # Password.
    'class=s'       => \$lClass,        #XML query Command
    'filter=s'      => \$lfilter,        # XML attribute filter

    # Standard meta-options
    'usage'         => sub { usage(); },
    'help'          => sub { usage(); },
);


usage() if !$options_okay;

usage() if ((!$lUname) || (!$lPasswd) || (!$lPort) || (!$lServer));

#my $lUri = "http://" . $lServer . ":" . $lPort . "/nuova";
my $lUri = "https://" . $lServer . "/nuova";

my $lCookie = doLogin($lUri, $lUname, $lPasswd);

if (!defined $lCookie)
{
	croak "Failed to get cookie";
	exit(1);
}

print "\nGot cookie : $lCookie\n" if ($lDebug);



#storageLocalDiskSlotEp
#storageController
#memoryUnit
#memoryArray
#equipmentFan
#equipmentFanModule
#processorUnit
#adaptorHostEthIf
#adaptorExtEthIf
#equipmentPsu
#pciEquipSlot

dosystemquery($lUri, $lCookie, $lClass);
#doUSBflashDisable ($lUri, $lCookie);
doLogout($lUri, $lCookie);


# Returns undef if it fails.
sub doLogin
{
    my ($aInUri, $aInUname, $aInPassword) = @_;
    my $lXmlRequest = "<aaaLogin inName=\"REPLACE_USER\" inPassword=\"REPLACE_PASS\"/>";
    $lXmlRequest =~ s/REPLACE_USER/$aInUname/;
    $lXmlRequest =~ s/REPLACE_PASS/$aInPassword/;

    my $lCookie = undef;
    my ($lContent, $lMessage, $lSuccess) = doPostXML($aInUri, $lXmlRequest,1);

    if ($lSuccess)
    {
        eval {
            my $lParser = XML::Simple->new();
            my $lConfig = $lParser->XMLin($lContent);
            $lCookie = $lConfig->{'outCookie'};
            $lCookie = undef if ($lCookie && $lCookie eq "");
        };
    }
    return $lCookie;
}



##########################
#my $xml  = new XML::Simple (KeyAttr=>[],ForceArray=>1);
my $data = undef;
my $statsObject = "";
my $Extract_Classes_Attributes = "";
my $outputStr = "";
my @Extract_Attributes;
my $z=0;


sub dosystemquery
{
    my ($aInUri, $aInCookie, $aInClass) = @_;

    my $lXmlRequest = "<configResolveClass cookie=\"REPLACE_COOKIE\" inHierarchical='false' classId=\"REPLACE_CLASS\"></configResolveClass>";

    $lXmlRequest =~ s/REPLACE_COOKIE/$aInCookie/;
    $lXmlRequest =~ s/REPLACE_CLASS/$aInClass/;

    my @attribute =split (',',$lfilter);
    my $lCookie = undef;
    my ($lContent, $lMessage, $lSuccess) = doPostXML($aInUri, $lXmlRequest,1);
   
if ($aInClass eq "faultiest" or $aInClass eq "storageLocalDiskUsage" or $aInClass eq "storageLocalDiskProps")
{
   $data = XMLin($lContent,KeyAttr => '',);
   my @myarray= $data->{'outConfigs'}{$aInClass};
   my $i=0;
   foreach my $fooarray(@myarray)
    { my $j=0; foreach my $foocell(@$fooarray) { if ($lfilter eq "FULL") {foreach my $x (keys %{$foocell}) {print "$x:${$foocell}{$x},";}}
         else {foreach my $y (@attribute) { print"$y:${$foocell}{$y},";}}  $i++;print "\n";}}
}
else { $data = XMLin($lContent);
   $outputStr= $data->{'outConfigs'}{$aInClass};
   if ($lDebug) {print Dumper($data);}

    foreach my $attributes (keys %{$outputStr})
      {

        #      print Dumper ${$outputStr}{$attributes};
       
            $Extract_Classes_Attributes= ${$outputStr}{$attributes};

             if (ref($Extract_Classes_Attributes) eq 'HASH') {

                 if ($lfilter eq "FULL") {foreach my $x ( keys %{$Extract_Classes_Attributes}) {print "$x: ${$Extract_Classes_Attributes}{$x},";  }}
                 else { foreach my $y (@attribute) { print "$y:${$Extract_Classes_Attributes}{$y},";} }
       
             print "\n";
            }
            else {
                  if ($lfilter eq "FULL") { print "$attributes:${$outputStr}{$attributes},";}
                  else {foreach my $y (@attribute) { if ($attributes eq $y) {print "$y:${$outputStr}{$attributes},";}}}
                  $z=1;
                 }
        }
        if ($z==1) {  print "\n";}
}


#for (my $i = 0; $i <= $#{$statsObject->{$x}}; $i++) {

    if ($lSuccess)
    {
        eval {
            my $lParser = XML::Simple->new();
            my $lConfig = $lParser->XMLin($lContent);
            $lCookie = $lConfig->{'outCookie'};
            $lCookie = undef if ($lCookie && $lCookie eq "");
        };
    }
    return $lCookie;
}

######################
sub doConfigResolveClass {
#
# doConfigResolveClass - Run configResolveClass query
# Parameters:
#	aInUri		- UCS URI
#	aInCookie	- UCS authentication cookie
#	aInHier		- inHierarchical setting
#	aInConfig	- Configuration string
#
#		Command string - classId#filter
#
#		classId - class name to query
#		filter	- an XML encoded UCS query filter
#
#	aInDebug	- Debug flag
#	aInProcess	- Process flag
#
# Return Value
#	XML String	- The XML request doc if aInProcess is false otherwise the UCS XML response doc
#

	my ( $aInUri, $aInCookie, $aInHier, $aInConfig, $aInDebug, $aInProcess ) = @_;
	

	my @lCfg = split( /#/, $aInConfig );
	
	my $lXmlRequest = XML::Writer::String->new();
	my $writer  = new XML::Writer( OUTPUT => $lXmlRequest, UNSAFE => 1 );
	
	my $classId = $lCfg[0];
	my $filter	= $lCfg[1];
	
	$writer->startTag('configResolveClass', inHierarchical => $aInHier, cookie => $aInCookie, classId => $classId);

	if ($filter) {
		$writer->startTag('inFilter');
		$writer->raw($filter);
		$writer->endTag('inFilter');
	}
	
	$writer->endTag();
	$writer->end;
	
	if ($aInProcess) {
		my ( $lContent, $lMessage, $lSuccess ) = doPostXML( $aInUri, $lXmlRequest->value(), $aInDebug );
		return $lContent, $lMessage, $lSuccess;
	} else {
		return $lXmlRequest->value();
		return;
	}
}





########################

# Returns undef if it fails.
sub doLogout
{
    my ($aInUri, $aInCookie) = @_;
    my $lXmlRequest = "<aaaLogout inCookie=\"REPLACE_COOKIE\" />";
    $lXmlRequest =~ s/REPLACE_COOKIE/$aInCookie/;

    my $lCookie = undef;
    my ($lContent, $lMessage, $lSuccess) = doPostXML($aInUri, $lXmlRequest,1);

    if ($lSuccess)
    {
        eval {
            my $lParser = XML::Simple->new();
            my $lConfig = $lParser->XMLin($lContent);
            $lCookie = $lConfig->{'outCookie'};
            $lCookie = undef if ($lCookie && $lCookie eq "");
        };
    }
    return $lCookie;
}

# Parameters:
#  an arrayref or hashref for the key/value pairs,
#  and then, optionally, any header lines: (key,value, key,value)
sub doPostXML
{
    my ($aInUri, $aInPostData) = @_;

    my $browser = LWP::UserAgent->new();
    my $request = HTTP::Request->new(POST => $aInUri);
    $request->content_type("application/x-www-form-urlencoded");
    $request->content($aInPostData);

    # Print out the request and response
    if ($lDebug==1)
    {
        print ("\nRequest\n");
        print ("-------\n");
        print ($request->as_string() . "\n");
    }

    my $resp = $browser->request($request);    #HTTP::Response object

    if ($lDebug==1)
    {
        print ("\nResponse\n");
        print ("-------\n");
        print ($resp->content() . "\n");
    }

    return ($resp->content, $resp->status_line, $resp->is_success, $resp)
      if wantarray;
    return unless $resp->is_success;
    return $resp->content;
}


# Print usage message.
sub usage {
    my $options = <<HERE_OPT;
        --server=<server>        Server address.
        --port=<port>            Server port. 
        --usage                  This usage message.
        --help                   This help message.
HERE_OPT
    $options =~ s/^\s+/    /gm;

    print "Usage : $0 <OPTIONS>\n$options\n";
    print "Example :\n";
    print "perl  $0 --uname=admin --passwd=nbv12345 \\ \n";
    print "   --server=10.193.36.108 --port=80\n";

    exit(1);
}

