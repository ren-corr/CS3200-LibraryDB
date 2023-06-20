from bs4 import BeautifulSoup
import requests
import time

book_data = []

for page in range(1, 7):
    url = f'https://bpl.bibliocommons.com/v2/search?f_AUDIENCE=adult&f_FORMAT=BK%7CLPRINT%7CGRAPHIC_NOVEL%7CPAPERBACK&f_ON_ORDER=true&locked=false&query=new%20books%20&searchScope=BPL&searchType=catalogue&sort=newly_acquired&title=Books%20on%20Order&page={page}'
    req = requests.get(url)
    content = req.text

    soup = BeautifulSoup(content, "html.parser")

    # Example: Extract book titles
    books = soup.find_all("div", class_="cp-deprecated-bib-brief")
    # print(books)

    for book in books:
        title = book.find("span", class_="title-content").text.strip()
        author = book.find("a", class_="author-link").text.strip()
        book_data.append({"title": title, "author": author})

    time.sleep(1)

# Print the scraped data
for book in book_data:
    print("Title:", book["title"])
    print("Author:", book["author"])
    print()