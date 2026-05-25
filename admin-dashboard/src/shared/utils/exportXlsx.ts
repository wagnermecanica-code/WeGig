import * as XLSX from "xlsx";

export interface XlsxSheet {
  name: string;
  rows: Array<Record<string, unknown>>;
}

/**
 * Exporta uma ou mais planilhas como arquivo .xlsx e dispara o download no browser.
 * @param fileName Nome do arquivo sem extensão.
 * @param sheets Lista de planilhas com seus respectivos nomes/rows.
 */
export function exportSheetsToXlsx(fileName: string, sheets: XlsxSheet[]) {
  if (sheets.length === 0) return;

  const wb = XLSX.utils.book_new();

  for (const sheet of sheets) {
    const safeName = sheet.name.slice(0, 31) || "Planilha";
    const ws = XLSX.utils.json_to_sheet(sheet.rows.length ? sheet.rows : [{}]);
    XLSX.utils.book_append_sheet(wb, ws, safeName);
  }

  XLSX.writeFile(wb, `${fileName}.xlsx`, { compression: true });
}

/** Atalho para exportar uma planilha única. */
export function exportRowsToXlsx(
  fileName: string,
  sheetName: string,
  rows: Array<Record<string, unknown>>,
) {
  exportSheetsToXlsx(fileName, [{ name: sheetName, rows }]);
}
