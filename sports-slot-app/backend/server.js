import express from 'express';
import cors from 'cors';
import { facilities, users, slots } from './data.js';
import { v4 as uuid } from 'uuid';

const app = express();
app.use(cors());
app.use(express.json());

app.post('/auth/login', (req, res) => {
  const { name, password } = req.body;
  const user = users.find(u => u.name === name && u.password === password);
  if (!user) return res.status(401).json({ message: 'Invalid credentials' });
  res.json(user);
});

app.get('/facilities', (req, res) => {
  res.json(facilities);
});

app.get('/slots', (req, res) => {
  const { status } = req.query;
  if (status) {
    return res.json(slots.filter(s => s.status === status));
  }
  res.json(slots);
});

app.post('/slots', (req, res) => {
  const { facilityId, date, startTime, endTime, requesterId } = req.body;
  slots.push({
    id: uuid(),
    facilityId,
    date,
    startTime,
    endTime,
    requesterId,
    status: 'pending'
  });
  res.json({ message: 'Request submitted' });
});

app.patch('/slots/:id', (req, res) => {
  const slot = slots.find(s => s.id === req.params.id);
  if (!slot) return res.status(404).json({ message: 'Not found' });
  slot.status = req.body.status;
  res.json({ message: 'Updated' });
});

app.listen(4000, () => console.log('Backend running on http://localhost:4000'));
