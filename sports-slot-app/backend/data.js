import { v4 as uuid } from 'uuid';

export const facilities = [
  { id: '1', name: 'Basketball Court' },
  { id: '2', name: 'Football Ground' },
  { id: '3', name: 'Badminton Hall' },
];

export const users = [
  { id: 'u1', name: 'Alice', role: 'coordinator', password: 'pass1' },
  { id: 'u2', name: 'Bob', role: 'committee', password: 'pass2' },
  { id: 'u3', name: 'Viewer', role: 'public', password: 'pass3' }
];

export let slots = [];
