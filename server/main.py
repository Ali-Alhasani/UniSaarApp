from source.networking.UniAppServer import UniAppServer
from source.networking.RequestHandler import RequestHandler
from source.networking.NetworkManager import NetworkManager
from datetime import datetime
import threading
import smtplib
from email.message import EmailMessage
from source.Constants import MENSA_UPDATE_THRESHOLD_WORKING_HOURS, MAP_UPDATE_THRESHOLD, NEWSFEED_UPDATE_THRESHOLD, \
    HELPFUL_NUMBERS_THRESHOLD, SERVER_ADDRESS, SERVER_PORT, ERROR_SLEEP_INT, MAX_RETRY_BEFORE_LONG_WAIT, \
    ERROR_LONG_SLEEP, MENSA_UPDATE_THRESHOLD_NIGHT
import time
import argparse


def reportError(e, loc):
    print("there was an error while updating " + loc + ": " + str(e) + "\nRetrying...")
    #msg = EmailMessage()
    #msg.set_content("there was an error while updating " + loc + ": " + str(e) + "\nRetrying...")
    #msg['Subject'] = "Error in Uni Saar App Server"
    #msg['From'] = 'julien@schanz-stade.de'
    #msg['To'] = 'julien@schanz-stade.de'

    #s = smtplib.SMTP('localhost')
    #s.send_message(msg)
    #s.quit()


class UpdateMensaThread(threading.Thread):
    def __init__(self, server: UniAppServer, verbose: bool):
        threading.Thread.__init__(self)
        self.server = server
        self.verbose = verbose

    def run(self):
        unsuccesfulTries = 0
        while True:
            try:
                self.server.updateMensa()
            except Exception as e:
                unsuccesfulTries = unsuccesfulTries + 1
                reportError(e, "mensa")
                if unsuccesfulTries > MAX_RETRY_BEFORE_LONG_WAIT:
                    time.sleep(ERROR_LONG_SLEEP)
                else:
                    time.sleep(ERROR_SLEEP_INT)
                continue
            unsuccesfulTries = 0
            if self.verbose:
                now = datetime.now()
                print(str(now) + ': updated mensa')
            h = datetime.now().hour
            if h < 8 or h > 20:
                time.sleep(MENSA_UPDATE_THRESHOLD_NIGHT.total_seconds())
            else:
                time.sleep(MENSA_UPDATE_THRESHOLD_WORKING_HOURS.total_seconds())


class UpdateNewsFeedThread(threading.Thread):
    def __init__(self, server: UniAppServer, verbose: bool):
        threading.Thread.__init__(self)
        self.server = server
        self.verbose = verbose

    def run(self):
        unsuccesfulTries = 0
        while True:
            try:
                self.server.updateNewsFeed()
            except Exception as e:
                unsuccesfulTries = unsuccesfulTries + 1
                reportError(e, "newsfeed")
                if unsuccesfulTries > MAX_RETRY_BEFORE_LONG_WAIT:
                    time.sleep(ERROR_LONG_SLEEP)
                else:
                    time.sleep(ERROR_SLEEP_INT)
                continue
            if self.verbose:
                now = datetime.now()
                print(str(now) + ': updated newsfeed')
            time.sleep(NEWSFEED_UPDATE_THRESHOLD.total_seconds())


class UpdateMapThread(threading.Thread):
    def __init__(self, server: UniAppServer, verbose: bool):
        threading.Thread.__init__(self)
        self.server = server
        self.verbose = verbose

    def run(self):
        while True:
            try:
                self.server.updateMap()
            except Exception as e:
                reportError(e, "map")
                time.sleep(ERROR_SLEEP_INT)
                continue
            if self.verbose:
                now = datetime.now()
                print(str(now) + ': updated map')
            time.sleep(MAP_UPDATE_THRESHOLD.total_seconds())


class UpdateHelpfulNumbersThread(threading.Thread):
    def __init__(self, server: UniAppServer, verbose: bool):
        threading.Thread.__init__(self)
        self.server = server
        self.verbose = verbose

    def run(self):
        while True:
            try:
                self.server.updateHelpfulNumbers()
            except Exception as e:
                reportError(e, "helpful numbers")
                time.sleep(ERROR_SLEEP_INT)
                continue
            if self.verbose:
                now = datetime.now()
                print(str(now) + ': updated helpful numbers')
            time.sleep(HELPFUL_NUMBERS_THRESHOLD.total_seconds())


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='UniSaarApp Server. '
                                                 'See the README on the Github for more information.')
    parser.add_argument('-v', '--verbose', action="store_true", help='Prints update messages.')
    args = parser.parse_args()

    nm = NetworkManager()
    server = UniAppServer((SERVER_ADDRESS, SERVER_PORT), RequestHandler, nm)
    mensaUpdateThread = UpdateMensaThread(server, args.verbose)
    newsFeedUpdateThread = UpdateNewsFeedThread(server, args.verbose)
    mapUpdateThread = UpdateMapThread(server, args.verbose)
    helpfulNumbersUpdateThread = UpdateHelpfulNumbersThread(server, args.verbose)
    mensaUpdateThread.start()
    newsFeedUpdateThread.start()
    mapUpdateThread.start()
    helpfulNumbersUpdateThread.start()
    server.serve_forever()
