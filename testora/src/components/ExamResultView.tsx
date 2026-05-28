/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { School, CheckCircle, XCircle, Award, Download, Timer, BookOpen, Star, AlertTriangle } from 'lucide-react';
import { AppLang, Exam, ExamAttempt, TRANSLATIONS } from '../types';

interface ExamResultViewProps {
  exam: Exam;
  attempt: ExamAttempt;
  lang: AppLang;
  onBackToDashboard: () => void;
}

export default function ExamResultView({ exam, attempt, lang, onBackToDashboard }: ExamResultViewProps) {
  const t = TRANSLATIONS[lang];
  const [showCertificate, setShowCertificate] = useState(false);
  const [expandedQuestId, setExpandedQuestId] = useState<string | null>(null);

  // Generate particles confetti on render
  const [particles, setParticles] = useState<{ id: number; left: number; delay: number; color: string; duration: number }[]>([]);

  useEffect(() => {
    const arr = [];
    const colors = ['#3B82F6', '#10B981', '#F59E0B', '#6366F1', '#EC4899'];
    for (let i = 0; i < 40; i++) {
      arr.push({
        id: i,
        left: Math.random() * 100,
        delay: Math.random() * 2000,
        color: colors[Math.floor(Math.random() * colors.length)],
        duration: Math.random() * 3000 + 2000
      });
    }
    setParticles(arr);
  }, []);

  // Compute stats
  const questionsList = exam.questions;
  const answeredCount = Object.keys(attempt.answers).length;
  const correctCount = questionsList.filter(q => attempt.answers[q.id] === q.correctAnswer).length;
  const wrongCount = questionsList.length - correctCount;
  const finalScore = attempt.score !== undefined ? attempt.score : 85;

  const toggleExpand = (qId: string) => {
    setExpandedQuestId(expandedQuestId === qId ? null : qId);
  };

  const formatSeconds = (secs: number) => {
    const mins = Math.floor(secs / 60);
    const rSecs = secs % 60;
    return `${String(mins).padStart(2, '0')}:${String(rSecs).padStart(2, '0')}`;
  };

  return (
    <div className="min-h-screen bg-[#f7f9fb] pb-24 text-slate-800 relative overflow-x-hidden">
      
      {/* Falling particles confetti */}
      <div className="absolute inset-0 pointer-events-none overflow-hidden select-none z-10">
        {particles.map((p) => (
          <div 
            key={p.id}
            className="absolute rounded-full animate-fall"
            style={{
              width: '8px',
              height: '8px',
              left: `${p.left}%`,
              backgroundColor: p.color,
              top: '-10px',
              opacity: 0.8,
              animation: `fall ${p.duration}ms linear infinite`,
              animationDelay: `${p.delay}ms`
            }}
          />
        ))}
      </div>

      {/* Styled inline keyframes for confetti falling */}
      <style>{`
        @keyframes fall {
          0% { transform: translateY(0) rotate(0deg); opacity: 0.8; }
          100% { transform: translateY(100vh) rotate(360deg); opacity: 0; }
        }
      `}</style>

      {/* Certificate Modal */}
      {showCertificate && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[200] flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl border border-slate-100 p-6 md:p-8 max-w-lg w-full text-center shadow-2xl relative select-none">
            <button 
              onClick={() => setShowCertificate(false)}
              className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 font-bold text-sm"
            >
              ✕
            </button>
            
            {/* Elegant Certificate Border */}
            <div className="border-[12px] border-double border-blue-900/60 p-6 bg-amber-50/20 rounded-xl relative">
              <Award size={48} className="text-yellow-600 mx-auto mb-2" />
              <h2 className="font-headline text-lg tracking-widest text-slate-800 uppercase font-black">
                {lang === 'en' ? 'CERTIFICATE OF ACHIEVEMENT' : 'SERTIFIKAT KELULUSAN'}
              </h2>
              <p className="font-sans text-[10px] text-slate-400 tracking-wider">No: ACAD-TSTR-2026-0528</p>
              
              <div className="my-6 border-b border-slate-200 w-1/4 mx-auto" />

              <p className="font-sans text-xs italic text-slate-500">This is proudly presented to</p>
              <h3 className="font-headline text-2xl font-bold text-blue-900 my-2">Andi Pratama</h3>

              <p className="font-sans text-xs text-slate-600 leading-relaxed max-w-sm mx-auto">
                {lang === 'id' 
                  ? `Telah menyelesaikan ujian "${exam.title}" dengan hasil memuaskan pencapaian skor akhir:`
                  : `Has successfully completed the examination "${exam.title}" with an outstanding achievements score of:`
                }
              </p>

              <div className="my-4 inline-block bg-blue-900 text-white font-headline text-3xl font-black px-6 py-2 rounded-xl">
                {finalScore}
              </div>

              <div className="flex justify-between items-end mt-8 text-[10px]">
                <div className="text-center">
                  <div className="h-6 w-24 border-b border-slate-300 mx-auto" />
                  <p className="font-bold text-slate-700 mt-1">Siswa Terkait</p>
                </div>
                <div className="text-center relative">
                  <div className="absolute top-[-25px] left-1/2 -translate-x-1/2 opacity-30 select-none pointer-events-none">
                    <School className="text-blue-900" size={32} />
                  </div>
                  <p className="font-semibold text-blue-800">Sarah Pratama, M.Pd</p>
                  <div className="h-0.5 w-24 bg-slate-300 mx-auto my-1" />
                  <p className="font-bold text-slate-500">Guru Pendamping</p>
                </div>
              </div>
            </div>

            <button 
              onClick={() => window.print()}
              className="mt-6 w-full py-2.5 bg-blue-800 text-white font-bold font-headline text-xs tracking-wider uppercase rounded-xl flex items-center justify-center gap-1.5 transition-all active:scale-95 shadow-md"
            >
              <Download size={14} />
              <span>{lang === 'en' ? 'Print / Download Certificate' : 'Cetak / Unduh Sertifikat'}</span>
            </button>
          </div>
        </div>
      )}

      {/* Top sticky app header */}
      <header className="bg-white border-b border-slate-100 shadow-sm sticky top-0 z-50">
        <nav className="flex justify-between items-center w-full px-4 md:px-8 h-20 max-w-7xl mx-auto">
          <div className="flex items-center gap-3">
            <School className="text-blue-800" size={32} />
            <h1 className="font-headline text-2xl font-bold text-blue-800">Testora</h1>
          </div>
          <div className="flex items-center gap-3">
            <button 
              onClick={onBackToDashboard}
              className="px-4 py-2 text-xs font-bold text-blue-800 hover:bg-blue-50/50 rounded-xl transition-all outline-none"
            >
              {t.backToDashboard}
            </button>
          </div>
        </nav>
      </header>

      {/* Main Container */}
      <main className="max-w-3xl mx-auto px-4 md:px-8 mt-8 animate-fade-in">
        
        {/* Score Hero panel */}
        <section className="bg-white border border-slate-100 rounded-3xl p-6 text-center shadow-[4px_4px_15px_rgba(203,213,225,0.4),-4px_-4px_15px_rgba(255,255,255,0.9)] mb-8 relative overflow-hidden">
          <div className="absolute top-3 right-3 p-4 opacity-[0.05] pointer-events-none select-none text-slate-800">
            <Star size={100} />
          </div>

          <div className="flex flex-col items-center">
            <span className="inline-block bg-teal-50 text-teal-800 border border-teal-100 px-4 py-1 rounded-full font-bold text-xs mb-4 uppercase tracking-wider">
              {t.examCompletedBadge}
            </span>
            <h2 className="font-headline text-2xl md:text-3xl font-black text-slate-900 mb-2">
              {t.congratsTitle}, Andi!
            </h2>
            <p className="text-slate-400 text-xs md:text-sm font-medium mb-6">
              {lang === 'id' ? `Kamu telah menyelesaikan "${exam.title}"` : `You have successfully taken "${exam.title}"`}
            </p>

            {/* score dial display meter */}
            <div className="relative w-44 h-44 md:w-52 md:h-52 flex items-center justify-center mb-6">
              <svg className="w-full h-full -rotate-90">
                <circle cx="50%" cy="50%" fill="transparent" r="42%" stroke="#F1F5F9" strokeWidth="10" />
                <circle 
                  cx="50%" 
                  cy="50%" 
                  fill="transparent" 
                  r="42%" 
                  stroke={finalScore >= 70 ? "#1e40af" : "#ba1a1a"} 
                  strokeDasharray="264" 
                  strokeDashoffset={264 - (264 * finalScore) / 100} 
                  strokeLinecap="round" 
                  strokeWidth="10" 
                  className="transition-all duration-1000"
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="font-headline text-5xl md:text-6xl font-black tracking-tight leading-none text-blue-800">
                  {finalScore}
                </span>
                <span className="text-[9px] tracking-wider font-extrabold text-slate-400 mt-1 uppercase">
                  SKOR AKHIR
                </span>
              </div>
            </div>

            {/* stats box benar salah */}
            <div className="grid grid-cols-2 gap-4 w-full max-w-xs">
              <div className="bg-slate-50 border border-slate-200/40 rounded-xl p-3 flex flex-col items-center shadow-inner">
                <CheckCircle size={16} className="text-emerald-600 mb-0.5" />
                <span className="font-headline text-lg font-bold text-slate-800">{correctCount || '17'}</span>
                <span className="text-[10px] text-slate-400 font-semibold">{t.correctLabel}</span>
              </div>
              <div className="bg-slate-50 border border-slate-200/40 rounded-xl p-3 flex flex-col items-center shadow-inner">
                <XCircle size={16} className="text-red-500 mb-0.5" />
                <span className="font-headline text-lg font-bold text-slate-800">{wrongCount !== undefined ? wrongCount : '3'}</span>
                <span className="text-[10px] text-slate-400 font-semibold">{t.wrongLabel}</span>
              </div>
            </div>
          </div>
        </section>

        {/* Stats Bento Grid elements */}
        <section className="grid grid-cols-1 md:grid-cols-12 gap-4 mb-8">
          
          {/* accuracy list container */}
          <div className="md:col-span-8 bg-white border border-slate-100 rounded-2xl p-5 shadow-[4px_4px_12px_rgba(203,213,225,0.3)] flex flex-col justify-between min-h-[160px]">
            <div>
              <h3 className="font-headline text-sm font-bold text-slate-900 mb-3">{t.reviewPerformance}</h3>
              <div className="space-y-3 text-xs font-semibold">
                <div>
                  <div className="flex justify-between mb-1">
                    <span className="text-slate-500">{t.accuracy}</span>
                    <span className="text-blue-800">{finalScore}%</span>
                  </div>
                  <div className="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                    <div className="h-full bg-blue-800 rounded-full" style={{ width: `${finalScore}%` }} />
                  </div>
                </div>

                <div>
                  <div className="flex justify-between mb-1">
                    <span className="text-slate-500">{t.timeManagement}</span>
                    <span className="text-emerald-700">{lang === 'en' ? 'Fast' : 'Cepat'}</span>
                  </div>
                  <div className="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                    <div className="h-full bg-emerald-600 rounded-full" style={{ width: `78%` }} />
                  </div>
                </div>
              </div>
            </div>

            <div className="mt-4 flex gap-3">
              <button 
                onClick={() => questionsList[0] && toggleExpand(questionsList[0].id)}
                className="flex-1 py-2 bg-slate-100 hover:bg-slate-200 font-sans text-xs font-bold text-blue-800 rounded-xl transition-all flex items-center justify-center gap-1 border border-slate-200/20"
              >
                <BookOpen size={14} />
                <span>{t.btnReview}</span>
              </button>
              <button 
                onClick={() => setShowCertificate(true)}
                className="flex-1 py-1.5 bg-blue-800 hover:bg-blue-700 font-sans text-xs font-bold text-white rounded-xl transition-all flex items-center justify-center gap-1 shadow-md"
              >
                <Award size={14} />
                <span>{t.btnCertificate}</span>
              </button>
            </div>
          </div>

          {/* study logs elapsed details */}
          <div className="md:col-span-4 bg-white border border-slate-100 rounded-2xl p-5 shadow-[4px_4px_12px_rgba(203,213,225,0.3)] flex flex-col justify-around text-center">
            <div>
              <p className="font-sans text-[11px] text-slate-400 font-bold uppercase tracking-wider mb-1">{t.timeSpent}</p>
              <p className="font-headline text-lg font-black text-slate-800 flex items-center justify-center gap-1">
                <Timer size={16} className="text-slate-400" />
                {attempt.durationSpent ? formatSeconds(attempt.durationSpent) : '42:15'}
              </p>
            </div>

            <div className="border-t border-slate-100 my-2" />

            <div>
              <p className="font-sans text-[11px] text-slate-400 font-bold uppercase tracking-wider mb-1">{t.rankClass}</p>
              <p className="font-headline text-lg font-black text-blue-800">
                #4 <span className="text-[10px] text-slate-400 font-semibold">{lang === 'id' ? 'dari' : lang === 'tt' ? 'husi' : 'of'} 32</span>
              </p>
            </div>
          </div>
        </section>

        {/* Detailed Question Review Dropdown list */}
        <section>
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-headline text-base font-bold text-slate-900">{t.qListTitle}</h3>
            <div className="flex gap-3 text-[10px] font-bold">
              <span className="flex items-center gap-1 text-slate-500">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" /> {t.correctLabel}
              </span>
              <span className="flex items-center gap-1 text-slate-500">
                <span className="w-2.5 h-2.5 rounded-full bg-red-500" /> {t.wrongLabel}
              </span>
            </div>
          </div>

          <div className="space-y-3">
            {questionsList.map((q, qidx) => {
              const isCorrect = attempt.answers[q.id] === q.correctAnswer;
              const isExpanded = expandedQuestId === q.id;

              return (
                <div 
                  key={q.id}
                  className={`bg-white rounded-2xl border border-slate-100/80 shadow-sm transition-all overflow-hidden ${
                    isCorrect ? 'border-l-4 border-l-emerald-500' : 'border-l-4 border-l-red-500'
                  }`}
                >
                  <div 
                    onClick={() => toggleExpand(q.id)}
                    className="p-4 flex items-start gap-3 cursor-pointer hover:bg-slate-50/30 select-none"
                  >
                    <div className={`w-8 h-8 rounded-full shrink-0 flex items-center justify-center font-bold text-xs ${
                      isCorrect ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-500'
                    }`}>
                      {qidx + 1}
                    </div>

                    <div className="flex-1 min-w-0">
                      <p className="font-sans text-xs md:text-sm font-semibold text-slate-800 truncate">
                        {q.text}
                      </p>
                      
                      <div className="flex items-center gap-2 mt-1.5 text-[11px] font-bold">
                        {isCorrect ? (
                          <span className="text-emerald-700 flex items-center gap-0.5">
                            ✓ {t.correctLabel} ({q.correctAnswer})
                          </span>
                        ) : (
                          <span className="text-red-500 flex items-center gap-0.5">
                            ✕ {t.wrongLabel} (Your Answer: {attempt.answers[q.id] || '-'})
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Expanded explanations details */}
                  {isExpanded && (
                    <div className="p-4 border-t border-slate-50 bg-slate-50/50 text-xs">
                      <p className="font-medium text-slate-700 mb-3 leading-relaxed">{q.text}</p>
                      
                      {q.image && (
                        <div className="w-full max-w-sm rounded-lg overflow-hidden border border-slate-200 my-2">
                          <img alt="Step Help" className="w-full object-cover" src={q.image} />
                        </div>
                      )}

                      <div className="space-y-1.5 mt-2">
                        {q.options.map((opt) => {
                          const isOprCorrect = opt.key === q.correctAnswer;
                          const isOprSelected = opt.key === attempt.answers[q.id];
                          return (
                            <div 
                              key={opt.key}
                              className={`flex items-center p-2 rounded-lg ${
                                isOprCorrect 
                                  ? 'bg-emerald-50/60 border border-emerald-100 text-emerald-800'
                                  : isOprSelected
                                    ? 'bg-red-50/60 border border-red-100 text-red-800'
                                    : 'bg-white'
                              }`}
                            >
                              <span className="font-headline font-bold mr-2 uppercase">{opt.key}.</span>
                              <span className="font-sans font-medium">{opt.text}</span>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </section>
      </main>
    </div>
  );
}
