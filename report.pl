#!/usr/bin/perl

use strict;
use warnings;

use lib ".";
use GUI::DB;

use Data::Dumper;

my $report_table = "report";
my %latest_count;
my %old_count;
my %domain_count;
my %final_domain_report;

my $report_top = 50;

my $dbh = GUI::DB->dbConnect();

my @rows = GUI::DB::query($dbh, "select * from mailing");

my ($sec,$min,$hour,$day,$mon,$year) = localtime(time);
$mon += 1;
$year += 1900;

my $date = "$year-$mon-$day";
##print $date;

foreach my $row ( @rows ) {
	my $email = $row->{addr};
##	print "$email\n";
	my $domain = (split /\@/, $email)[1];
	$domain_count{$domain}++;
}

foreach my $domain ( keys %domain_count ) {
##	print "Inserting data: $domain, $domain_count{$domain}, $date\n";
	GUI::DB::query($dbh, "insert into $report_table values(?,?,?)", $domain, $domain_count{$domain}, $date);
}

($sec,$min,$hour,$day,$mon,$year) = localtime(time - 30*86400);
$mon += 1;
$year += 1900;
$day = "0$day" unless $day =~ /\d{2}/;
$mon = "0$mon" unless $mon =~ /\d{2}/;
my $old_date_to_be_used = "$year$mon$day";

@rows = GUI::DB::query($dbh, "select * from $report_table order by updated_on desc");


foreach my $row ( @rows ) {
	my $domain = $row->{domain};
	my $count = $row->{count};
	my $date = $row->{updated_on};
	$date =~ s#\D##g;
	unless ( $latest_count{$domain} ) {
		$latest_count{$domain} = $count;
	}
##	print "$date $old_date_to_be_used\n";
	next if ( $old_count{$domain} or $date > $old_date_to_be_used );
	$old_count{$domain} = $count;
}

my $count = 0;
my @top_domains = ();
my %sorted_domains;

foreach my $domain ( sort { $latest_count{$b} <=> $latest_count{$a} } keys %latest_count ) {
	$count++;
	last if $report_top < $count;
##	print "$domain => $latest_count{$domain}\n";
	$final_domain_report{$domain}{latest_count} = $latest_count{$domain};
	$final_domain_report{$domain}{old_count} = 0;
	if ( $old_count{$domain} ) {
		$final_domain_report{$domain}{old_count} = $old_count{$domain};
		$sorted_domains{old}{$domain} = sprintf ("%.2f", $latest_count{$domain}*100/$old_count{$domain});
	} else {
		$sorted_domains{new}{$domain} = $latest_count{$domain};
	}
}

print "\n";
print "Final Report:\n","="x13,"\n\n";
print "Domain\t\tLatest\tOld\tPercent-Change\n";
print "-"x46,"\n";
foreach my $domain ( sort { $sorted_domains{new}{$b} <=> $sorted_domains{new}{$a} } keys %{$sorted_domains{new}} ) {
	print "$domain\t$final_domain_report{$domain}{latest_count}\t$final_domain_report{$domain}{old_count}\tNA\n";
}

foreach my $domain ( sort { $sorted_domains{old}{$b} <=> $sorted_domains{old}{$a} } keys %{$sorted_domains{old}} ) {
		print "$domain\t$final_domain_report{$domain}{latest_count}\t$final_domain_report{$domain}{old_count}\t$sorted_domains{old}{$domain} %\n";
}
