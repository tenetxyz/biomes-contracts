import type { Hex } from "ox";

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
    payload: { entityId: Hex.Hex };
    response: undefined;
  },
];
