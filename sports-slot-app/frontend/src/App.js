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
