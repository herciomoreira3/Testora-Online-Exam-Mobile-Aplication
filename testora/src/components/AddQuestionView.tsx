/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { School, ArrowLeft, Image, Trash2, ListMinus, Save, Plus, CheckCircle, HelpCircle } from 'lucide-react';
import { AppLang, Exam, Question, TRANSLATIONS } from '../types';

interface AddQuestionViewProps {
  exam: Exam;
  lang: AppLang;
  onExit: () => void;
  onQuestionAdded: (quest: Question, addNewAnother: boolean) => void;
}

export default function AddQuestionView({ exam, lang, onExit, onQuestionAdded }: AddQuestionViewProps) {
  const t = TRANSLATIONS[lang];

  const [text, setText] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [points, setPoints] = useState(5);
  
  // Mocks option inputs
  const [optionA, setOptionA] = useState('');
  const [optionB, setOptionB] = useState('');
  const [optionC, setOptionC] = useState('');
  const [optionD, setOptionD] = useState('');
  const [correctKey, setCorrectKey] = useState('A');
  const [loading, setLoading] = useState(false);

  const handleSave = (addNewAnother: boolean) => {
    if (!text) {
      alert(lang === 'en' ? 'Question text is required' : 'Isi teks pertanyaan terlebih dahulu');
      return;
    }
    if (!optionA || !optionB || !optionC || !optionD) {
      alert(lang === 'en' ? 'All 4 options must be completed' : 'Harap melengkapi keempat pilihan jawaban');
      return;
    }

    setLoading(true);

    const newQuestion: Question = {
      id: `quest-${Date.now()}`,
      text,
      points,
      image: imageUrl || undefined,
      correctAnswer: correctKey,
      options: [
        { key: 'A', text: optionA },
        { key: 'B', text: optionB },
        { key: 'C', text: optionC },
        { key: 'D', text: optionD }
      ]
    };

    setTimeout(() => {
      setLoading(false);
      onQuestionAdded(newQuestion, addNewAnother);

      // Reset fields if adding another
      if (addNewAnother) {
        setText('');
        setImageUrl('');
        setPoints(5);
        setOptionA('');
        setOptionB('');
        setOptionC('');
        setOptionD('');
        setCorrectKey('A');
      }
    }, 700);
  };

  return (
    <div className="min-h-screen pb-24 bg-[#f7f9fb] text-slate-800 animate-fade-in">
      
      {/* TopBar */}
      <header className="bg-white border-b border-slate-100 shadow-sm sticky top-0 z-50">
        <div className="flex justify-between items-center w-full px-4 md:px-8 h-20 max-w-7xl mx-auto">
          <div className="flex items-center gap-3">
            <School className="text-blue-800" size={32} />
            <h1 className="font-headline text-2xl font-bold text-blue-800">Testora</h1>
          </div>
          <div className="flex items-center gap-4">
            <div className="h-10 w-10 rounded-full bg-blue-800/10 overflow-hidden border-2 border-white shadow-sm">
              <img 
                alt="Teacher Profile" 
                className="w-full h-full object-cover" 
                src="https://lh3.googleusercontent.com/aida-public/AB6AXuAL28lwa-pxP98hGnL_sSXnY1dABRtnYyBzDugcwNtS8VZe4cRl5eMEg5MiWKCVHKXZMrMKMhaIwfcPcDMUfmh7TJJwEVb-TJKJGc4XcBEOF_crcpZ6Ga0HuCUJxpBkwWSoZWtFuwM5l_fZgNfbzggVP3DsOKg6hd5WISzOFLVLzvr9QS1vcpRYMrRlV_dsXDvb4XTPBxuUkoh0irh68GXut7DbeLQbXvkHyvqZfDE68vtG4nCBpdE5eA6Gfgs8W5yZfW5Wf0ozFw"
              />
            </div>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <main className="max-w-4xl mx-auto px-4 md:px-8 py-8 select-none">
        
        {/* Back navigation header */}
        <div className="flex items-center gap-4 mb-6">
          <button 
            onClick={onExit}
            className="w-10 h-10 border border-slate-200/50 bg-white hover:bg-slate-50 items-center justify-center flex rounded-full shadow-sm outline-none active:scale-95 transition-all"
          >
            <ArrowLeft className="text-blue-800" size={18} />
          </button>
          
          <div>
            <h2 className="font-headline text-2xl font-black text-slate-900">
              {lang === 'en' ? 'Add Questions' : 'Tambah Pertanyaan'}
            </h2>
            <p className="font-sans text-xs text-slate-400 mt-0.5">{exam.title} ({exam.subject})</p>
          </div>
        </div>

        <div className="space-y-6">
          
          {/* Question text Area */}
          <section className="bg-white border border-slate-100 rounded-2xl p-6 shadow-[5px_5px_15px_rgba(203,213,225,0.3)]">
            <label className="block text-xs font-bold text-slate-500 mb-2">{t.questionText}</label>
            <textarea 
              rows={4}
              value={text}
              onChange={(e) => setText(e.target.value)}
              placeholder="Enter your question here..."
              className="w-full text-xs font-semibold py-3 px-4 bg-slate-50/80 border border-slate-200/50 rounded-xl focus:ring-2 focus:ring-blue-800 outline-none transition-all resize-none mb-4 min-h-[120px]"
            />

            <div className="mt-4 flex flex-wrap gap-4 items-center justify-between">
              {/* Optional image input */}
              <div className="flex-1 min-w-[260px] space-y-1">
                <label className="text-xs font-bold text-slate-500">{t.questionImage}</label>
                <div className="flex gap-2">
                  <div className="relative flex-1">
                    <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400">
                      <Image size={18} />
                    </span>
                    <input 
                      type="text"
                      value={imageUrl}
                      onChange={(e) => setImageUrl(e.target.value)}
                      placeholder={lang === 'en' ? "Image URL e.g. https://..." : "Masukkan URL Gambar bantuan..."}
                      className="w-full text-[11px] font-semibold pl-12 pr-4 py-2.5 bg-slate-50 border border-slate-200/50 rounded-xl focus:ring-2 focus:ring-blue-800 outline-none transition-all"
                    />
                  </div>
                  
                  {imageUrl && (
                    <button 
                      type="button"
                      onClick={() => setImageUrl('')}
                      className="p-2.5 bg-red-50 text-red-600 border border-red-100 hover:bg-red-100 rounded-xl transition-colors shrink-0"
                    >
                      <Trash2 size={16} />
                    </button>
                  )}
                </div>
              </div>

              {/* points weigh config */}
              <div className="w-full md:w-32 space-y-1">
                <label className="text-xs font-bold text-slate-500">{t.pointsWeight}</label>
                <input 
                  type="number"
                  min="1"
                  max="100"
                  value={points}
                  onChange={(e) => setPoints(Number(e.target.value))}
                  className="w-full text-xs font-bold py-2.5 bg-slate-50 border border-slate-200/50 rounded-xl text-center focus:ring-2 focus:ring-blue-800 outline-none transition-all"
                />
              </div>
            </div>
            
            {imageUrl && (
              <div className="mt-4 max-w-sm rounded-lg overflow-hidden border border-slate-200/50 relative shadow-sm">
                <span className="absolute top-2 left-2 bg-black/60 text-white font-bold text-[9px] px-2 py-0.5 rounded uppercase">Image Preview</span>
                <img alt="Preview" className="w-full h-32 object-cover" src={imageUrl} />
              </div>
            )}
          </section>

          {/* Option keys config inputs */}
          <section className="bg-white border border-slate-100 rounded-2xl p-6 shadow-[5px_5px_15px_rgba(203,213,225,0.3)]">
            <div className="flex items-center gap-2 mb-4 border-b border-slate-50 pb-3">
              <ListMinus className="text-blue-800" size={18} />
              <div>
                <h3 className="font-headline text-base font-bold text-slate-800">{t.answerChoicesLabel}</h3>
                <p className="text-[10px] text-slate-400 font-semibold mt-0.5">{t.answerChoicesSub}</p>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Option A Field */}
              <div className={`p-4 rounded-xl border transition-all ${
                correctKey === 'A' ? 'bg-blue-50/40 border-blue-800 shadow-[inset_2px_2px_5px_rgba(30,64,175,0.06)]' : 'bg-slate-50/50 border-slate-200/40'
              }`}>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-xs font-bold text-blue-800 uppercase tracking-wider">Option A</span>
                  <input 
                    type="radio" 
                    name="correct" 
                    checked={correctKey === 'A'} 
                    onChange={() => setCorrectKey('A')}
                    className="w-4 h-4 text-blue-800 bg-gray-100 border-slate-300 focus:ring-blue-800 cursor-pointer"
                  />
                </div>
                <input 
                  type="text" 
                  value={optionA} 
                  onChange={(e) => setOptionA(e.target.value)} 
                  placeholder={lang === 'en' ? "Option A phrase" : "Masukkan teks opsi A"}
                  className="w-full bg-white border border-slate-200/60 rounded-lg p-2 text-xs font-medium outline-none focus:border-blue-800" 
                />
              </div>

              {/* Option B Field */}
              <div className={`p-4 rounded-xl border transition-all ${
                correctKey === 'B' ? 'bg-blue-50/40 border-blue-800 shadow-[inset_2px_2px_5px_rgba(30,64,175,0.06)]' : 'bg-slate-50/50 border-slate-200/40'
              }`}>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-xs font-bold text-blue-800 uppercase tracking-wider">Option B</span>
                  <input 
                    type="radio" 
                    name="correct" 
                    checked={correctKey === 'B'} 
                    onChange={() => setCorrectKey('B')}
                    className="w-4 h-4 text-blue-800 bg-gray-100 border-slate-300 focus:ring-blue-800 cursor-pointer"
                  />
                </div>
                <input 
                  type="text" 
                  value={optionB} 
                  onChange={(e) => setOptionB(e.target.value)} 
                  placeholder={lang === 'en' ? "Option B phrase" : "Masukkan teks opsi B"}
                  className="w-full bg-white border border-slate-200/60 rounded-lg p-2 text-xs font-medium outline-none focus:border-blue-800" 
                />
              </div>

              {/* Option C Field */}
              <div className={`p-4 rounded-xl border transition-all ${
                correctKey === 'C' ? 'bg-blue-50/40 border-blue-800 shadow-[inset_2px_2px_5px_rgba(30,64,175,0.06)]' : 'bg-slate-50/50 border-slate-200/40'
              }`}>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-xs font-bold text-blue-800 uppercase tracking-wider">Option C</span>
                  <input 
                    type="radio" 
                    name="correct" 
                    checked={correctKey === 'C'} 
                    onChange={() => setCorrectKey('C')}
                    className="w-4 h-4 text-blue-800 bg-gray-100 border-slate-300 focus:ring-blue-800 cursor-pointer"
                  />
                </div>
                <input 
                  type="text" 
                  value={optionC} 
                  onChange={(e) => setOptionC(e.target.value)} 
                  placeholder={lang === 'en' ? "Option C phrase" : "Masukkan teks opsi C"}
                  className="w-full bg-white border border-slate-200/60 rounded-lg p-2 text-xs font-medium outline-none focus:border-blue-800" 
                />
              </div>

              {/* Option D Field */}
              <div className={`p-4 rounded-xl border transition-all ${
                correctKey === 'D' ? 'bg-blue-50/40 border-blue-800 shadow-[inset_2px_2px_5px_rgba(30,64,175,0.06)]' : 'bg-slate-50/50 border-slate-200/40'
              }`}>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-xs font-bold text-blue-800 uppercase tracking-wider">Option D</span>
                  <input 
                    type="radio" 
                    name="correct" 
                    checked={correctKey === 'D'} 
                    onChange={() => setCorrectKey('D')}
                    className="w-4 h-4 text-blue-800 bg-gray-100 border-slate-300 focus:ring-blue-800 cursor-pointer"
                  />
                </div>
                <input 
                  type="text" 
                  value={optionD} 
                  onChange={(e) => setOptionD(e.target.value)} 
                  placeholder={lang === 'en' ? "Option D phrase" : "Masukkan teks opsi D"}
                  className="w-full bg-white border border-slate-200/60 rounded-lg p-2 text-xs font-medium outline-none focus:border-blue-800" 
                />
              </div>
            </div>
          </section>

          {/* Action buttons save / save & add another */}
          <footer className="flex flex-col md:flex-row gap-4 pt-4 border-t border-slate-200">
            <button 
              type="button" 
              onClick={() => handleSave(false)}
              disabled={loading}
              className="flex-1 py-3 bg-blue-800 text-white font-semibold font-headline text-xs rounded-xl flex items-center justify-center gap-1.5 transition-all hover:bg-blue-700 hover:scale-[0.98] outline-none active:scale-95 shadow-md"
            >
              <Save size={16} />
              <span>{t.saveQuestionBtn}</span>
            </button>

            <button 
              type="button" 
              onClick={() => handleSave(true)}
              disabled={loading}
              className="flex-1 py-3 bg-white border border-blue-800 hover:bg-blue-550/10 text-blue-800 font-semibold font-headline text-xs rounded-xl flex items-center justify-center gap-1.5 transition-all hover:scale-[0.98] outline-none active:scale-95 shadow-sm"
            >
              <Plus size={16} />
              <span>{t.addAnotherQBtn}</span>
            </button>
          </footer>
        </div>
      </main>
    </div>
  );
}
