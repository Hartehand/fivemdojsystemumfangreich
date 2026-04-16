const tabs = [
  'Dashboard', 'Fälle', 'Strafsachen', 'Gerichtsfälle', 'Anhörungen / Hearings', 'Haftbefehle / Warrants',
  'Personen', 'Fahrzeuge', 'Beweise', 'Notizen', 'Dokumente', 'Timeline / Aktivitätsverlauf', 'Suche', 'Einstellungen / Berechtigungen'
]

const state = { open: false, tab: 'Dashboard', bootstrap: null, cases: null, search: null, selectedCaseId: null }

const app = document.getElementById('app')
const tabsEl = document.getElementById('tabs')
const contentEl = document.getElementById('content')
const badgeEl = document.getElementById('badgeRow')
const pageTitleEl = document.getElementById('pageTitle')

const cb = (name, payload = {}) => fetch(`https://${GetParentResourceName()}/${name}`, {
  method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload)
}).then((r) => r.json())

const html = (strings, ...vals) => strings.reduce((acc, s, i) => `${acc}${s}${vals[i] ?? ''}`, '')

function renderTabs() {
  tabsEl.innerHTML = ''
  tabs.forEach((tab) => {
    const b = document.createElement('button')
    b.textContent = tab
    b.className = state.tab === tab ? 'active' : ''
    b.onclick = () => { state.tab = tab; renderTabs(); render() }
    tabsEl.appendChild(b)
  })
}

function fillFilterSelect(id, values) {
  const select = document.getElementById(id)
  const firstOption = select.options[0] ? select.options[0].outerHTML : ''
  select.innerHTML = firstOption
  values.forEach((v) => {
    const o = document.createElement('option')
    o.value = v
    o.textContent = v
    select.appendChild(o)
  })
}

function renderDashboard() {
  const d = state.bootstrap?.dashboard || {}
  badgeEl.innerHTML = [
    `Offene Fälle: ${d.open_cases || 0}`,
    `Hearings heute: ${d.hearings_today || 0}`,
    `Neue Beweise: ${d.new_evidence || 0}`,
    `Versiegelt: ${d.sealed_cases || 0}`,
    `Überfällige Aufgaben: ${d.overdue_tasks || 0}`
  ].map((x) => `<div class="badge">${x}</div>`).join('')

  const rows = (d.latest_activity || []).map((a) => `<tr><td>${a.created_at}</td><td>${a.action}</td><td>${a.entity_type}#${a.entity_id}</td><td>${a.actor_name}</td></tr>`).join('')
  contentEl.innerHTML = `<div class="card"><h3>Letzte Aktivitäten</h3><table class="table"><thead><tr><th>Zeit</th><th>Aktion</th><th>Entity</th><th>Actor</th></tr></thead><tbody>${rows || '<tr><td colspan="4">Keine Daten</td></tr>'}</tbody></table></div>`
}

async function loadCases() {
  const payload = {
    status: document.getElementById('filterStatus').value,
    case_type: document.getElementById('filterType').value,
    priority: document.getElementById('filterPriority').value,
    page: 1,
    pageSize: 25
  }
  state.cases = await cb('getCases', payload)
}

function renderCaseList() {
  badgeEl.innerHTML = ''
  const list = state.cases?.data?.items || []
  const rows = list.map((c) => `<tr data-case-id="${c.id}" class="case-row"><td>${c.case_number}</td><td>${c.title}</td><td>${c.case_type}</td><td>${c.status}</td><td>${c.priority}</td><td>${c.is_sealed === 1 ? 'SEALED' : '-'}</td></tr>`).join('')

  const templateOptions = (state.bootstrap?.templates || []).map((t) => `<option value="${t.template_key}">${t.display_name}</option>`).join('')

  contentEl.innerHTML = html`
    <div class="grid two">
      <div class="card">
        <h3>Neuer Fall</h3>
        <div class="row"><input id="caseTitle" placeholder="Titel" /></div>
        <div class="row"><select id="caseTemplate"><option value="">Template (optional)</option>${templateOptions}</select></div>
        <div class="row"><select id="caseType"></select><select id="casePriority"></select></div>
        <div class="row"><textarea id="caseDescription" placeholder="Beschreibung"></textarea></div>
        <div class="actions"><button id="createCaseBtn">Fall erstellen</button></div>
      </div>
      <div class="card">
        <h3>Fallaktionen</h3>
        <div class="small">Ausgewählter Fall: <span id="selectedCaseInfo">-</span></div>
        <div class="actions"><button id="sealCaseBtn">Seal</button><button id="unsealCaseBtn">Unseal</button></div>
        <div class="actions"><button id="exportCaseBtn">Export (Full)</button><button id="exportCaseRedactedBtn">Export (Redacted)</button></div>
      </div>
    </div>
    <div class="card">
      <h3>Fälle</h3>
      <table class="table"><thead><tr><th>Fallnr</th><th>Titel</th><th>Typ</th><th>Status</th><th>Priorität</th><th>Seal</th></tr></thead><tbody>${rows || '<tr><td colspan="6">Keine Fälle</td></tr>'}</tbody></table>
    </div>
  `

  const typeSel = document.getElementById('caseType')
  ;(state.bootstrap?.defaults?.caseTypes || []).forEach((x) => { const o = document.createElement('option'); o.value = x; o.textContent = x; typeSel.appendChild(o) })
  const prioSel = document.getElementById('casePriority')
  ;(state.bootstrap?.defaults?.casePriority || []).forEach((x) => { const o = document.createElement('option'); o.value = x; o.textContent = x; prioSel.appendChild(o) })

  document.querySelectorAll('.case-row').forEach((row) => {
    row.onclick = () => {
      state.selectedCaseId = Number(row.dataset.caseId)
      document.getElementById('selectedCaseInfo').textContent = `#${state.selectedCaseId}`
    }
  })

  document.getElementById('createCaseBtn').onclick = async () => {
    const response = await cb('createCase', {
      title: document.getElementById('caseTitle').value,
      case_type: typeSel.value,
      priority: prioSel.value,
      description: document.getElementById('caseDescription').value,
      template_key: document.getElementById('caseTemplate').value || null
    })
    if (response.ok) { await loadCases(); renderCaseList() }
  }

  document.getElementById('sealCaseBtn').onclick = async () => {
    if (!state.selectedCaseId) return
    await cb('sealCase', { case_id: state.selectedCaseId, reason: 'Vom Benutzer versiegelt' })
    await loadCases(); renderCaseList()
  }

  document.getElementById('unsealCaseBtn').onclick = async () => {
    if (!state.selectedCaseId) return
    await cb('unsealCase', { case_id: state.selectedCaseId, reason: 'Vom Benutzer entsiegelt', status_after_unseal: 'under_review' })
    await loadCases(); renderCaseList()
  }

  const runExport = async (profile) => {
    if (!state.selectedCaseId) return
    const response = await cb('exportCase', { case_id: state.selectedCaseId, profile, format: 'print' })
    if (response.ok) {
      const pre = document.createElement('pre')
      pre.textContent = JSON.stringify(response.data.payload, null, 2)
      const w = window.open('', '_blank')
      w.document.write(`<html><head><title>Case Export</title><link rel="stylesheet" href="print.css"></head><body><h1>DOJ Export ${response.data.profile}</h1>${pre.outerHTML}</body></html>`)
      w.document.close()
    }
  }

  document.getElementById('exportCaseBtn').onclick = () => runExport('full')
  document.getElementById('exportCaseRedactedBtn').onclick = () => runExport('redacted')
}

async function renderHearings() {
  const response = await cb('getCalendar', { mode: 'week' })
  const rows = (response.data || []).map((h) => `<tr><td>${h.start_at}</td><td>${h.end_at}</td><td>${h.hearing_type}</td><td>${h.judge_name || '-'}</td><td>${h.courtroom_label || '-'}</td><td>${h.case_number}</td></tr>`).join('')
  contentEl.innerHTML = `<div class="card"><h3>Court Calendar</h3><table class="table"><thead><tr><th>Start</th><th>Ende</th><th>Typ</th><th>Richter</th><th>Saal</th><th>Fall</th></tr></thead><tbody>${rows || '<tr><td colspan="6">Keine Termine</td></tr>'}</tbody></table></div>`
}

function renderSearch() {
  const r = state.search?.data || {}
  contentEl.innerHTML = `<div class="grid two"><div class="card"><h3>Fälle</h3><p>${(r.cases || []).length} Treffer</p></div><div class="card"><h3>Personen</h3><p>${(r.people || []).length} Treffer</p></div><div class="card"><h3>Fahrzeuge</h3><p>${(r.vehicles || []).length} Treffer</p></div><div class="card"><h3>Waffen</h3><p>${(r.weapons || []).length} Treffer</p></div><div class="card"><h3>Beweise</h3><p>${(r.evidence || []).length} Treffer</p></div></div>`
}

async function render() {
  pageTitleEl.textContent = state.tab
  if (state.tab === 'Dashboard') return renderDashboard()
  if (state.tab === 'Fälle' || state.tab === 'Strafsachen' || state.tab === 'Gerichtsfälle') {
    await loadCases(); return renderCaseList()
  }
  if (state.tab === 'Anhörungen / Hearings') return renderHearings()
  if (state.tab === 'Suche') return renderSearch()
  badgeEl.innerHTML = ''
  contentEl.innerHTML = `<div class="card"><h3>${state.tab}</h3><p class="small">Modul aktiv.</p></div>`
}

window.addEventListener('message', (event) => {
  if (event.data.action === 'open') {
    state.open = true
    state.bootstrap = event.data.payload
    document.getElementById('actorInfo').textContent = `${state.bootstrap?.actor?.name || '-'} (${state.bootstrap?.role || '-'})`
    fillFilterSelect('filterStatus', state.bootstrap?.defaults?.caseStatus || [])
    fillFilterSelect('filterType', state.bootstrap?.defaults?.caseTypes || [])
    fillFilterSelect('filterPriority', state.bootstrap?.defaults?.casePriority || [])
    app.classList.remove('hidden')
    renderTabs(); render()
  }
  if (event.data.action === 'close') {
    state.open = false
    state.bootstrap = null
    app.classList.add('hidden')
  }
})

document.getElementById('closeBtn').onclick = () => cb('close')
document.getElementById('refreshBtn').onclick = async () => {
  const response = await cb('bootstrap')
  if (response?.ok) {
    state.bootstrap = response.data
    document.getElementById('actorInfo').textContent = `${state.bootstrap?.actor?.name || '-'} (${state.bootstrap?.role || '-'})`
    fillFilterSelect('filterStatus', state.bootstrap?.defaults?.caseStatus || [])
    fillFilterSelect('filterType', state.bootstrap?.defaults?.caseTypes || [])
    fillFilterSelect('filterPriority', state.bootstrap?.defaults?.casePriority || [])
    await render()
  }
}

document.getElementById('globalSearch').addEventListener('keydown', async (e) => {
  if (e.key !== 'Enter') return
  state.search = await cb('search', { query: e.target.value })
  state.tab = 'Suche'
  renderTabs(); render()
})

document.getElementById('filterStatus').onchange = () => render()
document.getElementById('filterType').onchange = () => render()
document.getElementById('filterPriority').onchange = () => render()
