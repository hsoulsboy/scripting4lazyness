#!/bin/bash

while true; do
	echo
	echo "-------------------------------------------|"
	echo "| 1 - Generate Certificate Authority (CA)  |"
	echo "| 2 - Execute operations using existing CA |"
	echo "| 3 - Exit                                 |"
	echo "-------------------------------------------|"

	read -p "Option: " OPERATION

	if [[ $OPERATION -eq "1" ]]; then

		read -p "CA directory destination (default is '/tmp/ca-ts-[Timestamp]'): " CA_DIR

		if [[ $CA_DIR == "" ]]; then
			CA_DIR=/tmp/ca-ts-$(date +%Y-%m-%d_%H_%M_%S)
		fi

		mkdir $CA_DIR
		mkdir -p $CA_DIR/newcerts
		touch $CA_DIR/index.txt
		echo "01" > $CA_DIR/serial
		mkdir -p $CA_DIR/certs
		mkdir -p $CA_DIR/certs/clientAuth/
		mkdir -p $CA_DIR/certs/serverAuth/
		mkdir -p $CA_DIR/certs/custom/

		openssl req -x509 \
	    		    -sha256 \
				    -days 3560 \
	    		    -nodes \
	    		    -newkey rsa:2048 \
	    		    -keyout $CA_DIR/rootCA.key \
	    		    -out $CA_DIR/rootCA.crt

		cp ca.cnf $CA_DIR
		sed -i "s|<CA_DIR>|$CA_DIR|g" $CA_DIR/ca.cnf

		echo "CA '$CA_DIR' was successfully created."
	
	elif [[ $OPERATION -eq "2" ]]; then

		if [[ $CA_DIR == "" ]]; then
			read -p "CA directory: " CA_DIR
		fi

		echo $CA_DIR
		if ! [ -d $CA_DIR ]; then
			echo "CA directory does not exist."
			exit
		fi

		echo "--------------------------------------|"
		echo "| 1 - Generate ClientAuth Certificate |"
		echo "| 2 - Generate ServerAuth Certificate |"
		echo "| 3 - Generate Custom Certificate     |"
		echo "--------------------------------------|"

		read -p "Option: " OPERATION

		if [[ $OPERATION -eq "1" || $OPERATION -eq "2" || $OPERATION -eq "3" ]]; then
			read -p "Generate private key? [Y/n] " PRIV_KEY_GEN

			if ! [[ $PRIV_KEY_GEN == "Y" || $PRIV_KEY_GEN == "y" ]]; then
				echo
				echo "------------------------|"
				echo "| Signing specified CSR |"
				echo "------------------------|"
				echo

				read -p "CSR file full path: " CSR_FILE_PATH

				if ! [ -f $CSR_FILE_PATH ]; then
					echo "File not located."
					exit
				fi

				if [[ $OPERATION -eq "1" ]]; then
					CERT_EXT="usr_cert"
					CERT_DEST=$CA_DIR/certs/clientAuth
				elif [[ $OPERATION -eq "2" ]]; then
					CERT_EXT="server_cert"
					CERT_DEST=$CA_DIR/certs/serverAuth
				else
					read -p "Custom extension: " CERT_EXT
					CERT_DEST=$CA_DIR/certs/custom
				fi

				CERT_REQ_DIR=$CERT_DEST/cert-request-ts-$(date +%Y-%m-%d_%H_%M_%S)
				mkdir -p $CERT_REQ_DIR

				openssl ca -batch \
	 		   	 		   -notext \
			       		   -extensions $CERT_EXT \
			       		   -in $CSR_FILE_PATH \
				   		   -config $CA_DIR/ca.cnf
			       		   -out $CERT_REQ_DIR/request.crt

			else
				echo
				echo "---------------------------------------------|"
				echo "| Generating Private Key and signing its CSR |"
				echo "---------------------------------------------|"
				echo

				if [[ $OPERATION -eq "1" ]]; then
					CERT_EXT="usr_cert"
					CERT_DEST=$CA_DIR/certs/clientAuth
				elif [[ $OPERATION -eq "2" ]]; then
					CERT_EXT="server_cert"
					CERT_DEST=$CA_DIR/certs/serverAuth
				else
					read -p "Custom extension: " CERT_EXT
					CERT_DEST=$CA_DIR/certs/custom
				fi

				CERT_REQ_DIR=$CERT_DEST/cert-request-ts-$(date +%Y-%m-%d_%H_%M_%S)
				mkdir -p $CERT_REQ_DIR

				openssl req -new \
				            -newkey rsa:2048 \
				    		-nodes \
				    		-keyout $CERT_REQ_DIR/request.key \
				    		-out $CERT_REQ_DIR/request.csr

				openssl ca -batch \
			   	           -notext \
			   	           -extensions $CERT_EXT \
			               -in $CERT_REQ_DIR/request.csr \
				           -config $CA_DIR/ca.cnf \
			               -out $CERT_REQ_DIR/request.crt
			fi

		else
			echo "Invalid option."
			exit
		fi

	elif [[ $OPERATION -eq "3" ]]; then
		exit

	else
		echo "Invalid option."
		exit
	fi
done