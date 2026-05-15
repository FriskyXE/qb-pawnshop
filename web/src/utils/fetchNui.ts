export async function fetchNui<T = any>(
  eventName: string,
  data?: any,
  mockData?: T
): Promise<T> {
  const options = {
    method: "post",
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
    },
    body: JSON.stringify(data),
  };

  if (import.meta.env.MODE === "development" && mockData) {
    return mockData;
  }

  const resourceName = (window as any).GetParentResourceName
    ? (window as any).GetParentResourceName()
    : "qb-pawnshop";

  const resp = await fetch(`https://${resourceName}/${eventName}`, options);

  const respFormatted = await resp.json();

  return respFormatted;
}
