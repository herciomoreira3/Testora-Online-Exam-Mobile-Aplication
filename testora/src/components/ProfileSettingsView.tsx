/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { School, ArrowLeft, HelpCircle, Edit, Globe, Lightbulb, Bell, Lock, ShieldCheck, ChevronRight, BookOpen, LogOut, Home, User as UserIcon } from 'lucide-react';
import { AppLang, User, TRANSLATIONS } from '../types';

interface ProfileSettingsViewProps {
  user: User;
  lang: AppLang;
  onLanguageChange: (lang: AppLang) => void;
  onExit: () => void;
  onLogout: () => void;
  darkMode: boolean;
  onToggleDarkMode: () => void;
}

export default function ProfileSettingsView({
  user,
  lang,
  onLanguageChange,
  onExit,
  onLogout,
  darkMode,
  onToggleDarkMode
}: ProfileSettingsViewProps) {
  const t = TRANSLATIONS[lang];

  // Local settings switches
  const [examNotifs, setExamNotifs] = useState(true);

  // Pick portrait matching the login roles
  const getAvatar = () => {
    if (user.role === 'student') {
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuDXuusVdyd2Apyas30TqcJxAqZquyc-XL42Ue7sTNkLKzr8d61wNAD4dlEwDPaGkXHeKGL2T-CHUFXAWY4nLabmpUqiCDvtmy94sDV5odTpQiZupFPQb5hFPC5q20JMevwv1x-UTdXeGI2LBZ1Uc3zuSpUOyHkrrqysGcMm6vyrcbPWBbaYz0vDSCgAUIm6meeGmnjqMi1XrpS6yNRIo4zhlREV0qd03Vgf_vwpE_OCkI-RGqblYS-Mb8vMkXhSycHHufBe_Rn0Kg';
    } else if (user.role === 'teacher') {
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuAL28lwa-pxP98hGnL_sSXnY1dABRtnYyBzDugcwNtS8VZe4cRl5eMEg5MiWKCVHKXZMrMKMhaIwfcPcDMUfmh7TJJwEVb-TJKJGc4XcBEOF_crcpZ6Ga0HuCUJxpBkwWSoZWtFuwM5l_fZgNfbzggVP3DsOKg6hd5WISzOFLVLzvr9QS1vcpRYMrRlV_dsXDvb4XTPBxuUkoh0irh68GXut7DbeLQbXvkHyvqZfDE68vtG4nCBpdE5eA6Gfgs8W5yZfW5Wf0ozFw';
    } else {
      return 'https://lh3.googleusercontent.com/aida-public/AB6AXuBx3xIEd2siQ6-PKLvVMaAmHvBSw6VZ1ByNVUl0RplZRhaiNvskUX-QX_Jus6kE4DQ563JZLp27MFnaK_FAcKsPsB9MBKG10cX5UTHObXbTlXS812IDUUmAXbRCn5Uul7wiXsDvOadU1scBWMxQFkP-8th_5Bum1FHOC3_SC3sCXeRv2Jc3nHYGKVVODZ4wz96Kxu7MXbSQcX01ybGTo2ILLPaPrzC4xVAd-D-4EzgXOFygY-1jxcxvfxwgcoDZtA-g5oGR7XN4EA';
    }
  };

  const getSubLabel = () => {
    if (user.role === 'student') return 'Student • Computer Science';
    if (user.role === 'teacher') return 'Senior Instructor • Matematika M.Pd';
    return 'Administrator • Systems Auditor';
  };

  return (
    <div className="min-h-screen pb-24 bg-[#f7f9fb] dark:bg-slate-900 dark:text-white transition-colors duration-300">
      
      {/* AppBar navigation */}
      <header className="bg-white dark:bg-slate-800 border-b border-slate-100 dark:border-slate-750 shadow-sm sticky top-0 z-50">
        <div className="flex justify-between items-center w-full px-4 md:px-8 h-20 max-w-7xl mx-auto">
          <div className="flex items-center gap-4">
            <button 
              onClick={onExit}
              className="w-10 h-10 border border-slate-200/50 dark:border-slate-700 bg-white dark:bg-slate-800 hover:bg-slate-50 dark:hover:bg-slate-700 flex items-center justify-center rounded-full shadow-sm outline-none active:scale-95 transition-all text-blue-800 dark:text-blue-400"
            >
              <ArrowLeft size={18} />
            </button>
            <h1 className="font-headline text-lg font-black">{lang === 'en' ? 'Profile & Settings' : 'Profil & Pengaturan'}</h1>
          </div>

          <div className="flex items-center gap-3 select-none">
            <div className="flex items-center gap-1">
              <School className="text-blue-800 dark:text-blue-400" size={24} />
              <span className="font-headline text-lg font-bold text-blue-800 dark:text-white">Testora</span>
            </div>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="max-w-xl mx-auto px-4 md:px-8 pt-8 animate-fade-in">
        
        {/* Profile Card Section */}
        <section className="flex flex-col items-center mb-8">
          <div className="relative group">
            <div className="w-28 h-28 rounded-full overflow-hidden border-2 border-white dark:border-slate-700 shadow-[4px_4px_12px_rgba(203,213,225,0.4)] mb-4">
              <img 
                alt="Profile Large" 
                className="w-full h-full object-cover" 
                src={getAvatar()}
              />
            </div>
            
            <button className="absolute bottom-3 right-0 bg-blue-800 text-white p-2 rounded-full shadow-md hover:scale-115 transition-transform active:scale-95">
              <Edit size={12} />
            </button>
          </div>

          <h2 className="font-headline text-xl font-bold text-slate-850 dark:text-white mb-0.5">
            {user.fullName}
          </h2>
          <p className="font-sans text-xs text-slate-400 font-bold tracking-wide">
            {getSubLabel()}
          </p>
        </section>

        {/* Categories list */}
        <div className="space-y-4">
          
          {/* Card Category 1: Account setup */}
          <div className="bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-2xl p-5 shadow-[4px_4px_12px_rgba(203,213,225,0.2)]">
            <h3 className="font-headline text-[10px] uppercase tracking-widest font-black text-slate-400 mb-4">{t.identitySection}</h3>
            
            <div className="divide-y divide-slate-100 dark:divide-slate-700">
              
              {/* Language Switch */}
              <div className="flex items-center justify-between py-3.5 first:pt-0 last:pb-0">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-slate-50 dark:bg-slate-700/50 text-blue-850 dark:text-blue-400 flex items-center justify-center border border-slate-100 dark:border-slate-650 shadow-inner">
                    <Globe size={18} />
                  </div>
                  <span className="font-sans text-xs md:text-sm font-semibold">{t.langSettings}</span>
                </div>

                <div className="flex bg-slate-100 dark:bg-slate-900 border border-slate-200/50 dark:border-slate-750 p-0.5 rounded-xl z-20 text-[10px]">
                  <button 
                    onClick={() => onLanguageChange('id')}
                    className={`px-3 py-1.5 rounded-lg font-bold transition-all ${
                      lang === 'id' ? 'bg-white dark:bg-slate-800 text-blue-800 dark:text-white shadow-sm' : 'text-slate-400'
                    }`}
                  >
                    INA
                  </button>
                  <button 
                    onClick={() => onLanguageChange('en')}
                    className={`px-3 py-1.5 rounded-lg font-bold transition-all ${
                      lang === 'en' ? 'bg-white dark:bg-slate-800 text-blue-800 dark:text-white shadow-sm' : 'text-slate-400'
                    }`}
                  >
                    ENG
                  </button>
                  <button 
                    onClick={() => onLanguageChange('tt')}
                    className={`px-3 py-1.5 rounded-lg font-bold transition-all ${
                      lang === 'tt' ? 'bg-white dark:bg-slate-800 text-blue-800 dark:text-white shadow-sm' : 'text-slate-400'
                    }`}
                  >
                    TET
                  </button>
                </div>
              </div>

              {/* Dark mode Toggle */}
              <div className="flex items-center justify-between py-3.5 last:pb-0">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-slate-50 dark:bg-slate-700/50 text-blue-850 dark:text-blue-400 flex items-center justify-center border border-slate-100 dark:border-slate-650 shadow-inner">
                    <Lightbulb size={18} />
                  </div>
                  <span className="font-sans text-xs md:text-sm font-semibold">{t.darkMode}</span>
                </div>

                {/* customized toggle switch */}
                <button 
                  onClick={onToggleDarkMode}
                  className={`w-11 h-6 rounded-full transition-colors relative outline-none border border-slate-200/20 shadow-inner ${
                    darkMode ? 'bg-blue-800' : 'bg-slate-300'
                  }`}
                >
                  <div 
                    className={`absolute top-0.5 left-0.5 w-4.5 h-4.5 rounded-full bg-white transition-all shadow-sm ${
                      darkMode ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

            </div>
          </div>

          {/* Card Category 2: alerts / alerts policy settings */}
          <div className="bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-2xl p-5 shadow-[4px_4px_12px_rgba(203,213,225,0.2)]">
            <h3 className="font-headline text-[10px] uppercase tracking-widest font-black text-slate-400 mb-4">{t.notifSettings}</h3>
            
            <div className="divide-y divide-slate-100 dark:divide-slate-700">
              
              {/* Notif triggers */}
              <div className="flex items-center justify-between py-3.5 first:pt-0 last:pb-0">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-slate-50 dark:bg-slate-700/50 text-blue-850 dark:text-blue-400 flex items-center justify-center border border-slate-100 dark:border-slate-650 shadow-inner">
                    <Bell size={18} />
                  </div>
                  <div className="flex flex-col">
                    <span className="font-sans text-xs md:text-sm font-semibold">{t.notifExams}</span>
                    <span className="font-sans text-[10px] text-slate-400">{t.notifExamsSub}</span>
                  </div>
                </div>

                <button 
                  onClick={() => setExamNotifs(!examNotifs)}
                  className={`w-11 h-6 rounded-full transition-colors relative outline-none border border-slate-200/20 shadow-inner ${
                    examNotifs ? 'bg-emerald-600' : 'bg-slate-300'
                  }`}
                >
                  <div 
                    className={`absolute top-0.5 left-0.5 w-4.5 h-4.5 rounded-full bg-white transition-all shadow-sm ${
                      examNotifs ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {/* Password update links */}
              <div className="flex items-center justify-between py-3.5 last:pb-0 cursor-pointer group" onClick={() => alert(lang === 'en' ? 'Password change module initialized' : 'Layanan ganti kata sandi diaktifkan.')}>
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-slate-50 dark:bg-slate-700/50 text-blue-850 dark:text-blue-400 flex items-center justify-center border border-slate-100 dark:border-slate-650 shadow-inner">
                    <Lock size={18} />
                  </div>
                  <span className="font-sans text-xs md:text-sm font-semibold">{t.changePass}</span>
                </div>
                <ChevronRight size={16} className="text-slate-400 group-hover:translate-x-1 transition-transform" />
              </div>

              {/* Account verification info */}
              <div className="flex items-center justify-between py-3.5 last:pb-0">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-slate-50 dark:bg-slate-700/50 text-blue-850 dark:text-blue-400 flex items-center justify-center border border-slate-100 dark:border-slate-650 shadow-inner">
                    <ShieldCheck size={18} />
                  </div>
                  <span className="font-sans text-xs md:text-sm font-semibold">{t.verifyAccount}</span>
                </div>
                <span className="bg-emerald-100 text-emerald-800 border border-emerald-200 px-3 py-1 font-bold text-[10px] uppercase rounded-full">
                  {lang === 'en' ? 'Active' : 'Aktif'}
                </span>
              </div>

            </div>
          </div>

          {/* Card Category 3: helps center / terms */}
          <div className="bg-white dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-2xl p-5 shadow-[4px_4px_12px_rgba(203,213,225,0.2)]">
            <h3 className="font-headline text-[10px] uppercase tracking-widest font-black text-slate-400 mb-4">{lang === 'en' ? 'Support' : 'Bantuan'}</h3>
            
            <div className="divide-y divide-slate-100 dark:divide-slate-700">
              
              {/* Help center links */}
              <div className="flex items-center justify-between py-3.5 first:pt-0 last:pb-0 cursor-pointer group" onClick={() => alert(lang === 'en' ? 'Help Center coordinates is 1500-111' : 'Pusat bantuan interaktif di nomor 1500-111.')}>
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-slate-50 dark:bg-slate-700/50 text-blue-850 dark:text-blue-400 flex items-center justify-center border border-slate-100 dark:border-slate-650 shadow-inner">
                    <HelpCircle size={18} />
                  </div>
                  <span className="font-sans text-xs md:text-sm font-semibold">{t.supportHelp}</span>
                </div>
                <ChevronRight size={16} className="text-slate-400 group-hover:translate-x-1 transition-transform" />
              </div>

              {/* terms & cond trigger links */}
              <div className="flex items-center justify-between py-3.5 last:pb-0 cursor-pointer group" onClick={() => alert('Testora v2.4.0 Terms & Academic Regulations')}>
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-slate-50 dark:bg-slate-700/50 text-blue-850 dark:text-blue-400 flex items-center justify-center border border-slate-100 dark:border-slate-650 shadow-inner">
                    <BookOpen size={18} />
                  </div>
                  <span className="font-sans text-xs md:text-sm font-semibold">{t.termsCond}</span>
                </div>
                <ChevronRight size={16} className="text-slate-400 group-hover:translate-x-1 transition-transform" />
              </div>

            </div>
          </div>

          {/* Card Category 4: Log Out application session */}
          <button 
            type="button"
            onClick={onLogout}
            className="w-full flex items-center justify-center gap-2.5 py-3.5 bg-white dark:bg-slate-800 border border-red-200 dark:border-red-950 text-red-600 font-headline font-semibold text-sm rounded-2xl shadow-sm hover:bg-red-50 dark:hover:bg-red-950/20 active:scale-[0.98] transition-all outline-none"
          >
            <LogOut size={16} />
            <span>{t.logoutBtn}</span>
          </button>
          
          <p className="text-center font-sans text-[10px] text-slate-400 pt-2 tracking-wider">
            Testora v2.4.0 • {t.academicGuaranteed}
          </p>
        </div>

      </main>
    </div>
  );
}
