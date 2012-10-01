package User;

use strict;
use Exporter;

my $base_dir = "/data0/projects/collective_qa/system";
my $ufile = $base_dir."/user_data.txt";

my %user_data = ();
my %user_stats = ();
my %answer_stats = ();

our @ISA = qw(Exporter);
our @EXPORT = qw(print_user_stats update_user_stats);

sub new {
    load_user_data();
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
	$user_stats{$uid}{'attempt'} = 0 unless exists $user_stats{$uid}{'attempt'};
	$user_stats{$uid}{'correct'} = 0 unless exists $user_stats{$uid}{'correct'};
	$user_stats{$uid}{'attempt'}++;
	$user_stats{$uid}{'correct'}++ if $res eq '1';
    }
}

sub get_user_stats {
    my $self = shift;
    my $uid = shift;
    return "Attempted:".$user_stats{$uid}{'attempt'}.", Correct: ".$user_stats{$uid}{'correct'};
}

sub get_user_answers {
    my $self = shift;
    my $qid = shift;
    my $ret_answers = "";
    return $ret_answers unless exists $user_data{$qid};
    my $uanswers = $user_data{$qid};
    while(my ($uid, $answers) = each %$uanswers) {
	foreach my $a (@$answers) {
	    $ret_answers .= "\n".$uid.": '".$a."' ";
	}
    }
    return $ret_answers;
}

sub has_user_answers {
    my $self = shift;
    my $qid = shift;
    return exists $user_data{$qid};
}

sub record_user_answer {
    my $self = shift;
    my $uid = shift;
    my $qid = shift;
    my $answer = shift;
    my $correct = shift;

    my $str = "$qid $uid $answer $correct";
    `echo "$str" >> $ufile`;
}

sub update_scores {
    my $self = shift;
    my $uid = shift;
    my $correct = shift;

    $user_stats{$uid}{'attempt'} = 0 unless exists $user_stats{$uid}{'attempt'};
    $user_stats{$uid}{'correct'} = 0 unless exists $user_stats{$uid}{'correct'};
    $user_stats{$uid}{'attempt'} += 1;
    $user_stats{$uid}{'correct'} += 1 if $correct;
}


1;
