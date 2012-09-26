#!/usr/bin/perl

my $base_dir = "/data0/projects/collective_qa/system";
my $qfile = $base_dir."/questions.txt";
my $afile = $base_dir."/answers.txt";
my $ufile = $base_dir."/user_data.txt";

my %questions = ();
my %answers = ();
my %user_data = ();

load_questions();
load_answers();
load_user_data();

my $uname = get_user_name();
my $acount = `cat $ufile | grep $uname | wc -l`;
my $ccount = `cat $ufile | grep $uname | grep ' 1\$' | wc -l`;
chomp($acount);
chomp($ccount);
print "\nHi $uname! You have attempted $acount questions with $ccount correct answers. Starting a new round ...\n\nType 'skip' as answer to skip any question.\nType 'quit' to exit at any point of time.\n";
$done = 0;
my @qkeys = keys %questions;
my %visited = ();
my $system_response = "";

while(!$done) {
    my $qidx = int(rand(@qkeys));
    while(exists $visited{$qidx}) {
	$qidx = int(rand(@qkeys));
    }
    $visited{$qidx} = 1;

    my $qid = $qkeys[$qidx];
    print "\n".$questions{$qid}." : ";
    my $change_question = 0;
    my $correct = 0;
    while(!$change_question) {
	$current_answer = <STDIN>;
	chomp($current_answer);
	while($current_answer =~ m/^$/) {
	    print "You didn't provide an answer : ";
	    $current_answer = <STDIN>;
	    chomp($current_answer);
	}

	last if($current_answer eq "skip" || $current_answer eq "quit");

	$acount++; # increment attempated questions

	my $result = check_answer($qid, $current_answer);
	if($result eq "false") {
	    print "\nIncorrect. ";
	    my $user_answers = get_user_answers($qid);
	    my $next_string = ($user_answers eq "") ? "\nThere are no other user responses at this time.\n" : "\n\nOther people have answered : \n".get_user_answers($qid)."\n"; 
	    print $next_string;
	    print "\nTry this question again? (y/n) : ";
	    my $response = <STDIN>;
	    chomp($response);
	    while(!$response =~ m/^(y|n|quit)$/i) {
		print "\nPlease type y, n or quit : ";
		my $response = <STDIN>;
		chomp($response);
	    }

	    if($response eq "quit" || $response eq "n"){
		$system_response = $response;
		last;
	    } 

#	    if (!($response eq "y")) {
#		print "\nCorrect answers are : ";
#		print_correct_answers($qid);
#		last;
#	    }
	}

	elsif($result eq "na") {
	    print "\nThanks for your answer. We currently don't have a correct answer for this in our system.";
	    my $user_answers = get_user_answers($qid);
	    my $next_string = ($user_answers eq "") ? "\n\nThere are no other user responses at this time." : "\n\nOther people have answered : \n".get_user_answers($qid); 
	    print $next_string;
	    last;
	}
	elsif($result eq "true") {
	    $ccount++;
	    print "\nCorrect!";
	    $correct = 1;
	    last;
	}
	print "Enter the new answer here : ";
    }

    update_user_answers($qid, $uname, $current_answer, $correct) unless($current_answer eq "skip" || $current_answer eq "quit");

    if($current_answer eq "skip" || $system_response eq "skip" || $system_response eq "n") {
	print "\nSkipped. ";
	if(exists $answers{$qid}) {
	    print "Correct answers are: ";
	    print_correct_answers($qid);
	} 
    }
    print "\n\n**** Current score: Attempted - $acount, Correct - $ccount ****\n";
    last if ($current_answer eq "quit" || $system_response eq "quit");
    # print "\nTry another question? (y/n) : ";
    # my $response = <STDIN>;
    # chomp($response);
    # while(!($response =~ m/[yn]/i)) {
    # 	print "\nYou must answer either y or n : ";
    # 	my $response = <STDIN>;
    # 	chomp($response);
    # }

    # last if(lc($response) eq "n");
}

# if matches tell user and pick next one
# if does not match and user 
print "\nBye!\n";

sub print_correct_answers {
    my $qid = shift;
    for my $apat (@{$answers{$qid}}) {
	$apat =~ s/\.\*/ /g;
	$apat =~ s/\\\-/-/g;
	$apat =~ s/(\([^\|]*\s*)\|\s*[^\)]*\)/$1/g;
	$apat =~ s/[\(\)]//g;
	$apat =~ s/\\s\*//g;
	$apat =~ s/\?//g;
	
	print "'$apat' ";
    }
}

sub get_user_answers {
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

sub check_answer {
    my $qid = shift;
    my $user_answer = shift;
    if(!exists $answers{$qid}) {
	return "na";
    }
    my $correct_answers = $answers{$qid};
    foreach my $ta (@$correct_answers) {
	return "true" if $user_answer =~ m/$ta/i;
    }
    return "false";
}

sub get_user_name {
    my $done = 0;
    print "Hi, please enter your username (alphanumeric with no spaces) : ";
    my $input = <STDIN>;
    chomp($input);
    while(!$done) {
	if($input =~ m/^[a-zA-Z0-9]+$/) {
	    return $input;
	} else {
	    print "Invalid username, please use only alphanumeric characters with no spaces : ";
	    $input = <STDIN>;
	    chomp($input);
	}
    }
}
sub load_questions {
    open QFILE, $qfile or die $!;
    while(<QFILE>) {
	chomp($_);
	my ($qid, $qtext) = split(/ ::: /, $_);
	$questions{$qid} = $qtext;
    }
    close QFILE;
}

sub load_answers {
    open AFILE, $afile or die $!;
    while(<AFILE>) {
	chomp($_);
	$_ =~ m/^(\d+)\s+(.*)$/;
	my $aid = $1;
	my $apat = $2;
	$answers{$aid} = [] unless exists $answers{$aid};
	push(@{$answers{$aid}}, $apat);
    }
    close AFILE;
}

sub load_user_data {
    open UFILE, $ufile or die $!;
    while(<UFILE>) {
	chomp($_);
	next if $_ =~ m/^$/;
	$_ =~ m/^(\d+)\s+([a-zA-Z]+)\s+(.*)\s+[01]$/;
	my $qid = $1;
	my $uid = $2;
	my $answer = $3;
	
	$user_data{$qid} = {} unless exists $user_data{$qid};
	$user_data{$qid}{$uid} = [] unless exists $user_data{$qid}{$uid};
	push(@{$user_data{$qid}{$uid}}, $answer);
    }

}

sub update_user_answers {
    my $qid = shift;
    my $uid = shift;
    my $answer = shift;
    my $correct = shift;
    
    my $str = "$qid $uid $answer $correct";
    `echo "$str" >> $ufile`;
}

sub quit {

}

sub update_user_data {
    
}
