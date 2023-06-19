## MAIN: RUNS THE APPLICATION AND ACT AS A CONTROLLER
## TRANG DO, REN CORR, MORGAN SPENCER
## PYTHON USING PYMYSQL CONNECTION

## ####################################################################

import method


#############################################################################################

# Welcome message
print("Welcome to library managment application\n")

print("\nConnecting to the database...\n")

# create the method object (which is the controller)
# also establish a connection to the MySQL server
method = method.Method()

# Display the list of supported commands

# Process input
while method.isRunning:
    method.processComms()

# Disconnect from the database
method.disconnectDB()