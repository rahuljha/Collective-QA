package Rating;

use strict;
use Exporter;

use Data::Dumper;

my $base_dir = "/data0/projects/collective_qa/system";
my $ufile = $base_dir."/user_data.txt";
my $rfile = $base_dir."/ratings.txt";

my %user_data = ();
my %answer_data = ();
my %rating_data = ();
my %user_stats = ();

sub new {
    load_user_data();
    load_rating_data();

    my $self = {};
    bless $self;
}

sub load_user_data {
    open UFILE, $ufile or die $!;
    while(<UFILE>) {
	chomp($_);
	next if $_ =~ m/^$/;
	$_ =~ m/^(\d+)\s+([a-zA-Z]+)\s+(.*)\s+([01])$/;
	my $qid = $1;
	my $uid = $2;
	my $answer = $3;
	my $res = $4;
	
	$user_data{$qid} = {} unless exists $user_data{$qid};
	$user_data{$qid}{$uid} = [] unless exists $user_data{$qid}{$uid};
	push(@{$user_data{$qid}{$uid}}, $answer);
	
	my $akey = norm_string($answer);
	$answer_data{$qid} = {} unless exists $answer_data{$qid};

	my $max_id = 0;
	foreach my $ak (keys %{$answer_data{$qid}}) {
	    if($answer_data{$qid}{$ak}{id} > $max_id) {
		$max_id = $answer_data{$qid}{$ak}{id};
	    }
	}

	if(exists $answer_data{$qid}{$akey}) {
	    $answer_data{$qid}{$akey}{users} = {} unless exists $answer_data{$qid}{$akey}{users};
	    $answer_data{$qid}{$akey}{users}{$uid} = 1;
	} else {
	    $answer_data{$qid}{$akey} = {};
	    $answer_data{$qid}{$akey}{id} = $max_id+1;
	    $answer_data{$qid}{$akey}{users} = {};
	    $answer_data{$qid}{$akey}{users}{$uid} = 1;
	}
	
	$user_stats{$uid}{'attempt'} = 0 unless exists $user_stats{$uid}{'attempt'};
	$user_stats{$uid}{'correct'} = 0 unless exists $user_stats{$uid}{'correct'};
	$user_stats{$uid}{'attempt'}++;
	$user_stats{$uid}{'correct'}++ if $res eq '1';
    }

}

sub load_rating_data {
    open RFILE, $rfile or die $!;    

    while(<RFILE>) {
	chomp($_);
	my ($qid, $astr, $rating) = split(/ ::: /, $_);
	$rating_data{$qid} = {} unless exists $rating_data{$qid};
	$rating_data{$qid}{$astr} = 0 unless exists $rating_data{$qid}{$astr};
	++$rating_data{$qid}{$astr};
    }
}

sub print_rating_data {
    my $self = shift;
    my $qid = shift;
    
    my $print_data = {};

    foreach my $astr (keys %{$answer_data{$qid}}) {
	my $aid = $answer_data{$qid}{$astr}{id};
	my @users = keys %{$answer_data{$qid}{$astr}{users}};
	$print_data->{$aid} = {};
	$print_data->{$aid}{users} = join(",", @users);
	$print_data->{$aid}{str} = $astr;
    }

    foreach my $k (sort keys %{$print_data}) {
	my $astr = $print_data->{$k}{str};
	my $rating = "no rating yet";
	if(exists $rating_data{$qid}) {
	    if(exists $rating_data{$qid}{$astr}) {
		$rating = $rating_data{$qid}{$astr};
	    }
	}

	print $k.". ".$astr." [".$print_data->{$k}{users}."] : $rating\n";
    }
}

sub norm_string {
    my $str = shift;
    $str = lc($str);
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

1;
