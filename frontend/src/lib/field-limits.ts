// Match service_net.field_limits: Unicode code points, including astral emoji.
export const MEETING_TITLE_MAX = 50;
export const USER_NAME_MAX = 32;
export const ROOM_NAME_MAX = 20;
export const textLength = (value: string) => Array.from(value).length;
export const limitText = (value: string, max: number) => Array.from(value).slice(0, max).join('');
