import React, { useState, useEffect } from "react";
import { signOut } from "firebase/auth";
import {
  collection,
  query,
  orderBy,
  onSnapshot,
} from "firebase/firestore";
import { auth, db } from "../firebase";
import {
  LogOut,
  Flag,
  MessageSquare,
  Bug,
  Star,
  Lightbulb,
  MessageCircle,
  BookOpen,
} from "lucide-react";
import ReportsTab from "./ReportsTab";
import CommentsTab from "./CommentsTab";
import CatalogTab from "./CatalogTab";

function getFeedbackTypeIcon(type) {
  switch (type) {
    case "problem":    return <Bug className="w-4 h-4 text-red-500" />;
    case "review":     return <Star className="w-4 h-4 text-yellow-500" />;
    case "suggestion": return <Lightbulb className="w-4 h-4 text-blue-500" />;
    default:           return <MessageCircle className="w-4 h-4 text-gray-500" />;
  }
}

function getFeedbackTypeBadge(type) {
  switch (type) {
    case "problem":    return "text-red-700 bg-red-100";
    case "review":     return "text-yellow-700 bg-yellow-100";
    case "suggestion": return "text-blue-700 bg-blue-100";
    default:           return "text-gray-700 bg-gray-100";
  }
}

function FeedbacksTab() {
  const [feedbacks, setFeedbacks] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, "feedbacks"), orderBy("createdAt", "desc"));
    const unsubscribe = onSnapshot(q, (snap) => {
      setFeedbacks(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      setLoading(false);
    });
    return unsubscribe;
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <div className="bg-white shadow overflow-hidden sm:rounded-md">
      <ul className="divide-y divide-gray-200">
        {feedbacks.length === 0 ? (
          <li className="px-6 py-8 text-center text-gray-500">
            Nenhum feedback recebido ainda.
          </li>
        ) : (
          feedbacks.map((feedback) => (
            <li key={feedback.id} className="px-6 py-4">
              <div className="flex items-start space-x-4">
                <div className="flex-shrink-0 mt-1">
                  {getFeedbackTypeIcon(feedback.type)}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center space-x-3 mb-1">
                    <span
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getFeedbackTypeBadge(feedback.type)}`}
                    >
                      {feedback.typeLabel || feedback.type}
                    </span>
                    <span className="text-xs text-gray-500">
                      {feedback.createdAt
                        ? new Date(feedback.createdAt.toDate()).toLocaleString("pt-BR")
                        : "—"}
                    </span>
                  </div>
                  <p className="text-sm text-gray-900 whitespace-pre-wrap">
                    {feedback.message}
                  </p>
                  <p className="text-xs text-gray-500 mt-2">
                    {feedback.userEmail || "Sem email"} · ID: {feedback.userId || "—"}
                  </p>
                </div>
              </div>
            </li>
          ))
        )}
      </ul>
    </div>
  );
}

const TABS = [
  { key: "reports",   label: "Denúncias",   Icon: Flag },
  { key: "feedbacks", label: "Feedbacks",   Icon: MessageSquare },
  { key: "comments",  label: "Comentários", Icon: MessageCircle },
  { key: "catalog",   label: "Catálogo",    Icon: BookOpen },
];

function Dashboard({ user }) {
  const [activeTab, setActiveTab] = useState("reports");
  const [reportCount, setReportCount] = useState(0);
  const [feedbackCount, setFeedbackCount] = useState(0);

  useEffect(() => {
    const unsubReports = onSnapshot(
      query(collection(db, "adminNotifications"), orderBy("timestamp", "desc")),
      (snap) => setReportCount(snap.size),
    );
    const unsubFeedbacks = onSnapshot(
      query(collection(db, "feedbacks"), orderBy("createdAt", "desc")),
      (snap) => setFeedbackCount(snap.size),
    );
    return () => { unsubReports(); unsubFeedbacks(); };
  }, []);

  const handleLogout = async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error("Error signing out:", error);
    }
  };

  const badgeFor = (key) => {
    if (key === "reports")   return reportCount > 0 ? reportCount : null;
    if (key === "feedbacks") return feedbackCount > 0 ? feedbackCount : null;
    return null;
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">WeGig Admin</h1>
              <p className="text-sm text-gray-500">
                Denúncias · Feedbacks · Comentários · Catálogo
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-600">{user.email}</span>
              <button
                onClick={handleLogout}
                className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
              >
                <LogOut className="w-4 h-4 mr-2" />
                Sair
              </button>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {/* Tabs */}
        <div className="mb-6 border-b border-gray-200">
          <nav className="-mb-px flex space-x-6">
            {TABS.map(({ key, label, Icon }) => {
              const badge = badgeFor(key);
              return (
                <button
                  key={key}
                  onClick={() => setActiveTab(key)}
                  className={`py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2 ${
                    activeTab === key
                      ? "border-primary text-primary"
                      : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  {label}
                  {badge !== null && (
                    <span className="inline-flex items-center justify-center px-1.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-700">
                      {badge}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>
        </div>

        {activeTab === "reports"   && <ReportsTab />}
        {activeTab === "feedbacks" && <FeedbacksTab />}
        {activeTab === "comments"  && <CommentsTab />}
        {activeTab === "catalog"   && <CatalogTab />}
      </main>
    </div>
  );
}

export default Dashboard;
