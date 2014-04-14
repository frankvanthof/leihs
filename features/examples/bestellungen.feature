# language: de

Funktionalität: Bestellungen

  @javascript
  Szenario: Keine leeren Bestellungen in der Liste der Bestellungen
    Angenommen man ist "Pius"
    Und es existiert eine leere Bestellung
    Dann sehe ich diese Bestellung nicht in der Liste der Bestellungen

  Szenario: Sichtbare Reiter
    Angenommen ich bin Andi
    Wenn ich mich auf der Liste der Bestellungen befinde
    Dann sehe ich die Reiter "Alle, Offen, Genehmigt, Abgelehnt"

  Szenario: Definition visierpflichtige Bestellungen
    Angenommen Personas existieren
    Und es existiert eine visierpflichtige Bestellung
    Dann wurde diese Bestellung von einem Benutzer aus einer visierpflichtigen Gruppe erstellt
    Und diese Bestellung beinhaltet ein Modell aus einer visierpflichtigen Gruppe

  @javascript
  Szenario: Alle Bestellungen anzeigen - Reiter Alle Bestellungen
    Angenommen ich bin Andi
    Und ich befinde mich im Gerätepark mit visierpflichtigen Bestellungen
    Und ich mich auf der Liste der Bestellungen befinde
    Wenn ich den Reiter "Alle" einsehe
    Dann sehe ich alle visierpflichtigen Bestellungen
    Und diese Bestellungen sind nach Erstelltdatum aufgelistet

  @javascript
  Szenario: Reiter Offene Bestellungen Darstellung
    Angenommen ich bin Andi
    Und ich befinde mich im Gerätepark mit visierpflichtigen Bestellungen
    Und ich mich auf der Liste der Bestellungen befinde
    Wenn ich den Reiter "Offen" einsehe
    Dann sehe ich alle offenen visierpflichtigen Bestellungen
    Und ich sehe auf der Bestellungszeile den Besteller mit Popup-Ansicht der Benutzerinformationen
    Und ich sehe auf der Bestellungszeile das Erstelldatum
    Und ich sehe auf der Bestellungszeile die Anzahl Gegenstände mit Popup-Ansicht der bestellten Gegenstände
    Und ich sehe auf der Bestellungszeile die Dauer der Bestellung
    Und ich sehe auf der Bestellungszeile den Zweck
    Und ich kann die Bestellung genehmigen
    Und ich kann die Bestellung ablehnen
    Und ich kann die Bestellung editieren
    Und ich kann keine Bestellungen aushändigen
