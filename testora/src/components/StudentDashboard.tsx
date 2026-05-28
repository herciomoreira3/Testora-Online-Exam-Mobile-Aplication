/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { School, LogOut, CheckCircle, TrendingUp, History, Timer, Calendar, ListCollapse, ArrowRight, ExternalLink, Home, BookOpen, User as UserIcon } from 'lucide-react';
import { AppLang, User, Exam, ExamHistoryItem, TRANSLATIONS } from '../types';

interface StudentDashboardProps {
  user: User;
  exams: Exam[];
  history: ExamHistoryItem[];
  lang: AppLang;
  onStartExam: (exam: Exam) => void;
  onNavigate: (view: any) => void;
  onLogout: () => void;
}

export default function StudentDashboard({
  user,
  exams,
  history,
  lang,
  onStartExam,
  onNavigate,
  onLogout
}: StudentDashboardProps) {
  const t = TRANSLATIONS[lang];
  
  // Real-time countdown clock state (e.g. for Kalkulus II in 2 Days, 14 Hours, 35 Min)
  const [countdown, setCountdown] = useState({
    days: 2,
    hours: 14,
    minutes: 35,
    seconds: 12
  });

  useEffect(() => {
    const interval = setInterval(() => {
      setCountdown((prev) => {
        if (prev.seconds > 0) {
          return { ...prev, seconds: prev.seconds - 1 };
        } else if (prev.minutes > 0) {
          return { ...prev, minutes: prev.minutes - 1, seconds: 59 };
        } else if (prev.hours > 0) {
          return { ...prev, hours: prev.hours - 1, minutes: 59, seconds: 59 };
        } else if (prev.days > 0) {
          return { ...prev, days: prev.days - 1, hours: 23, minutes: 59, seconds: 59 };
        } else {
          return prev;
        }
      });
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  // Filter exams that are current or waiting
  const ongoingExams = exams.filter(e => e.status === 'ongoing');
  const nextExam = exams.find(e => e.status === 'wait') || exams[0];

  return (
    <div className="min-h-screen pb-24 md:pb-8 bg-[#f7f9fb] text-slate-800">
      
      {/* Top Header Navigation Anchor bar */}
      <header className="bg-white border-b border-slate-100 shadow-sm sticky top-0 z-50">
        <div className="flex justify-between items-center w-full px-4 md:px-8 h-20 max-w-7xl mx-auto">
          <div className="flex items-center gap-3">
            <School className="text-blue-800" size={32} />
            <h1 className="font-headline text-2xl font-bold text-blue-800">Testora</h1>
          </div>

          <div className="flex items-center gap-4">
            <nav className="hidden md:flex items-center gap-8 mr-6">
              <button onClick={() => onNavigate('student_dashboard')} className="text-blue-800 font-bold border-b-2 border-blue-800 py-1.5 font-sans text-xs tracking-wider uppercase">
                {t.navHome}
              </button>
              <button onClick={() => onNavigate('profile_settings')} className="text-slate-500 hover:text-blue-800 font-semibold py-1.5 font-sans text-xs tracking-wider uppercase transition-colors">
                {t.navProfile}
              </button>
              <button onClick={onLogout} className="text-slate-500 hover:text-red-600 font-semibold py-1.5 font-sans text-xs tracking-wider uppercase transition-colors flex items-center gap-1">
                <LogOut size={14} /> {lang === 'en' ? 'Logout' : 'Keluar'}
              </button>
            </nav>

            {/* Profile Avatar Widget */}
            <div 
              onClick={() => onNavigate('profile_settings')}
              className="flex items-center gap-3 px-3 py-1.5 rounded-full border border-slate-200/50 bg-slate-50 hover:bg-slate-100 cursor-pointer shadow-sm transition-all"
            >
              <div className="text-right hidden sm:block">
                <p className="font-sans text-xs font-bold leading-none text-slate-800">{user.fullName}</p>
                <p className="font-sans text-[10px] text-slate-400 mt-0.5">Andi Pratama • Kelas 12-A</p>
              </div>
              <img 
                alt="Profile" 
                className="w-10 h-10 rounded-full border-2 border-blue-800/10 object-cover" 
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuA5ha-vEyKPwl3J-w9NpleQ59MnSF0ksWs4Cs6u_V8WBwcXeUAyMKLk9gGj-hwqvdnD0c3lGwm-HgidwmZiKycva6h_ollB8vrf75ojiyaUJIRfUdtIAVNLYUdJXwZmsOyFXWT7XdgDqHb4SX0fQmQwRDAhR5Zm3aPQmVhANaiD_NtUKFKPRpn_kasnKPJ8lFUCkwbG8f8LrprrWojmu--93bw16YfCPdH9bT2sjd_oFJ75nurfmXyO0enyzC4kXn17yFYZExjOAQ"
              />
            </div>
          </div>
        </div>
      </header>

      {/* Main Container Content */}
      <main className="max-w-7xl mx-auto px-4 md:px-8 py-8 animate-fade-in">
        
        {/* Welcome message section */}
        <section className="mb-8">
          <h2 className="font-headline text-3xl text-slate-900 font-bold mb-1">
            {t.welcomeTitle}, {user.fullName.split(' ')[0]}!
          </h2>
          <p className="font-sans text-sm text-slate-500">
            {t.welcomeSubtitle}
          </p>
        </section>

        {/* Bento Grid layout */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 mb-8">
          
          {/* Next Exam Card Hero */}
          <div className="lg:col-span-8 bg-white border border-slate-100 rounded-2xl shadow-[6px_6px_15px_rgba(203,213,225,0.4),-6px_-6px_15px_rgba(255,255,255,0.9)] p-6 relative overflow-hidden flex flex-col justify-between min-h-[300px]">
            <div className="absolute top-[-20px] right-[-20px] opacity-[0.04] pointer-events-none select-none text-slate-900">
              <School size={280} className="rotate-12" />
            </div>

            <div>
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-orange-50 text-orange-600 border border-orange-100/60 font-semibold text-xs mb-4">
                <Calendar size={14} />
                <span>{t.upcomingBadge}</span>
              </div>
              <h3 className="font-headline text-2xl md:text-3xl font-bold text-blue-900 mb-2">
                {nextExam ? nextExam.title : 'Matematika Wajib: Kalkulus II'}
              </h3>
              <p className="font-sans text-xs text-slate-400 font-medium flex items-center gap-1.5">
                <Timer size={14} />
                {nextExam?.scheduledDate 
                  ? `${nextExam.scheduledDate} • ${nextExam.scheduledTime} WIB`
                  : 'Senin, 24 Mei 2024 • 08:00 WIB'
                }
              </p>
            </div>

            <div className="mt-6 flex flex-wrap items-end justify-between gap-4">
              {/* Countdowns ticks */}
              <div className="flex gap-2">
                <div className="bg-slate-50/80 border border-slate-200/40 px-3 py-2.5 rounded-xl text-center min-w-[65px] shadow-inner">
                  <span className="block font-headline text-xl font-bold text-blue-800">
                    {String(countdown.days).padStart(2, '0')}
                  </span>
                  <span className="text-[10px] text-slate-400 font-medium">{lang === 'id' ? 'Hari' : lang === 'tt' ? 'Loron' : 'Days'}</span>
                </div>
                <div className="bg-slate-50/80 border border-slate-200/40 px-3 py-2.5 rounded-xl text-center min-w-[65px] shadow-inner">
                  <span className="block font-headline text-xl font-bold text-blue-800">
                    {String(countdown.hours).padStart(2, '0')}
                  </span>
                  <span className="text-[10px] text-slate-400 font-medium">{lang === 'id' ? 'Jam' : lang === 'tt' ? 'Oras' : 'Hours'}</span>
                </div>
                <div className="bg-slate-50/80 border border-slate-200/40 px-3 py-2.5 rounded-xl text-center min-w-[65px] shadow-inner">
                  <span className="block font-headline text-xl font-bold text-blue-800">
                    {String(countdown.minutes).padStart(2, '0')}
                  </span>
                  <span className="text-[10px] text-slate-400 font-medium">{lang === 'id' ? 'Menit' : lang === 'tt' ? 'Minutu' : 'Min'}</span>
                </div>
                <div className="bg-slate-50/80 border border-slate-200/40 px-3 py-2.5 rounded-xl text-center min-w-[65px] shadow-inner hidden sm:block">
                  <span className="block font-headline text-xl font-bold text-blue-800">
                    {String(countdown.seconds).padStart(2, '0')}
                  </span>
                  <span className="text-[10px] text-slate-400 font-medium">{lang === 'id' ? 'Detik' : lang === 'tt' ? 'Segundu' : 'Sec'}</span>
                </div>
              </div>

              <button 
                onClick={() => nextExam && onStartExam(nextExam)}
                className="bg-blue-800 text-white text-xs font-bold font-headline py-3 px-6 rounded-xl hover:bg-blue-700 shadow-md hover:scale-95 transition-all outline-none flex items-center gap-1.5"
              >
                {lang === 'en' ? 'View Details' : 'Lihat Detail'}
                <ArrowRight size={16} />
              </button>
            </div>
          </div>

          {/* Study Statistics Card */}
          <div className="lg:col-span-4 bg-white border border-slate-100 rounded-2xl shadow-[6px_6px_15px_rgba(203,213,225,0.4),-6px_-6px_15px_rgba(255,255,255,0.9)] p-6 flex flex-col justify-between">
            <h4 className="font-headline text-lg font-bold text-slate-900 mb-3 hover:text-blue-800 transition-colors">
              {t.studyStats}
            </h4>
            
            <div className="space-y-3.5">
              <div className="p-3 bg-blue-50/40 rounded-xl flex items-center gap-3.5 border border-blue-100/30">
                <div className="w-10 h-10 rounded-full bg-blue-800/10 text-blue-800 flex items-center justify-center">
                  <CheckCircle size={20} />
                </div>
                <div>
                  <p className="font-headline text-[15px] font-bold text-slate-800">12/15</p>
                  <p className="font-sans text-[11px] text-slate-400 mt-0.5">{t.examsCompleted}</p>
                </div>
              </div>

              <div className="p-3 bg-emerald-50/40 rounded-xl flex items-center gap-3.5 border border-emerald-100/30">
                <div className="w-10 h-10 rounded-full bg-emerald-800/10 text-emerald-800 flex items-center justify-center">
                  <TrendingUp size={20} />
                </div>
                <div>
                  <p className="font-headline text-[15px] font-bold text-slate-800">88.5</p>
                  <p className="font-sans text-[11px] text-slate-400 mt-0.5">{t.avgScore}</p>
                </div>
              </div>

              <div className="p-3 bg-indigo-50/40 rounded-xl flex items-center gap-3.5 border border-indigo-100/30">
                <div className="w-10 h-10 rounded-full bg-indigo-800/10 text-indigo-800 flex items-center justify-center">
                  <History size={20} />
                </div>
                <div>
                  <p className="font-headline text-[15px] font-bold text-slate-800">420</p>
                  <p className="font-sans text-[11px] text-slate-400 mt-0.5">{t.studyMinutes}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Ongoing Exams Section */}
        <section className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="w-2.5 h-6 bg-blue-800 rounded-full" />
              <h3 className="font-headline text-xl text-slate-900 font-bold">
                {t.ongoingTitle}
              </h3>
            </div>
            
            <div className="flex items-center gap-1.5 text-blue-600 animate-pulse text-xs font-bold bg-blue-50 border border-blue-100 px-3 py-1 rounded-full">
              <span className="w-2 h-2 rounded-full bg-blue-600" />
              <span>LIVE</span>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {ongoingExams.length > 0 ? (
              ongoingExams.map((exam) => (
                <div 
                  key={exam.id} 
                  className="bg-white p-5 rounded-2xl border border-slate-100 border-l-4 border-l-blue-800 shadow-[4px_4px_12px_rgba(203,213,225,0.3)] flex flex-col justify-between md:flex-row gap-4 items-start hover:shadow-md transition-all duration-300"
                >
                  <div className="flex-1">
                    <span className="font-sans text-[10px] text-blue-800 uppercase tracking-widest font-bold">
                      {exam.subject}
                    </span>
                    <h4 className="font-headline text-base font-bold text-slate-800 mt-1 mb-2">
                      {exam.title}
                    </h4>
                    <div className="flex flex-wrap gap-3 text-slate-400 font-sans text-xs">
                      <span className="flex items-center gap-1">
                        <Timer size={14} />
                        {exam.duration} {lang === 'en' ? 'Mins' : 'Menit'}
                      </span>
                      <span className="flex items-center gap-1 font-medium bg-slate-50/80 px-2 py-0.5 rounded border border-slate-100">
                        {exam.questions.length || '30'} {lang === 'en' ? 'Questions' : 'Soal'}
                      </span>
                    </div>
                  </div>
                  <button 
                    onClick={() => onStartExam(exam)}
                    className="w-full md:w-auto px-5 py-2.5 bg-blue-800 text-white font-headline text-xs font-bold rounded-xl shadow-sm hover:bg-blue-700 outline-none hover:scale-105 active:scale-95 transition-all shrink-0 mt-2 md:mt-0"
                  >
                    {t.btnStartExam}
                  </button>
                </div>
              ))
            ) : (
              <div className="col-span-2 text-center p-8 bg-slate-50 rounded-2xl border border-dashed border-slate-200 text-slate-400 text-xs font-medium">
                {lang === 'en' ? 'No other active exams scheduled for today' : 'Tidak ada ujian aktif lain yang dijadwalkan hari ini'}
              </div>
            )}
          </div>
        </section>

        {/* History of exams completed */}
        <section className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="w-2.5 h-6 bg-slate-800 rounded-full" />
              <h3 className="font-headline text-xl text-slate-900 font-bold">
                {t.examHistory}
              </h3>
            </div>
            <button 
              onClick={() => onNavigate('profile_settings')} 
              className="text-blue-800 text-xs font-bold hover:underline flex items-center gap-1 cursor-pointer transition-colors"
            >
              {t.seeAll} <ExternalLink size={14} />
            </button>
          </div>

          <div className="bg-white rounded-2xl border border-slate-100 shadow-[6px_6px_15px_rgba(203,213,225,0.4),-6px_-6px_15px_rgba(255,255,255,0.9)] overflow-hidden">
            <table className="w-full text-left border-collapse">
              <thead className="bg-slate-50/80 border-b border-slate-100">
                <tr>
                  <th className="p-4 font-headline text-xs text-slate-400 font-bold tracking-wider">{t.thSubject}</th>
                  <th className="p-4 font-headline text-xs text-slate-400 font-bold tracking-wider hidden sm:table-cell">{t.thDate}</th>
                  <th className="p-4 font-headline text-xs text-slate-400 font-bold tracking-wider">{t.thScore}</th>
                  <th className="p-4 font-headline text-xs text-slate-400 font-bold tracking-wider text-right">{t.thStatus}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {history.map((item, idx) => (
                  <tr key={idx} className="hover:bg-slate-50/50 transition-colors group">
                    <td className="p-4">
                      <p className="font-sans text-sm font-bold text-slate-800">{item.subject}</p>
                      <p className="font-sans text-[11px] text-slate-400 mt-0.5 sm:hidden">{item.date}</p>
                    </td>
                    <td className="p-4 font-sans text-xs text-slate-500 hidden sm:table-cell">
                      {item.date}
                    </td>
                    <td className="p-4">
                      <span className={`font-headline font-bold text-sm ${item.score >= 70 ? 'text-emerald-600' : 'text-red-500'}`}>
                        {item.score}/{item.maxScore}
                      </span>
                    </td>
                    <td className="p-4 text-right">
                      <span className={`inline-flex items-center px-3 py-1 rounded-full text-[10px] font-bold ${
                        item.status === 'Lulus' || item.status === 'Passed'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-100'
                          : 'bg-red-50 text-red-700 border border-red-100'
                      }`}>
                        {item.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      </main>

      {/* Bottom NavBar (Mobile Only) */}
      <nav className="md:hidden fixed bottom-0 left-0 w-full z-50 bg-white/95 backdrop-blur-md border-t border-slate-100 shadow-[0_-4px_12px_rgba(0,0,0,0.05)] h-16 flex justify-around items-center px-2 pb-safe rounded-t-2xl">
        <button 
          onClick={() => onNavigate('student_dashboard')}
          className="flex flex-col items-center justify-center text-blue-800 bg-blue-50/70 p-1.5 px-4 rounded-full"
        >
          <Home size={18} />
          <span className="text-[10px] font-bold mt-0.5">{t.navHome}</span>
        </button>
        <button 
          onClick={() => onNavigate('profile_settings')}
          className="flex flex-col items-center justify-center text-slate-500 hover:text-blue-800"
        >
          <UserIcon size={18} />
          <span className="text-[10px] font-bold mt-0.5">{t.navProfile}</span>
        </button>
        <button 
          onClick={onLogout}
          className="flex flex-col items-center justify-center text-slate-400 hover:text-red-600"
        >
          <LogOut size={18} />
          <span className="text-[10px] font-bold mt-0.5">{lang === 'en' ? 'Logout' : 'Keluar'}</span>
        </button>
      </nav>
    </div>
  );
}
