import argparse
import json
from os.path import join


def main(args):
    helpfulNumbers = []

    language = input("Please enter the language used for this data (use language codes like de, en or fr): ")
    print("Remember to create a file for each language you want to support.")

    while True:
        number = input("Please enter a helpful number: ")

        link = ""
        linkYN = input("Do you want to add an associated link? [y/N]")
        if linkYN in ['y']:
            link = input("Please enter the link: ")

        mail = ""
        mailYN = input("Do you want to add an associated email address? [y/N]")
        if mailYN in ['y']:
            mail = input("Please enter the email address: ")

        name = input("Please enter the name for this helpful number: ")

        helpfulNumbers.append({'number': number, 'link': link, 'mail': mail, 'name': name})

        again = input("Do you want to add another helpful number? [y/N]")
        if again in ['', 'N']:
            break

    filename = 'helpfulNumbers_' + language + '.info'

    with open(join(args.path, filename), 'w') as f:
        data = json.dumps({'language': language, 'numbers': helpfulNumbers})
        f.write(data)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Interactive writer for helpfulNumber files. '
                                                 'Prompts the user for input.')
    parser.add_argument('-p', '--path', required=True, type=str, help='The path where to store files.')
    args = parser.parse_args()

    main(args)
