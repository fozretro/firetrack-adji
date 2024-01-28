#!/usr/bin/perl -w
use strict;

# Beeb Utilities to manipulate MMB and SSD files
# Copyright (C) 2012 Stephen Harris
# 
# See file "COPYING" for GPLv2 licensing

use FindBin;
use lib "$FindBin::Bin";
use BeebUtils;

my $concat=0;
if (@ARGV && $ARGV[0] eq '-concat') { $concat=1; shift @ARGV; }
@ARGV=BeebUtils::init_ssd(@ARGV);
my $src=$BeebUtils::BBC_FILE;
my ($dest1,$dest2)=@ARGV;
die "Syntax: $BeebUtils::PROG [-concat] src.dsd side0.ssd side2.ssd\n" unless $dest2;

die "$dest1 already exists\n" if -e $dest1;
die "$dest2 already exists\n" if -e $dest2;
 
my $SIZE=256*10; # 10 sectors per track

my $src_image=BeebUtils::load_external_ssd(undef,0);
# Ensure the disk is big enough; crummy non-dsd DSD images!
$src_image .= "\0" x ($SIZE*80*2);

my ($disk1,$disk2);

# In concat mode the first 200K is for disk1, the second is for disk2
# Otherwise we're interleaved at the track level

if ($concat)
{
  $disk1 = substr($src_image,0,$SIZE*80);
  $disk2 = substr($src_image,$SIZE*80,$SIZE*80);
}
else
{
  foreach my $track (0..79)
  {
    my $offset=$track*$SIZE*2; # interleaved
    $disk1 .= substr($src_image,$offset,$SIZE);
    $disk2 .= substr($src_image,$offset+$SIZE,$SIZE);
  }
}

BeebUtils::write_ssd(\$disk1,$dest1);
BeebUtils::write_ssd(\$disk2,$dest2);
print "Disks created\n";
