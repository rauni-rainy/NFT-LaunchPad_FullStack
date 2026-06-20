import LotusMandala from '@/components/LotusMandala';

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24 relative overflow-hidden">
      <div className="z-10 w-full max-w-5xl items-center justify-between font-mono text-sm flex flex-col gap-8">
        <h1 className="display text-4xl text-center">Mandala Test Page</h1>

        {/* Render the Mandala */}
        <div className="flex justify-center items-center w-full h-[600px] relative">
          <LotusMandala />
        </div>

      </div>
    </main>
  );
}
