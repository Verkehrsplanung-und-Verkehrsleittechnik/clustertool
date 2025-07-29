import logging

import pandas as pd
import numpy as np
import holidays
## @package calendar_attributes
#  @brief This module provides functionalities for handling calendar-related attributes.
#
#  The `calendar_attributes` module defines the `CalendarAttributes` class, which manages
#  date-related attributes such as public holidays, school holidays, weekdays, months,
#  and seasonal classifications. It also includes methods for fetching school holidays
#  from an API and processing holiday data.
#
#  **Main functionalities:**
#  - **Calendar Attribute Management:**
#    - `CalendarAttributes`: Class for handling date-related properties such as holidays, weekdays, and seasons.
#    - `translate_attributes()`: Translates attribute names to German (if applicable).
#  - **Holiday & Workday Handling:**
#    - `import_bank_holidays()`: Loads bank holidays for a given country/state.
#    - `import_school_holidays()`: Loads school holidays from local files or an API.
#    - `fill_workdays()`: Determines workdays based on weekends and public holidays.
#    - `fill_bridging_days()`: Identifies bridging days between holidays and weekends.
#  - **Season & Time Classification:**
#    - `fill_summertime()`: Identifies summer and wintertime periods.
#    - `fill_season()`: Assigns meteorological or astronomical seasons to dates.
#  - **School Holiday API Integration:**
#    - `fetch_holidays_from_api()`: Fetches school holidays from an online API.
#    - `query_school_holidays()`: Retrieves school holidays for specific years and states.
#
#  @author MaS, based on Matlab CLustertool, supported by GPT
#  @date 2025
#
#  @note This module supports multi-language attributes (currently German & English).

from pathlib import Path
import urllib.request
import json
import time
from datetime import datetime, timedelta

## @class CalendarAttributes
#  @brief Manages calendar-related operations, including holidays, weekdays, and date filtering.
#
#  The `CalendarAttributes` class provides functionality for determining public and school
#  holidays, weekdays, months, seasons, and workdays. It integrates with APIs to fetch
#  school holidays dynamically and supports localization for German and English.
class CalendarAttributes:
    ## @brief Initializes the CalendarAttributes object.
    #  @param list_datetimes A list of datetime objects to be analyzed.
    #  @param dir_data_holidays Path to the directory containing holiday data (optional).
    #  @param language Language for attribute names ('de' for German, 'en' for English).
    #  @param country The country code (default: "DE" for Germany).
    #  @param state The state code (default: "BW" for Baden-Württemberg).
    #  @param dummy If True, skips holiday and calendar calculations.
    def __init__(self, list_datetimes: list, dir_data_holidays: Path = None, language: str = "de",
                 country: str = "DE", state: str = "BW", dummy: bool = False):

        ## @var dates
        #  A Pandas Series containing all dates to be analyzed.
        self.dates = pd.to_datetime(list_datetimes)

        ## @var years
        #  A list of unique years present in the dataset.
        self.years = self.dates.year.unique()

        ## @var country
        #  The country code for holiday retrieval (default: "DE").
        self.country = country

        ## @var state
        #  The state code for regional holidays (default: "BW").
        self.state = state

        ## @var language
        #  The selected language for calendar attributes.
        self.language = language

        ## @var format_date
        #  The default date format used for processing.
        self.format_date = "%Y-%m-%d"

        ## @var bank_holidays
        #  Dictionary mapping bank holiday names to their dates.
        self.bank_holidays = dict()

        ## @var school_holidays
        #  Dictionary mapping school holiday names to their dates.
        self.school_holidays = dict()

        ## @var summertime
        #  Dictionary mapping summer/winter time periods.
        self.summertime = dict()

        ## @var season
        #  Dictionary mapping seasons to corresponding dates.
        self.season = dict()

        ## @var weekday
        #  Dictionary mapping weekdays to corresponding dates.
        self.weekday = dict()

        ## @var month
        #  Dictionary mapping months to corresponding dates.
        self.month = dict()

        ## @var bridging_day
        #  Dictionary mapping bridging days (Brückentage).
        self.bridging_day = dict()

        ## @var workday
        #  Dictionary mapping workdays and non-workdays.
        self.workday = dict()

        if not dummy:

            self.file_path_holiday_data = dir_data_holidays
            logging.info(f"Pfad Daten Kalender: {self.file_path_holiday_data}")
            logging.info("Start Import Feiertage")
            self.import_bank_holidays()
            logging.info(f"Start Import Ferien")

            self.import_school_holidays()
            self.fill_summertime()
            self.fill_season(season_type="meteorological")
            self.fill_weekday()
            self.fill_month()
            self.fill_workdays()
            self.fill_bridging_days()

        self.translate_attributes()

    ## @brief Translates attribute names to German if the selected language is 'de'.
    #
    # This method updates the internal attribute dictionaries to use German names if
    # the language setting is "de". It ensures that all attribute keys are localized,
    # while maintaining their respective values.
    #
    # If the language is not "de", the method does nothing.
    #
    # Translated attributes include:
    # - Seasons (e.g., "spring" → "Frühling")
    # - Weekdays (e.g., "Monday" → "Montag")
    # - Months (e.g., "January" → "Januar")
    # - Calendar-related terms (e.g., "bridging day" → "Brückentag")
    #
    # Additionally, it creates German aliases for internal dictionaries:
    # - `self.feiertage` → `self.bank_holidays`
    # - `self.ferien` → `self.school_holidays`
    # - `self.sommerzeit` → `self.summertime`
    # - `self.jahreszeit` → `self.season`
    # - `self.wochentag` → `self.weekday`
    # - `self.monat` → `self.month`
    # - `self.brueckentag` → `self.bridging_day`
    # - `self.arbeitstag` → `self.workday`
    #
    # @return None
    def translate_attributes(self):
        if self.language == "de":
            translation = {
                "summertime": "Sommerzeit",
                "wintertime": "Winterzeit",
                "winter": "Winter",
                "spring": "Frühling",
                "summer": "Sommer",
                "autumn": "Herbst",
                "Monday": "Montag",
                "Tuesday": "Dienstag",
                "Wednesday": "Mittwoch",
                "Thursday": "Donnerstag",
                "Friday": "Freitag",
                "Saturday": "Samstag",
                "Sunday": "Sonntag",
                "January": "Januar",
                "February": "Februar",
                "March": "März",
                "April": "April",
                "May": "Mai",
                "June": "Juni",
                "July": "Juli",
                "August": "August",
                "September": "September",
                "October": "Oktober",
                "November": "November",
                "December": "Dezember",
                "bridging day": "Brückentag",
                "no bridging day": "kein Brückentag",
                "workday": "Werktag",
                "no workday": "kein Werktag",
            }

            self.summertime = {translation.get(k, k): v for k, v in self.summertime.items()}
            self.season = {translation.get(k, k): v for k, v in self.season.items()}
            self.weekday = {translation.get(k, k): v for k, v in self.weekday.items()}
            self.month = {translation.get(k, k): v for k, v in self.month.items()}
            self.bridging_day = {translation.get(k, k): v for k, v in self.bridging_day.items()}

            # Creating German aliases
            self.feiertage = self.bank_holidays
            self.ferien = self.school_holidays
            self.sommerzeit = self.summertime
            self.jahreszeit = self.season
            self.wochentag = self.weekday
            self.monat = self.month
            self.brueckentag = self.bridging_day
            self.werktag = self.workday

            # Removing English attribute names
            del self.bank_holidays, self.school_holidays, self.summertime
            del self.season, self.weekday, self.month, self.bridging_day, self.workday


    ## @brief Fills the `summertime` dictionary with summer and winter time periods.
    #
    # This method determines the summer and winter time periods for each year in the dataset.
    # - In Europe, daylight saving time (DST) begins on the last Sunday of March.
    # - DST ends on the last Sunday of October.
    #
    # The method:
    # 1. Identifies the start and end of daylight saving time (summertime).
    # 2. Assigns all dates within this period to the "summertime" category.
    # 3. Assigns all other dates to the "wintertime" category.
    #
    # The results are stored in the `self.summertime` dictionary.
    #
    # @return None
    def fill_summertime(self):
        for year in self.years:
            # Find the last Sunday in March (start of summertime)
            start = datetime(year, 3, 31) - timedelta(days=(datetime(year, 3, 31).weekday() + 1))

            # Find the last Sunday in October (end of summertime)
            end = datetime(year, 10, 31) - timedelta(days=(datetime(year, 10, 31).weekday() + 1))

            # Filter dates falling within the summertime period
            summer_dates = self.dates[(self.dates >= start) & (self.dates < end)]
            self.summertime["summertime"] = summer_dates.date.tolist()

            # Assign remaining dates to wintertime
            winter_dates = self.dates[~self.dates.isin(summer_dates)].date
            self.summertime['wintertime'] = winter_dates.tolist()

    ## @brief Assigns each date to a meteorological or astronomical season.
    #
    # This method categorizes each date in the dataset into one of four seasons.
    # - **Meteorological seasons**:
    #   - Winter: December, January, February
    #   - Spring: March, April, May
    #   - Summer: June, July, August
    #   - Autumn: September, October, November
    # - **Astronomical seasons**:
    #   - Winter: December 21 – March 20
    #   - Spring: March 21 – June 20
    #   - Summer: June 21 – September 22
    #   - Autumn: September 23 – December 20
    #
    # By default, meteorological seasons are used.
    #
    # @param season_type Specifies the type of season classification ('meteorological' or 'astronomical').
    # @return None
    def fill_season(self, season_type="meteorological"):
        for date in self.dates.date:
            if season_type == "meteorological":
                if date.month in [12, 1, 2]:
                    self.season.setdefault("winter", []).append(date)
                elif date.month in [3, 4, 5]:
                    self.season.setdefault("spring", []).append(date)
                elif date.month in [6, 7, 8]:
                    self.season.setdefault("summer", []).append(date)
                else:
                    self.season.setdefault("autumn", []).append(date)
            elif season_type == "astronomical":
                if (date.month == 12 and date.day >= 21) or (date.month in [1, 2]) or (
                        date.month == 3 and date.day < 21):
                    self.season.setdefault("winter", []).append(date)
                elif (date.month == 3 and date.day >= 21) or (date.month in [4, 5]) or (
                        date.month == 6 and date.day < 21):
                    self.season.setdefault("spring", []).append(date)
                elif (date.month == 6 and date.day >= 21) or (date.month in [7, 8]) or (
                        date.month == 9 and date.day < 23):
                    self.season.setdefault("summer", []).append(date)
                else:
                    self.season.setdefault("autumn", []).append(date)

    ## @brief Groups dates by weekday.
    #
    # This method assigns each date to the corresponding weekday (Monday–Sunday).
    # The result is stored in the `weekday` dictionary, where each key is a weekday name
    # (e.g., 'Monday', 'Tuesday', etc.), and the value is a list of dates that fall on that day.
    #
    # @return None
    def fill_weekday(self):
        # Convert the DateTimeIndex into a DataFrame for grouping
        df = pd.DataFrame({'date': self.dates.date})

        # Group by weekday name (e.g., Monday, Tuesday, ...) and convert to dictionary
        self.weekday = df.groupby(self.dates.day_name())['date'].apply(list).to_dict()


    ## @brief Groups dates by month.
    #
    # This method assigns each date to the corresponding month (January–December).
    # The result is stored in the `month` dictionary, where each key is a month name
    # (e.g., 'January', 'February', etc.), and the value is a list of dates that fall in that month.
    #
    # @return None
    def fill_month(self):
        # Convert the DateTimeIndex into a DataFrame for grouping
        df = pd.DataFrame({'date': self.dates.date})

        # Group by month name (e.g., January, February, ...) and convert to dictionary
        self.month = df.groupby(self.dates.month_name())['date'].apply(list).to_dict()


    ## @brief Identifies bridging days (Brückentage).
    #
    # A bridging day is a workday that falls between a public holiday and a weekend.
    # This method checks for such occurrences within the dataset and categorizes dates as either:
    # - "bridging day" (if they fulfill the condition)
    # - "no bridging day" (all other dates)
    #
    # The result is stored in the `bridging_day` dictionary.
    #
    # @return None
    def fill_bridging_days(self):
        if len(self.workday) < 1:
            self.fill_workdays()

        # Create a boolean Series indicating whether each date is a workday
        series_workdays = pd.Series([date in self.workday["workday"] for date in self.dates.date],
                                    index=self.dates.date, name="workday").sort_index()

        # Identify bridging days: a workday that is surrounded by non-workdays
        bridging_days = series_workdays.loc[(series_workdays == True)
                                            & (series_workdays.shift(-1) == False)
                                            & (series_workdays.shift(1) == False)]

        if len(bridging_days) < 1:
            logging.warning("Keine Brückentage gefunden")

        # Store the results in the `bridging_day` dictionary
        self.bridging_day["bridging day"] = bridging_days.index.tolist()
        self.bridging_day["no bridging day"] = self.dates[
            ~self.dates.isin(pd.to_datetime(bridging_days.index))].date.tolist()


    ## @brief Determines workdays and non-workdays.
    #
    # This method classifies all dates into either:
    # - "workday" (regular working days)
    # - "no workday" (weekends and public holidays)
    #
    # The classification is based on:
    # - Public holidays (retrieved via `import_bank_holidays()`)
    # - Weekends (Saturdays and Sundays)
    #
    # The result is stored in the `workday` dictionary.
    #
    # @return None
    def fill_workdays(self):

        # Ensure public holidays and weekdays are available
        if len(self.bank_holidays) < 1:
            self.import_bank_holidays()
        if len(self.weekday) < 1:
            self.fill_weekday()

        # Collect all non-workdays (weekends + public holidays)
        if len(self.bank_holidays) > 0:
            set_weekend_holidays = set.union(*self.bank_holidays.values())
        else:
            set_weekend_holidays = set()
        set_weekend_holidays.update(self.weekday["Saturday"])
        set_weekend_holidays.update(self.weekday["Sunday"])

        # Convert to Pandas DatetimeIndex for filtering
        set_weekend_holidays = pd.DatetimeIndex(set_weekend_holidays)

        # Classify dates into workdays and non-workdays
        self.workday["workday"] = self.dates[~self.dates.isin(set_weekend_holidays)].date
        self.workday["no workday"] = self.dates[self.dates.isin(set_weekend_holidays)].date


    ## @brief Retrieves public holidays for the specified years, country, and state.
    #
    # This method fetches official bank holidays based on:
    # - The selected country (`self.country`)
    # - The selected state (`self.state`, if applicable)
    # - The years present in `self.years`
    # - The specified language (`self.language`)
    #
    # The retrieved holidays are stored in the `bank_holidays` dictionary, where:
    # - Keys = Holiday names
    # - Values = Corresponding dates
    #
    # @return None
    def import_bank_holidays(self):
        dir_data = self.file_path_holiday_data / "bank_holidays" / self.country.lower() # Directory where holiday data is stored.

        for year in self.years:
            file = dir_data / f"{year}" / f"{self.state}.csv"

            if file.exists():
                logging.info("Local file found for school holidays.")
                series_holidays = pd.read_csv(file, index_col=0).squeeze()
                series_holidays = pd.to_datetime(series_holidays, format=self.format_date).dt.date
                holiday_dict = series_holidays.to_dict()
            else:
                logging.info("Fetching school holidays from API...")
                holiday_dict = fetch_bank_holidays_from_api(state=self.state, years=[year], country=self.country.upper(), language=self.country.lower())

            # Update the class attribute with retrieved holidays
            for key, value in holiday_dict.items():
                if key in self.bank_holidays:
                    # Falls der Key existiert, erweitere die Liste mit dem neuen Wert
                    self.bank_holidays[key].add(value)
                else:
                    # Falls der Key nicht existiert, füge einen neuen Eintrag hinzu
                    self.bank_holidays[key] = {value}


    ## @brief Imports school holiday data from local files or an API.
    #
    # This method attempts to load school holidays for the specified state and years.
    # - First, it checks if a local CSV file exists in the holiday data directory.
    # - If no local file is found, it queries an API to fetch holiday data dynamically.
    # - The fetched holidays are stored in the `school_holidays` dictionary, where:
    #   - Keys = Holiday names
    #   - Values = Lists of dates corresponding to each holiday.
    #
    # @return None
    def import_school_holidays(self):
        dir_data = self.file_path_holiday_data / "school_holidays" / self.country.lower()  # Directory where holiday data is stored.

        for year in self.years:
            file = dir_data / f"{year}" / f"{self.state}.csv"

            if file.exists():
                logging.info("Local file found for school holidays.")
                series_holidays = pd.read_csv(file, index_col=0).squeeze()
            else:
                logging.info("Fetching school holidays from API...")
                series_holidays = query_school_holidays(state=self.state, list_years=[year])

            if series_holidays is not None and len(series_holidays) > 0:
                # Convert index to datetime for consistency
                series_holidays.index = pd.to_datetime(series_holidays.index, format=self.format_date).date
                self.school_holidays.update(series_holidays.groupby(series_holidays).groups)
                logging.info(f"Successfully imported school holidays for {self.state}.")
            else:
                logging.error(f"Failed to import school holidays for {self.state}.")

    ## @brief Filters the data indices based on selected calendar properties.
    #
    #  This method applies filtering criteria such as weekdays, holidays, and date range
    #  to determine which time-series data should be included in the clustering process.
    #
    #  @return A list of filtered datetime indices that match the selected criteria.
    def _get_filtered_indices_data(self, indices: pd.DatetimeIndex,
                                   days_to_include: list=None,
                                   include_bank_holidays: bool=True,
                                   include_school_holidays: bool=True,
                                   start_date: datetime.date=None, end_date: datetime.date=None):

        # 4. Initiale Liste der Datetime-Indizes im Dataset
        filtered_indices = indices

        # 5. Filtern der Wochentage
        if len(days_to_include) < 7:
            num_char_day = len(days_to_include[0])
            weekdays = getattr(self, "wochentag", getattr(self, "weekday", {}))
            dict_keys = {key[:num_char_day]: key for key in weekdays.keys()}
            day_short = [dict_keys[day] for day in days_to_include]
            days = [date for day in day_short for date in
                    (weekdays[day].date.tolist() if isinstance(weekdays[day], pd.DatetimeIndex) else weekdays[day])]
            days = pd.to_datetime(days)
            days = pd.to_datetime(days)
            filtered_indices = filtered_indices[filtered_indices.isin(days)]

        # 6. Filtern der Feiertage und Ferien
        holidays = set()

        if include_school_holidays and include_bank_holidays:
            pass
        elif not include_school_holidays and not include_bank_holidays:
            feiertage = getattr(self, "feiertage", getattr(self, "bank_holidays", {}))
            ferien = getattr(self, "ferien",
                                 getattr(self, "school_holidays", []))
            if len(feiertage) > 0:
                holidays.update({date for dates in feiertage.values() for date in dates})
            if len(ferien) > 0:
                holidays.update({date for dates in ferien.values() for date in dates})

        elif not include_bank_holidays:
            feiertage = getattr(self, "feiertage", getattr(self, "bank_holidays", {}))
            if len(feiertage) > 0:
                holidays.update({date for dates in feiertage.values() for date in dates})
        elif not include_school_holidays:
            ferien = getattr(self, "ferien",
                                 getattr(self, "school_holidays", []))
            if len(ferien) > 0:
                holidays.update({date for dates in ferien.values() for date in dates})
        else:
            logging.error("Unvorhergesehener Fall beim Filtern von Feiertagen und Ferien.")

        # Falls Feiertage vorhanden sind, diese herausfiltern
        if len(holidays) > 0:
            holidays = pd.to_datetime(list(holidays))
            filtered_indices = filtered_indices[~filtered_indices.isin(holidays)]

        filtered_indices = filtered_indices[(filtered_indices >= start_date) & (filtered_indices <= end_date)].date

        # Logging der gefilterten Daten
        logging.info(f"Es werden {len(filtered_indices)} von {len(indices)} Ganglinien berücksichtigt")

        return filtered_indices



## @brief Expands and saves school holiday data for a given range of years.
#
#  This function queries school holiday data for all German federal states
#  for the specified year range and saves the data as CSV files.
#
#  @param year_start The starting year of the range.
#  @param year_end The ending year of the range.
def expand_csv_school_holidays(year_start, year_end):
    list_states = ['BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', 'NI', 'NW',
                   'RP', 'SL', 'SN', 'ST', 'SH', 'TH']

    dir_data = Path(__file__).parents[1] / "data" / "school_holidays" / "de"
    list_years = pd.date_range(start=f"{year_start}-01-01", end=f"{year_end}-12-31", freq="YE").year.tolist()

    for state in list_states:
        for year in list_years:
            file = dir_data / f"{year}" / f"{state}.csv"
            if file.exists():
                continue
            else:
                file.parent.mkdir(exist_ok=True)
                series_holidays = query_school_holidays(list_years=[year], state=state)
                if len(series_holidays) > 0:
                    series_holidays.to_csv(file)

## @brief Expands and saves school holiday data for a given range of years.
#
#  This function queries school holiday data for all German federal states
#  for the specified year range and saves the data as CSV files.
#
#  @param year_start The starting year of the range.
#  @param year_end The ending year of the range.
def expand_csv_bank_holidays(year_start, year_end):
    list_states = ['BW', 'BY', 'BE', 'BB', 'HB', 'HH', 'HE', 'MV', 'NI', 'NW',
                   'RP', 'SL', 'SN', 'ST', 'SH', 'TH']

    dir_data = Path(__file__).parents[1] / "data" / "bank_holidays" / "de"
    list_years = pd.date_range(start=f"{year_start}-01-01", end=f"{year_end}-12-31", freq="YE").year.tolist()

    for state in list_states:
        for year in list_years:
            file = dir_data / f"{year}" / f"{state}.csv"
            if file.exists():
                continue
            else:
                file.parent.mkdir(exist_ok=True)
                dict_holidays = fetch_bank_holidays_from_api(years=[year], state=state, country="DE", language="de")
                series_holidays = pd.Series(dict_holidays)
                if len(series_holidays) > 0:
                    series_holidays.to_csv(file, encoding="utf-8")



## @brief Fetches school holidays for a given state and year from an API with retry logic.
#
#  This function queries an online API to retrieve school holiday data for a specific state
#  and year. If the request fails, it retries up to `max_retries` times.
#
#  @param state The state code (e.g., "BW" for Baden-Württemberg).
#  @param year The year to query.
#  @param max_retries The maximum number of retry attempts (default: 5).
#  @return A list of holiday objects from the API, or None if an error occurs after max retries.
def fetch_school_holidays_from_api(state: str, year: int, max_retries=5):
    url = f"https://ferien-api.de/api/v1/holidays/{state}/{year}"
    request = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})

    attempts = 0
    while attempts < max_retries:
        try:
            with urllib.request.urlopen(request) as response:
                return json.loads(response.read().decode())
        except Exception as e:
            attempts += 1
            print(f"Warning: Could not fetch data for {state} {year} (Attempt {attempts}/{max_retries}): {e}")

            if attempts < max_retries:
                print("Retrying in 30 seconds...")
                time.sleep(0)  # Wait before retrying

    print(f"Error: Failed to fetch data for {state} {year} after {max_retries} attempts.")
    return None


## @brief Retrieves school holidays for a given list of years and state.
#
#  This function fetches school holidays for a given list of years and state.
#  It first tries to retrieve the data from an API and organizes the results into a
#  pandas Series.
#
#  @param list_years A list or set of years to retrieve holidays for.
#  @param state The state code (e.g., "BW" for Baden-Württemberg).
#  @param format_str The date format string (default: "%Y-%m-%d").
#  @return A pandas Series with dates as index and holiday names as values.
def query_school_holidays(list_years, state, format_str: str = "%Y-%m-%d") -> pd.Series:
    holidays_dict = {}

    for year in list_years:
        holidays_data = fetch_school_holidays_from_api(state, year, max_retries=1)
        if holidays_data is None:
            continue  # Skip this year if data couldn't be fetched

        for holiday in holidays_data:
            name = holiday["name"].split(" ")[0].capitalize()
            start = holiday["start"]
            end = holiday["end"]
            days = pd.date_range(start=start, end=end, freq="D")
            for day in days:
                holidays_dict[day.date()] = name  # Save holiday name for each date

    # Handle Christmas holidays from the previous year (carry-over into January)
    previous_year = min(list_years) - 1
    holidays_data = fetch_school_holidays_from_api(state, previous_year, max_retries=1)

    if holidays_data:
        for holiday in holidays_data:
            if holiday["name"].lower() == "weihnachtsferien":  # Christmas holidays
                start = holiday["start"]
                end = holiday["end"]
                days = pd.date_range(start=start, end=end, freq="D")
                for day in days:
                    holidays_dict[day.date()] = holiday["name"].split(" ")[0].capitalize()
                break  # Stop after finding Christmas holidays

    # Convert dictionary to pandas Series
    holiday_series = pd.Series(holidays_dict, name=state)

    # Sort by date
    holiday_series = holiday_series.sort_index()

    # Filter only dates that belong to the specified years
    holiday_series = holiday_series[holiday_series.index.map(lambda x: x.year in list_years)]

    return holiday_series


## @brief Fetches bank holidays for a given state and year from an API
#
#  This function queries an online API to retrieve school holiday data for a specific state
#  and year.
#
#  @param state The state code (e.g., "BW" for Baden-Württemberg).
#  @param year The year to query.
#  @return A list of holiday objects from the API, or None if an error occurs after max retries.
def fetch_bank_holidays_from_api(state: str, years: list, country: str, language):
    holiday_dict = {}

    for year in years:
        # Retrieve country-specific holidays (localized if supported)
        try:
            country_holidays = holidays.country_holidays(
                country, subdiv=state, years=year, language=language
            )

            # Store holidays in dictionary (name -> date mapping)
            for date, name in country_holidays.items():
                holiday_dict[name] = date
        except:
            logging.warning("Abfrage Feiertage war erfolglos. Internetverbindung ist notwendig")

    return holiday_dict


    
    
if __name__ == '__main__':
    # obj = CalendarAttributes([])
    expand_csv_bank_holidays(2000, 2025)
    expand_csv_school_holidays(2017, 2025)
