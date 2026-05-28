/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useEffect, useState } from 'react';
import { School } from 'lucide-react';
import { AppLang, TRANSLATIONS } from '../types';

interface SplashViewProps {
  onFinished: () => void;
  lang: AppLang;
}

export default function SplashView({ onFinished, lang }: SplashViewProps) {
  const [progress, setProgress] = useState(0);
  const [statusText, setStatusText] = useState('Menyiapkan Sesi...');
  const t = TRANSLATIONS[lang];

  useEffect(() => {
    const states = [
      { p: 15, text: lang === 'id' ? "Menyiapkan Sesi..." : lang === 'tt' ? "Prepara hela Sesaun..." : "Preparing Session..." },
      { p: 45, text: lang === 'id' ? "Memvalidasi Keamanan..." : lang === 'tt' ? "Valida hela Seguransa..." : "Validating Security..." },
      { p: 75, text: lang === 'id' ? "Sinkronisasi Data..." : lang === 'tt' ? "Sincroniza hela Dadus..." : "Synchronizing Data..." },
      { p: 95, text: lang === 'id' ? "Hampir Selesai..." : lang === 'tt' ? "Besik atu Remata..." : "Almost Done..." },
      { p: 100, text: lang === 'id' ? "Siap Mulai" : lang === 'tt' ? "Prontu ona" : "Ready" },
    ];

    let currentStep = 0;
    
    const interval = setInterval(() => {
      if (currentStep < states.length) {
        setProgress(states[currentStep].p);
        setStatusText(states[currentStep].text);
        currentStep++;
      } else {
        clearInterval(interval);
        setTimeout(() => {
          onFinished();
        }, 650);
      }
    }, 700);

    return () => clearInterval(interval);
  }, [onFinished, lang]);

  return (
    <main className="fixed inset-0 flex flex-col items-center justify-between py-20 px-6 h-screen w-screen z-[100] bg-gradient-to-br from-blue-800 to-blue-500 overflow-hidden text-white select-none">
      {/* Decorative blurred backdrops */}
      <div className="absolute top-[-10%] left-[-10%] w-64 h-64 rounded-full bg-white/10 blur-3xl pointer-events-none" />
      <div className="absolute bottom-[-5%] right-[-5%] w-80 h-80 rounded-full bg-slate-900/20 blur-3xl pointer-events-none" />
      
      <div className="h-10" />

      {/* Central Branding */}
      <div className="flex flex-col items-center text-center z-10 transition-all duration-700 select-none">
        {/* Animated logo box */}
        <div className="mb-6 p-6 rounded-3xl bg-white/10 backdrop-blur-md shadow-[4px_4px_15px_rgba(0,0,0,0.15)] animate-bounce duration-1000">
          <School size={80} className="text-white" />
        </div>

        {/* Brand name */}
        <h1 className="font-headline text-4xl md:text-5xl font-bold tracking-tight mb-2 drop-shadow-sm">
          Testora
        </h1>

        {/* Taglines */}
        <div className="space-y-2 max-w-xs md:max-w-md">
          <p className="font-sans text-base font-medium text-white/90">
            {t.tagline}
          </p>
          <p className="font-sans text-xs text-white/70 italic">
            {t.taglineSub}
          </p>
        </div>
      </div>

      {/* Bottom Progress status loading bar */}
      <div className="w-full max-w-[280px] md:max-w-sm flex flex-col items-center gap-4 z-10">
        <div className="w-full h-1.5 bg-white/20 rounded-full overflow-hidden relative">
          <div 
            className="absolute top-0 left-0 h-full bg-white rounded-full transition-all duration-300 ease-out" 
            style={{ width: `${progress}%` }} 
          />
        </div>
        <p className="font-sans text-[11px] font-semibold text-white/65 tracking-widest uppercase text-center min-h-[20px]">
          {statusText}
        </p>
      </div>
    </main>
  );
}
