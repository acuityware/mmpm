.NOTPARALLEL:

all: clean dependencies build install

clean:
	@printf -- "-----------------------------------------"
	@printf "\n| \e[92mRemoving old installation destination\e[0m |"
	@printf "\n-----------------------------------------\n"
	sudo rm -f /usr/local/bin/mmpm

dependencies: dependencies-gui

dependencies-cli:
	@printf -- "------------------------------"
	@printf "\n| \e[92mGathering CLI dependencies\e[0m |"
	@printf "\n------------------------------\n"
	@pip3 install -r requirements.txt --user

dependencies-gui:
	@printf -- "------------------------------"
	@printf "\n| \e[92mGathering GUI dependencies\e[0m |"
	@printf "\n------------------------------\n"
	@sudo apt install nginx nginx-extras -y
	@sudo service nginx start
	@sudo systemctl status --no-pager nginx
	@npm install -g @angular/cli
	@npm install --prefix gui

build: build-cli build-gui

build-cli:
	# nothing yet for this, but keeping for consistency sake

build-gui:
	@printf -- "---------------------"
	@printf "\n| \e[92mBuilding MMPM GUI\e[0m |"
	@printf "\n---------------------\n"
	@cd gui && ng build --prod --deploy-url static/

install: install-cli install-gui

install-cli:
	@printf -- "------------------------"
	@printf "\n| \e[92mInstalling MMPM CLI \e[0m |"
	@printf "\n------------------------\n"
	@pip3 install --user .
	@printf -- "-------------------------------------------------------"
	@printf "\n| \e[92mNOTE: Ensure \"${HOME}/.local/bin\" is in your PATH\e[0m |"
	@printf "\n-------------------------------------------------------\n"

install-gui:
	@printf -- "------------------------"
	@printf "\n| \e[92mInstalling MMPM GUI \e[0m |"
	@printf "\n------------------------\n"
	@sudo mkdir -p /var/www/mmpm/templates && \
		sudo cp -r gui/build/static /var/www/mmpm && \
		sudo cp /var/www/mmpm/static/index.html /var/www/mmpm/templates
	@[ ! $? ] && printf "\n\033[1;36mMMPM Successfully Installed \e[0m\n"
	@[ ! $? ] && printf "\nThe MMPM GUI is being served the IP address of your default interface at port 8091"
	@[ ! $? ] && printf "\nBest guess: http://$$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p'):8091\n\n"
	@printf -- "------------------------------------------------------------------------"
	@printf "\n| \e[92mNOTE: Ensure your ufw (firewall) settings allow ports 8090 and 8091 \e[0m |"
	@printf "\n------------------------------------------------------------------------\n"

uninstall: uninstall-cli uninstall-gui

uninstall-cli:
	@printf -- "----------------------"
	@printf "\n| \e[92mRemoving MMPM CLI \e[0m |"
	@printf "\n----------------------\n"
	@pip3 uninstall mmpm -y

uninstall-gui:
	@printf -- "----------------------"
	@printf "\n| \e[92mRemoving MMPM GUI \e[0m |"
	@printf "\n----------------------\n"
	rm $$HOME/.config/mmpm/configs/gunicorn.conf.py
	sudo systemctl stop mmpm.service
	sudo systemctl disable mmpm.service
	sudo rm /etc/systemd/system/mmpm.service
	sudo systemctl daemon-reload
	sudo systemctl reset-failed
	sudo rm -rf /var/www/mmpm
	sudo rm -rf /etc/nginx/sites-enabled/mmpm.conf
	sudo rm -rf /etc/nginx/sites-available/mmpm.conf
	sudo service nginx restart
	@[ ! $? ] && printf "\n\033[1;36mSuccessfully Removed MMPM \e[0m\n"
