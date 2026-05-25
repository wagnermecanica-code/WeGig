import React, { useState, useEffect } from "react";
import { doc, getDoc, setDoc } from "firebase/firestore";
import { db } from "../firebase";
import { Plus, Trash2, Save, RefreshCw, Info } from "lucide-react";

// Valores padrão espelhando packages/core_ui/lib/utils/music_constants.dart
const DEFAULT_INSTRUMENTS = [
  "Violão",
  "Guitarra",
  "Baixo elétrico",
  "Contrabaixo acústico",
  "Baixolão",
  "Bateria",
  "Teclado",
  "Piano",
  "Saxofone",
  "Flauta",
  "Trompete",
  "Trombone",
  "Trompa",
  "Clarinete",
  "Oboé",
  "Fagote",
  "Violino",
  "Viola",
  "Violão cósmico",
  "Cello",
  "Voz",
  "Voz (Soprano)",
  "Voz (Contralto)",
  "Voz (Tenor)",
  "Voz (Barítono)",
  "Voz (Baixo)",
  "Voz (Backing)",
  "DJ",
  "Percussão",
  "Bateria Eletrônica",
  "Caixa",
  "Cajón",
  "Bongô",
  "Pandeiro",
  "Zabumba",
  "Timbal",
  "Harmônica",
  "Gaita",
  "Acordeon",
  "Sanfona",
  "Bandolim",
  "Cavaquinho",
  "Ukulele",
  "Banjo",
  "Harpa",
  "Sitar",
  "Alaúde",
  "Guitarra Clássica",
  "Berimbau",
  "Escaleta",
  "Melódica",
  "Theremin",
  "Sintetizador",
  "Teclado MIDI",
  "Sampler",
  "Produtor Musical",
  "Beatmaker",
  "Outros",
];

const DEFAULT_GENRES = [
  "Rock",
  "Pop",
  "Jazz",
  "Blues",
  "Funk",
  "Soul",
  "R&B",
  "Reggae",
  "MPB",
  "Sertanejo",
  "Sertanejo Universitário",
  "Sertanejo Raiz",
  "Forró",
  "Forró Eletrônico",
  "Axé",
  "Hip-Hop",
  "Rap",
  "Trap",
  "Drill",
  "Eletrônica",
  "House",
  "Techno",
  "Trance",
  "Dubstep",
  "Drum and Bass",
  "EDM",
  "Folk",
  "Country",
  "Classical",
  "Ópera",
  "Metal",
  "Heavy Metal",
  "Death Metal",
  "Black Metal",
  "Thrash Metal",
  "Power Metal",
  "Punk",
  "Punk Rock",
  "Hardcore",
  "Post-Punk",
  "Indie",
  "Indie Rock",
  "Alternative",
  "Grunge",
  "Samba",
  "Samba-Enredo",
  "Pagode",
  "Bossa Nova",
  "Gospel",
  "Música Católica",
  "Música Evangélica",
  "Choro",
  "Baião",
  "Maracatu",
  "Frevo",
  "Salsa",
  "Merengue",
  "Bachata",
  "Tango",
  "Flamenco",
  "Brega",
  "Piseiro",
  "Arrocha",
  "Música Sertaneja",
  "Música Gaúcha",
  "Música Caipira",
  "Música meditativa",
  "Rock Progressivo",
  "Psicodélico",
  "Disco",
  "New Wave",
  "Synth-pop",
  "Ska",
  "Reggaeton",
  "K-Pop",
  "J-Pop",
  "World Music",
  "Afrobeat",
  "Zouk",
  "Ambient",
  "Experimental",
  "Avant-garde",
  "Minimalista",
  "Lo-fi",
  "Vaporwave",
  "Outros",
];

function ListEditor({ title, items, onAdd, onRemove }) {
  const [newItem, setNewItem] = useState("");

  const handleAdd = () => {
    const trimmed = newItem.trim();
    if (!trimmed) return;
    if (items.includes(trimmed)) {
      alert(`"${trimmed}" já está na lista.`);
      return;
    }
    onAdd(trimmed);
    setNewItem("");
  };

  return (
    <div className="flex-1 min-w-0">
      <h3 className="text-sm font-semibold text-gray-700 mb-3 uppercase tracking-wide">
        {title}{" "}
        <span className="text-gray-400 font-normal normal-case">
          ({items.length})
        </span>
      </h3>

      {/* Add new */}
      <div className="flex gap-2 mb-4">
        <input
          type="text"
          placeholder={`Novo ${title.toLowerCase().slice(0, -1)}…`}
          value={newItem}
          onChange={(e) => setNewItem(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleAdd()}
          className="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
        />
        <button
          onClick={handleAdd}
          className="inline-flex items-center gap-1 px-3 py-2 text-sm font-medium rounded-md text-white bg-primary hover:opacity-90"
        >
          <Plus className="w-4 h-4" />
          Adicionar
        </button>
      </div>

      {/* Items */}
      <div className="border border-gray-200 rounded-md overflow-hidden max-h-96 overflow-y-auto">
        {items.map((item, idx) => (
          <div
            key={idx}
            className="flex items-center justify-between px-3 py-2 hover:bg-gray-50 border-b border-gray-100 last:border-b-0"
          >
            <span className="text-sm text-gray-800">{item}</span>
            <button
              onClick={() => onRemove(item)}
              className="text-gray-400 hover:text-red-500 transition-colors ml-2 flex-shrink-0"
              title="Remover"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}

export default function CatalogTab() {
  const [instruments, setInstruments] = useState([]);
  const [genres, setGenres] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [fromFirestore, setFromFirestore] = useState(false);

  const loadCatalog = async () => {
    setLoading(true);
    try {
      const snap = await getDoc(doc(db, "appConfig", "musicOptions"));
      if (snap.exists()) {
        const data = snap.data();
        setInstruments(data.instruments ?? DEFAULT_INSTRUMENTS);
        setGenres(data.genres ?? DEFAULT_GENRES);
        setFromFirestore(true);
      } else {
        // Ainda não salvo no Firestore — carrega os valores padrão do app
        setInstruments([...DEFAULT_INSTRUMENTS]);
        setGenres([...DEFAULT_GENRES]);
        setFromFirestore(false);
      }
    } catch (e) {
      console.error("CatalogTab:", e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCatalog();
  }, []);

  const saveChanges = async () => {
    setSaving(true);
    try {
      await setDoc(doc(db, "appConfig", "musicOptions"), {
        instruments,
        genres,
        updatedAt: new Date(),
      });
      setSaved(true);
      setFromFirestore(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (e) {
      alert("Erro ao salvar: " + e.message);
    } finally {
      setSaving(false);
    }
  };

  const resetToDefaults = () => {
    if (
      !confirm(
        "Restaurar as listas para os valores padrão do app? As alterações não salvas serão perdidas.",
      )
    )
      return;
    setInstruments([...DEFAULT_INSTRUMENTS]);
    setGenres([...DEFAULT_GENRES]);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
      </div>
    );
  }

  return (
    <>
      {/* Info banner */}
      {!fromFirestore && (
        <div className="mb-6 flex items-start gap-3 bg-yellow-50 border border-yellow-200 rounded-md p-4 text-sm text-yellow-800">
          <Info className="w-4 h-4 flex-shrink-0 mt-0.5" />
          <p>
            O catálogo ainda não foi salvo no Firestore. As listas abaixo
            refletem os valores padrão do app. Clique em{" "}
            <strong>Salvar alterações</strong> para publicar no Firestore e
            habilitar atualizações dinâmicas.
          </p>
        </div>
      )}

      {/* Action bar */}
      <div className="flex items-center justify-between mb-6">
        <p className="text-sm text-gray-600">
          {fromFirestore
            ? "Catálogo carregado do Firestore (appConfig/musicOptions)."
            : "Usando valores padrão do app."}
        </p>
        <div className="flex gap-2">
          <button
            onClick={resetToDefaults}
            className="inline-flex items-center gap-1 px-3 py-2 text-sm font-medium rounded-md text-gray-700 border border-gray-300 bg-white hover:bg-gray-50"
          >
            <RefreshCw className="w-4 h-4" />
            Restaurar padrões
          </button>
          <button
            onClick={saveChanges}
            disabled={saving}
            className={`inline-flex items-center gap-1 px-4 py-2 text-sm font-medium rounded-md text-white disabled:opacity-50 ${
              saved ? "bg-green-600" : "bg-primary hover:opacity-90"
            }`}
          >
            <Save className="w-4 h-4" />
            {saving ? "Salvando…" : saved ? "Salvo!" : "Salvar alterações"}
          </button>
        </div>
      </div>

      {/* Two-column editors */}
      <div className="flex gap-6 items-start">
        <ListEditor
          title="Instrumentos"
          items={instruments}
          onAdd={(item) =>
            setInstruments((prev) => [
              ...prev.slice(0, -1),
              item,
              prev[prev.length - 1],
            ])
          }
          onRemove={(item) =>
            setInstruments((prev) => prev.filter((i) => i !== item))
          }
        />
        <ListEditor
          title="Gêneros"
          items={genres}
          onAdd={(item) =>
            setGenres((prev) => [
              ...prev.slice(0, -1),
              item,
              prev[prev.length - 1],
            ])
          }
          onRemove={(item) =>
            setGenres((prev) => prev.filter((i) => i !== item))
          }
        />
      </div>
    </>
  );
}
