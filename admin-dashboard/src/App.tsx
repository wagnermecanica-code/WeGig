import { AuthProvider } from "@core/auth/AuthProvider";
import { ThemeProvider } from "@core/theme/ThemeProvider";
import { AppRouter } from "./app/router";

export function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <AppRouter />
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
