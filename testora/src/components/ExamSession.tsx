/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { School, Flag, Timer, ArrowLeft, ArrowRight, Upload, Sparkles, Send, AlertTriangle } from 'lucide-react';
import { AppLang, Exam, ExamAttempt, TRANSLATIONS } from '../types';

interface ExamSessionProps {
  exam: Exam;
  lang: AppLang;
  onSubmitExam: (attempt: ExamAttempt) => void;
  onExit: () => void;
}

export default function ExamSession({ exam, lang, onSubmitExam, onExit }: ExamSessionProps) {
  const t = TRANSLATIONS[lang];
  
  // Initialize question answers and indicators
  const [currentQuestionIdx, setCurrentQuestionIdx] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [flagged, setFlagged] = useState<Record<string, boolean>>({});
  const [timeLeft, setTimeLeft] = useState(exam.duration * 60); // standard seconds representation
  const [cheatingMsgs, setCheatingMsgs] = useState<string[]>([]);
  const [cheatingAttempts, setCheatingAttempts] = useState(0);
  const [showWarningModal, setShowWarningModal] = useState(false);
  const [isSubmitConfirmOpen, setIsSubmitConfirmOpen] = useState(false);

  const activeQuestion = exam.questions[currentQuestionIdx];
  const questionCount = exam.questions.length;

  // Real-time ticking down timer
  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          // Auto submit on timeout
          handleAutoSubmit();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  // Monitor anti-cheat behavior (tab switching / screen blur metrics)
  useEffect(() => {
    if (!exam.antiCheat) return;

    let warningGiven = false;

    const handleVisibilityBlur = () => {
      if (document.hidden || !document.hasFocus()) {
        if (!warningGiven) {
          warningGiven = true;
          setCheatingAttempts((prev) => {
            const currentTotal = prev + 1;
            setShowWarningModal(true);
            
            // Log timestamped trace
            const timestamp = new Date().toLocaleTimeString();
            setCheatingMsgs((prevLogs) => [
              ...prevLogs,
              `[${timestamp}] Tab switched / focus lost. Alert given.`
            ]);

            return currentTotal;
          });
        }
      } else {
        warningGiven = false;
      }
    };

    window.addEventListener('blur', handleVisibilityBlur);
    document.addEventListener('visibilitychange', handleVisibilityBlur);

    return () => {
      window.removeEventListener('blur', handleVisibilityBlur);
      document.removeEventListener('visibilitychange', handleVisibilityBlur);
    };
  }, [exam.antiCheat]);

  const handleSelectOption = (qId: string, optionKey: string) => {
    setAnswers((prev) => ({
      ...prev,
      [qId]: optionKey
    }));
  };

  const toggleFlag = (qId: string) => {
    setFlagged((prev) => ({
      ...prev,
      [qId]: !prev[qId]
    }));
  };

  const handleNext = () => {
    if (currentQuestionIdx < questionCount - 1) {
      setCurrentQuestionIdx(currentQuestionIdx + 1);
    }
  };

  const handlePrev = () => {
    if (currentQuestionIdx > 0) {
      setCurrentQuestionIdx(currentQuestionIdx - 1);
    }
  };

  const handleAutoSubmit = () => {
    // Generate scores
    let finalScore = 0;
    let maxPoints = 0;

    exam.questions.forEach((q) => {
      maxPoints += q.points;
      if (answers[q.id] === q.correctAnswer) {
        finalScore += q.points;
      }
    });

    const scaledScore = maxPoints > 0 ? Math.round((finalScore / maxPoints) * 100) : 100;

    onSubmitExam({
      examId: exam.id,
      examTitle: exam.title,
      subject: exam.subject,
      answers,
      flagged,
      timeLeft,
      cheatingAttempts,
      durationSpent: (exam.duration * 60) - timeLeft,
      isSubmitted: true,
      score: scaledScore
    });
  };

  // Convert seconds to clean display MM:SS
  const formatTime = (secs: number) => {
    const mins = Math.floor(secs / 60);
    const remainingSecs = secs % 60;
    return `${String(mins).padStart(2, '0')}:${String(remainingSecs).padStart(2, '0')}`;
  };

  // Calculate completeness progress percentage
  const finishedStateCount = Object.keys(answers).length;
  const progressPercent = questionCount > 0 ? (finishedStateCount / questionCount) * 100 : 0;

  // Render cheating lock screen if switched more than 3 times
  if (cheatingAttempts >= 4) {
    return (
      <main className="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-6 text-white text-center">
        <AlertTriangle size={80} className="text-red-500 animate-pulse mb-6" />
        <h2 className="font-headline text-3xl font-bold text-red-500 mb-2">
          {lang === 'en' ? 'SESSION LOCKED' : 'SESI DIKUNCI'}
        </h2>
        <p className="font-sans text-slate-300 max-w-md mx-auto leading-relaxed mb-8">
          {t.cheatingExclusion}
        </p>
        <div className="bg-slate-900 border border-red-500/30 rounded-xl p-4 max-w-sm w-full mb-8 text-xs text-left text-slate-400">
          <p className="font-bold mb-2 text-slate-200">Security Violations Trace Log:</p>
          <ul className="space-y-1 font-mono list-disc pl-4">
            {cheatingMsgs.map((msg, i) => (
              <li key={i}>{msg}</li>
            ))}
          </ul>
        </div>
        <button 
          onClick={onExit}
          className="px-8 py-3 bg-red-600 hover:bg-red-700 text-white font-bold font-headline text-xs tracking-wider uppercase rounded-xl transition-all"
        >
          {lang === 'en' ? 'Back to Dashboard' : 'Kembali'}
        </button>
      </main>
    );
  }

  return (
    <div className="min-h-screen pb-32 bg-[#f7f9fb] text-slate-800 relative">
      
      {/* Visual Anti-Cheat blur Modal Warning */}
      {showWarningModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[200] flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl border border-red-200 p-6 md:p-8 max-w-sm text-center shadow-2xl">
            <AlertTriangle size={48} className="text-red-500 mx-auto mb-4 animate-bounce" />
            <h3 className="font-headline text-lg font-bold text-red-600 mb-2">
              {t.cheatingDetected}
            </h3>
            <p className="font-sans text-xs text-slate-400 leading-relaxed mb-6">
              {lang === 'id' 
                ? `Testora mendeteksi Anda meninggalkan layar ujian. Pelanggaran tercatat! (${cheatingAttempts}/3 kali sebelum ujian terkunci).`
                : `Testora detected you left the browser tab. Violation logged! (${cheatingAttempts}/3 times before session lock).`
              }
            </p>
            <button 
              onClick={() => setShowWarningModal(false)}
              className="w-full py-2.5 bg-red-600 hover:bg-red-700 text-white font-bold font-headline text-xs tracking-widest uppercase rounded-xl transition-all"
            >
              IKTIAR, MENGERTI
            </button>
          </div>
        </div>
      )}

      {/* Submit Confirmation Modal */}
      {isSubmitConfirmOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[200] flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl border border-blue-100 p-6 md:p-8 max-w-sm text-center shadow-2xl">
            <Sparkles size={48} className="text-blue-800 mx-auto mb-4 animate-pulse" />
            <h3 className="font-headline text-lg font-bold text-blue-800 mb-2">
              {lang === 'en' ? 'Submit Exam?' : 'Kumpulkan Ujian?'}
            </h3>
            <p className="font-sans text-xs text-slate-400 leading-relaxed mb-6">
              {t.submitConfirm}
            </p>
            <div className="flex gap-3">
              <button 
                onClick={() => setIsSubmitConfirmOpen(false)}
                className="flex-1 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-500 font-bold font-headline text-[10px] tracking-wider uppercase rounded-xl transition-all"
              >
                {lang === 'en' ? 'Cancel' : 'Kembali'}
              </button>
              <button 
                onClick={() => {
                  setIsSubmitConfirmOpen(false);
                  handleAutoSubmit();
                }}
                className="flex-1 py-2.5 bg-blue-800 hover:bg-blue-700 text-white font-bold font-headline text-[10px] tracking-wider uppercase rounded-xl transition-all shadow-md"
              >
                {lang === 'en' ? 'Submit' : 'Ya, Kumpulkan'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Top sticky app header showing progress & time remaining */}
      <header className="fixed top-0 left-0 right-0 z-50 bg-white border-b border-slate-100 shadow-sm h-20">
        <div className="max-w-4xl mx-auto h-full px-4 md:px-8 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <School className="text-blue-800" size={28} />
            <div className="flex flex-col">
              <h1 className="font-headline text-sm md:text-base font-bold text-blue-900 leading-tight">
                {exam.title}
              </h1>
              <p className="font-sans text-[10px] text-slate-400 font-semibold">{exam.subject} • 12-A</p>
            </div>
          </div>

          <div className={`flex items-center gap-2 px-4 py-1.5 rounded-full transition-colors duration-300 ${
            timeLeft < 300 ? 'bg-red-50 border border-red-100 text-red-600 animate-pulse' : 'bg-slate-100 border border-slate-200/50 text-slate-700'
          }`}>
            <Timer size={16} />
            <span className="font-headline text-xs md:text-sm font-bold tabular-nums">
              {formatTime(timeLeft)}
            </span>
          </div>
        </div>

        {/* Dynamic progress bar tracking answered state */}
        <div className="absolute bottom-0 left-0 w-full h-1.5 bg-slate-100">
          <div 
            className="h-full bg-blue-800 transition-all duration-500 rounded-r-full" 
            style={{ width: `${progressPercent}%` }} 
          />
        </div>
      </header>

      {/* Main active question contents */}
      <main className="pt-28 pb-32 px-4 md:px-8 max-w-2xl mx-auto animate-fade-in z-20">
        
        {/* Question indices headers */}
        <div className="flex items-center justify-between mb-4 mt-2">
          <div className="flex items-center gap-2">
            <span className="font-sans text-[10px] font-bold text-blue-800 uppercase tracking-widest">{t.navExams}</span>
            <span className="px-3 py-1 bg-blue-50 text-blue-800 text-xs font-bold rounded-full border border-blue-100">
              {String(currentQuestionIdx + 1).padStart(2, '0')}{' '}
              <span className="opacity-50 text-[10px]">/ {String(questionCount).padStart(2, '0')}</span>
            </span>
          </div>

          {activeQuestion && (
            <button 
              onClick={() => toggleFlag(activeQuestion.id)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold select-none shadow-sm transition-all border outline-none ${
                flagged[activeQuestion.id]
                  ? 'bg-orange-50 border-orange-200 text-orange-600'
                  : 'bg-white border-slate-200 text-slate-400 hover:bg-slate-50'
              }`}
            >
              <Flag size={14} fill={flagged[activeQuestion.id] ? "currentColor" : "none"} />
              <span>{t.flagBtn}</span>
            </button>
          )}
        </div>

        {activeQuestion ? (
          <div>
            <section className="mb-6">
              <h2 className="font-headline text-base md:text-lg font-bold text-slate-900 leading-relaxed mb-4">
                {activeQuestion.text}
              </h2>

              {/* Display visual help map/math illustrations */}
              {activeQuestion.image && (
                <div className="w-full h-44 md:h-52 rounded-xl overflow-hidden shadow-sm border border-slate-100 mb-6 bg-slate-200 relative group">
                  <img 
                    alt="Question Visual" 
                    className="w-full h-full object-cover select-none pointer-events-none group-hover:scale-105 transition-transform duration-700" 
                    src={activeQuestion.image}
                  />
                </div>
              )}
            </section>

            {/* Answer Options list */}
            <div className="grid grid-cols-1 gap-3">
              {activeQuestion.options.map((opt) => {
                const isSelected = answers[activeQuestion.id] === opt.key;
                return (
                  <button 
                    key={opt.key}
                    onClick={() => handleSelectOption(activeQuestion.id, opt.key)}
                    className={`flex items-center p-4 rounded-xl text-left w-full border outline-none transition-all duration-200 ${
                      isSelected
                        ? 'bg-blue-50/50 border-blue-800 shadow-[inset_2px_2px_5px_rgba(30,64,175,0.06)]'
                        : 'bg-white border-slate-200/60 shadow-[4px_4px_8px_rgba(203,213,225,0.2)] hover:bg-slate-50/40'
                    }`}
                  >
                    <span className={`w-8 h-8 shrink-0 flex items-center justify-center rounded-lg font-bold text-sm mr-3 transition-colors ${
                      isSelected
                        ? 'bg-blue-800 text-white'
                        : 'bg-slate-100 text-slate-500'
                    }`}>
                      {opt.key}
                    </span>
                    <span className={`font-sans text-xs md:text-sm font-medium ${
                      isSelected ? 'text-blue-800 font-semibold' : 'text-slate-700'
                    }`}>
                      {opt.text}
                    </span>
                  </button>
                );
              })}
            </div>
          </div>
        ) : (
          <div className="text-center p-8 bg-slate-50 rounded-2xl border border-dashed border-slate-200 text-slate-400 text-xs font-semibold">
            {lang === 'en' ? 'Warning: No questions uploaded' : 'Peringatan: Tidak ada soal terunggah'}
          </div>
        )}
      </main>

      {/* Bottom controllers bar */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white/90 backdrop-blur-md h-20 border-t border-slate-100 flex items-center shadow-[0_-5px_15px_rgba(0,0,0,0.02)]">
        <div className="max-w-2xl mx-auto w-full px-4 flex justify-between items-center">
          <button 
            onClick={handlePrev}
            disabled={currentQuestionIdx === 0}
            className={`flex items-center gap-1.5 px-4 py-2.5 rounded-xl border font-sans text-xs font-bold transition-all ${
              currentQuestionIdx === 0
                ? 'opacity-30 border-slate-100 text-slate-300'
                : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50 active:scale-95'
            }`}
          >
            <ArrowLeft size={16} />
            <span>{t.prevBtn}</span>
          </button>

          <span className="hidden sm:inline font-sans text-[10px] text-slate-400 italic">
            {t.autoSaved}
          </span>

          <button 
            onClick={currentQuestionIdx === questionCount - 1 ? () => setIsSubmitConfirmOpen(true) : handleNext}
            className="flex items-center gap-1.5 px-5 py-2.5 bg-blue-800 text-white hover:bg-blue-700 text-xs font-bold font-headline rounded-xl shadow-md transition-all active:scale-95"
          >
            {currentQuestionIdx === questionCount - 1 ? (
              <>
                <span>{lang === 'en' ? 'Finish Exam' : 'Selesai'}</span>
                <Send size={14} />
              </>
            ) : (
              <>
                <span>{t.nextBtn}</span>
                <ArrowRight size={16} />
              </>
            )}
          </button>
        </div>
      </nav>

      {/* Floating Action Button (FAB) shortcut for submit */}
      <div className="fixed bottom-24 right-5 hover:scale-105 active:scale-95 transition-all z-35 bg-emerald-700 p-4 rounded-full text-white shadow-xl flex items-center justify-center cursor-pointer">
        <button onClick={() => setIsSubmitConfirmOpen(true)} className="outline-none flex items-center justify-center">
          <Upload size={22} />
        </button>
      </div>
    </div>
  );
}
