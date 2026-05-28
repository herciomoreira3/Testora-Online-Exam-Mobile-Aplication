/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { School, LogOut, Bell, Timer, Users, FileLock2, Award, ArrowUpRight, TrendingUp, Settings, Plus, Home, BookOpen, User as UserIcon } from 'lucide-react';
import { AppLang, User, Exam, TRANSLATIONS } from '../types';

interface TeacherDashboardProps {
  user: User;
  exams: Exam[];
  lang: AppLang;
  onNavigate: (view: any) => void;
  onLogout: () => void;
  onSelectExamEdit: (exam: Exam) => void;
}

export default function TeacherDashboard({
  user,
  exams,
  lang,
  onNavigate,
  onLogout,
  onSelectExamEdit
}: TeacherDashboardProps) {
  const t = TRANSLATIONS[lang];

  // Group exams
  const activeExams = exams.filter(e => e.status === 'ongoing' || e.status === 'wait');
  const pastExams = exams.filter(e => e.status === 'done');

  return (
    <div className="min-h-screen pb-24 md:pb-8 bg-[#f7f9fb] text-slate-800">
      
      {/* AppBar Bar */}
      <header className="bg-white border-b border-slate-100 shadow-sm sticky top-0 z-50">
        <div className="flex justify-between items-center w-full px-4 md:px-8 h-20 max-w-7xl mx-auto">
          <div className="flex items-center gap-3">
            <School className="text-blue-800" size={32} />
            <h1 className="font-headline text-2xl font-bold text-blue-800">Testora</h1>
          </div>

          <div className="flex items-center gap-4">
            <nav className="hidden md:flex items-center gap-8 mr-6">
              <button onClick={() => onNavigate('teacher_dashboard')} className="text-blue-800 font-bold border-b-2 border-blue-800 py-1.5 font-sans text-xs tracking-wider uppercase">
                {t.navHome}
              </button>
              <button onClick={() => onNavigate('profile_settings')} className="text-slate-500 hover:text-blue-800 font-semibold py-1.5 font-sans text-xs tracking-wider uppercase transition-colors">
                {t.navProfile}
              </button>
              <button onClick={onLogout} className="text-slate-500 hover:text-red-600 font-semibold py-1.5 font-sans text-xs tracking-wider uppercase transition-colors flex items-center gap-1">
                <LogOut size={14} /> {lang === 'en' ? 'Logout' : 'Keluar'}
              </button>
            </nav>

            <button className="relative p-2 rounded-full hover:bg-slate-100 text-slate-500 border border-slate-200/50 shadow-sm">
              <Bell size={18} />
              <span className="absolute top-1 right-1 w-2 h-2 bg-orange-600 rounded-full" />
            </button>

            {/* Profile Avatar */}
            <div 
              onClick={() => onNavigate('profile_settings')}
              className="w-10 h-10 rounded-full bg-blue-800/10 border-2 border-white overflow-hidden shadow-sm hover:scale-105 transition-transform cursor-pointer"
            >
              <img 
                alt="Teacher Profile" 
                className="w-full h-full object-cover" 
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuAL28lwa-pxP98hGnL_sSXnY1dABRtnYyBzDugcwNtS8VZe4cRl5eMEg5MiWKCVHKXZMrMKMhaIwfcPcDMUfmh7TJJwEVb-TJKJGc4XcBEOF_crcpZ6Ga0HuCUJxpBkwWSoZWtFuwM5l_fZgNfbzggVP3DsOKg6hd5WISzOFLVLzvr9QS1vcpRYMrRlV_dsXDvb4XTPBxuUkoh0irh68GXut7DbeLQbXvkHyvqZfDE68vtG4nCBpdE5eA6Gfgs8W5yZfW5Wf0ozFw"
              />
            </div>
          </div>
        </div>
      </header>

      {/* Main Grid */}
      <main className="max-w-7xl mx-auto px-4 md:px-8 py-8 animate-fade-in">
        
        {/* Greetings */}
        <section className="mb-8">
          <h2 className="font-headline text-3xl text-slate-900 font-bold mb-1">
            {t.teacherWelcome}
          </h2>
          <p className="font-sans text-sm text-slate-500">
            {t.teacherSub}
          </p>
        </section>

        {/* Stats Horizontal Slider Scroll */}
        <section className="mb-8">
          <div className="flex gap-4 pb-4 overflow-x-auto scrollbar-none">
            {/* Stat Card 1 */}
            <div className="min-w-[240px] flex-1 bg-white border border-slate-100 p-5 rounded-2xl shadow-[4px_4px_12px_rgba(203,213,225,0.2)] flex items-center gap-4 hover:shadow-md transition-shadow">
              <div className="bg-blue-50 text-blue-800 p-3.5 rounded-xl border border-blue-100/40">
                <FileLock2 size={24} />
              </div>
              <div>
                <p className="font-sans text-[11px] font-bold text-slate-400 uppercase tracking-widest">{t.totalExams}</p>
                <p className="font-headline text-xl font-black text-slate-800">{exams.length || '24'}</p>
              </div>
            </div>

            {/* Stat Card 2 */}
            <div className="min-w-[240px] flex-1 bg-white border border-slate-100 p-5 rounded-2xl shadow-[4px_4px_12px_rgba(203,213,225,0.2)] flex items-center gap-4 hover:shadow-md transition-shadow">
              <div className="bg-emerald-50 text-emerald-800 p-3.5 rounded-xl border border-emerald-100/40">
                <Users size={24} />
              </div>
              <div>
                <p className="font-sans text-[11px] font-bold text-slate-400 uppercase tracking-widest">{t.totalStudents}</p>
                <p className="font-headline text-xl font-black text-slate-800">128</p>
              </div>
            </div>

            {/* Stat Card 3 */}
            <div className="min-w-[240px] flex-1 bg-white border border-slate-100 p-5 rounded-2xl shadow-[4px_4px_12px_rgba(203,213,225,0.2)] flex items-center gap-4 hover:shadow-md transition-shadow">
              <div className="bg-orange-50 text-orange-600 p-3.5 rounded-xl border border-orange-100/40">
                <TrendingUp size={24} />
              </div>
              <div>
                <p className="font-sans text-[11px] font-bold text-slate-400 uppercase tracking-widest">{t.needReview}</p>
                <p className="font-headline text-xl font-black text-slate-800">12</p>
              </div>
            </div>
          </div>
        </section>

        {/* Active Exams list */}
        <section className="mb-8">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-headline text-lg font-bold text-slate-900">{t.activeExamsToday}</h3>
            <button 
              onClick={() => onNavigate('teacher_dashboard')} 
              className="text-blue-800 font-bold text-xs tracking-wider uppercase hover:underline"
            >
              {t.seeAll}
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {activeExams.map((exam) => (
              <div 
                key={exam.id}
                className="bg-white border border-slate-100 rounded-2xl shadow-[6px_6px_15px_rgba(203,213,225,0.3)] overflow-hidden group hover:scale-[1.01] transition-all duration-300 flex flex-col justify-between"
              >
                <div className="h-32 bg-blue-800 relative mix-blend-multiply overflow-hidden">
                  {/* Mock illustrative banner inside card header */}
                  <img 
                    alt="Class Background" 
                    className="w-full h-full object-cover opacity-30 select-none pointer-events-none" 
                    src={exam.subject.includes('Biologi') 
                      ? "https://lh3.googleusercontent.com/aida-public/AB6AXuDoizYpV4dYrsgAkvl9oX3r08Ww8CMNots2O-dNALSk8pr0Qv7OO8mfmywZ3L-DmOA-dwVtvi35LFY5r9H4UpNPLmFEFvJLhksyqW2bnSohNVBATuxeOcgARrNOcCJMAGSZzHbNKcXqM9SkUBKKTIHebWeSrhW-vHr43uORc4Fh1VHtUwazMru3t5lIDRDgBagwY21g0w4Oh_59F3pdUeWD5_F5X8FenP1XODWcyUiunC1KaQMtroBzJ-QIxVk5LPFqhlJHeuYF7Q"
                      : "https://lh3.googleusercontent.com/aida-public/AB6AXuD5jWZYAPS6LKyIw8xbaEU35LAbKrh9boh_NJ59rFCCyFdMPp2f28h74Q32Rso2MHdL3r9rlofOqnl_a50nvw1thenv31dtLhZAaAiBPsOnUwwU0taRk-Cl4zhgP_ojvSOTUtTInBpBaCupuSMVFyqfsgHtWwBn3mw_mo_lvEEaqmKN3PFJUzAy0rc9CXtiyDQJJ2rDAu8-oJCEx3caH4_UYvJie0_8v9ZkAm0sbbWo5xtv99P0FBDZH5dZHLnkIJZcmQKzGP0bYQ"
                    }
                  />
                  <span className="absolute top-4 right-4 bg-white/20 backdrop-blur-md text-white border border-white/10 px-3 py-1 rounded-full font-bold text-[10px] uppercase tracking-wider">
                    {exam.subject}
                  </span>
                </div>

                <div className="p-5 flex-1 flex flex-col justify-between">
                  <div>
                    <h4 className="font-headline text-base font-bold text-slate-800 leading-tight mb-2 group-hover:text-blue-800 transition-colors">
                      {exam.title}
                    </h4>
                    <div className="flex items-center gap-1 text-slate-400 text-xs font-semibold mb-5">
                      <Timer size={14} />
                      <span>{exam.scheduledTime ? `${exam.scheduledTime} (${exam.duration} Min)` : `08:00 (${exam.duration} Min)`}</span>
                    </div>

                    <div className="mb-5">
                      <div className="flex justify-between items-center mb-1.5 text-xs font-semibold">
                        <span className="text-slate-400">{t.studentAttendance}</span>
                        <span className="text-blue-800">{exam.studentCount || '12/32'}</span>
                      </div>
                      <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                        <div 
                          className="bg-blue-800 h-full rounded-full transition-all duration-500" 
                          style={{ width: exam.studentCount === '32/32' ? '100%' : '37.5%' }} 
                        />
                      </div>
                    </div>
                  </div>

                  <div className="flex gap-2.5">
                    <button 
                      onClick={() => alert(lang === 'en' ? 'Live session monitor is active. Zero student flag warnings.' : 'Monitor siaran langsung aktif. Tidak ada peringatan sekuriti.')}
                      className="flex-1 py-2 px-4 bg-blue-800 text-white font-bold font-headline text-xs rounded-xl shadow-sm outline-none hover:scale-[0.98] transition-transform active:scale-95 text-center"
                    >
                      {t.monitorLive}
                    </button>
                    <button 
                      onClick={() => onSelectExamEdit(exam)}
                      className="p-2.5 bg-slate-100 text-blue-800 border border-slate-200/50 hover:bg-slate-200 rounded-xl transition-colors outline-none cursor-pointer"
                      title={lang === "en" ? "Edit Questions" : "Edit Pertanyaan"}
                    >
                      <Settings size={16} />
                    </button>
                  </div>
                </div>
              </div>
            ))}

            {/* dashed scheduled placeholder */}
            <div 
              onClick={() => onNavigate('create_exam')}
              className="border-2 border-dashed border-slate-300 rounded-2xl flex flex-col items-center justify-center p-6 text-slate-400 hover:border-blue-800 hover:bg-blue-50/20 hover:text-blue-800 transition-all cursor-pointer group min-h-[340px]"
            >
              <div className="w-12 h-12 rounded-full bg-slate-100 group-hover:bg-blue-50 flex items-center justify-center mb-4 transition-transform group-hover:scale-110 shadow-sm">
                <Plus size={24} />
              </div>
              <p className="font-headline text-sm font-bold">{t.schedulePlaceholder}</p>
            </div>
          </div>
        </section>
      </main>

      {/* Teacher dynamic Floating action Button for scheduling */}
      <button 
        onClick={() => onNavigate('create_exam')}
        className="fixed bottom-24 right-5 md:right-10 bg-blue-800 text-white font-headline text-xs font-bold px-5 py-3.5 rounded-full shadow-lg hover:scale-105 active:scale-95 transition-all outline-none flex items-center gap-1.5 focus:ring-4 focus:ring-blue-800/30"
      >
        <Plus size={18} />
        <span>{t.btnCreateExam}</span>
      </button>

      {/* Bottom navbar mobile footer */}
      <nav className="md:hidden fixed bottom-0 left-0 w-full z-50 bg-white/95 backdrop-blur-md border-t border-slate-100 shadow-[0_-4px_12px_rgba(0,0,0,0.05)] h-16 flex justify-around items-center px-2 pb-safe rounded-t-2xl">
        <button 
          onClick={() => onNavigate('teacher_dashboard')}
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
