import { Navigate, Outlet, Route, Routes } from 'react-router-dom'
import { AdminLayout } from './components/AdminLayout'
import { useAuth } from './auth/AuthContext'
import { AddStockPage } from './pages/AddStockPage'
import { AlertsPage } from './pages/AlertsPage'
import { DashboardPage } from './pages/DashboardPage'
import { ItemFormPage } from './pages/ItemFormPage'
import { ItemsPage } from './pages/ItemsPage'
import { LoginPage } from './pages/LoginPage'
import { ReportsHubPage } from './pages/ReportsHubPage'
import { StockHistoryPage } from './pages/StockHistoryPage'
import { StockInPage } from './pages/StockInPage'
import { StockMovementReportPage } from './pages/StockMovementReportPage'
import { StockSummaryReportPage } from './pages/StockSummaryReportPage'
import { UsersPage } from './pages/UsersPage'

function ProtectedRoute() {
  const { user, loading } = useAuth()
  if (loading) return <div className="loading">Loading…</div>
  if (!user) return <Navigate to="/login" replace />
  return <Outlet />
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<AdminLayout />}>
          <Route index element={<DashboardPage />} />
          <Route path="items" element={<ItemsPage />} />
          <Route path="items/new" element={<ItemFormPage />} />
          <Route path="items/:code/edit" element={<ItemFormPage />} />
          <Route path="stock-in" element={<StockInPage />} />
          <Route path="stock-in/new" element={<AddStockPage />} />
          <Route path="stock-history" element={<StockHistoryPage />} />
          <Route path="alerts" element={<AlertsPage />} />
          <Route path="reports" element={<ReportsHubPage />} />
          <Route path="reports/stock-summary" element={<StockSummaryReportPage />} />
          <Route path="reports/stock-movement" element={<StockMovementReportPage />} />
          <Route path="users" element={<UsersPage />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
