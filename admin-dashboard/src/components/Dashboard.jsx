import React, { useState, useEffect } from "react";
import { signOut } from "firebase/auth";
import { auth, db } from "../firebase";
import {
  collection,
  query,
  orderBy,
  onSnapshot,
  doc,
  updateDoc,
} from "firebase/firestore";
import {
  LogOut,
  AlertTriangle,
  CheckCircle,
  Clock,
  Flag,
  MessageSquare,
  Bug,
  Star,
  Lightbulb,
  MessageCircle,
} from "lucide-react";

function Dashboard({ user }) {
  const [reports, setReports] = useState([]);
  const [feedbacks, setFeedbacks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all"); // all, unread, high
  const [activeTab, setActiveTab] = useState("reports"); // reports, feedbacks

  useEffect(() => {
    // Listen to adminNotifications collection
    const q = query(
      collection(db, "adminNotifications"),
      orderBy("timestamp", "desc"),
    );

    const unsubscribe = onSnapshot(q, (querySnapshot) => {
      const reportsData = [];
      querySnapshot.forEach((doc) => {
        reportsData.push({ id: doc.id, ...doc.data() });
      });
      setReports(reportsData);
      setLoading(false);
    });

    // Listen to feedbacks collection
    const feedbackQuery = query(
      collection(db, "feedbacks"),
      orderBy("createdAt", "desc"),
    );

    const unsubscribeFeedbacks = onSnapshot(feedbackQuery, (querySnapshot) => {
      const feedbacksData = [];
      querySnapshot.forEach((doc) => {
        feedbacksData.push({ id: doc.id, ...doc.data() });
      });
      setFeedbacks(feedbacksData);
    });

    return () => {
      unsubscribe();
      unsubscribeFeedbacks();
    };
  }, []);

  const handleLogout = async () => {
    try {
      await signOut(auth);
    } catch (error) {
      console.error("Error signing out:", error);
    }
  };

  const markAsRead = async (reportId) => {
    try {
      const reportRef = doc(db, "adminNotifications", reportId);
      await updateDoc(reportRef, { read: true });
    } catch (error) {
      console.error("Error marking as read:", error);
    }
  };

  const getPriorityColor = (priority) => {
    switch (priority) {
      case "high":
        return "text-red-600 bg-red-100";
      case "normal":
        return "text-yellow-600 bg-yellow-100";
      default:
        return "text-gray-600 bg-gray-100";
    }
  };

  const getPriorityIcon = (priority) => {
    switch (priority) {
      case "high":
        return <AlertTriangle className="w-4 h-4" />;
      default:
        return <Flag className="w-4 h-4" />;
    }
  };

  const getFeedbackTypeIcon = (type) => {
    switch (type) {
      case "problem":
        return <Bug className="w-4 h-4 text-red-500" />;
      case "review":
        return <Star className="w-4 h-4 text-yellow-500" />;
      case "suggestion":
        return <Lightbulb className="w-4 h-4 text-blue-500" />;
      default:
        return <MessageCircle className="w-4 h-4 text-gray-500" />;
    }
  };

  const getFeedbackTypeBadge = (type) => {
    switch (type) {
      case "problem":
        return "text-red-700 bg-red-100";
      case "review":
        return "text-yellow-700 bg-yellow-100";
      case "suggestion":
        return "text-blue-700 bg-blue-100";
      default:
        return "text-gray-700 bg-gray-100";
    }
  };

  const filteredReports = reports.filter((report) => {
    if (filter === "unread") return !report.read;
    if (filter === "high") return report.priority === "high";
    return true;
  });

  const unreadCount = reports.filter((r) => !r.read).length;
  const highPriorityCount = reports.filter((r) => r.priority === "high").length;

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-gray-600">Carregando relatórios...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                WeGig Admin Dashboard
              </h1>
              <p className="text-sm text-gray-600">
                Gerencie denúncias, feedbacks e modere conteúdo
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <span className="text-sm text-gray-600">Olá, {user.email}</span>
              <button
                onClick={handleLogout}
                className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary"
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
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveTab("reports")}
              className={`py-4 px-1 border-b-2 font-medium text-sm flex items-center space-x-2 ${
                activeTab === "reports"
                  ? "border-primary text-primary"
                  : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              }`}
            >
              <Flag className="w-4 h-4" />
              <span>Denúncias ({reports.length})</span>
            </button>
            <button
              onClick={() => setActiveTab("feedbacks")}
              className={`py-4 px-1 border-b-2 font-medium text-sm flex items-center space-x-2 ${
                activeTab === "feedbacks"
                  ? "border-primary text-primary"
                  : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              }`}
            >
              <MessageSquare className="w-4 h-4" />
              <span>Feedbacks ({feedbacks.length})</span>
            </button>
          </nav>
        </div>

        {activeTab === "reports" && (
          <>
            {/* Stats */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
              <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="p-5">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <Clock className="h-6 w-6 text-gray-400" />
                    </div>
                    <div className="ml-5 w-0 flex-1">
                      <dl>
                        <dt className="text-sm font-medium text-gray-500 truncate">
                          Total de Denúncias
                        </dt>
                        <dd className="text-lg font-medium text-gray-900">
                          {reports.length}
                        </dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="p-5">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <AlertTriangle className="h-6 w-6 text-yellow-400" />
                    </div>
                    <div className="ml-5 w-0 flex-1">
                      <dl>
                        <dt className="text-sm font-medium text-gray-500 truncate">
                          Não Lidas
                        </dt>
                        <dd className="text-lg font-medium text-gray-900">
                          {unreadCount}
                        </dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white overflow-hidden shadow rounded-lg">
                <div className="p-5">
                  <div className="flex items-center">
                    <div className="flex-shrink-0">
                      <AlertTriangle className="h-6 w-6 text-red-400" />
                    </div>
                    <div className="ml-5 w-0 flex-1">
                      <dl>
                        <dt className="text-sm font-medium text-gray-500 truncate">
                          Prioridade Alta
                        </dt>
                        <dd className="text-lg font-medium text-gray-900">
                          {highPriorityCount}
                        </dd>
                      </dl>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Filters */}
            <div className="mb-6">
              <div className="flex space-x-2">
                <button
                  onClick={() => setFilter("all")}
                  className={`px-4 py-2 rounded-md text-sm font-medium ${
                    filter === "all"
                      ? "bg-primary text-white"
                      : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  Todas ({reports.length})
                </button>
                <button
                  onClick={() => setFilter("unread")}
                  className={`px-4 py-2 rounded-md text-sm font-medium ${
                    filter === "unread"
                      ? "bg-primary text-white"
                      : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  Não Lidas ({unreadCount})
                </button>
                <button
                  onClick={() => setFilter("high")}
                  className={`px-4 py-2 rounded-md text-sm font-medium ${
                    filter === "high"
                      ? "bg-primary text-white"
                      : "bg-white text-gray-700 border border-gray-300 hover:bg-gray-50"
                  }`}
                >
                  Prioridade Alta ({highPriorityCount})
                </button>
              </div>
            </div>

            {/* Reports List */}
            <div className="bg-white shadow overflow-hidden sm:rounded-md">
              <ul className="divide-y divide-gray-200">
                {filteredReports.length === 0 ? (
                  <li className="px-6 py-8 text-center text-gray-500">
                    {filter === "all"
                      ? "Nenhuma denúncia encontrada."
                      : `Nenhuma denúncia ${
                          filter === "unread"
                            ? "não lida"
                            : "de prioridade alta"
                        } encontrada.`}
                  </li>
                ) : (
                  filteredReports.map((report) => (
                    <li
                      key={report.id}
                      className={`px-6 py-4 ${!report.read ? "bg-blue-50" : ""}`}
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex-1">
                          <div className="flex items-center space-x-3">
                            <div
                              className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getPriorityColor(
                                report.priority,
                              )}`}
                            >
                              {getPriorityIcon(report.priority)}
                              <span className="ml-1 capitalize">
                                {report.priority === "high" ? "Alta" : "Normal"}
                              </span>
                            </div>
                            <span className="text-sm text-gray-500">
                              {report.targetType === "post" ? "Post" : "Perfil"}
                            </span>
                            {!report.read && (
                              <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                                Novo
                              </span>
                            )}
                          </div>
                          <div className="mt-2">
                            <h3 className="text-sm font-medium text-gray-900">
                              {report.totalReports} denúncia
                              {report.totalReports > 1 ? "s" : ""} -{" "}
                              {report.reason}
                            </h3>
                            <p className="text-sm text-gray-600 mt-1">
                              ID: {report.targetId}
                            </p>
                            {report.description && (
                              <p className="text-sm text-gray-600 mt-1 italic">
                                "{report.description}"
                              </p>
                            )}
                            <p className="text-xs text-gray-500 mt-2">
                              {new Date(
                                report.timestamp?.toDate(),
                              ).toLocaleString("pt-BR")}
                            </p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          {!report.read && (
                            <button
                              onClick={() => markAsRead(report.id)}
                              className="inline-flex items-center px-3 py-1 border border-transparent text-xs font-medium rounded-md text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                            >
                              <CheckCircle className="w-3 h-3 mr-1" />
                              Marcar como Lido
                            </button>
                          )}
                        </div>
                      </div>
                    </li>
                  ))
                )}
              </ul>
            </div>
          </>
        )}

        {activeTab === "feedbacks" && (
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
                            className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getFeedbackTypeBadge(
                              feedback.type,
                            )}`}
                          >
                            {feedback.typeLabel || feedback.type}
                          </span>
                          <span className="text-xs text-gray-500">
                            {feedback.createdAt
                              ? new Date(
                                  feedback.createdAt.toDate(),
                                ).toLocaleString("pt-BR")
                              : "—"}
                          </span>
                        </div>
                        <p className="text-sm text-gray-900 whitespace-pre-wrap">
                          {feedback.message}
                        </p>
                        <p className="text-xs text-gray-500 mt-2">
                          {feedback.userEmail || "Sem email"} · ID:{" "}
                          {feedback.userId || "—"}
                        </p>
                      </div>
                    </div>
                  </li>
                ))
              )}
            </ul>
          </div>
        )}
      </main>
    </div>
  );
}

export default Dashboard;
