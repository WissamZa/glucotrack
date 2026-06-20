"use client";

import { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { MoreVertical, Pencil, Trash2 } from "lucide-react";
import { useAppStore } from "@/lib/store";
import { useDeleteReading } from "@/lib/api-hooks";
import { themes } from "@/lib/themes";
import { t } from "@/lib/i18n";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { useToast } from "@/hooks/use-toast";
import type { Reading } from "@/lib/types";

interface ReadingActionsProps {
  reading: Reading;
  onEdit: (reading: Reading) => void;
}

export function ReadingActions({ reading, onEdit }: ReadingActionsProps) {
  const settings = useAppStore((s) => s.settings)!;
  const theme = themes[settings.theme];
  const lang = settings.language;
  const deleteReading = useDeleteReading();
  const { toast } = useToast();
  const [menuOpen, setMenuOpen] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const btnRef = useRef<HTMLButtonElement>(null);

  // Close menu on outside click
  useEffect(() => {
    if (!menuOpen) return;
    const handler = (e: MouseEvent) => {
      if (btnRef.current && !btnRef.current.contains(e.target as Node)) {
        setMenuOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [menuOpen]);

  const handleDelete = () => {
    setMenuOpen(false);
    setConfirmOpen(true);
  };

  const confirmDelete = () => {
    deleteReading.mutate(reading.id, {
      onSuccess: () => toast({ title: t(lang, "deleted_success") }),
    });
    setConfirmOpen(false);
  };

  const handleEdit = () => {
    setMenuOpen(false);
    onEdit(reading);
  };

  return (
    <>
      <div className="relative flex-shrink-0">
        <button
          ref={btnRef}
          onClick={() => setMenuOpen((v) => !v)}
          className={`h-8 w-8 rounded-lg ${theme.surfaceAlt} flex items-center justify-center ${theme.textMuted} hover:${theme.text}`}
          aria-label="More actions"
        >
          <MoreVertical className="h-4 w-4" />
        </button>

        <AnimatePresence>
          {menuOpen && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9, y: -5 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.9, y: -5 }}
              transition={{ duration: 0.12 }}
              className={`absolute end-0 mt-1 ${theme.surface} border-2 ${theme.border} rounded-xl shadow-xl z-50 min-w-32 overflow-hidden`}
            >
              <button
                onClick={handleEdit}
                className={`w-full px-3 py-2.5 text-start text-sm font-medium flex items-center gap-2 ${theme.text} hover:bg-teal-50 dark:hover:bg-teal-900/20`}
              >
                <Pencil className="h-4 w-4 text-teal-600" />
                {t(lang, "edit")}
              </button>
              <button
                onClick={handleDelete}
                className="w-full px-3 py-2.5 text-start text-sm font-medium flex items-center gap-2 text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20"
              >
                <Trash2 className="h-4 w-4" />
                {t(lang, "delete")}
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <AlertDialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t(lang, "delete_reading")}</AlertDialogTitle>
            <AlertDialogDescription>
              {t(lang, "delete_confirm")}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{t(lang, "cancel")}</AlertDialogCancel>
            <AlertDialogAction
              onClick={confirmDelete}
              className="bg-red-600 hover:bg-red-700 text-white"
            >
              {t(lang, "ok")}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
