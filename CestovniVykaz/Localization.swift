import Foundation
import Combine

// MARK: - Localization System
enum Language: String, CaseIterable {
    case czech = "cs"
    case english = "en"
    case german = "de"
    
    var displayName: String {
        switch self {
        case .czech: return "Čeština"
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }
    
    var flag: String {
        switch self {
        case .czech: return "🇨🇿"
        case .english: return "🇬🇧"
        case .german: return "🇩🇪"
        }
    }
}

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: Language = .czech
    
    static let shared = LocalizationManager()
    private let languageKey = "selectedLanguage"
    
    private init() {
        loadSavedLanguage()
    }
    
    func localizedString(_ key: String) -> String {
        return LocalizationData.shared.getString(for: key, language: currentLanguage)
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        saveLanguage()
    }
    
    private func loadSavedLanguage() {
        if let savedLanguageString = UserDefaults.standard.string(forKey: languageKey),
           let savedLanguage = Language(rawValue: savedLanguageString) {
            currentLanguage = savedLanguage
        }
    }
    
    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
    }
}

// MARK: - Localization Data
class LocalizationData {
    static let shared = LocalizationData()
    
    private var czechStrings: [String: String] = [:]
    private var englishStrings: [String: String] = [:]
    private var germanStrings: [String: String] = [:]
    
    private init() {
        loadLocalizationData()
    }
    
    private func loadLocalizationData() {
        // Czech strings
        czechStrings = [
            // Navigation
            "home": "Vítej",
            "overview": "Přehled",
            "history": "Historie",
            "statistics": "Statistiky",
            "records": "Záznamy",
            "customers": "Zákazníci",
            "fuel": "Tankování",
            "settings": "Nastavení",
            
            // App Title and Subtitle
            "appTitle": "Cestovní Výkaz",
            "appSubtitle": "Pro mechaniky",
            "appDescription": "Digitalizace pro mechanika",
            
            // Loading Screen
            "loadingApp": "Načítání aplikace...",
            "createdBy": "Vytvořil Jakub Sedláček",
            
            // Page Titles
            "recordsTitle": "Záznam výkazů",
            "fuelTitle": "Přehled tankování",
            "historyTitle": "Historie výkazů",
            
            // Customer Screen
            "addNewCustomer": "Přidat nového zákazníka",
            "tryDifferentSearch": "Zkuste jiné vyhledávací slovo",
            "saveChanges": "Uložit změny",
            "customerUpdated": "Zákazník byl úspěšně upraven",
            
            // History Screen
            "monthCalendar": "Kalendář měsíce",
            "legend": "Legenda",
            "vacation": "Dovolená",
            "sickMedical": "Lékař/Nemoc",
            "workingDay": "Pracovní den",
            "save": "Uložit",
            
            // Alerts
            "confirmDeleteFuel": "Opravdu chcete smazat tankování z {date}? Tato akce je nevratná.",
            "confirmDeleteCustomer": "Opravdu chcete smazat zákazníka '{name}'? Tato akce je nevratná.",
            
            // Common
            "dash": "—",
            "version": "1.0.0",
            
            // Day declension (Czech)
            "day1": "1 den",
            "day2to4": "{count} dny",
            "day5plus": "{count} dnů",
            
            // Form Fields
            "date": "Datum",
            "enterCity": "Zadejte město",
            "notes": "Poznámka",
            "enterNotes": "Zadejte poznámku...",
            
            // Statistics Labels
            "driving": "Jízda",
            "work": "Práce",
            "days": "Dny",
            "daysCount": "Dnů",
            
            // Quick Actions
            "addRecordForDay": "Přidat výkaz za den",
            "viewPreviousMonths": "Zobrazit předchozí měsíce",
            "fuelTracking": "Sledování paliva",
            "hoursKilometersOverview": "Přehled hodin a kilometrů",
            
            // Calendar
            "workingDays": "Pracovní dny",
            "delete": "Smazat",
            "searchCustomers": "Hledat zákazníky...",
            
            // Weekday abbreviations
            "mon": "Po",
            "tue": "Út",
            "wed": "St",
            "thu": "Čt",
            "fri": "Pá",
            "sat": "So",
            "sun": "Ne",
            
            // Home Screen
            "currentMonth": "Aktuální měsíc",
            "drivingHours": "Hodiny jízdy",
            "workingHours": "Hodiny práce",
            "totalHours": "Celkem hodin",
            "kilometers": "Kilometry",
            "recordsCount": "záznamů",
            "fuelCosts": "Náklady na palivo",
            "quickActions": "Rychlé akce",
            "viewStatistics": "Zobrazit statistiky",
            "addRecord": "Přidat záznam",
            "addCustomer": "Přidat zákazníka",
            "addFuel": "Přidat tankování",
            
            // Records Screen
            "drivingTime": "Doba jízdy",
            "workingTime": "Doba práce",
            "kilometersDriven": "Ujeté kilometry",
            "city": "Město",
            "dayType": "Typ dne",
            "saveRecord": "Uložit výkaz",
            "updateRecord": "Aktualizovat výkaz",
            "recordSaved": "Výkaz byl úspěšně uložen",
            "recordUpdated": "Výkaz byl úspěšně aktualizován",
            "validationError": "Chyba validace",
            "fillRequiredFields": "Vyplňte všechna povinná pole",
            "existingRecord": "Záznam pro tento den již existuje",
            "recordLoaded": "Data jsou načtena a uzamčena pro zobrazení",
            "weekendHoliday": "Víkend/Svátek",
            "alreadyHasRecord": "Již máte záznam pro tento den",
            "editRecord": "Upravit záznam",
            "deleteRecord": "Smazat záznam",
            "customer": "Zákazník",
            
            // Day Types
            "workDay": "Práce",
            "sickDay": "Lékař/Nemoc",
            "noRecords": "Žádné záznamy",
            "monthOverview": "Přehled měsíce",
            "totalDrivingHours": "Celkem hodin jízdy",
            "totalWorkingHours": "Celkem hodin práce",
            "totalKilometers": "Celkem kilometrů",
            "recordsCountShort": "Počet záznamů",
            "vacationDays": "Dovolená",
            "sickDays": "Lékař/Nemoc",
            "workingDaysSection": "Pracovní dny",
            "noRecordsForMonth": "Žádné záznamy pro tento měsíc",
            "monthNotFound": "Měsíc nebyl nalezen",
            "close": "Zavřít",
            "edit": "Upravit",
            
            // Statistics Screen
            "statisticsTitle": "Statistiky",
            "periodStats": "Statistika za",
            "totalHoursLabel": "Celkem hodin",
            "totalKilometersLabel": "Celkem km",
            "timeRange": "Časové období",
            "currentMonthStats": "Aktuální měsíc",
            "lastMonth": "Minulý měsíc",
            "last3Months": "Poslední 3 měsíce",
            "allTime": "Celkově",
            "monthlyOverview": "Měsíční přehled",
            "noDataForPeriod": "Žádné data pro vybrané období",
            "monthlyFuelCosts": "Měsíční náklady na palivo",
            "averageFuelCost": "Průměrné náklady na palivo",
            
            // Customers Screen
            "customersTitle": "Zákazníci",
            "addCustomerTitle": "Nový zákazník",
            "customerName": "Jméno zákazníka",
            "customerCity": "Město",
            "customerKilometers": "Kilometry",
            "customerDrivingTime": "Čas jízdy",
            "addCustomerButton": "Přidat zákazníka",
            "customerAdded": "Zákazník byl úspěšně přidán",
            "noCustomers": "Žádní zákazníci",
            "startAddingCustomers": "Začněte přidáváním prvního zákazníka",
            
            // Fuel Screen
            "lastFuelEntries": "Poslední tankování",
            "newFuelEntry": "Nové tankování",
            "fuelCalendar": "Kalendář tankování",
            "noFuelEntries": "Žádné tankování",
            "startAddingFuel": "Začněte přidáváním prvního tankování",
            "fuelDate": "Datum",
            "fuelType": "Druh paliva",
            "fuelAmount": "Množství",
            "fuelPrice": "Cena za litr",
            "fuelLocation": "Místo tankování",
            "fuelNotes": "Poznámka",
            "fuelPricePerLiter": "Cena za litr",
            "totalPrice": "Celková cena",
            "liters": "Litr",
            "currency": "Kč",
            "pricePerLiterUnit": "Kč/L",
            "saveFuelEntry": "Uložit tankování",
            "fuelEntrySaved": "Tankování bylo úspěšně uloženo",
            "diesel": "Diesel",
            "gasoline": "Benzín",
            "currentDateTime": "Aktuální datum a čas jsou předvyplněny",
            "currentDateTimePrefilled": "Aktuální datum a čas jsou předvyplněny",
            "calculatedTotalPrice": "Vypočtená celková cena",
            "calculatedPricePerLiter": "Vypočtená cena za litr",
            "fuelStation": "Čerpací stanice",
            "fuelStationSuggestions": "Nápověda čerpacích stanic",
            
            // Settings Screen
            "settingsTitle": "Nastavení",
            "notifications": "Notifikace",
            "dailyReminder": "Denní připomínka",
            "notificationDescription": "Notifikace ve 20:00 pokud není vyplněn výkaz",
            "enableNotifications": "Povolit notifikace",
            "notificationsEnabled": "Notifikace jsou povoleny",
            "testNotification": "Test notifikace (15s)",
            "testNotificationTime": "Test notifikace (15s)",
            "appInfo": "Informace o aplikaci",
            "language": "Jazyk",
            "selectLanguage": "Vyberte jazyk",
            "done": "Hotovo",
            
            // Alerts
            "success": "Úspěch",
            "error": "Chyba",
            "cancel": "Zrušit",
            "ok": "OK",
            "confirm": "Potvrdit",
            "clear": "Vymazat",
            "generate": "Vygenerovat",
            
            // Months
            "january": "Leden",
            "february": "Únor",
            "march": "Březen",
            "april": "Duben",
            "may": "Květen",
            "june": "Červen",
            "july": "Červenec",
            "august": "Srpen",
            "september": "Září",
            "october": "Říjen",
            "november": "Listopad",
            "december": "Prosinec",
            
            // Weekdays
            "monday": "Pondělí",
            "tuesday": "Úterý",
            "wednesday": "Středa",
            "thursday": "Čtvrtek",
            "friday": "Pátek",
            "saturday": "Sobota",
            "sunday": "Neděle",
            
            // Common
            "working": "Práce",
            "sick": "Nemoc",
            "day": "den",
            "hours": "hodin",
            "hour": "hodina",
            "km": "km",
            "litersUnit": "L",
            "currencyUnit": "Kč",
            
            // Additional UI translations
            "newRecord": "Nový Záznam",
            "timeData": "Časové údaje",
            "kilometersAndLocation": "Kilometry a místo",
            "note": "Poznámka",
            "dateAndTime": "Datum a čas",
            "amountAndPrice": "Množství a cena",
            "enterStation": "Zadejte stanici",
            "enterNote": "Zadejte poznámku",
            "newCustomer": "Nový Zákazník",
            "customerInfo": "Informace o zákazníkovi",
            "back": "Zpět",
            
            // Time Input Settings
            "timeInputSettings": "Zadávání času",
            "useTimePicker": "Použít časový výběr",
            "timePickerDescription": "Čas se zadává pomocí hodin a minut",
            "textInputDescription": "Čas se zadává jako desetinné číslo (např. 6,5)",
            "textMode": "Textový režim",
            "timePickerMode": "Časový výběr",
            "textModeDescription": "6,5 = 6 hodin 30 minut",
            "timePickerDescription2": "Přesné nastavení hodin a minut"
        ]
        
        // English strings
        englishStrings = [
            // Navigation
            "home": "Welcome",
            "overview": "Overview",
            "history": "History",
            "statistics": "Statistics",
            "records": "Records",
            "customers": "Customers",
            "fuel": "Fuel",
            "settings": "Settings",
            
            // App Title and Subtitle
            "appTitle": "Travel Report",
            "appSubtitle": "For Mechanics",
            "appDescription": "Digitalization for Mechanics",
            
            // Loading Screen
            "loadingApp": "Loading application...",
            "createdBy": "Created by Jakub Sedláček",
            
            // Page Titles
            "recordsTitle": "Record Reports",
            "fuelTitle": "Fuel Overview",
            "historyTitle": "Report History",
            
            // Customer Screen
            "addNewCustomer": "Add New Customer",
            "tryDifferentSearch": "Try different search term",
            "saveChanges": "Save Changes",
            "customerUpdated": "Customer updated successfully",
            
            // History Screen
            "monthCalendar": "Month Calendar",
            "legend": "Legend",
            "vacation": "Vacation",
            "sickMedical": "Sick/Medical",
            "workingDay": "Working Day",
            "save": "Save",
            
            // Alerts
            "confirmDeleteFuel": "Do you really want to delete fuel entry from {date}? This action is irreversible.",
            "confirmDeleteCustomer": "Do you really want to delete customer '{name}'? This action is irreversible.",
            
            // Common
            "dash": "—",
            "version": "1.0.0",
            
            // Day declension (English)
            "day1": "1 day",
            "day2to4": "{count} days",
            "day5plus": "{count} days",
            
            // Form Fields
            "date": "Date",
            "enterCity": "Enter city",
            "notes": "Notes",
            "enterNotes": "Enter notes...",
            
            // Statistics Labels
            "driving": "Driving",
            "work": "Work",
            "days": "Days",
            "daysCount": "Days",
            
            // Quick Actions
            "addRecordForDay": "Add report for day",
            "viewPreviousMonths": "View previous months",
            "fuelTracking": "Fuel tracking",
            "hoursKilometersOverview": "Hours and kilometers overview",
            
            // Calendar
            "workingDays": "Working Days",
            "delete": "Delete",
            "searchCustomers": "Search customers...",
            
            // Weekday abbreviations
            "mon": "Mon",
            "tue": "Tue",
            "wed": "Wed",
            "thu": "Thu",
            "fri": "Fri",
            "sat": "Sat",
            "sun": "Sun",
            
            // Home Screen
            "currentMonth": "Current Month",
            "drivingHours": "Driving Hours",
            "workingHours": "Working Hours",
            "totalHours": "Total Hours",
            "kilometers": "Kilometers",
            "recordsCount": "records",
            "fuelCosts": "Fuel Costs",
            "quickActions": "Quick Actions",
            "viewStatistics": "View Statistics",
            "addRecord": "Add Record",
            "addCustomer": "Add Customer",
            "addFuel": "Add Fuel",
            
            // Records Screen
            "drivingTime": "Driving Time",
            "workingTime": "Working Time",
            "kilometersDriven": "Kilometers Driven",
            "city": "City",
            "dayType": "Day Type",
            "saveRecord": "Save Record",
            "updateRecord": "Update Record",
            "recordSaved": "Record saved successfully",
            "recordUpdated": "Record updated successfully",
            "validationError": "Validation Error",
            "fillRequiredFields": "Please fill in all required fields",
            "existingRecord": "Record for this day already exists",
            "recordLoaded": "Data is loaded and locked for display",
            "weekendHoliday": "Weekend/Holiday",
            "alreadyHasRecord": "You already have a record for this day",
            "editRecord": "Edit Record",
            "deleteRecord": "Delete Record",
            "customer": "Customer",
            
            // Day Types
            "workDay": "Work",
            "sickDay": "Sick/Medical",
            "noRecords": "No Records",
            "monthOverview": "Month Overview",
            "totalDrivingHours": "Total Driving Hours",
            "totalWorkingHours": "Total Working Hours",
            "totalKilometers": "Total Kilometers",
            "recordsCountShort": "Number of Records",
            "vacationDays": "Vacation",
            "sickDays": "Sick/Medical",
            "workingDaysSection": "Working Days",
            "noRecordsForMonth": "No records for this month",
            "monthNotFound": "Month not found",
            "close": "Close",
            "edit": "Edit",
            
            // Statistics Screen
            "statisticsTitle": "Statistics",
            "periodStats": "Statistics for",
            "totalHoursLabel": "Total Hours",
            "totalKilometersLabel": "Total km",
            "timeRange": "Time Period",
            "currentMonthStats": "Current Month",
            "lastMonth": "Last Month",
            "last3Months": "Last 3 Months",
            "allTime": "All Time",
            "monthlyOverview": "Monthly Overview",
            "noDataForPeriod": "No data for selected period",
            "monthlyFuelCosts": "Monthly Fuel Costs",
            "averageFuelCost": "Average Fuel Cost",
            
            // Customers Screen
            "customersTitle": "Customers",
            "addCustomerTitle": "New Customer",
            "customerName": "Customer Name",
            "customerCity": "City",
            "customerKilometers": "Kilometers",
            "customerDrivingTime": "Driving Time",
            "addCustomerButton": "Add Customer",
            "customerAdded": "Customer added successfully",
            "noCustomers": "No customers",
            "startAddingCustomers": "Start by adding your first customer",
            
            // Fuel Screen
            "lastFuelEntries": "Last Fuel Entries",
            "newFuelEntry": "New Fuel Entry",
            "fuelCalendar": "Fuel Calendar",
            "noFuelEntries": "No fuel entries",
            "startAddingFuel": "Start by adding your first fuel entry",
            "fuelDate": "Date",
            "fuelType": "Fuel Type",
            "fuelAmount": "Amount",
            "fuelPrice": "Price per Liter",
            "fuelLocation": "Location",
            "fuelNotes": "Notes",
            "fuelPricePerLiter": "Price per Liter",
            "totalPrice": "Total Price",
            "liters": "Liter",
            "currency": "CZK",
            "pricePerLiterUnit": "CZK/L",
            "saveFuelEntry": "Save Fuel Entry",
            "fuelEntrySaved": "Fuel entry saved successfully",
            "diesel": "Diesel",
            "gasoline": "Gasoline",
            "currentDateTime": "Current date and time are pre-filled",
            "currentDateTimePrefilled": "Current date and time are pre-filled",
            "calculatedTotalPrice": "Calculated total price",
            "calculatedPricePerLiter": "Calculated price per liter",
            "fuelStation": "Gas Station",
            "fuelStationSuggestions": "Gas Station Suggestions",
            
            // Settings Screen
            "settingsTitle": "Settings",
            "notifications": "Notifications",
            "dailyReminder": "Daily Reminder",
            "notificationDescription": "Notification at 8:00 PM if report is not filled",
            "enableNotifications": "Enable Notifications",
            "notificationsEnabled": "Notifications are enabled",
            "testNotification": "Test Notification (15s)",
            "testNotificationTime": "Test Notification (15s)",
            "appInfo": "App Information",
            "language": "Language",
            "selectLanguage": "Select Language",
            "done": "Done",
            
            // Alerts
            "success": "Success",
            "error": "Error",
            "cancel": "Cancel",
            "ok": "OK",
            "confirm": "Confirm",
            "clear": "Clear",
            "generate": "Generate",
            
            // Months
            "january": "January",
            "february": "February",
            "march": "March",
            "april": "April",
            "may": "May",
            "june": "June",
            "july": "July",
            "august": "August",
            "september": "September",
            "october": "October",
            "november": "November",
            "december": "December",
            
            // Weekdays
            "monday": "Monday",
            "tuesday": "Tuesday",
            "wednesday": "Wednesday",
            "thursday": "Thursday",
            "friday": "Friday",
            "saturday": "Saturday",
            "sunday": "Sunday",
            
            // Common
            "working": "Work",
            "sick": "Sick",
            "day": "day",
            "hours": "hours",
            "hour": "hour",
            "km": "km",
            "litersUnit": "L",
            "currencyUnit": "CZK",
            
            // Additional UI translations
            "newRecord": "New Record",
            "timeData": "Time Data",
            "kilometersAndLocation": "Kilometers and Location",
            "note": "Note",
            "dateAndTime": "Date and Time",
            "amountAndPrice": "Amount and Price",
            "enterStation": "Enter Station",
            "enterNote": "Enter Note",
            "newCustomer": "New Customer",
            "customerInfo": "Customer Information",
            "back": "Back",
            
            // Time Input Settings
            "timeInputSettings": "Time Input",
            "useTimePicker": "Use Time Picker",
            "timePickerDescription": "Time is entered using hours and minutes",
            "textInputDescription": "Time is entered as decimal number (e.g. 6.5)",
            "textMode": "Text Mode",
            "timePickerMode": "Time Picker",
            "textModeDescription": "6.5 = 6 hours 30 minutes",
            "timePickerDescription2": "Precise hours and minutes setting"
        ]
        
        // German strings
        germanStrings = [
            // Navigation
            "home": "Willkommen",
            "overview": "Übersicht",
            "history": "Verlauf",
            "statistics": "Statistiken",
            "records": "Aufzeichnungen",
            "customers": "Kunden",
            "fuel": "Tankstellen",
            "settings": "Einstellungen",
            
            // App Title and Subtitle
            "appTitle": "Reisebericht",
            "appSubtitle": "Für Mechaniker",
            "appDescription": "Digitalisierung für Mechaniker",
            
            // Loading Screen
            "loadingApp": "Anwendung wird geladen...",
            "createdBy": "Erstellt von Jakub Sedláček",
            
            // Page Titles
            "recordsTitle": "Berichtsaufzeichnungen",
            "fuelTitle": "Kraftstoffübersicht",
            "historyTitle": "Berichtsverlauf",
            
            // Customer Screen
            "addNewCustomer": "Neuen Kunden hinzufügen",
            "tryDifferentSearch": "Versuchen Sie einen anderen Suchbegriff",
            "saveChanges": "Änderungen speichern",
            "customerUpdated": "Kunde erfolgreich aktualisiert",
            
            // History Screen
            "monthCalendar": "Monatskalender",
            "legend": "Legende",
            "vacation": "Urlaub",
            "sickMedical": "Krank/Arzt",
            "workingDay": "Arbeitstag",
            "save": "Speichern",
            
            // Alerts
            "confirmDeleteFuel": "Möchten Sie den Tankvorgang vom {date} wirklich löschen? Diese Aktion ist unumkehrbar.",
            "confirmDeleteCustomer": "Möchten Sie den Kunden '{name}' wirklich löschen? Diese Aktion ist unumkehrbar.",
            
            // Common
            "dash": "—",
            "version": "1.0.0",
            
            // Day declension (German)
            "day1": "1 Tag",
            "day2to4": "{count} Tage",
            "day5plus": "{count} Tage",
            
            // Form Fields
            "date": "Datum",
            "enterCity": "Stadt eingeben",
            "notes": "Notizen",
            "enterNotes": "Notizen eingeben...",
            
            // Statistics Labels
            "driving": "Fahren",
            "work": "Arbeit",
            "days": "Tage",
            "daysCount": "Tage",
            
            // Quick Actions
            "addRecordForDay": "Bericht für Tag hinzufügen",
            "viewPreviousMonths": "Vorherige Monate anzeigen",
            "fuelTracking": "Kraftstoffverfolgung",
            "hoursKilometersOverview": "Stunden und Kilometer Übersicht",
            
            // Calendar
            "workingDays": "Arbeitstage",
            "delete": "Löschen",
            "searchCustomers": "Kunden suchen...",
            
            // Weekday abbreviations
            "mon": "Mo",
            "tue": "Di",
            "wed": "Mi",
            "thu": "Do",
            "fri": "Fr",
            "sat": "Sa",
            "sun": "So",
            
            // Home Screen
            "currentMonth": "Aktueller Monat",
            "drivingHours": "Fahrstunden",
            "workingHours": "Arbeitsstunden",
            "totalHours": "Gesamtstunden",
            "kilometers": "Kilometer",
            "recordsCount": "Aufzeichnungen",
            "fuelCosts": "Kraftstoffkosten",
            "quickActions": "Schnellaktionen",
            "viewStatistics": "Statistiken anzeigen",
            "addRecord": "Aufzeichnung hinzufügen",
            "addCustomer": "Kunde hinzufügen",
            "addFuel": "Tankvorgang hinzufügen",
            
            // Records Screen
            "drivingTime": "Fahrzeit",
            "workingTime": "Arbeitszeit",
            "kilometersDriven": "Gefahrene Kilometer",
            "city": "Stadt",
            "dayType": "Tagestyp",
            "saveRecord": "Aufzeichnung speichern",
            "updateRecord": "Aufzeichnung aktualisieren",
            "recordSaved": "Aufzeichnung erfolgreich gespeichert",
            "recordUpdated": "Aufzeichnung erfolgreich aktualisiert",
            "validationError": "Validierungsfehler",
            "fillRequiredFields": "Bitte füllen Sie alle Pflichtfelder aus",
            "existingRecord": "Aufzeichnung für diesen Tag existiert bereits",
            "recordLoaded": "Daten sind geladen und für die Anzeige gesperrt",
            "weekendHoliday": "Wochenende/Feiertag",
            "alreadyHasRecord": "Sie haben bereits eine Aufzeichnung für diesen Tag",
            "editRecord": "Aufzeichnung bearbeiten",
            "deleteRecord": "Aufzeichnung löschen",
            "customer": "Kunde",
            
            // Day Types
            "workDay": "Arbeit",
            "sickDay": "Krank/Arzt",
            "noRecords": "Keine Aufzeichnungen",
            "monthOverview": "Monatsübersicht",
            "totalDrivingHours": "Gesamte Fahrstunden",
            "totalWorkingHours": "Gesamte Arbeitsstunden",
            "totalKilometers": "Gesamte Kilometer",
            "recordsCountShort": "Anzahl der Aufzeichnungen",
            "vacationDays": "Urlaub",
            "sickDays": "Krank/Arzt",
            "workingDaysSection": "Arbeitstage",
            "noRecordsForMonth": "Keine Aufzeichnungen für diesen Monat",
            "monthNotFound": "Monat nicht gefunden",
            "close": "Schließen",
            "edit": "Bearbeiten",
            
            // Statistics Screen
            "statisticsTitle": "Statistiken",
            "periodStats": "Statistiken für",
            "totalHoursLabel": "Gesamtstunden",
            "totalKilometersLabel": "Gesamt km",
            "timeRange": "Zeitraum",
            "currentMonthStats": "Aktueller Monat",
            "lastMonth": "Letzter Monat",
            "last3Months": "Letzte 3 Monate",
            "allTime": "Gesamt",
            "monthlyOverview": "Monatliche Übersicht",
            "noDataForPeriod": "Keine Daten für den ausgewählten Zeitraum",
            "monthlyFuelCosts": "Monatliche Kraftstoffkosten",
            "averageFuelCost": "Durchschnittliche Kraftstoffkosten",
            
            // Customers Screen
            "customersTitle": "Kunden",
            "addCustomerTitle": "Neuer Kunde",
            "customerName": "Kundenname",
            "customerCity": "Stadt",
            "customerKilometers": "Kilometer",
            "customerDrivingTime": "Fahrzeit",
            "addCustomerButton": "Kunde hinzufügen",
            "customerAdded": "Kunde erfolgreich hinzugefügt",
            "noCustomers": "Keine Kunden",
            "startAddingCustomers": "Beginnen Sie mit dem Hinzufügen Ihres ersten Kunden",
            
            // Fuel Screen
            "lastFuelEntries": "Letzte Tankvorgänge",
            "newFuelEntry": "Neuer Tankvorgang",
            "fuelCalendar": "Tankkalender",
            "noFuelEntries": "Keine Tankvorgänge",
            "startAddingFuel": "Beginnen Sie mit dem Hinzufügen Ihres ersten Tankvorgangs",
            "fuelDate": "Datum",
            "fuelType": "Kraftstoffart",
            "fuelAmount": "Menge",
            "fuelPrice": "Preis pro Liter",
            "fuelLocation": "Standort",
            "fuelNotes": "Notizen",
            "fuelPricePerLiter": "Preis pro Liter",
            "totalPrice": "Gesamtpreis",
            "liters": "Liter",
            "currency": "CZK",
            "pricePerLiterUnit": "CZK/L",
            "saveFuelEntry": "Tankvorgang speichern",
            "fuelEntrySaved": "Tankvorgang erfolgreich gespeichert",
            "diesel": "Diesel",
            "gasoline": "Benzin",
            "currentDateTime": "Aktuelles Datum und Uhrzeit sind vorausgefüllt",
            "currentDateTimePrefilled": "Aktuelles Datum und Uhrzeit sind vorausgefüllt",
            "calculatedTotalPrice": "Berechneter Gesamtpreis",
            "calculatedPricePerLiter": "Berechneter Preis pro Liter",
            "fuelStation": "Tankstelle",
            "fuelStationSuggestions": "Tankstellen-Vorschläge",
            
            // Settings Screen
            "settingsTitle": "Einstellungen",
            "notifications": "Benachrichtigungen",
            "dailyReminder": "Tägliche Erinnerung",
            "notificationDescription": "Benachrichtigung um 20:00 Uhr, wenn Bericht nicht ausgefüllt ist",
            "enableNotifications": "Benachrichtigungen aktivieren",
            "notificationsEnabled": "Benachrichtigungen sind aktiviert",
            "testNotification": "Test-Benachrichtigung (15s)",
            "testNotificationTime": "Test-Benachrichtigung (15s)",
            "appInfo": "App-Informationen",
            "language": "Sprache",
            "selectLanguage": "Sprache auswählen",
            "done": "Fertig",
            
            // Alerts
            "success": "Erfolg",
            "error": "Fehler",
            "cancel": "Abbrechen",
            "ok": "OK",
            "confirm": "Bestätigen",
            "clear": "Löschen",
            "generate": "Generieren",
            
            // Months
            "january": "Januar",
            "february": "Februar",
            "march": "März",
            "april": "April",
            "may": "Mai",
            "june": "Juni",
            "july": "Juli",
            "august": "August",
            "september": "September",
            "october": "Oktober",
            "november": "November",
            "december": "Dezember",
            
            // Weekdays
            "monday": "Montag",
            "tuesday": "Dienstag",
            "wednesday": "Mittwoch",
            "thursday": "Donnerstag",
            "friday": "Freitag",
            "saturday": "Samstag",
            "sunday": "Sonntag",
            
            // Common
            "working": "Arbeit",
            "sick": "Krank",
            "day": "Tag",
            "hours": "Stunden",
            "hour": "Stunde",
            "km": "km",
            "litersUnit": "L",
            "currencyUnit": "CZK",
            
            // Additional UI translations
            "newRecord": "Neuer Eintrag",
            "timeData": "Zeitdaten",
            "kilometersAndLocation": "Kilometer und Ort",
            "note": "Notiz",
            "dateAndTime": "Datum und Zeit",
            "amountAndPrice": "Menge und Preis",
            "enterStation": "Station eingeben",
            "enterNote": "Notiz eingeben",
            "newCustomer": "Neuer Kunde",
            "customerInfo": "Kundeninformationen",
            "back": "Zurück",
            
            // Time Input Settings
            "timeInputSettings": "Zeiteingabe",
            "useTimePicker": "Zeitauswahl verwenden",
            "timePickerDescription": "Zeit wird mit Stunden und Minuten eingegeben",
            "textInputDescription": "Zeit wird als Dezimalzahl eingegeben (z.B. 6,5)",
            "textMode": "Textmodus",
            "timePickerMode": "Zeitauswahl",
            "textModeDescription": "6,5 = 6 Stunden 30 Minuten",
            "timePickerDescription2": "Präzise Stunden- und Minuten-Einstellung"
        ]
    }
    
    func getString(for key: String, language: Language) -> String {
        switch language {
        case .czech:
            return czechStrings[key] ?? key
        case .english:
            return englishStrings[key] ?? key
        case .german:
            return germanStrings[key] ?? key
        }
    }
}

// MARK: - Extensions for easier usage
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(self)
    }
}

// MARK: - Date formatting extensions
extension Date {
    func localizedMonthYear(for language: Language) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
    
    func localizedMonth(for language: Language) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.rawValue)
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }
}
