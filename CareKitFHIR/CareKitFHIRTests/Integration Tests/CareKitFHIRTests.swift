/*
 Copyright (c) 2019, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3. Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

@testable import CareKitFHIR
import CareKitStore
import XCTest

class CareKitFHIRTests: XCTestCase {

    func testParseFHIRPatient() throws {
        let resource = OCKFHIRResourceData<R4, JSON>(data: samplePatientData)
        let patient = try OCKR4PatientCoder().decode(resource)
        XCTAssert(patient.id == "pat1")
        XCTAssert(patient.name.familyName == "Donald")
        XCTAssert(patient.name.givenName == "Duck")
    }

    func testParseFHIRCarePlanActivity() throws {
        let resource = OCKFHIRResourceData<DSTU2, JSON>(data: sampleCarePlanActivityData)
        let task = try OCKDSTU2CarePlanActivityCoder().decode(resource)
        XCTAssert(task.id == "ABC")
        XCTAssert(task.schedule.elements.first?.interval == DateComponents(day: 2))
        XCTAssert(task.schedule.elements.first?.duration == .hours(1))
    }

    func testParseFHIRMedicationOrder() throws {
        let resource = OCKFHIRResourceData<DSTU2, JSON>(data: sampleMedicationOrderData)
        var coder = OCKDSTU2MedicationOrderCoder()
        coder.getCareKitSchedule = { _ in OCKSchedule.dailyAtTime(hour: 0, minutes: 0, start: Date(), end: nil, text: nil, duration: .allDay) }
        let task = try coder.decode(resource)
        XCTAssert(task.id == "24")
        XCTAssert(task.instructions == "2 puffs every 2-4 hours")
        XCTAssert(task.schedule.elements.first?.interval == DateComponents(day: 1))
    }

    func testParseFailsWhenDataIsCorrupt() {
        let corruptData = "{badJson: missingQuotes}".data(using: .utf8)!
        let resource = OCKFHIRResourceData(release: R4.self, content: JSON.self, data: corruptData)
        let coder = OCKR4PatientCoder()

        let errorMessage = "Failed to decode FHIR Patient data. Error: The data couldn’t be read because it isn’t in the correct format."
        let expectedError = OCKFHIRCodingError.corruptData(errorMessage)
        XCTAssertThrowsError(try coder.decode(resource), matching: expectedError)
    }

    func testParseFailsWhenUnsupportedXMLContentTypeIsUsed() {
        let resource = OCKFHIRResourceData(release: R4.self, content: XML.self, data: samplePatientData)
        let errorMessage = "Failed to convert FHIR Patient to OCKPatient. Error: Unsupported encoding: XML is not supported!"
        let expectedError = OCKFHIRCodingError.unsupportedEncoding(errorMessage)
        XCTAssertThrowsError(try OCKR4PatientCoder().decode(resource), matching: expectedError)
    }

    func testEncodeCareKitPatientToR4() throws {
        let patient = OCKPatient(id: "abc", givenName: "A", familyName: "B")
        let coder = OCKR4PatientCoder()
        let data = try coder.encode(patient, format: JSON.self)
        let json = String(data: data, encoding: .utf8)!
        XCTAssert(json.contains("\"id\":\"abc\""))
        XCTAssert(json.contains("\"given\":[\"A\"]"))
        XCTAssert(json.contains("\"family\":\"B\""))
    }

    func testEncodeCareKitPatientToDSTU2() throws {
        let patient = OCKPatient(id: "abc", givenName: "A", familyName: "B")
        let coder = OCKDSTU2PatientCoder()
        let data = try coder.encode(patient, format: JSON.self)
        let json = String(data: data, encoding: .utf8)!
        XCTAssert(json.contains("\"id\":\"abc\""))
        XCTAssert(json.contains("\"given\":[\"A\"]"))
        XCTAssert(json.contains("\"family\":[\"B\"]"))
    }

    func testEncodeCareKitTaskToDSTU2MedicationOrder() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        let task = OCKTask(id: "tylenol", title: "Take Tylenol", carePlanUUID: nil, schedule: schedule)
        let coder = OCKDSTU2MedicationOrderCoder()
        let data = try coder.encode(task, format: JSON.self)
        let json = String(data: data, encoding: .utf8)!
        XCTAssert(json.contains("\"id\":\"tylenol\""))
        XCTAssert(json.contains("\"text\":\"Take Tylenol\""))
        XCTAssert(json.contains("12:00:00"))
    }

    func testEncodeCareKitTaskToDSTU2CarePlanActivity() throws {
        let schedule = OCKSchedule.dailyAtTime(hour: 12, minutes: 0, start: Date(), end: nil, text: nil)
        let task = OCKTask(id: "tylenol", title: "Take Tylenol", carePlanUUID: nil, schedule: schedule)
        let coder = OCKDSTU2CarePlanActivityCoder()
        let data = try coder.encode(task, format: JSON.self)
        let json = String(data: data, encoding: .utf8)!
        XCTAssert(json.contains("\"id\":\"tylenol\""))
        XCTAssert(json.contains("\"description\":\"Take Tylenol\""))
        XCTAssert(json.contains("12:00:00"))
    }
}

/// Sample data based on JSON borrowed from https://www.hl7.org/fhir/patient-example-a.json.html
private let samplePatientData = """
{
  "resourceType": "Patient",
  "id": "pat1",
  "identifier": [
    {
      "use": "usual",
      "type": {
        "coding": [
          {
            "system": "http://terminology.hl7.org/CodeSystem/v2-0203",
            "code": "MR"
          }
        ]
      },
      "system": "urn:oid:0.1.2.3.4.5.6.7",
      "value": "654321"
    }
  ],
  "active": true,
  "name": [
    {
      "use": "official",
      "family": "Donald",
      "given": [
        "Duck"
      ]
    }
  ],
  "gender": "male",
  "contact": [
    {
      "relationship": [
        {
          "coding": [
            {
              "system": "http://terminology.hl7.org/CodeSystem/v2-0131",
              "code": "E"
            }
          ]
        }
      ],
      "organization": {
        "reference": "Organization/1",
        "display": "Walt Disney Corporation"
      }
    }
  ],
  "managingOrganization": {
    "reference": "Organization/1",
    "display": "ACME Healthcare, Inc"
  },
  "link": [
    {
      "other": {
        "reference": "Patient/pat2"
      },
      "type": "seealso"
    }
  ]
}
""".data(using: .utf8)!

private let sampleCarePlanActivityData = """
{
  "id":"ABC",
  "detail":{
    "prohibited":false,
    "scheduledTiming":{
      "resourceType":"Timing",
      "event":[

      ],
      "repeat":{
        "boundsPeriod": {
          "start": "2019-11-07T16:49:57-08:00",
          "end": "2021-11-07T16:49:57-08:00"
        },
        "duration":3600,
        "durationUnits":"s",
        "frequency":1,
        "period":2,
        "periodUnits":"d"
      }
    }
  }
}
""".data(using: .utf8)!

private let sampleMedicationOrderData = """
{
  "status":"active",
  "note":"Please let me know if you need to use this more than three times per day",
  "id":"24",
  "medicationCodeableConcept":{
    "text":"Albuterol HFA 90 mcg",
    "coding":[
      {
        "system":"http://www.nlm.nih.gov/research/umls/rxnorm/",
        "code":"329498"
      }
    ]
  },
  "patient":{
    "display":"Candace Salinas",
    "reference":"Patient/1"
  },
  "prescriber":{
    "display":"Daren Estrada",
    "reference":"Practitioner/20"
  },
  "dateWritten":"1985-10-11",
  "resourceType":"MedicationOrder",
  "dosageInstruction":[
    {
      "text":"2 puffs every 2-4 hours"
    }
  ]
}
""".data(using: .utf8)!
