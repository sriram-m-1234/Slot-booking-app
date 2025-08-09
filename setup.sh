#!/bin/bash
echo "=== Setting up Sports Slot App ==="

# Create folder structure
mkdir -p backend frontend/src/{components,pages,store}

###################
# Backend files
###################
cat > backend/package.json <<'EOF'
{
  "name": "sports-slot-backend",
  "version": "1.0.0",
  "main": "server.js",
  "type": "module",
  "dependencies": {
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "uuid": "^9.0.0"
  }
}
EOF

cat > backend/data.js <<'EOF'
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
EOF

cat > backend/server.js <<'EOF'
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
EOF

###################
# Frontend files
###################
cat > frontend/package.json <<'EOF'
{
  "name": "sports-slot-frontend",
  "version": "1.0.0",
  "dependencies": {
    "@reduxjs/toolkit": "^1.9.7",
    "axios": "^1.4.0",
    "react": "^18.3.1",
    "react-big-calendar": "^1.8.5",
    "moment": "^2.29.4",
    "react-dom": "^18.3.1",
    "react-redux": "^8.1.2",
    "react-router-dom": "^6.14.1"
  }
}
EOF

cat > frontend/src/store/store.js <<'EOF'
import { configureStore, createSlice } from '@reduxjs/toolkit';

const authSlice = createSlice({
  name: 'auth',
  initialState: { user: null },
  reducers: {
    loginSuccess(state, action) { state.user = action.payload; },
    logout(state) { state.user = null; }
  }
});

export const { loginSuccess, logout } = authSlice.actions;

export const store = configureStore({
  reducer: { auth: authSlice.reducer }
});
EOF

cat > frontend/src/App.js <<'EOF'
import React from "react";
import { BrowserRouter, Routes, Route, Link } from "react-router-dom";
import PublicTimetable from "./pages/PublicTimetable";
import Login from "./pages/Login";
import RequestSlot from "./pages/RequestSlot";
import Approvals from "./pages/Approvals";
import { useSelector, useDispatch } from "react-redux";
import { logout } from "./store/store";

export default function App() {
  const user = useSelector(s => s.auth.user);
  const dispatch = useDispatch();

  return (
    <BrowserRouter>
      <nav>
        <Link to="/">Timetable</Link> |{" "}
        {user?.role === 'coordinator' && <Link to="/request">Request Slot</Link>} |{" "}
        {user?.role === 'committee' && <Link to="/approvals">Approvals</Link>} |{" "}
        {user ? (
          <button onClick={() => dispatch(logout())}>Logout</button>
        ) : (
          <Link to="/login">Login</Link>
        )}
      </nav>
      <Routes>
        <Route path="/" element={<PublicTimetable />} />
        <Route path="/login" element={<Login />} />
        <Route path="/request" element={<RequestSlot />} />
        <Route path="/approvals" element={<Approvals />} />
      </Routes>
    </BrowserRouter>
  );
}
EOF

cat > frontend/src/components/SlotCalendar.js <<'EOF'
import { Calendar, momentLocalizer } from "react-big-calendar";
import moment from "moment";
import "react-big-calendar/lib/css/react-big-calendar.css";

const localizer = momentLocalizer(moment);

export default function SlotCalendar({ events }) {
  return (
    <Calendar
      localizer={localizer}
      events={events}
      startAccessor="start"
      endAccessor="end"
      views={["week", "day"]}
      style={{ height: 500 }}
    />
  );
}
EOF

cat > frontend/src/pages/PublicTimetable.js <<'EOF'
import React, { useEffect, useState } from "react";
import axios from "axios";
import SlotCalendar from "../components/SlotCalendar";

export default function PublicTimetable() {
  const [slots, setSlots] = useState([]);
  const [facilities, setFacilities] = useState([]);

  useEffect(() => {
    axios.get("http://localhost:4000/facilities").then(res => setFacilities(res.data));
  }, []);

  useEffect(() => {
    if (facilities.length > 0) {
      axios.get("http://localhost:4000/slots?status=approved").then(res => {
        setSlots(res.data.map(s => ({
          title: facilities.find(f => f.id === s.facilityId)?.name || s.facilityId,
          start: new Date(`${s.date}T${s.startTime}`),
          end: new Date(`${s.date}T${s.endTime}`)
        })));
      });
    }
  }, [facilities]);

  return <SlotCalendar events={slots} />;
}
EOF

cat > frontend/src/pages/Login.js <<'EOF'
import React, { useState } from "react";
import axios from "axios";
import { useDispatch } from "react-redux";
import { loginSuccess } from "../store/store";
import { useNavigate } from "react-router-dom";

export default function Login() {
  const [name, setName] = useState("");
  const [password, setPassword] = useState("");
  const dispatch = useDispatch();
  const navigate = useNavigate();

  const login = async (e) => {
    e.preventDefault();
    try {
      const res = await axios.post("http://localhost:4000/auth/login", { name, password });
      dispatch(loginSuccess(res.data));
      navigate("/");
    } catch {
      alert("Invalid credentials");
    }
  };

  return (
    <form onSubmit={login}>
      <input value={name} onChange={e => setName(e.target.value)} placeholder="Name" />
      <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="Password" />
      <button type="submit">Login</button>
    </form>
  );
}
EOF

cat > frontend/src/pages/RequestSlot.js <<'EOF'
import React, { useEffect, useState } from "react";
import axios from "axios";
import { useSelector } from "react-redux";

export default function RequestSlot() {
  const [facilities, setFacilities] = useState([]);
  const [form, setForm] = useState({ facilityId: '', date: '', startTime: '', endTime: '' });
  const user = useSelector(s => s.auth.user);

  useEffect(() => {
    axios.get("http://localhost:4000/facilities").then(res => setFacilities(res.data));
  }, []);

  const submit = async e => {
    e.preventDefault();
    await axios.post("http://localhost:4000/slots", { ...form, requesterId: user.id });
    alert("Slot request sent");
  };

  return (
    <form onSubmit={submit}>
      <select value={form.facilityId} onChange={e => setForm({ ...form, facilityId: e.target.value })}>
        <option value="">Select Facility</option>
        {facilities.map(f => <option key={f.id} value={f.id}>{f.name}</option>)}
      </select>
      <input type="date" onChange={e => setForm({...form, date: e.target.value})} />
      <input type="time" onChange={e => setForm({...form, startTime: e.target.value})} />
      <input type="time" onChange={e => setForm({...form, endTime: e.target.value})} />
      <button type="submit">Request</button>
    </form>
  );
}
EOF

cat > frontend/src/pages/Approvals.js <<'EOF'
import React, { useEffect, useState } from "react";
import axios from "axios";

export default function Approvals() {
  const [pending, setPending] = useState([]);

  const fetchPending = () => {
    axios.get("http://localhost:4000/slots?status=pending").then(res => setPending(res.data));
  };

  useEffect(() => { fetchPending(); }, []);

  const updateStatus = async (id, status) => {
    await axios.patch(`http://localhost:4000/slots/${id}`, { status });
    fetchPending();
  };

  return (
    <div>
      <h2>Pending Requests</h2>
      {pending.map(s => (
        <div key={s.id}>
          Facility: {s.facilityId} | Date: {s.date} | {s.startTime} - {s.endTime}
          <button onClick={() => updateStatus(s.id, 'approved')}>Approve</button>
          <button onClick={() => updateStatus(s.id, 'rejected')}>Reject</button>
        </div>
      ))}
    </div>
  );
}
EOF

###################
# Install and launch
###################
echo "Installing backend dependencies..."
(cd backend && npm install)

echo "Installing frontend dependencies..."
(cd frontend && npm install)

echo "Launching backend and frontend..."
(cd backend && node server.js &)  
(cd frontend && npm start &)

echo "=== Setup complete! ==="
echo "Backend: http://localhost:4000"
echo "Frontend: http://localhost:3000"
echo "Login as Alice(pass1), Bob(pass2), or Viewer(pass3)"
