from source.networking.UniAppServer import UniAppServer
from source.networking.RequestHandler import RequestHandler
from source.networking.NetworkManager import NetworkManager
from datetime import datetime
import threading
import smtplib
from email.message import EmailMessage
from source.Constants import MENSA_UPDATE_THRESHOLD_WORKING_HOURS, MAP_UPDATE_THRESHOLD, NEWSFEED_UPDATE_THRESHOLD, \
    HELPFUL_NUMBERS_THRESHOLD, SERVER_ADDRESS, SERVER_PORT, ERROR_SLEEP_INT, MAX_RETRY_BEFORE_LONG_WAIT, \
    ERROR_LONG_SLEEP, MENSA_UPDATE_THRESHOLD_NIGHT, DEAD_THREAD_CHECK_INTERVAL
import time
import argparse


def reportError(e, loc):
    now = datetime.now()
    print(str(now) + ": there was an error while updating " + loc + ": " + str(type(e).__name__) + ", " + str(e)
          + "\nRetrying...")


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


class ServerThread(threading.Thread):
    def __init__(self, server: UniAppServer):
        threading.Thread.__init__(self)
        self.server = server

    def run(self):
        self.server.serve_forever()

class TestThread(threading.Thread):
    def __init__(self):
        threading.Thread.__init__(self)

    def run(self):
        time.sleep(10)


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
    serverThread = ServerThread(server)
    serverThread.start()
    while True:
        if mensaUpdateThread.is_alive() is not True:
            mensaUpdateThread = UpdateMensaThread(server, args.verbose)
            mensaUpdateThread.start()
            now = datetime.now()
            print(str(now) + ": restarted mensa thread.")
        if newsFeedUpdateThread.is_alive() is not True:
            newsFeedUpdateThread = UpdateNewsFeedThread(server, args.verbose)
            newsFeedUpdateThread.start()
            now = datetime.now()
            print(str(now) + ": restarted newsfeed thread.")
        if mapUpdateThread.is_alive() is not True:
            mapUpdateThread = UpdateMapThread(server, args.verbose)
            mapUpdateThread.start()
            now = datetime.now()
            print(str(now) + ": restarted map thread.")
        if helpfulNumbersUpdateThread.is_alive() is not True:
            helpfulNumbersUpdateThread = UpdateHelpfulNumbersThread(server, args.verbose)
            helpfulNumbersUpdateThread.start()
            now = datetime.now()
            print(str(now) + ": restarted helpful numbers thread.")
        time.sleep(DEAD_THREAD_CHECK_INTERVAL.total_seconds())