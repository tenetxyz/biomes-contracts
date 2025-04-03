import type { EntityId } from "../common";

export type MessengerSchema = [
  {
    topic: "close";
    payload: undefined;
    response: undefined;
  },
  {
    topic: "ready";
    payload: undefined;
    response: undefined;
  },
  {
    topic: "requestWaypoint";
    payload: {
      target: EntityId;
      label: string;
    };
    response: undefined;
  },
];
