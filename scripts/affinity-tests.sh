#!/bin/bash

source /home/stack/overcloudrc
echo

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|    Start of Affinity-Different-Computes.sh     |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

bash affinity-different-computes.sh

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|     End of Affinity-Different-Computes.sh      |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

echo 
echo -e "**************************************************"
echo

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|         Start of Affinity-Evacuate.sh          |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

bash affinity-evacuate.sh

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|          End of Affinity-Evacuate.sh           |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

echo 
echo -e "**************************************************"
echo

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|          Start of Affinity-Migrate.sh          |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

bash affinity-migrate.sh

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|           End of Affinity-Migrate.sh           |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

echo
echo -e "**************************************************"
echo

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|          Start of Affinity-Rebuild.sh          |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

bash affinity-rebuild.sh

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|           End of Affinity-Rebuild.sh           |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

echo
echo -e "**************************************************"
echo

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|  Start of Anti-Affinity-Different-Computes.sh  |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

bash anti-affinity-different-computes.sh

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|   End of Anti-Affinity-Different-Computes.sh   |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

echo
echo -e "**************************************************"
echo

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|      Start of Anti-Affinity-Evacuate.sh        |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

bash anti-affinity-evacuate.sh

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|       End of Anti-Affinity-Evacuate.sh         |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

echo
echo -e "**************************************************"
echo

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|       Start of Anti-Affinity-Migrate.sh        |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

bash anti-affinity-migrate.sh

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|        End of Anti-Affinity-Migrate.sh         |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

echo
echo -e "**************************************************"
echo

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|       Start of Anti-Affinity-Rebuild.sh        |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

bash anti-affinity-rebuild.sh

echo -e "+------------------------------------------------+"
echo -e "|                                                |"
echo -e "|        End of Anti-Affinity-Rebuild.sh         |"
echo -e "|                                                |"
echo -e "+------------------------------------------------+"

echo
echo -e "**************************************************"
echo

