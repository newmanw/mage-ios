//
//  ObservationTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs

@testable import MAGE

class ObservationTests: KIFSpec {
    
    override func spec() {
        
        describe("Transformation Tests") {
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                Server.setCurrentEventId(1);
                UserDefaults.standard.currentUserId = "userabc";
                NSManagedObject.mr_setDefaultBatchSize(0);
                ObservationPushService.singleton()?.start();
            }
            
            afterEach {
                ObservationPushService.singleton().stop();
                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("should create an observation with geometry") {
                let observation = Observation(geometry: SFPoint(x: 15, andY: 20), andAccuracy: 4.5, andProvider: "gps", andDelta: 2, in: NSManagedObjectContext.mr_default());
                expect(observation).toNot(beNil());
                expect(observation.eventId).to(equal(1));
                expect(observation.user?.username).to(equal("userabc"));
                expect(observation.dirty).to(equal(0));
                expect(observation.state).to(equal(1));
                expect(observation.getGeometry()).to(equal(SFPoint(x: 15, andY: 20)));
                let observationProperties = observation.properties!;
                expect(observationProperties["provider"] as? String).to(equal("gps"));
                expect(observationProperties["accuracy"] as? NSNumber).to(equal(4.5));
                expect(observationProperties["delta"] as? Int).to(equal(2));
                expect(observationProperties["forms"]).toNot(beNil());
            }
        }
        
        describe("Field Tests") {
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                Server.setCurrentEventId(1);
                NSManagedObject.mr_setDefaultBatchSize(0);
            }
            
            afterEach {
                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.clearAndSetUpStack();
            }
            
            it("should get the primary field name") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "testfield";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi"
                    ]
                ]
                
                expect(observation.getPrimaryField()).to(equal("testfield"))
            }
            
            it("should get the secondary field name") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "testfield";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "testfield": "Hi"
                    ]
                ]
                
                expect(observation.getSecondaryField()).to(equal("testfield"))
            }
            
            it("should get text for text field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field7";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field7": "Hi"
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("Hi"))
            }
            
            it("should get text for multiselectdropdown field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field21";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field21": ["Purple", "Blue"]
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("Purple, Blue"))
            }
            
            it("should get text for dropdown field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "type";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "type": "Parade Event"
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("Parade Event"))
            }
            
            it("should get text for textarea field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field6";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field6": "text area field"
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("text area field"))
            }
            
            it("should get text for date field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field11";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field11": "2017-02-10T10:20:30.111Z"
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("2017-02-10 03:20 MST"))
            }
            
            it("should get text for email field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field12";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field12": "test@example.com"
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("test@example.com"))
            }
            
            it("should get text for number field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field13";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field13": 8
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("8"))
            }
            
            it("should get text for password field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field14";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field14": "secret"
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("secret"))
            }
            
            it("should get text for radio field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field15";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field15": "blue"
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("blue"))
            }
            
            it("should get text for checkbox field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field19";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field19": 1
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("YES"))
            }
            
            it("should get text for location field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field22";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field22": ["type": "Point", "coordinates": [-104.89900236793747, 39.6272948483364]]
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("39.627295, -104.899002"))
            }
            
            it("should get text for location field set as SFGeometry") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryField"] = "field22";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field22": GeometryDeserializer.parseGeometry(["type": "Point", "coordinates": [-104.89900236793747, 39.6272948483364]])!
                    ]
                ]
                
                expect(observation.primaryFieldText()).to(equal("39.627295, -104.899002"))
            }
            
            it("should get text for text secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field7";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field7": "Hi"
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("Hi"))
            }
            
            it("should get text for multiselectdropdown secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field21";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field21": ["Purple", "Blue"]
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("Purple, Blue"))
            }
            
            it("should get text for dropdown secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "type";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "type": "Parade Event"
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("Parade Event"))
            }
            
            it("should get text for textarea secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field6";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field6": "text area field"
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("text area field"))
            }
            
            it("should get text for date secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field11";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field11": "2017-02-10T10:20:30.111Z"
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("2017-02-10 03:20 MST"))
            }
            
            it("should get text for email secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field12";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field12": "test@example.com"
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("test@example.com"))
            }
            
            it("should get text for number secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field13";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field13": 8
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("8"))
            }
            
            it("should get text for password secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field14";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field14": "secret"
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("secret"))
            }
            
            it("should get text for radio secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field15";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field15": "blue"
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("blue"))
            }
            
            it("should get text for checkbox secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field19";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field19": 1
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("YES"))
            }
            
            it("should get text for location secondary field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field22";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field22": ["type": "Point", "coordinates": [-104.89900236793747, 39.6272948483364]]
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("39.627295, -104.899002"))
            }
            
            it("should get text for location secondary field set as SFGeometry") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["variantField"] = "field22";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field22": GeometryDeserializer.parseGeometry(["type": "Point", "coordinates": [-104.89900236793747, 39.6272948483364]])!
                    ]
                ]
                
                expect(observation.secondaryFieldText()).to(equal("39.627295, -104.899002"))
            }
            
            it("should get text for text feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field7";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field7": "Hi"
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("Hi"))
            }
            
            it("should get text for multiselectdropdown feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field21";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field21": ["Purple", "Blue"]
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("Purple, Blue"))
            }
            
            it("should get text for dropdown feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "type";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "type": "Parade Event"
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("Parade Event"))
            }
            
            it("should get text for textarea feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field6";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field6": "text area field"
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("text area field"))
            }
            
            it("should get text for date feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field11";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field11": "2017-02-10T10:20:30.111Z"
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("2017-02-10 03:20 MST"))
            }
            
            it("should get text for email feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field12";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field12": "test@example.com"
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("test@example.com"))
            }
            
            it("should get text for number feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field13";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field13": 8
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("8"))
            }
            
            it("should get text for password feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field14";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field14": "secret"
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("secret"))
            }
            
            it("should get text for radio feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field15";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field15": "blue"
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("blue"))
            }
            
            it("should get text for checkbox feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field19";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field19": 1
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("YES"))
            }
            
            it("should get text for location feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field22";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field22": ["type": "Point", "coordinates": [-104.89900236793747, 39.6272948483364]]
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("39.627295, -104.899002"))
            }
            
            it("should get text for location feed field set as SFGeometry") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field22";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field22": GeometryDeserializer.parseGeometry(["type": "Point", "coordinates": [-104.89900236793747, 39.6272948483364]])!
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal("39.627295, -104.899002"))
            }
            
            it("should get text for text feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field7";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for multiselectdropdown feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field21";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for dropdown feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "type";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for textarea feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field6";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for date feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field11";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for email feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field12";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for number feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field13";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for password feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field14";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for radio feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field15";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for checkbox feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field19";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for a location feed field that is not set") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field22";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26
                    ]
                ]
                
                expect(observation.primaryFeedFieldText()).to(equal(""))
            }
            
            it("should get text for secondary text feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["primaryFeedField"] = "field7";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field7": "Hi"
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("Hi"))
            }
            
            it("should get text for secondary multiselectdropdown feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field21";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field21": ["Purple", "Blue"]
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("Purple, Blue"))
            }
            
            it("should get text for secondary dropdown feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "type";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "type": "Parade Event"
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("Parade Event"))
            }
            
            it("should get text for secondary textarea feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field6";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field6": "text area field"
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("text area field"))
            }
            
            it("should get text for secondary date feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field11";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field11": "2017-02-10T10:20:30.111Z"
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("2017-02-10 03:20 MST"))
            }
            
            it("should get text for secondary email feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field12";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field12": "test@example.com"
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("test@example.com"))
            }
            
            it("should get text for secondary number feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field13";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field13": 8
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("8"))
            }
            
            it("should get text for secondary password feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field14";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field14": "secret"
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("secret"))
            }
            
            it("should get text for secondary radio feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field15";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field15": "blue"
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("blue"))
            }
            
            it("should get text for secondary checkbox feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field19";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field19": 1
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("YES"))
            }
            
            it("should get text for secondary location feed field") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field22";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field22": ["type": "Point", "coordinates": [-104.89900236793747, 39.6272948483364]]
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("39.627295, -104.899002"))
            }
            
            it("should get text for secondary location feed field set as SFGeometry") {
                var formsJson = MageCoreDataFixtures.parseJsonFile(jsonFile: "allTheThings") as! [[AnyHashable: Any]];
                
                formsJson[0]["secondaryFeedField"] = "field22";
                
                MageCoreDataFixtures.addEventFromJson(remoteId: 1, name: "Event", formsJson: formsJson)
                
                let observation = ObservationBuilder.createBlankObservation(1);
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                observation.properties!["forms"] = [
                    [
                        "formId": 26,
                        "field22": GeometryDeserializer.parseGeometry(["type": "Point", "coordinates": [-104.89900236793747, 39.6272948483364]])!
                    ]
                ]
                
                expect(observation.secondaryFeedFieldText()).to(equal("39.627295, -104.899002"))
            }
        }
        
        describe("Route Tests") {
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                UserDefaults.standard.baseServerUrl = "https://magetest";

                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                Server.setCurrentEventId(1);
                UserDefaults.standard.currentUserId = "userabc";
                NSManagedObject.mr_setDefaultBatchSize(0);
                ObservationPushService.singleton()?.start();
            }
            
            afterEach {
                ObservationPushService.singleton().stop();
                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("should pull the observations as initial") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations") &&
                        containsQueryParams(["sort": "lastModified+DESC"])
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    let stubPath = OHPathForFile("observations.json", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                ObservationFetchService.singleton()?.start(asInitial: true);
                expect(stubCalled).toEventually(beTrue());
                expect(Observation.mr_findAll()?.count).toEventually(equal(1));
                ObservationFetchService.singleton()?.stop();
            }
            
            it("should pull the observations as initial and then update one") {
                var stubCalled = false;
                
                stub(condition: isMethodGET() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations") &&
                        containsQueryParams(["sort": "lastModified+DESC"])
                ) { (request) -> HTTPStubsResponse in
                    stubCalled = true;
                    let stubPath = OHPathForFile("observations.json", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                ObservationFetchService.singleton()?.start(asInitial: true);
                expect(stubCalled).toEventually(beTrue());
                expect(Observation.mr_findAll()?.count).toEventually(equal(1));
                ObservationFetchService.singleton()?.stop();
                let firstObservation1 = Observation.mr_findFirst();
                let forms1: [[AnyHashable : Any]] = firstObservation1?.properties!["forms"] as! [[AnyHashable : Any]];
                expect(forms1[0]["field2"] as? String).to(equal("Test"))
                
                HTTPStubs.removeAllStubs();
                
                var updateStubCalled = false;
                
                stub(condition: isMethodGET() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations") &&
                        containsQueryParams(["sort": "lastModified+DESC"])
                ) { (request) -> HTTPStubsResponse in
                    updateStubCalled = true;
                    let stubPath = OHPathForFile("observationsUpdate.json", ObservationTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                ObservationFetchService.singleton()?.start(asInitial: true);
                expect(updateStubCalled).toEventually(beTrue());
                expect(Observation.mr_findAll()?.count).toEventually(equal(1));
                ObservationFetchService.singleton()?.stop();
                let firstObservation = Observation.mr_findFirst();
                let forms: [[AnyHashable : Any]] = firstObservation?.properties!["forms"] as! [[AnyHashable : Any]];
                expect(forms[0]["field2"] as? String).to(equal("Buffalo"))
            }
            
            it("should tell the server to delete an observation") {
                
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                var stubCalled = false;
                
                stub(condition: isMethodPOST() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabc/states") &&
                        hasJsonBody(["name": "archive"])
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [ : ];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                expect(observation).toNot(beNil());
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let localObservation = observation.mr_(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    // archive the observation
                    localObservation.state = 0;
                    localObservation.dirty = true;
                })
                
                expect(stubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()).toEventually(beNil());
            }
            
            it("should tell the server to delete an observation and remove it if a 404 is returned") {
                
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                var stubCalled = false;
                
                stub(condition: isMethodPOST() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabc/states") &&
                        hasJsonBody(["name": "archive"])
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [ : ];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 404, headers: nil);
                }
                
                expect(observation).toNot(beNil());
                observation.delete(completion: nil);
                
                expect(stubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()).toEventually(beNil());
                expect(ObservationPushService.singleton().isPushingObservations()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should tell the server to create an observation") {
                var idStubCalled = false;
                var createStubCalled = false;
                
                stub(condition: isMethodPOST() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/id")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [
                        "id" : "observationabctest",
                        "url": "https://magetest/api/events/1/observations/observationabctest"
                    ];
                    idStubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var expectedObservationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                expectedObservationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                expectedObservationJson["id"] = "observationabctest";
                expectedObservationJson["important"] = nil;
                expectedObservationJson["favoriteUserIds"] = nil;
                expectedObservationJson["attachments"] = nil;
                expectedObservationJson["lastModified"] = nil;
                expectedObservationJson["createdAt"] = nil;
                expectedObservationJson["eventId"] = nil;
                expectedObservationJson["timestamp"] = "2020-06-05T17:21:46.969Z";
                expectedObservationJson["state"] = [
                    "name": "active"
                ]
                
                stub(condition: isMethodPUT() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest")
                        &&
                        hasJsonBody(expectedObservationJson)
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [
                        "id" : "observationabctest",
                        "url": "https://magetest/api/events/1/observations/observationabctest"
                    ];
                    createStubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = nil;
                observationJson["id"] = nil;
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let localObservation = observation.mr_(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    localObservation.dirty = true;
                })
                
                expect(idStubCalled).toEventually(beTrue());
                expect(createStubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()!.dirty).toEventually(equal(0));
            }
            
            it("should tell the server to update an observation") {
                var updateStubCalled = false;
                
                var expectedObservationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                expectedObservationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                expectedObservationJson["id"] = "observationabctest";
                expectedObservationJson["important"] = nil;
                expectedObservationJson["favoriteUserIds"] = nil;
                expectedObservationJson["attachments"] = nil;
                expectedObservationJson["lastModified"] = nil;
                expectedObservationJson["createdAt"] = nil;
                expectedObservationJson["eventId"] = nil;
                expectedObservationJson["timestamp"] = "2020-06-05T17:21:46.969Z";
                expectedObservationJson["state"] = [
                    "name": "active"
                ]
                
                stub(condition: isMethodPUT() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest")
                        &&
                        hasJsonBody(expectedObservationJson)
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [
                        "id" : "observationabctest",
                        "url": "https://magetest/api/events/1/observations/observationabctest"
                    ];
                    updateStubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let localObservation = observation.mr_(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    localObservation.dirty = true;
                })
                
                expect(updateStubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()!.dirty).toEventually(equal(0));
            }
            
            it("should tell the server to add an observation favorite") {
                var stubCalled = false;
                
                stub(condition: isMethodPUT() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest/favorite")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [:];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());
                expect(Observation.mr_findFirst()!.favorites?.count).toEventually(equal(0));
                
                observation.toggleFavorite(completion: nil);
                
                expect(stubCalled).toEventually(beTrue());
                expect(Observation.mr_findFirst()!.favorites!.count).toEventually(equal(1));
                expect(Observation.mr_findFirst()!.favorites!.first!.dirty).toEventually(beFalse());
                expect(ObservationPushService.singleton().isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should tell the server to delete an observation favorite") {
                var stubCalled = false;
                
                stub(condition: isMethodDELETE() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest/favorite")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [:];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());
                expect(Observation.mr_findFirst()!.favorites?.count).toEventually(equal(1));

                observation.toggleFavorite(completion: nil);
                
                expect(stubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()!.favorites!.first!.favorite).toEventually(beFalse());
                expect(Observation.mr_findFirst()!.favorites!.first!.dirty).toEventually(beFalse());
                expect(ObservationPushService.singleton().isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should tell the server to make the observation important") {
                var stubCalled = false;
                
                stub(condition: isMethodPUT() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest/important")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [:];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());
                expect(observation.isImportant).to(beFalse());
                observation.flagImportant(withDescription: "new important")
                
                expect(stubCalled).toEventually(beTrue());
                expect(Observation.mr_findFirst()!.isImportant()).toEventually(beTrue());
                expect(ObservationPushService.singleton().isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should tell the server to remove the observation important") {
                var stubCalled = false;
                
                stub(condition: isMethodDELETE() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest/important")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [:];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = [
                    "description":"This is important",
                    "timestamp":"2020-06-05T17:21:54.220Z",
                    "userId":"userabc"];
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }

                expect(observation).toNot(beNil());
                expect(observation.isImportant()).to(beTrue());

                    observation.removeImportant()
                expect(stubCalled).toEventually(beTrue());
                expect(Observation.mr_findFirst()!.isImportant()).toEventually(beFalse());
                expect(Observation.mr_findFirst()!.observationImportant!.dirty).toEventually(equal(0));
                expect(ObservationPushService.singleton().isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
        }
    }
}
