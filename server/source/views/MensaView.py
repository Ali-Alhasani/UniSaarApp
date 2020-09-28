import json
from source.models.MensaModel import MensaModel, Meal, Counter, ServingDay
from datetime import datetime


def weekdayToString(day: int, language: str) -> str:
    """
    Returns a weekday name for a given day (0 = Monday, 6 = Sunday)
    @param day: int, day of the week
    @param language: str, language code
    @return: string
    """
    if language == 'de':
        if day == 0:
            return 'Montag'
        elif day == 1:
            return 'Dienstag'
        elif day == 2:
            return 'Mittwoch'
        elif day == 3:
            return 'Donnerstag'
        elif day == 4:
            return 'Freitag'
        elif day == 5:
            return 'Samstag'
        elif day == 6:
            return 'Sonntag'
    elif language == 'fr':
        if day == 0:
            return 'Lundi'
        elif day == 1:
            return 'Mardi'
        elif day == 2:
            return 'Mercredi'
        elif day == 3:
            return 'Jeudi'
        elif day == 4:
            return 'Vendredi'
        elif day == 5:
            return 'Samedi'
        elif day == 6:
            return 'Dimanche'
    else:
        if day == 0:
            return 'Monday'
        elif day == 1:
            return 'Tuesday'
        elif day == 2:
            return 'Wednesday'
        elif day == 3:
            return 'Thursday'
        elif day == 4:
            return 'Friday'
        elif day == 5:
            return 'Saturday'
        elif day == 6:
            return 'Sunday'

class MensaView:

    def timeIntervalToStr(self, timeInterval: tuple) -> str:
        """
        Converts a pair of datetime to a readable string of the form 'HH:MM - HH:MM'
        @param timeInterval: tuple of datetime
        @return: str
        """
        time1 = timeInterval[0]
        time2 = timeInterval[1]
        return '{t1.hour:02}:{t1.minute:02} - {t2.hour:02}:{t2.minute:02}'.format(t1=time1, t2=time2)

    def dateToStr(self, date: datetime, language: str = 'de') -> str:
        """
        Converts a datetime object to a readable string of the form 'Weekday DD.MM.'
        @param date: datetime
        @param language: string (optional, default 'de'),
                        language code for the language in which the weekday will be written
        @return: str
        """
        return '{w} {d.day:02}.{d.month:02}.'.format(w=weekdayToString(date.weekday(), language), d=date)

    def mealGeneralToJSON(self, meal: Meal, counter: Counter, language: str = 'de') -> dict:
        """
        Creates a dictionary of a Meal to be packed into a JSON.
        @param meal: Meal object
        @param counter: Counter, the counter at which the meal is served
        @param language: str (optional, default 'de'), a language code
        @return: a dictionary of the form:
            { "id": id (int),
              "mealName": mealName (str),
              "counterName": counterName (str),
              "openingHours": openingHours (str),
              "color": { "r": r, "g": g, "b": b },
              "components": [ component1, component2, ... ] (str),
              "notices": [ noticeID1, noticeID2, ... ] (str),
              "prices": [ { "priceTag": priceTierName (str), "price": price (float) }, ... ],
              "pricingNotice": pricingNotice (str)
            }
            where "prices" and "pricingNotice" are mutually exclusive and optional
        """
        openingHours = counter.getOpeningHours()
        stringOpeningHours = self.timeIntervalToStr(openingHours) if openingHours is not None else ""

        color = counter.getColor()
        colorDict = color.getDict() if color is not None else {}

        mealDict = {"id": meal.getID(), "mealName": meal.getName(), "counterName": counter.getName(),
                    "openingHours": stringOpeningHours,
                    "color": colorDict,
                    "components": [component.getName() for component in meal.getComponents()]}

        # collect all notices both of the meal itself as well as of the individual components
        mealNotices = set()
        for notice in meal.getNotices():
            mealNotices.add(notice.getID())
        for component in meal.getComponents():
            for notice in component.getNotices():
                mealNotices.add(notice.getID())
        mealDict["notices"] = list(mealNotices)

        # get the price information if available
        if meal.getPricingNotice() is None:
            priceDict = meal.getPrices()
            if priceDict is not None:
                # use the price dictionary
                mealDict["prices"] = \
                    [{"priceTag": priceTier.getName(), "price": '{:.2f}'.format(price)}
                     for priceTier, price in priceDict.items()]
        else:
            # use the pricing notice
            mealDict["pricingNotice"] = meal.getPricingNotice()

        return mealDict

    def servingDayToJSON(self, servingDay: ServingDay, language: str = 'de') -> dict:
        """
        Creates a dictionary of a ServingDay to be packed to JSON
        @param servingDay: ServingDay object
        @param language: str (optional, default 'de'), a language code
        @return: a dictionary of the form:
            { "date": date (str),
              "meals": [ { "id": id (int),
                         "mealName": mealName (str),
                         "counterName": counterName (str),
                         "openingHours": openingHours (str),
                         "color": { "r": r, "g": g, "b": b },
                         "components": [ component1, component2, ... ] (str),
                         "notices": [ noticeID1, noticeID2, ... ] (str)
                         "prices": [ { "priceTag": priceTierName (str), "price": price (float) }, ... ],
                         "pricingNotice": pricingNotice (str)
                         }, { ... }, ...
                     ]
            }
            where for each meal prices and pricingNotice are mutually exclusive and optional
        """
        day = {'date': self.dateToStr(servingDay.getDate(), language), "meals": []}

        # add all meals from across all counters of that servingDay
        for counter in servingDay.getCounters():
            for meal in counter.getMeals():
                day["meals"].append(self.mealGeneralToJSON(meal, counter, language))

        return day

    def mensaMainScreenJSON(self, mensaModel: MensaModel, locationID: str = 'sb', language: str = 'de',
                            date: datetime = None) -> str:
        """
        Creates a JSON for a request for the mensa main screen from a MensaModel. The request should contain location,
        language and date as parameters.
        locationID, language and date are optional. If date is None, all available dates will be packed.
        @param mensaModel: MensaModel, the model containing the data.
        @param locationID: str (optional, default 'sb'), the location's ID
        @param language: str (optional, default 'de'), a language code
        @param date: datetime (optional, default 'None'), the date for which the data is required
        @return: a JSON of the form:
            { "days":
                [ { "date": date (str),
                    "meals": [ { "id": id (int),
                                 "mealName": mealName (str),
                                 "counterName": counterName (str),
                                 "openingHours": openingHours (str),
                                 "color": { "r": r, "g": g, "b": b },
                                 "components": [ component1, component2, ... ] (str),
                                 "notices": [ noticeID1, noticeID2, ... ] (str),
                                 "prices": [ { "priceTag": priceTierName (str), "price": price (float) }, ... ],
                                 "pricingNotice": pricingNotice (str) },
                               { ... }, ...
                             ]
                  }, { ... }, ...
                ],
              "filtersLastChanged": filtersLastChanged (str)
            }
            where for each meal prices and pricingNotice are mutually exclusive and optional
        """
        location = mensaModel.getLocation(locationID, language)
        days = []
        requestedDates = location.getMenu(date=date)  # list of ServingDays fitting date or all ServingDays available

        for servingDay in requestedDates:
            days.append(self.servingDayToJSON(servingDay=servingDay, language=language))

        returnDict = {'days': days, 'filtersLastChanged': str(mensaModel.getFiltersLastChanged(language))}

        return json.dumps(returnDict, separators=(',', ':'))  # remove ws after separator for compact representation

    def mealDetailToJSON(self, mensaModel: MensaModel, mealID: int, language: str = 'de') -> str:
        """
        Creates a JSON for a request for a meal detail from a MensaModel. The request should contain a mealID, the
        meal's location and language.
        The language is optional.
        @param mensaModel: MensaModel, the model containing the data
        @param mealID: int, the meal's ID
        @param language: str (optional, default 'de'), a language code
        @return: a JSON of the form:
            { "mealName": name (str),
              "description": counterDescription (str),
              "color": { "r": r, "g": g, "b": b },
              "generalNotices": [ { "notice": noticeID (str), "displayName": name (str) }, ... ],
              "prices": [ { "priceTag": priceTierName (str), "price": price (float) }, ... ],
              "pricingNotice": pricingNotice (str)
              "mealComponents": [ { "componentName": name (str),
                                    "notices": [ { "notice": noticeID (str), "displayName": name (str) }, ... ], ... ]
            }

            where "prices" and "pricingNotice" are mutually exclusive and optional
        """
        meal, counter = mensaModel.getMealAndCounter(mealID, language)

        mealJSON = {"mealName": meal.getName(), "description": counter.getDescription(),
                    "color": counter.getColor().getDict()}

        generalNotices = [{"notice": notice.getID(), "displayName": notice.getName()} for notice in meal.getNotices()]
        mealJSON["generalNotices"] = generalNotices

        if meal.getPricingNotice() is None:
            priceDict = meal.getPrices()
            if priceDict is not None:
                # use the price dictionary
                mealJSON["prices"] = \
                    [{"priceTag": priceTier.getName(), "price": '{:.2f}'.format(price)}
                     for priceTier, price in priceDict.items()]
        else:
            # use the pricing notice
            mealJSON["pricingNotice"] = meal.getPricingNotice()

        mealComponents = [{"componentName": component.getName(),
                           "notices": [{"notice": notice.getID(),
                                        "displayName": notice.getName()} for notice in component.getNotices()]}
                          for component in meal.getComponents()]
        mealJSON["mealComponents"] = mealComponents

        return json.dumps(mealJSON, separators=(',', ':'))  # remove ws after separator for compact representation

    def mensaInfoToJSON(self, mensaModel: MensaModel, locationID: str, language: str = 'de') -> str:
        """
        Creates a JSON for a request for mensa information from a MensaModel. The request should contain a locationID
        and a language. The language is optional.
        @param mensaModel: MensaModel, the model containing the data
        @param locationID: str, the location's ID
        @param language: str (optional, default 'de'), a language code
        @return: a JSON of the form:
            { "name": name (str), "description": description (str), "imageLink": imagelink (str) }
        """
        locationInfo = mensaModel.getLocationInfo(locationID, language)

        locationInfoJSON = {"name": locationInfo.getName(), "description": locationInfo.getDescription(),
                            "imageLink": locationInfo.getImageLink()}

        # remove ws after separator for compact representation
        return json.dumps(locationInfoJSON, separators=(',', ':'))

    def mensaFilterToJSON(self, mensaModel: MensaModel, language: str = 'de') -> str:
        """
        Creates a JSON for a request for the mensa filters from a MensaModel. The request can contain a language.
        @param mensaModel: MensaModel, the model containing the data
        @param language: str (optional, default 'de'), a language code
        @return: a JSON of the form:
            { "locations": [ { "locationID": locationID (str), "name": name (str) }, ... ],
              "notices": [ { "noticeID": noticeID (str), "name": name (str),
                             "isAllergen": isAllergen (bool), "isNegated": isNegated (bool) }, ... ] }
        """
        # Since Prof Zeller only wants to see the locations "sb" and "hom",
        # the mensa filter only returns these locations. To change this, remove the conditional in the following list
        # comprehension
        notices = sorted(mensaModel.getNotices(language=language), key=lambda x: x.getName())
        locationList = [{"locationID": location.getID(), "name": location.getName()}
                        for location in mensaModel.getLocations(language=language) if location.getID() in ["sb", "hom"]]
        filterJSON = {"locations": locationList,
                      "notices": [{"noticeID": notice.getID(), "name": notice.getName(),
                                   "isAllergen": notice.getIsAllergen(), "isNegated": notice.getIsNegated()}
                                  for notice in notices]}

        return json.dumps(filterJSON, separators=(',', ':'))  # remove ws after separator for compact representation
