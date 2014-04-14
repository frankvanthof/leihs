# language: de

Funktionalität: Gegenstand bearbeiten

  Grundlage:
    Angenommen Personas existieren
    Und man ist "Matti"
    Und man editiert einen Gegenstand, wo man der Besitzer ist
    
  @javascript
  Szenario: Einen Gegenstand mit allen Informationen editieren
    Angenommen Personas existieren
    Und man ist "Matti"
    Und man navigiert zur Gegenstandsbearbeitungsseite eines Gegenstandes, der am Lager und in keinem Vertrag vorhanden ist
    Wenn ich die folgenden Informationen erfasse
      | Feldname                     | Type         | Wert                          |

      | Inventarcode                 |              | Test Inventory Code           |
      | Modell                       | autocomplete | Sharp Beamer Test             |

      | Inventarrelevant             | select       | Ja                            |
      | Anschaffungskategorie        | select       | Werkstatt-Technik             |

      | Bezug                        | radio must   | investment                    |
      | Projektnummer                |              | Test Nummer                   |
      | Rechnungsnummer              |              | Test Nummer                   |
      | Rechnungsdatum               |              | 01.01.2013                    |
      | Anschaffungswert             |              | 50.0                          |
      | Garantieablaufdatum          |              | 01.01.2013                    |
      | Vertragsablaufdatum          |              | 01.01.2013                    |

    Und ich speichern druecke
    Dann man wird zur Liste des Inventars zurueckgefuehrt
    Und ist der Gegenstand mit all den angegebenen Informationen gespeichert

