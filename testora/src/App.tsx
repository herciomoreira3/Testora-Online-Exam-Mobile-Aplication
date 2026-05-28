/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { 
  AppLang, 
  ViewState, 
  User, 
  Exam, 
  ExamAttempt, 
  ExamHistoryItem,
  INITIAL_EXAMS,
  INITIAL_HISTORY 
} from './types';

// Importing views
import SplashView from './components/SplashView';
import AuthView from './components/AuthView';
import StudentDashboard from './components/StudentDashboard';
import TeacherDashboard from './components/TeacherDashboard';
import AdminDashboard from './components/AdminDashboard';
import ExamSession from './components/ExamSession';
import ExamResultView from './components/ExamResultView';
import CreateExamView from './components/CreateExamView';
import AddQuestionView from './components/AddQuestionView';
import ProfileSettingsView from './components/ProfileSettingsView';

export default function App() {
  // Application Language state
  const [lang, setLang] = useState<AppLang>(() => {
    const saved = localStorage.getItem('testora_lang');
    return (saved as AppLang) || 'id';
  });

  // Dark mode styling state
  const [darkMode, setDarkMode] = useState<boolean>(() => {
    const saved = localStorage.getItem('testora_dark');
    return saved === 'true';
  });

  // Sync dark mode HTML classes
  useEffect(() => {
    const root = window.document.documentElement;
    if (darkMode) {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
    localStorage.setItem('testora_dark', String(darkMode));
  }, [darkMode]);

  // Save language settings to local storage
  const handleLanguageChange = (newLang: AppLang) => {
    setLang(newLang);
    localStorage.setItem('testora_lang', newLang);
  };

  // Main UI States
  const [view, setView] = useState<ViewState>('splash');
  const [previousViews, setPreviousViews] = useState<ViewState[]>([]);
  const [user, setUser] = useState<User | null>(null);

  // Active examinations data state
  const [exams, setExams] = useState<Exam[]>(() => {
    const saved = localStorage.getItem('testora_exams');
    return saved ? JSON.parse(saved) : INITIAL_EXAMS;
  });

  // Completed student attempts history
  const [history, setHistory] = useState<ExamHistoryItem[]>(() => {
    const saved = localStorage.getItem('testora_history');
    return saved ? JSON.parse(saved) : INITIAL_HISTORY;
  });

  // State coordinate for currently taken exam Session
  const [currentExam, setCurrentExam] = useState<Exam | null>(null);
  const [currentAttempt, setCurrentAttempt] = useState<ExamAttempt | null>(null);

  // State coordinate for currently configured exam during the builder flow
  const [newConfiguratingExam, setNewConfiguratingExam] = useState<Exam | null>(null);

  // Save exams & histories on modify
  useEffect(() => {
    localStorage.setItem('testora_exams', JSON.stringify(exams));
  }, [exams]);

  useEffect(() => {
    localStorage.setItem('testora_history', JSON.stringify(history));
  }, [history]);

  // Navigate helper maintaining back stacks
  const navigateTo = (nextView: ViewState) => {
    setPreviousViews((prev) => [...prev, view]);
    setView(nextView);
  };

  // Safe back navigation action
  const navigateBack = () => {
    if (previousViews.length > 0) {
      const copy = [...previousViews];
      const prev = copy.pop()!;
      setPreviousViews(copy);
      setView(prev);
    } else {
      // Revert to primary home roles
      if (user) {
        if (user.role === 'student') setView('student_dashboard');
        else if (user.role === 'teacher') setView('teacher_dashboard');
        else setView('admin_dashboard');
      } else {
        setView('auth');
      }
    }
  };

  // Timer simulation for Splash completion is driven directly by the SplashView loader progress
  
  // Successful Auth login trigger
  const handleAuthSuccess = (authenticatedUser: User) => {
    setUser(authenticatedUser);
    if (authenticatedUser.role === 'student') {
      setView('student_dashboard');
    } else if (authenticatedUser.role === 'teacher') {
      setView('teacher_dashboard');
    } else {
      setView('admin_dashboard');
    }
    setPreviousViews([]);
  };

  // Logout action reset session
  const handleLogout = () => {
    setUser(null);
    setCurrentExam(null);
    setNewConfiguratingExam(null);
    setView('auth');
    setPreviousViews([]);
  };

  // Start Exam assessment
  const handleStartExam = (selectedExam: Exam) => {
    setCurrentExam(selectedExam);
    navigateTo('exam_session');
  };

  // Submit Exam answers calculation
  const handleSubmitExam = (attempt: ExamAttempt) => {
    setCurrentAttempt(attempt);

    // Save attempt to student's history dynamically if logged in
    const feedbackStatus = attempt.score !== undefined && attempt.score >= 70 
      ? (lang === 'en' ? 'Passed' : 'Lulus') 
      : (lang === 'en' ? 'Failed' : 'Remedial');

    const newHistoryItem: ExamHistoryItem = {
      id: `hist-${Date.now()}`,
      subject: attempt.subject,
      title: attempt.examTitle || (currentExam ? currentExam.title : 'Ujian Terkait'),
      date: new Date().toLocaleDateString(lang === 'en' ? 'en-US' : 'id-ID', {
        day: 'numeric',
        month: 'short',
        year: 'numeric'
      }),
      score: attempt.score !== undefined ? attempt.score : 85,
      maxScore: 100,
      status: feedbackStatus
    };

    setHistory((prev) => [newHistoryItem, ...prev]);
    
    // Switch state from dynamic listing to wait/done
    if (currentExam) {
      setExams((prev) => 
        prev.map((e) => e.id === currentExam.id ? { ...e, status: 'done', studentCount: '32/32' } : e)
      );
    }

    setView('exam_result');
  };

  // Teacher configures a new Exam template successfully
  const handleExamCreated = (examConfig: Exam) => {
    setNewConfiguratingExam(examConfig);
    // Move onto question writing screen
    setView('add_question');
  };

  // Teacher completes or adds questions to configured exams
  const handleQuestionAdded = (question: any, addAnother: boolean) => {
    if (!newConfiguratingExam) return;

    // Append to child array
    const updatedExam: Exam = {
      ...newConfiguratingExam,
      questions: [...newConfiguratingExam.questions, question]
    };

    setNewConfiguratingExam(updatedExam);

    if (!addAnother) {
      // Append fully completed exam template to public list database
      setExams((prev) => [updatedExam, ...prev]);
      setNewConfiguratingExam(null);
      // Return to teacher dashboard workspace
      setView('teacher_dashboard');
    }
  };

  // Teacher accesses settings button to edit questions of existing exams in real-time
  const handleSelectExamEdit = (exam: Exam) => {
    setNewConfiguratingExam(exam);
    navigateTo('add_question');
  };

  // Main UI router switches
  const renderView = () => {
    switch (view) {
      case 'splash':
        return <SplashView lang={lang} onFinished={() => setView('auth')} />;
      
      case 'auth':
        return <AuthView lang={lang} onLoginSuccess={handleAuthSuccess} onLanguageChange={handleLanguageChange} />;

      case 'student_dashboard':
        if (!user) return <AuthView lang={lang} onLoginSuccess={handleAuthSuccess} onLanguageChange={handleLanguageChange} />;
        return (
          <StudentDashboard 
            user={user}
            exams={exams}
            history={history}
            lang={lang}
            onStartExam={handleStartExam}
            onNavigate={navigateTo}
            onLogout={handleLogout}
          />
        );

      case 'exam_session':
        if (!currentExam) return <StudentDashboard user={user!} exams={exams} history={history} lang={lang} onStartExam={handleStartExam} onNavigate={navigateTo} onLogout={handleLogout} />;
        return (
          <ExamSession 
            exam={currentExam}
            lang={lang}
            onSubmitExam={handleSubmitExam}
            onExit={navigateBack}
          />
        );

      case 'exam_result':
        if (!currentExam || !currentAttempt) return <StudentDashboard user={user!} exams={exams} history={history} lang={lang} onStartExam={handleStartExam} onNavigate={navigateTo} onLogout={handleLogout} />;
        return (
          <ExamResultView 
            exam={currentExam}
            attempt={currentAttempt}
            lang={lang}
            onBackToDashboard={() => setView('student_dashboard')}
          />
        );

      case 'teacher_dashboard':
        if (!user) return <AuthView lang={lang} onLoginSuccess={handleAuthSuccess} onLanguageChange={handleLanguageChange} />;
        return (
          <TeacherDashboard 
            user={user}
            exams={exams}
            lang={lang}
            onNavigate={navigateTo}
            onLogout={handleLogout}
            onSelectExamEdit={handleSelectExamEdit}
          />
        );

      case 'create_exam':
        return (
          <CreateExamView 
            lang={lang}
            onExit={navigateBack}
            onExamCreated={handleExamCreated}
          />
        );

      case 'add_question':
        if (!newConfiguratingExam) return <TeacherDashboard user={user!} exams={exams} lang={lang} onNavigate={navigateTo} onLogout={handleLogout} onSelectExamEdit={handleSelectExamEdit} />;
        return (
          <AddQuestionView 
            exam={newConfiguratingExam}
            lang={lang}
            onExit={navigateBack}
            onQuestionAdded={handleQuestionAdded}
          />
        );

      case 'admin_dashboard':
        if (!user) return <AuthView lang={lang} onLoginSuccess={handleAuthSuccess} onLanguageChange={handleLanguageChange} />;
        return (
          <AdminDashboard 
            user={user}
            exams={exams}
            lang={lang}
            onNavigate={navigateTo}
            onLogout={handleLogout}
          />
        );

      case 'profile_settings':
        if (!user) return <AuthView lang={lang} onLoginSuccess={handleAuthSuccess} onLanguageChange={handleLanguageChange} />;
        return (
          <ProfileSettingsView 
            user={user}
            lang={lang}
            onLanguageChange={handleLanguageChange}
            onExit={navigateBack}
            onLogout={handleLogout}
            darkMode={darkMode}
            onToggleDarkMode={() => setDarkMode(!darkMode)}
          />
        );

      default:
        return <SplashView lang={lang} onFinished={() => setView('auth')} />;
    }
  };

  return (
    <div className="font-sans min-h-screen bg-[#f7f9fb] transition-all duration-300">
      {renderView()}
    </div>
  );
}
