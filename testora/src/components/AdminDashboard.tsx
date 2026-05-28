/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { School, LogOut, Users, FileLock2, Award, ArrowUpRight, TrendingUp, Bolt, ArrowUp, Menu, BookOpen, Globe, FlaskConical, Home, BarChart2, Activity } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { AppLang, User, Exam, TRANSLATIONS } from '../types';

interface AdminDashboardProps {
  user: User;
  exams: Exam[];
  lang: AppLang;
  onNavigate: (view: any) => void;
  onLogout: () => void;
}

export default function AdminDashboard({
  user,
  exams,
  lang,
  onNavigate,
  onLogout
}: AdminDashboardProps) {
  const t = TRANSLATIONS[lang];

  // Recharts mock dataset matching the visual design (Monday - Friday)
  const chartData = [
    { name: lang === 'en' ? 'Mon' : 'Sen', exams: 30, completed: 15 },
    { name: lang === 'en' ? 'Tue' : 'Sel', exams: 45, completed: 33 },
    { name: lang === 'en' ? 'Wed' : 'Rab', exams: 25, completed: 10 },
    { name: lang === 'en' ? 'Thu' : 'Kam', exams: 50, completed: 50 },
    { name: lang === 'en' ? 'Fri' : 'Jum', exams: 36, completed: 24 },
  ];

  return (
    <div className="min-h-screen pb-24 md:pb-8 bg-[#f7f9fb] text-slate-800">
      
      {/* Top Bar Navigation */}
      <header className="bg-white border-b border-slate-100 shadow-sm sticky top-0 z-50">
        <div className="flex justify-between items-center w-full px-4 md:px-8 h-20 max-w-7xl mx-auto">
          <div className="flex items-center gap-3">
            <School className="text-blue-800" size={32} />
            <h1 className="font-headline text-2xl font-bold text-blue-800">Testora</h1>
          </div>

          <div className="hidden md:flex gap-6 items-center">
            <nav className="flex gap-4">
              <button onClick={() => onNavigate('admin_dashboard')} className="text-blue-800 font-bold border-b-2 border-blue-800 py-1.5 px-1 font-sans text-xs uppercase tracking-wider">
                {t.navHome}
              </button>
              <button 
                onClick={() => alert(lang === 'en' ? 'User management modules are administrative only' : 'Modul manajemen pengguna dikhususkan untuk administrator.')} 
                className="text-slate-500 hover:text-blue-800 py-1.5 px-3 rounded-lg font-sans text-xs uppercase tracking-wider transition-colors"
              >
                Users
              </button>
              <button 
                onClick={() => alert(lang === 'en' ? 'Exam configurations audit modules' : 'Audit konfigurasi ujian akademik.')} 
                className="text-slate-500 hover:text-blue-800 py-1.5 px-3 rounded-lg font-sans text-xs uppercase tracking-wider transition-colors"
              >
                Exams
              </button>
            </nav>

            {/* Profile Avatar */}
            <div 
              onClick={() => onNavigate('profile_settings')}
              className="h-10 w-10 rounded-full bg-blue-800/10 flex items-center justify-center overflow-hidden ring-2 ring-blue-850 hover:scale-105 transition-transform cursor-pointer shadow-sm"
            >
              <img 
                alt="Admin Avatar" 
                className="w-full h-full object-cover" 
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuBx3xIEd2siQ6-PKLvVMaAmHvBSw6VZ1ByNVUl0RplZRhaiNvskUX-QX_Jus6kE4DQ563JZLp27MFnaK_FAcKsPsB9MBKG10cX5UTHObXbTlXS812IDUUmAXbRCn5Uul7wiXsDvOadU1scBWMxQFkP-8th_5Bum1FHOC3_SC3sCXeRv2Jc3nHYGKVVODZ4wz96Kxu7MXbSQcX01ybGTo2ILLPaPrzC4xVAd-D-4EzgXOFygY-1jxcxvfxwgcoDZtA-g5oGR7XN4EA"
              />
            </div>
            
            <button onClick={onLogout} className="text-slate-500 hover:text-red-600 font-semibold font-sans text-xs tracking-wider uppercase transition-colors flex items-center gap-1">
              <LogOut size={14} /> {lang === 'en' ? 'Logout' : 'Keluar'}
            </button>
          </div>

          <button onClick={() => alert(lang === 'en' ? 'Open system logs menu' : 'Membuka menu log sistem.')} className="md:hidden p-2 text-slate-500 hover:bg-slate-100 rounded-lg">
            <Menu size={20} />
          </button>
        </div>
      </header>

      {/* Main Body Grid */}
      <main className="pt-8 pb-24 px-4 md:px-8 max-w-7xl mx-auto min-h-screen animate-fade-in">
        
        {/* Greetings Panel */}
        <section className="mb-8">
          <h2 className="font-headline text-3xl font-black text-slate-900 leading-tight">
            {t.adminTitle}
          </h2>
          <p className="font-sans text-sm text-slate-500 mt-1">
            {t.adminSub}
          </p>
        </section>

        {/* Stats Grid */}
        <section className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8">
          {/* Stat 1 */}
          <div className="bg-white border border-slate-100 p-5 rounded-2xl shadow-[4px_4px_12px_rgba(203,213,225,0.2)] flex flex-col justify-between hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <Users size={20} className="text-blue-800 opacity-60" />
              <span className="text-[10px] font-bold text-emerald-600 bg-emerald-50 border border-emerald-100 px-2 py-0.5 rounded-full flex items-center">
                <ArrowUp size={10} className="mr-0.5" /> +12%
              </span>
            </div>
            <div className="mt-4">
              <p className="font-sans text-[11px] font-bold text-slate-400 uppercase tracking-widest">{t.totalTeachers}</p>
              <p className="font-headline text-2xl font-black text-slate-800">48</p>
            </div>
          </div>

          {/* Stat 2 */}
          <div className="bg-white border border-slate-100 p-5 rounded-2xl shadow-[4px_4px_12px_rgba(203,213,225,0.2)] flex flex-col justify-between hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <Users size={20} className="text-indigo-600 opacity-60" />
              <span className="text-[10px] font-bold text-emerald-600 bg-emerald-50 border border-emerald-100 px-2 py-0.5 rounded-full flex items-center">
                <ArrowUp size={10} className="mr-0.5" /> +5%
              </span>
            </div>
            <div className="mt-4">
              <p className="font-sans text-[11px] font-bold text-slate-400 uppercase tracking-widest">{lang === 'en' ? 'Total Students' : 'Total Murid'}</p>
              <p className="font-headline text-2xl font-black text-slate-800">1,240</p>
            </div>
          </div>

          {/* Stat 3 */}
          <div className="bg-white border border-slate-100 p-5 rounded-2xl shadow-[4px_4px_12px_rgba(203,213,225,0.2)] flex flex-col justify-between hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between">
              <FileLock2 size={20} className="text-orange-600 opacity-60" />
            </div>
            <div className="mt-4">
              <p className="font-sans text-[11px] font-bold text-slate-400 uppercase tracking-widest">{t.totalExams}</p>
              <p className="font-headline text-2xl font-black text-slate-800">156</p>
            </div>
          </div>

          {/* Stat 4 highlight color */}
          <div className="bg-blue-850 bg-gradient-to-br from-blue-900 to-blue-800 text-white p-5 rounded-2xl shadow-[4px_4px_12px_rgba(30,64,175,0.2)] flex flex-col justify-between hover:scale-[1.01] transition-transform">
            <div className="flex items-center justify-between">
              <Bolt size={20} className="text-white" />
            </div>
            <div className="mt-4">
              <p className="font-sans text-[11px] font-bold text-white/70 uppercase tracking-widest">{t.activeExamsNum}</p>
              <p className="font-headline text-2xl font-black text-white">8</p>
            </div>
          </div>
        </section>

        {/* Recharts Analytics Area + List column view */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          
          {/* Recharts Activity diagram */}
          <div className="lg:col-span-7 bg-white border border-slate-100 p-6 rounded-2xl shadow-[6px_6px_15px_rgba(203,213,225,0.3)]">
            <div className="flex justify-between items-center mb-6">
              <h3 className="font-headline text-base font-bold text-slate-900">{t.weeklyActivity}</h3>
              <select className="bg-slate-50 border border-slate-200 text-slate-500 font-sans text-xs font-semibold px-4 py-1.5 rounded-lg outline-none focus:ring-2 focus:ring-blue-800">
                <option>{lang === 'en' ? 'This Week' : 'Minggu Ini'}</option>
                <option>{lang === 'en' ? 'Last Week' : 'Minggu Lalu'}</option>
              </select>
            </div>

            {/* Recharts BarChart container element */}
            <div className="w-full h-64 mt-4 select-none">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <XAxis dataKey="name" tick={{ fontSize: 10, fill: '#64748b' }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 10, fill: '#64748b' }} axisLine={false} tickLine={false} />
                  <Tooltip cursor={{ fill: 'rgba(30,64,175,0.03)' }} />
                  <Bar dataKey="completed" radius={[6, 6, 0, 0]} barSize={28}>
                    {chartData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={index % 2 === 1 ? '#1e40af' : '#cbd5e1'} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Recent list column */}
          <div className="lg:col-span-5 bg-white border border-slate-100 p-6 rounded-2xl shadow-[6px_6px_15px_rgba(203,213,225,0.3)]">
            <div className="flex justify-between items-center mb-6">
              <h3 className="font-headline text-base font-bold text-slate-900">{t.recentExams}</h3>
              <button 
                onClick={() => alert('Access audit filters')} 
                className="text-blue-800 font-bold text-xs tracking-wider uppercase hover:underline"
              >
                {t.seeAll}
              </button>
            </div>

            <div className="space-y-4">
              
              {/* Item 1 */}
              <div className="flex items-center gap-4 p-3 hover:bg-slate-50 rounded-xl transition-all group cursor-pointer border border-transparent hover:border-slate-100">
                <div className="h-12 w-12 rounded-xl bg-blue-50 border border-blue-100/30 text-blue-800 flex items-center justify-center">
                  <BookOpen size={20} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-sans text-xs md:text-sm font-bold text-slate-800 truncate">Matematika Dasar</p>
                  <p className="font-sans text-[10px] text-slate-400 font-semibold mt-0.5">Kelas X-A • 10:00 WIB</p>
                </div>
                <div className="px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-800 text-[9px] font-black uppercase tracking-wider border border-emerald-100">
                  Ongoing
                </div>
              </div>

              {/* Item 2 */}
              <div className="flex items-center gap-4 p-3 hover:bg-slate-50 rounded-xl transition-all group cursor-pointer border border-transparent hover:border-slate-100">
                <div className="h-12 w-12 rounded-xl bg-indigo-50 border border-indigo-100/30 text-indigo-800 flex items-center justify-center">
                  <Globe size={20} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-sans text-xs md:text-sm font-bold text-slate-800 truncate">Bahasa Indonesia</p>
                  <p className="font-sans text-[10px] text-slate-400 font-semibold mt-0.5">Kelas XII • 08:30 WIB</p>
                </div>
                <div className="px-2.5 py-1 rounded-full bg-slate-100 text-slate-500 text-[9px] font-black uppercase tracking-wider border border-slate-200">
                  Done
                </div>
              </div>

              {/* Item 3 */}
              <div className="flex items-center gap-4 p-3 hover:bg-slate-50 rounded-xl transition-all group cursor-pointer border border-transparent hover:border-slate-100">
                <div className="h-12 w-12 rounded-xl bg-orange-50 border border-orange-100/30 text-orange-600 flex items-center justify-center">
                  <FlaskConical size={20} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-sans text-xs md:text-sm font-bold text-slate-850 truncate">Fisika Terapan</p>
                  <p className="font-sans text-[10px] text-slate-400 font-semibold mt-0.5">Kelas XI-C • 13:00 WIB</p>
                </div>
                <div className="px-2.5 py-1 rounded-full bg-orange-50 text-orange-700 text-[9px] font-black uppercase tracking-wider border border-orange-100">
                  Wait
                </div>
              </div>

            </div>
          </div>
        </div>
      </main>

      {/* Bottom navbar mobile footer */}
      <nav className="md:hidden fixed bottom-0 left-0 w-full z-50 bg-white/95 backdrop-blur-md border-t border-slate-100 shadow-[0_-4px_12px_rgba(0,0,0,0.05)] h-16 flex justify-around items-center px-2 pb-safe rounded-t-2xl">
        <button 
          onClick={() => onNavigate('admin_dashboard')}
          className="flex flex-col items-center justify-center text-blue-800 bg-blue-50/70 p-1.5 px-4 rounded-full"
        >
          <Home size={18} />
          <span className="text-[10px] font-bold mt-0.5">{t.navHome}</span>
        </button>
        <button 
          onClick={() => onNavigate('profile_settings')}
          className="flex flex-col items-center justify-center text-slate-500 hover:text-blue-800"
        >
          <TrendingUp size={18} />
          <span className="text-[10px] font-bold mt-0.5">{lang === 'en' ? 'Stats' : 'Profil'}</span>
        </button>
        <button 
          onClick={onLogout}
          className="flex flex-col items-center justify-center text-slate-400 hover:text-red-650"
        >
          <LogOut size={18} />
          <span className="text-[10px] font-bold mt-0.5">{lang === 'en' ? 'Logout' : 'Keluar'}</span>
        </button>
      </nav>
    </div>
  );
}
