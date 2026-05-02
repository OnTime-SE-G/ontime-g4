# Epic 01 Messaging

This folder is for the messaging backbone of OnTime G4. It covers Mosquitto, Kafka, the MQTT to Kafka bridge, and the WebSocket bridge used by G3.

## What belongs here

1. Mosquitto broker configuration and certificates.
2. Kafka cluster configuration and topic setup.
3. MQTT to Kafka bridge configuration.
4. WebSocket bridge for G3 updates.
5. Stubs and smoke tests for local verification.

## Issue order

1. G4-01 Deploy Mosquitto MQTT broker.
2. G4-02 Configure Mosquitto TLS.
3. G4-03 Deploy Apache Kafka cluster.
4. G4-04 Create and configure the five Kafka topics.
5. G4-05 Deploy the MQTT to Kafka bridge connector.
6. G4-06 Verify the end-to-end MQTT to Kafka flow.
7. G4-07 Deploy the WebSocket bridge for G3.
8. G4-08 Load test the MQTT broker.

## Key references

1. SDD section 2.2 for the messaging backbone.
2. SDD section 4.1 for the Kafka topic contract.
3. SDD section 6.3 for the Socket.IO room design.
4. SRS requirements FR-G4-02 and NFR-REL-03.

## Start here

1. Work only inside this folder.
2. Create the epic branch before feature work.
3. Use the local Docker Compose stack for validation.
4. Run the smoke test before opening a PR.


