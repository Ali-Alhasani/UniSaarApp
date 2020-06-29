from datetime import datetime
import argparse
import json
import pandas as pd


def edit_links(data):
    no = ['n', 'no', 'N', 'No']
    yes = ['y', 'yes', 'Y', 'Yes']

    while True:
        name = input('Enter link name \n')

        # one cannot have more than one link with the exact same name -- this would be confusing 
        # (vice versa would be okay, though)
        if name in data.name.unique():
            data = handle_duplicate_names(data, name)
            again = input("Do you want to add another link? [y/n] \n")
            if again in no:
                break
            else:
                continue

        link = input('Enter link location \n')
        importance = input('Enter the link importance (lower means more important)\n')
        data = data.append({'name': name, 'link': link, 'importance': importance}, ignore_index=True)


        again = input("Do you want to add another link? [y/n] \n")
        if again in no:
            break;

    return data


def write_to_file(location, to_write):
    """
    :param location, where to write the file
    :param to_write, the dataframe to be written
    :param from_scratch, true if writing from scratch
    return: location where file was written to
    """

    now = datetime.now()
    time_stamp = now.strftime("%Y-%m-%d %H:%M:%S")

    # time_stamp = time.asctime(time.localtime(time.time()))

    if location[-5:] != '.info':
        location += '.info'

    to_write_dict = {'linksLastChanged': time_stamp}

    accepted = ['en', 'fr', 'de']

    while True:
        language = input("What language is this file? [de/en/fr]\n")
        if language in accepted:
            break

    to_write_dict['language'] = language

    to_write_dict['links'] = to_write.to_dict('r')

    data = json.dumps(to_write_dict)

    with open(location, 'w') as f:
        f.write(data)

    print("Successfully wrote to %s" % location)

    return location


def handle_duplicate_names(data, redundant):
    """
    :param data, the dataframe to edit
    :param redundant, the redundant name entry
    :return the updated dataframe
    """
    no = ['n', 'no', 'N', 'No']
    yes = ['y', 'yes', 'Y', 'Yes']

    row_number = data.loc[data['name'] == redundant].index[0]

    while True:
        rewrite = input("the name '%s' is already associated with the link '%s'. Overwrite this entry? [y/n] \n" % (
            redundant, data['link'][row_number]))

        if rewrite in no:
            return data

        elif rewrite in yes:
            data = data.drop(data.index[row_number])
            link = input('Enter link location \n')
            return data.append({'name': redundant, 'link': link}, ignore_index=True)


def write_from_scratch(path):
    """
    :param path, the file location to write to
    :return False if filling the dataframe was unsuccessful, True otherwise
    """

    data = pd.DataFrame(columns=['name', 'link'])
    return edit_links(data)


def delete_links(data):
    while True:

        if data.shape[0] == 0:
            print("no links left to delete!")
            return data
        print("Current links are: \n")
        print(data)
        to_del = input("\n Type a link name to delete that link, or any other phrase to bypass deletion \n")
        try:
            if data.shape[0] == 1:
                data = data.iloc[0:0]
            else:
                attempt = data.loc[data['name'] == to_del]
                row_number = attempt.index[0]
                data = data.drop(data.index[row_number])
            print("Deletion successful \n")
        except (KeyError, IndexError) as e:
            print(e)
            print("Key not found \n")
            pass

        while True:
            next = input("Continue deleting links? [y/n] \n")
            if next in ['n', 'N', 'No', 'NO']:
                return data
            elif next in ['y', 'Y', 'Yes', 'YES']:
                break


def edit_or_delete(data):
    while True:
        next = input("Delete, or otherwise edit links? [d/e] \n")
        if next in ['d', 'D']:
            data = delete_links(data)
            return data
        elif next in ['e', 'E']:
            data = edit_links(data)
            return data


def offer_to_edit(data, path):
    """
    :param data, to be edited
    """

    yes = ['y', 'yes', 'Y', 'Yes']
    no = ['n', 'no', 'N', 'No']

    while True:
        next = input("Edit or display links? [e/d] \n")
        if next in ['e', 'E', 'edit', 'Edit']:
            data = edit_or_delete(data)
            next = input("Write to file? [y/n] \n")
            while True:
                if next in yes:
                    write_to_file(path, data)
                    return
                elif next in no:
                    break

        elif next in ['d', 'D', 'display', 'Display']:
            print(data)
            next = input("Continue? [y/n] \n")
            if next in no:
                print("Exiting... \n")
                return

            elif next in yes:
                continue


def main(args):
    no = ['n', 'no', 'N', 'No', 'quit', 'next']
    yes = ['y', 'yes', 'Y', 'Yes']

    # check if file exists
    try:
        f = open(args.path)
        f.close()

    except IOError:
        while True:
            next = input("File not found. Write a new file? [y/n] \n")
            if next in no:
                print("Exiting...\n")
                return
            elif next in yes:
                data = write_from_scratch(args.path)
                write_to_file(args.path, data)
                next = input("Continue? [y/n] \n")

                while True:
                    if next in yes:
                        offer_to_edit(data, args.path)
                        return
                    elif next in no:
                        print("Exiting...\n")
                        return

    # previous file found. Read in, then determine next step
    try:
        as_dict = json.load(open(args.path))
        data = pd.DataFrame.from_dict(as_dict["links"])
        # data = pd.read_json(all_data, orient = 'index')

    # if unable to read in the current json, ask if the user wants to rewrite

    except ValueError as e:

        print(e)

        while True:

            str = "Unable to read file. Overwrite with new file? [y/n] \n"

            # overwriting won't happen if the path doesn't end with '.info'
            if args.path[-5:] != '.info':
                str = "Unable to read file. Write new file? [y/n] \n"

            next = input(str)
            if next in no:
                print("Exiting... \n")
                return
            elif next in yes:
                data = write_from_scratch(args.path)
                write_to_file(args.path, data)
                next = input("Continue? [y/n] \n")
                while True:
                    if next in yes:
                        offer_to_edit(data, args.path)
                        return
                    elif next in no:
                        print("Exiting...\n")
                        return

    print("Successfully read file")
    offer_to_edit(data, args.path)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Interactive writer for files listing "More" links. '
                                                 'Prompts the user for input.')
    parser.add_argument('-p', '--path', required=True, type=str, help='The location of the file to create/edit.')
    args = parser.parse_args()

    main(args)
