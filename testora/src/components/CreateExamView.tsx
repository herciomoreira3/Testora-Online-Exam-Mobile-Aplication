/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { School, Calendar, Timer, ShieldAlert, ArrowLeft, ArrowRight, Shuffle, Lock, HelpCircle } from 'lucide-react';
import { AppLang, Exam, TRANSLATIONS } from '../types';

interface CreateExamViewProps {
  lang: AppLang;
  onExit: () => void;
  onExamCreated: (exam: Exam) => void;
}

export default function CreateExamView({ lang, onExit, onExamCreated }: CreateExamViewProps) {
  const t = TRANSLATIONS[lang];
  
  const [title, setTitle] = useState('');
  const [subject, setSubject] = useState('');
  const [description, setDescription] = useState('');
  
  const [date, setDate] = useState('');
  const [time, setTime] = useState('');
  const [duration, setDuration] = useState(60); // Default minutes

  const [randomize, setRandomize] = useState(false);
  const [antiCheat, setAntiCheat] = useState(true); // Default secure
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title) {
      alert(lang === 'en' ? 'Please provide an Exam Title' : 'Masukan judul ujian terlebih dahulu');
      return;
    }
    if (!subject) {
      alert(lang === 'en' ? 'Please select a Subject' : 'Pilih mata pelajaran terlebih dahulu');
      return;
    }

    setLoading(true);
    
    // Assemble new mock exam
    const newExam: Exam = {
      id: `exam-${Date.now()}`,
      title,
      subject,
      description,
      duration,
      randomize,
      antiCheat,
      questions: [], // Zero questions, pass to question editor
      status: 'wait',
      scheduledDate: date || '2026-05-28',
      scheduledTime: time || '09:00',
      studentCount: '0/32'
    };

    setTimeout(() => {
      setLoading(false);
      onExamCreated(newExam);
    }, 800);
  };

  return (
    <div className="min-h-screen pb-24 bg-[#f7f9fb] text-slate-800 animate-fade-in">
      
      {/* Header */}
      <header className="bg-white border-b border-slate-100 shadow-sm sticky top-0 z-50">
        <div className="flex justify-between items-center w-full px-4 md:px-8 h-20 max-w-7xl mx-auto">
          <div className="flex items-center gap-3">
            <School className="text-blue-800" size={32} />
            <h1 className="font-headline text-2xl font-bold text-blue-800">Testora</h1>
          </div>
          <div className="flex items-center gap-2">
            <button className="hidden md:flex items-center gap-1.5 px-4 py-2 hover:bg-slate-100 rounded-full font-sans text-xs font-bold text-slate-500">
              <HelpCircle size={16} />
              <span>{lang === "en" ? "Help" : "Bantuan"}</span>
            </button>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="max-w-4xl mx-auto px-4 md:px-8 py-8 select-none">
        
        {/* Breadcrumb & Intro */}
        <div className="mb-8">
          <div className="flex items-center gap-2 text-slate-400 font-sans text-[11px] font-bold uppercase tracking-wider mb-2">
            <span onClick={onExit} className="cursor-pointer hover:text-blue-800">{t.breadcrumbDashboard}</span>
            <span>/</span>
            <span className="text-blue-800">{t.breadcrumbNewExam}</span>
          </div>
          
          <h2 className="font-headline text-3xl font-black text-slate-900">
            {t.configNewExam}
          </h2>
          <p className="font-sans text-xs text-slate-400 mt-1">
            {t.configSub}
          </p>
        </div>

        {/* Configuration Form */}
        <form onSubmit={handleSubmit} className="space-y-6">
          
          {/* Identity Card */}
          <section className="bg-white border border-slate-100 rounded-2xl p-6 shadow-[5px_5px_15px_rgba(203,213,225,0.3)]">
            <div className="flex items-center gap-2 mb-4 border-b border-slate-50 pb-3">
              <School className="text-blue-800" size={20} />
              <h3 className="font-headline text-base font-bold text-slate-800">{t.identitySection}</h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-500">{t.examTitle}</label>
                <input 
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder={lang === 'en' ? "e.g. Linear Algebra Midterm" : "Contoh: Ujian Tengah Semester Aljabar"}
                  className="w-full text-xs font-medium py-3 px-4 bg-slate-50/80 border border-slate-200/50 rounded-xl focus:ring-2 focus:ring-blue-800 outline-none transition-all"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-500">{t.selectSubject}</label>
                <select 
                  value={subject}
                  onChange={(e) => setSubject(e.target.value)}
                  className="w-full text-xs font-medium py-3 px-4 bg-slate-50/80 border border-slate-200/50 rounded-xl focus:ring-2 focus:ring-blue-800 outline-none transition-all appearance-none cursor-pointer"
                >
                  <option value="">{t.selectSubject}</option>
                  <option value="Matematika">Matematika</option>
                  <option value="Biologi">Biologi</option>
                  <option value="Fisika">Fisika</option>
                  <option value="Sejarah">Sejarah</option>
                  <option value="B. Inggris">Bahasa Inggris</option>
                  <option value="Bahasa Indonesia">Bahasa Indonesia</option>
                </select>
              </div>

              <div className="md:col-span-2 space-y-1">
                <label className="text-xs font-bold text-slate-500">{t.descriptionLabel}</label>
                <textarea 
                  rows={2}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder={lang === 'en' ? "Provide quick instructions for candidates..." : "Berikan instruksi singkat untuk siswa..."}
                  className="w-full text-xs font-medium py-3 px-4 bg-slate-50/80 border border-slate-200/50 rounded-xl focus:ring-2 focus:ring-blue-800 outline-none transition-all resize-none"
                />
              </div>
            </div>
          </section>

          {/* Schedule Section */}
          <section className="bg-white border border-slate-100 rounded-2xl p-6 shadow-[5px_5px_15px_rgba(203,213,225,0.3)]">
            <div className="flex items-center gap-2 mb-4 border-b border-slate-50 pb-3">
              <Calendar className="text-blue-800" size={20} />
              <h3 className="font-headline text-base font-bold text-slate-800">{t.scheduleSection}</h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-500">{t.examDate}</label>
                <input 
                  type="date"
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  className="w-full text-xs font-medium py-3 px-4 bg-slate-50/80 border border-slate-200/50 rounded-xl focus:ring-2 focus:ring-blue-800 outline-none transition-all"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-500">{t.examTime}</label>
                <input 
                  type="time"
                  value={time}
                  onChange={(e) => setTime(e.target.value)}
                  className="w-full text-xs font-medium py-3 px-4 bg-slate-50/80 border border-slate-200/50 rounded-xl focus:ring-2 focus:ring-blue-800 outline-none transition-all"
                />
              </div>

              <div className="md:col-span-2 space-y-3 pt-2">
                <div className="flex justify-between items-center sm:mx-1">
                  <label className="text-xs font-bold text-slate-500">{t.examDuration}</label>
                  <span className="font-headline text-base font-bold text-blue-800">{duration} {lang === 'en' ? 'Minutes' : 'Menit'}</span>
                </div>
                
                <div className="px-1">
                  <input 
                    type="range"
                    min="15"
                    max="180"
                    step="15"
                    value={duration}
                    onChange={(e) => setDuration(Number(e.target.value))}
                    className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-blue-800"
                  />
                  <div className="flex justify-between text-[10px] text-slate-400 mt-2 font-bold uppercase tracking-wider">
                    <span>15 Min</span>
                    <span>180 Min</span>
                  </div>
                </div>
              </div>
            </div>
          </section>

          {/* Security Policy Settings */}
          <section className="bg-white border border-slate-100 rounded-2xl p-6 shadow-[5px_5px_15px_rgba(203,213,225,0.3)]">
            <div className="flex items-center gap-2 mb-4 border-b border-slate-50 pb-3">
              <ShieldAlert className="text-blue-800" size={20} />
              <h3 className="font-headline text-base font-bold text-slate-800">{t.securitySection}</h3>
            </div>

            <div className="space-y-4">
              
              {/* Randomize toggle */}
              <div className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50 transition-colors group">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center group-hover:bg-white text-slate-500 shadow-sm">
                    <Shuffle size={16} />
                  </div>
                  <div>
                    <p className="font-sans text-xs font-bold text-slate-800">{t.randomizeQuestions}</p>
                    <p className="text-[10px] text-slate-400 font-semibold">{t.randomizeSub}</p>
                  </div>
                </div>
                
                {/* Custom toggle style */}
                <button 
                  type="button"
                  onClick={() => setRandomize(!randomize)}
                  className={`w-11 h-6 rounded-full transition-colors relative outline-none border border-slate-200/20 shadow-inner ${
                    randomize ? 'bg-blue-800' : 'bg-slate-300'
                  }`}
                >
                  <div 
                    className={`absolute top-0.5 left-0.5 w-4.5 h-4.5 rounded-full bg-white transition-all shadow-sm ${
                      randomize ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {/* Anti Cheat toggle */}
              <div className="flex items-center justify-between p-3 rounded-xl hover:bg-slate-50 transition-colors group">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center group-hover:bg-white text-slate-500 shadow-sm">
                    <Lock size={16} />
                  </div>
                  <div>
                    <p className="font-sans text-xs font-bold text-slate-800">{t.antiCheatLabel}</p>
                    <p className="text-[10px] text-slate-400 font-semibold">{t.antiCheatSub}</p>
                  </div>
                </div>
                
                <button 
                  type="button"
                  onClick={() => setAntiCheat(!antiCheat)}
                  className={`w-11 h-6 rounded-full transition-colors relative outline-none border border-slate-200/20 shadow-inner ${
                    antiCheat ? 'bg-blue-800' : 'bg-slate-300'
                  }`}
                >
                  <div 
                    className={`absolute top-0.5 left-0.5 w-4.5 h-4.5 rounded-full bg-white transition-all shadow-sm ${
                      antiCheat ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>
            </div>
          </section>

          {/* CTA controls */}
          <div className="flex justify-between items-center pt-2">
            <button 
              type="button"
              onClick={onExit}
              className="px-6 py-3 border border-slate-200 font-sans text-xs font-bold text-slate-500 bg-white hover:bg-slate-50 rounded-xl transition-all shadow-sm flex items-center gap-1 active:scale-95 outline-none"
            >
              <ArrowLeft size={16} />
              <span>{lang === 'en' ? 'Cancel' : 'Batal'}</span>
            </button>

            <button 
              type="submit"
              disabled={loading}
              className="px-8 py-3 bg-blue-800 hover:bg-blue-700 text-white font-headline text-xs font-bold rounded-xl shadow-md transition-all active:scale-95 flex items-center gap-1.5 outline-none"
            >
              {loading ? (
                <span className="animate-spin border-2 border-white/30 border-t-white rounded-full w-5 h-5" />
              ) : (
                <>
                  <span>{t.btnProceedQuestions}</span>
                  <ArrowRight size={16} />
                </>
              )}
            </button>
          </div>
        </form>
      </main>
    </div>
  );
}
