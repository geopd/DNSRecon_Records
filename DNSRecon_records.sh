#!/bin/bash

dnsrecon_setup() {
		DNSRECON_DIR=
		DOMAIN_LIST=$DNSRECON_DIR/domain_list.txt
		DNSDUMP=$DNSRECON_DIR/Results/dnsout.txt
		DNSDUMP_FINAL=$DNSRECON_DIR/Results/dnsout_complete.txt
		DNSFINAL=$DNSRECON_DIR/Results/dnsrecon.csv
		LOGGER=$DNSRECON_DIR/dnsrecon_log
		cd $DNSRECON_DIR
		mkdir -p $DNSRECON_DIR/Results
		rm -rf $DNSDUMP DNSDUMP_FINAL $DNSFINAL
}

dnsrecon_initiate() {
		echo "DNSRecon: $i" | tee -a $DNSDUMP_FINAL
		echo "-------------------------------------------------" | tee -a $DNSDUMP_FINAL
		DNS=$(dnsrecon -d $i -t std --threads 24 --lifetime 40)
		echo "$DNS" > $DNSDUMP
		cat $DNSDUMP >> $DNSDUMP_FINAL
}

dnsrecon_records() {
		NS_RECORD=($(cat $DNSDUMP | grep -w "\[\*\]\+[[:space:]]\+NS" | cut -d ' ' -f4))
		NS_RECORD_IP=($(cat $DNSDUMP | grep -w "\[\*\]\+[[:space:]]\+NS" | cut -d ' ' -f5))
		A_RECORD=($(cat $DNSDUMP | grep -e "\[\*\]\+[[:space:]]\+A" | cut -d ' ' -f4))
		A_RECORD_IP=($(cat $DNSDUMP | grep -e "\[\*\]\+[[:space:]]\+A" | cut -d ' ' -f5))

		NS_RECORD+=("") && A_RECORD+=("")

		if [[ ${#A_RECORD[*]} > ${#NS_RECORD[*]} ]]; then
			Length=${#A_RECORD[*]}
		else
			Length=${#NS_RECORD[*]}
		fi
		
		if [[ $Length = 1 ]]; then
			echo "$i" "," ${NS_RECORD[n]} "," ${NS_RECORD_IP[n]} "," ${A_RECORD[n]} "," ${A_RECORD_IP[n]} >> $DNSFINAL
		else
			for (( n=0; n<$(( $Length-1 )); n++ ))
			do
				if [ $n = 0 ]; then
					echo "$i" "," ${NS_RECORD[n]} "," ${NS_RECORD_IP[n]} "," ${A_RECORD[n]} "," ${A_RECORD_IP[n]} >> $DNSFINAL
				else
					echo "" "," ${NS_RECORD[n]} "," ${NS_RECORD_IP[n]} "," ${A_RECORD[n]} "," ${A_RECORD_IP[n]} >> $DNSFINAL
				fi
			done
		fi
}

dnsrecon_call() {
		echo "Domain" "," "NS Records" "," "NS Record IP" "," "A Records" "," "A Records IP" >> $DNSFINAL

		while read i
		do
			count=0
			dnsrecon_initiate
			while grep 'A timeout error occurred' $DNSDUMP && (( count++ < 5 ))
			do
				echo "Timeout Error occured - Reinitiating DNSRecon"
				dnsrecon_initiate
			done
			echo "DNSRecon Success"
			echo "-------------------------------------------------" | tee -a $DNSDUMP_FINAL
			dnsrecon_records
		done < $DOMAIN_LIST
}

dnsrecon_final() {
		dnsrecon_setup
		echo "DNSRecon: Initiated - $(date +"%d/%m/%Y %H:%M:%S")" >> $LOGGER
		echo "-------------------------------------------------" >> $LOGGER
		dnsrecon_call
		echo "DNSRecon: Finished - $(date +"%d/%m/%Y %H:%M:%S")" >> $LOGGER
		echo "-------------------------------------------------" >> $LOGGER
}

dnsrecon_final
