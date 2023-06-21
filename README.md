# CS3200-LibraryDB
CS 3200 Final Project by Trang Do, Ren Corr and Morgan Spencer

## Building Specifications
### Required Programming Languages
- Python (**needs to be at least 3.10**)
- SQL

### Required Libraries
- PyMySQL
- Pandas
- bs4
- requests
- time

### Required Software
- MySQL Workbench for reading the SQL codebase
- Visual Studio Code/IntelliJ or similar developing tools for viewing and building the application (Refer to section *Instructions on Building*)
- Terminal/Command Line for running the application

### Expected Files
- **libraryDQ.sql** : contains the code for building the library database (backend)
- **main.py** : contains the code for running the application overall (frontend)
- **method.py** : contains the code for the controller of the application along with the supported commands (frontend)
- **data.py** : example of data scraping from the web for book's author and title

### Instructions on building
- Build the database *libraryDB.sql* in MySQL Workbench with your personal account
- Change the log in credentials in the file *method.py* to the credentials of the MySQL server which you used to build the database
    - This can be found in the method *connectDB* towards the top of the file, within the assignment of the variable *cnx*
    - We intentionally hidden the server login in the code instead of making it available to the user as in real life, the user would not hook the server up on their own

## Current UML Diagram of the Project
> insert diagram img here

## User's Work Flow using this Application
![Image of User's Workflow](/image/final_user_diagram.png)

### Supported Commands for Patron
- **exit()** : exits the application
- **booksAvailable()** : shows all books available for immediate checking out from the library database
- **createHold()** : creates a hold on a currently checked-out book give the book's ID
- **bookCheckout()** : checks out an available book given its ID
- **returnBook()** : returns a currently checked out book given its ID
- **booksBorrowed()** : shows all books which are currently borrowed by the user
- **bookInfo()** : shows all info on the desired book given its ID
- **showComms()** : shows all supported commands in the application
- **createUser()** : sign up as a new user to the application
- **deleteUser()** : remove a user from the application (to be implemented)

### Supported Commands for Librarian
- **addBook()** : add a new book to the application given all necessary information regarding the book (to be implemented)
- **removeBook()** : remove a book from the application given the book's ID (to be implemented)

### Hidden Supported Commands for User
- **login()** : log into the application given the user's id (patron only) or username and password (librarian only)

## Lessons Learned
### Technical Expertise Gained
- Coding in Python and SQL while being able to integrate both to create an interactable database program

### Insights

### Contemplations/Considerations on the Approach of the Project

### Code not Working in the Project

## Future Work
### Planned Uses of the Database
- Example work to demonstrate understanding and application of Python and SQL

### Potential Future Functionalities
- Working GUI for a more visual experience
- Functional data scrapping to populate the database with more meaningful data in a more effective way
- Sample reviews online can be collected via online queries through the application

