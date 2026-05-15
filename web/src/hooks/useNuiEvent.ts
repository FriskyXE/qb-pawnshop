import { useEffect, useRef } from "react";

interface NuiMessage<T = any> {
  action: string;
  data: T;
}

export const useNuiEvent = <T = any>(
  action: string,
  handler: (data: T) => void
) => {
  const savedHandler = useRef<(data: T) => void>();

  useEffect(() => {
    savedHandler.current = handler;
  }, [handler]);

  useEffect(() => {
    const eventListener = (event: MessageEvent<NuiMessage<T>>) => {
      const { action: eventAction, data } = event.data;

      if (savedHandler.current && eventAction === action) {
        savedHandler.current(data);
      }
    };

    window.addEventListener("message", eventListener);
    return () => window.removeEventListener("message", eventListener);
  }, [action]);
};
