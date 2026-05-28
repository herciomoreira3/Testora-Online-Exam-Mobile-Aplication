/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { Mail, Lock, User as UserIcon, Presentation, GraduationCap, ShieldCheck, School } from 'lucide-react';
import { AppLang, User, UserRole, TRANSLATIONS } from '../types';

interface AuthViewProps {
  onLoginSuccess: (user: User) => void;
  lang: AppLang;
  onLanguageChange: (lang: AppLang) => void;
}

export default function AuthView({ onLoginSuccess, lang, onLanguageChange }: AuthViewProps) {
  const [activeTab, setActiveTab] = useState<'login' | 'register'>('login');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [selectedRole, setSelectedRole] = useState<UserRole>('student');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const t = TRANSLATIONS[lang];

  // Helper autofills for the user to quickly test different roles
  const handlePickDemoAcct = (role: UserRole) => {
    setActiveTab('login');
    if (role === 'student') {
      setEmail('student@testora.com');
      setPassword('password123');
    } else if (role === 'teacher') {
      setEmail('teacher@testora.com');
      setPassword('password123');
    } else {
      setEmail('admin@testora.com');
      setPassword('password123');
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) {
      setError(lang === 'en' ? 'Email is required' : 'Email wajib diisi');
      return;
    }
    if (!password) {
      setError(lang === 'en' ? 'Password is required' : 'Password wajib diisi');
      return;
    }

    if (activeTab === 'register') {
      if (!fullName) {
        setError(lang === 'en' ? 'Full name is required' : 'Nama Lengkap wajib diisi');
        return;
      }
      if (password !== confirmPassword) {
        setError(lang === 'en' ? 'Passwords do not match' : 'Password konfirmasi tidak cocok');
        return;
      }
    }

    setLoading(true);
    setError('');

    // Simulate system login/signup delay
    setTimeout(() => {
      setLoading(false);
      
      // Determine final role based on email or selections
      let finalRole: UserRole = selectedRole;
      let name = fullName || 'User Demo';

      if (email.includes('teacher') || email.includes('guru')) {
        finalRole = 'teacher';
        name = 'Sarah Pratama';
      } else if (email.includes('admin') || email.includes('adm')) {
        finalRole = 'admin';
        name = 'Administrator Utama';
      } else if (email.includes('student') || email.includes('murid') || email.includes('andi') || email.includes('budi')) {
        finalRole = 'student';
        name = email.includes('budi') ? 'Budi Santoso' : 'Andi Pratama';
      }

      onLoginSuccess({
        email: email,
        fullName: name,
        role: finalRole,
        avatarUrl: finalRole === 'student' 
          ? 'https://lh3.googleusercontent.com/aida-public/AB6AXuA5ha-vEyKPwl3J-w9NpleQ59MnSF0ksWs4Cs6u_V8WBwcXeUAyMKLk9gGj-hwqvdnD0c3lGwm-HgidwmZiKycva6h_ollB8vrf75ojiyaUJIRfUdtIAVNLYUdJXwZmsOyFXWT7XdgDqHb4SX0fQmQwRDAhR5Zm3aPQmVhANaiD_NtUKFKPRpn_kasnKPJ8lFUCkwbG8f8LrprrWojmu--93bw16YfCPdH9bT2sjd_oFJ75nurfmXyO0enyzC4kXn17yFYZExjOAQ'
          : finalRole === 'teacher'
            ? 'https://lh3.googleusercontent.com/aida-public/AB6AXuAL28lwa-pxP98hGnL_sSXnY1dABRtnYyBzDugcwNtS8VZe4cRl5eMEg5MiWKCVHKXZMrMKMhaIwfcPcDMUfmh7TJJwEVb-TJKJGc4XcBEOF_crcpZ6Ga0HuCUJxpBkwWSoZWtFuwM5l_fZgNfbzggVP3DsOKg6hd5WISzOFLVLzvr9QS1vcpRYMrRlV_dsXDvb4XTPBxuUkoh0irh68GXut7DbeLQbXvkHyvqZfDE68vtG4nCBpdE5eA6Gfgs8W5yZfW5Wf0ozFw'
            : 'https://lh3.googleusercontent.com/aida-public/AB6AXuBx3xIEd2siQ6-PKLvVMaAmHvBSw6VZ1ByNVUl0RplZRhaiNvskUX-QX_Jus6kE4DQ563JZLp27MFnaK_FAcKsPsB9MBKG10cX5UTHObXbTlXS812IDUUmAXbRCn5Uul7wiXsDvOadU1scBWMxQFkP-8th_5Bum1FHOC3_SC3sCXeRv2Jc3nHYGKVVODZ4wz96Kxu7MXbSQcX01ybGTo2ILLPaPrzC4xVAd-D-4EzgXOFygY-1jxcxvfxwgcoDZtA-g5oGR7XN4EA'
      });
    }, 1000);
  };

  return (
    <div className="min-h-screen w-full flex flex-col items-center justify-center p-4 bg-[#f7f9fb] text-slate-800">
      {/* Language Switcher on Auth Screen */}
      <div className="absolute top-4 right-4 flex items-center bg-white rounded-full p-0.5 border border-slate-200/60 shadow-sm z-50 text-xs">
        <button 
          onClick={() => onLanguageChange('id')} 
          className={`px-3 py-1.5 rounded-full font-semibold transition-all ${lang === 'id' ? 'bg-blue-800 text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
        >
          INA
        </button>
        <button 
          onClick={() => onLanguageChange('en')} 
          className={`px-3 py-1.5 rounded-full font-semibold transition-all ${lang === 'en' ? 'bg-blue-800 text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
        >
          ENG
        </button>
        <button 
          onClick={() => onLanguageChange('tt')} 
          className={`px-3 py-1.5 rounded-full font-semibold transition-all ${lang === 'tt' ? 'bg-blue-800 text-white shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
        >
          TET
        </button>
      </div>

      {/* Main Container */}
      <div className="w-full max-w-md bg-white rounded-2xl border border-slate-100 shadow-[8px_8px_20px_rgba(203,213,225,0.4),-8px_-8px_20px_rgba(255,255,255,0.9)] p-6 md:p-8 relative overflow-hidden">
        
        {/* Top Header branding */}
        <div className="flex flex-col items-center mb-6">
          <div className="w-14 h-14 bg-blue-800 rounded-2xl flex items-center justify-center mb-3 shadow-md transform hover:scale-105 transition-transform">
            <School size={28} className="text-white" />
          </div>
          <h1 className="font-headline text-2xl font-bold text-blue-800">Testora</h1>
          <p className="font-sans text-xs text-slate-400 mt-0.5">{t.systemTitle}</p>
        </div>

        {/* Auth Role Quick Filters */}
        <div className="mb-5 p-2 bg-blue-50/50 rounded-xl border border-blue-100/60">
          <p className="text-[10px] uppercase tracking-wider text-blue-800/80 font-bold mb-1 text-center">
            {lang === 'en' ? '💡 Tap to Autofill Credentials' : '💡 Ketuk untuk Mengisi Demo otomatis'}
          </p>
          <div className="grid grid-cols-3 gap-1.5 text-[11px]">
            <button 
              type="button" 
              onClick={() => handlePickDemoAcct('student')}
              className="py-1 px-1 bg-white hover:bg-blue-100/30 text-blue-800 font-semibold rounded shadow-sm border border-slate-200/50 transition-all text-center"
            >
              🎓 Student
            </button>
            <button 
              type="button" 
              onClick={() => handlePickDemoAcct('teacher')}
              className="py-1 px-1 bg-white hover:bg-blue-100/30 text-blue-800 font-semibold rounded shadow-sm border border-slate-200/50 transition-all text-center"
            >
              👩‍🏫 Teacher
            </button>
            <button 
              type="button" 
              onClick={() => handlePickDemoAcct('admin')}
              className="py-1 px-1 bg-white hover:bg-blue-100/30 text-blue-800 font-semibold rounded shadow-sm border border-slate-200/50 transition-all text-center"
            >
              🛡️ Admin
            </button>
          </div>
        </div>

        {/* Switcher login vs register */}
        <div className="relative bg-slate-100 p-1 rounded-full flex mb-6 shadow-inner">
          <button 
            type="button"
            className={`flex-1 py-1.5 font-sans text-xs font-bold rounded-full transition-all leading-none ${activeTab === 'login' ? 'bg-white text-blue-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
            onClick={() => { setActiveTab('login'); setError(''); }}
          >
            {lang === 'en' ? 'Login' : 'Login'}
          </button>
          <button 
            type="button"
            className={`flex-1 py-1.5 font-sans text-xs font-bold rounded-full transition-all leading-none ${activeTab === 'register' ? 'bg-white text-blue-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
            onClick={() => { setActiveTab('register'); setError(''); }}
          >
            {lang === 'en' ? 'Register' : 'Register'}
          </button>
        </div>

        {/* Error Warning info banner */}
        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded-xl text-xs font-medium">
            {error}
          </div>
        )}

        {/* Authentication forms */}
        <form onSubmit={handleSubmit} className="space-y-4">
          
          {/* Full Name input for Register only */}
          {activeTab === 'register' && (
            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-500 ml-1">
                {t.fullname}
              </label>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <UserIcon size={18} />
                </span>
                <input 
                  type="text" 
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder={lang === 'en' ? "Full Name" : "Nama Lengkap"}
                  className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border-none rounded-xl focus:ring-2 focus:ring-blue-800/80 outline-none text-xs transition-all font-medium"
                />
              </div>
            </div>
          )}

          {/* Role selector for Register only */}
          {activeTab === 'register' && (
            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-500 ml-1">
                {t.roleLabel}
              </label>
              <div className="grid grid-cols-3 gap-2">
                <label className="cursor-pointer">
                  <input 
                    type="radio" 
                    name="role" 
                    value="student" 
                    checked={selectedRole === 'student'} 
                    onChange={() => setSelectedRole('student')}
                    className="peer hidden" 
                  />
                  <div className="flex flex-col items-center justify-center p-2.5 rounded-xl bg-slate-50 border-2 border-transparent peer-checked:border-blue-800 peer-checked:bg-white peer-checked:shadow-sm transition-all">
                    <GraduationCap size={18} className="text-slate-400 peer-checked:text-blue-800 mb-1" />
                    <span className="text-[10px] font-bold">{t.roleLabel === 'student' ? 'Student' : t.roleMurid}</span>
                  </div>
                </label>

                <label className="cursor-pointer">
                  <input 
                    type="radio" 
                    name="role" 
                    value="teacher" 
                    checked={selectedRole === 'teacher'} 
                    onChange={() => setSelectedRole('teacher')}
                    className="peer hidden" 
                  />
                  <div className="flex flex-col items-center justify-center p-2.5 rounded-xl bg-slate-50 border-2 border-transparent peer-checked:border-blue-800 peer-checked:bg-white peer-checked:shadow-sm transition-all">
                    <Presentation size={18} className="text-slate-400 peer-checked:text-blue-800 mb-1" />
                    <span className="text-[10px] font-bold">{t.roleGuru}</span>
                  </div>
                </label>

                <label className="cursor-pointer">
                  <input 
                    type="radio" 
                    name="role" 
                    value="admin" 
                    checked={selectedRole === 'admin'} 
                    onChange={() => setSelectedRole('admin')}
                    className="peer hidden" 
                  />
                  <div className="flex flex-col items-center justify-center p-2.5 rounded-xl bg-slate-50 border-2 border-transparent peer-checked:border-blue-800 peer-checked:bg-white peer-checked:shadow-sm transition-all">
                    <ShieldCheck size={18} className="text-slate-400 peer-checked:text-blue-800 mb-1" />
                    <span className="text-[10px] font-bold">Admin</span>
                  </div>
                </label>
              </div>
            </div>
          )}

          {/* Email field */}
          <div className="space-y-1">
            <label className="block text-xs font-bold text-slate-500 ml-1">
              Email
            </label>
            <div className="relative">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                <Mail size={18} />
              </span>
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder={t.emailPlaceholder}
                className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border-none rounded-xl focus:ring-2 focus:ring-blue-800/80 outline-none text-xs transition-all font-medium"
              />
            </div>
          </div>

          {/* Password field */}
          <div className="space-y-1">
            <div className="flex justify-between items-center ml-1">
              <label className="text-xs font-bold text-slate-500">
                Password
              </label>
              {activeTab === 'login' && (
                <a href="#forgot" className="text-[11px] font-semibold text-blue-800 hover:underline">
                  {t.forgotPass}
                </a>
              )}
            </div>
            <div className="relative">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                <Lock size={18} />
              </span>
              <input 
                type="password" 
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder={t.passwordPlaceholder}
                className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border-none rounded-xl focus:ring-2 focus:ring-blue-800/80 outline-none text-xs transition-all font-medium"
              />
            </div>
          </div>

          {/* Confirm password for register only */}
          {activeTab === 'register' && (
            <div className="space-y-1">
              <label className="block text-xs font-bold text-slate-500 ml-1">
                {lang === 'en' ? "Confirm Password" : "Konfirmasi Password"}
              </label>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                  <Lock size={18} />
                </span>
                <input 
                  type="password" 
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder={t.passwordPlaceholder}
                  className="w-full pl-12 pr-4 py-2.5 bg-slate-50 border-none rounded-xl focus:ring-2 focus:ring-blue-800/80 outline-none text-xs transition-all font-medium"
                />
              </div>
            </div>
          )}

          {/* Submit Button */}
          <button 
            type="submit" 
            disabled={loading}
            className="w-full py-3 bg-blue-800 text-white font-headline font-semibold text-sm rounded-xl shadow-md hover:bg-blue-700 hover:scale-[0.98] active:scale-95 transition-all outline-none mt-4 flex items-center justify-center gap-2"
          >
            {loading ? (
              <span className="animate-spin border-2 border-white/30 border-t-white rounded-full w-5 h-5" />
            ) : (
              activeTab === 'login' ? t.btnSubmitLogin : t.btnSubmitRegister
            )}
          </button>
        </form>

        {/* Divider and Google Single Sign-On */}
        <div className="mt-6 text-center select-none">
          <div className="relative flex py-4 items-center">
            <div className="flex-grow border-t border-slate-100" />
            <span className="flex-shrink mx-4 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
              {t.orContinueWith}
            </span>
            <div className="flex-grow border-t border-slate-100" />
          </div>

          <button 
            onClick={() => {
              // Direct login mock for student as Google trigger
              handlePickDemoAcct('student');
            }}
            className="w-full py-2.5 px-4 bg-white hover:bg-slate-50 border border-slate-200/80 rounded-xl flex items-center justify-center gap-2 transition-all shadow-sm active:scale-95"
          >
            <img 
              alt="Google Logo" 
              className="w-5 h-5 shrink-0" 
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuDpVDjvVyVJhLxNrLZEYchXo0kyi6AJ6HQgLdEPuAtnMFSVyGQkl8Wh8tU7S00wTS4MLZDQ6th3mW90CLSIyUK7r63Awjh0eNCZG_Xo-GOdC-jtRcweUGRLu2EltwMr9AjnTxk_uHsDsmwLSB01AY20tCpeY4lDkTtyd5pqEXCSlOitGqscGWM6YwclcXf92Uxhp93TpCb8GrQnOErEomILbpAMFWKcsHfiXYNb6j2rDErxuFmD-J2Fqm7zGnsXbilmxF_MxX52ZA"
            />
            <span className="font-sans text-xs font-bold text-slate-700">
              {t.googleAccount}
            </span>
          </button>

          {/* Switch tab buttons */}
          <p className="mt-6 font-sans text-xs text-slate-500">
            {activeTab === 'login' ? t.noAccount : t.haveAccount}{' '}
            <button 
              type="button"
              className="text-blue-800 font-bold hover:underline outline-none"
              onClick={() => {
                setActiveTab(activeTab === 'login' ? 'register' : 'login');
                setError('');
              }}
            >
              {activeTab === 'login' ? 'Register' : 'Login'}
            </button>
          </p>
        </div>
      </div>
    </div>
  );
}
