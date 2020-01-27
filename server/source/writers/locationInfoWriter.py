import argparse
import json
from os.path import join


def main(args):
    name = {}
    desc = {}
    languages = []

    id = input('Enter the locationID: ')
    image = input("Enter a link to an image of the location: ")

    while True:
        language = input("State the language in which you will specify the location info. "
                         "Please use a language code (i.e. en, de, fr): ")
        if language in languages:
            print('The language has been used already, please enter a different language.')
            continue

        languages.append(language)
        name[language] = input("Enter the location's name: ")
        desc[language] = input("Enter the location's description: ")

        again = input("Do you want to add data in another language? [y/N]")
        if again in ['', 'N']:
            break

    filename = id + '.info'

    with open(join(args.path, filename), 'w') as f:
        data = json.dumps({'id': id, 'image': image,
                           'langData': [{'lang': lang, 'name': name[lang], 'description': desc[lang]}
                                        for lang in languages]})
        f.write(data)


if __name__=='__main__':
    parser = argparse.ArgumentParser(description='Interactive writer for locationInfo files. '
                                                 'Prompts the user for input.')
    parser.add_argument('-p', '--path', required=True, type=str, help='The path where to store files.')
    args = parser.parse_args()

    main(args)
