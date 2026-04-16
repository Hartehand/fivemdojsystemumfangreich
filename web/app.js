const tabs = [
  'Dashboard', 'Fälle', 'Gerichtsprozesse', 'Anhörungen / Hearings', 'Beweise', 'Dokumente', 'Suche', 'Einstellungen / Berechtigungen'
]

const state = {
  open: false,
  tab: 'Dashboard',
  bootstrap: null,
  cases: [],
  selectedCase: null,
  caseDetails: null,
  hearings: [],
  documents: [],
  search: null
}

const app = document.getElementById('app')
const tabsEl = document.getElementById('tabs')
const contentEl = document.getElementById('content')
const badgeEl = document.getElementById('badgeRow')
const pageTitleEl = document.getElementById('pageTitle')

const cb = (name, payload = {}) => fetch(`https://${GetParentResourceName()}/${name}`, {
  method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload)
}).then((r) => r.json())

const h = (s, ...v) => s.reduce((a, b, i) => `${a}${b}${v[i] ?? ''}`, '')

function renderTabs() {
  tabsEl.innerHTML = ''
  for (const tab of tabs) {
    const b = document.createElement('button')
    b.textContent = tab
    b.className = state.tab === tab ? 'active' : ''
    b.onclick = () => { state.tab = tab; renderTabs(); render() }
    tabsEl.appendChild(b)
  }
}

function fillFilterSelect(id, values) {
  const select = document.getElementById(id)
  const firstOption = select.options[0] ? select.options[0].outerHTML : ''
  select.innerHTML = firstOption
  for (const value of values) {
    const o = document.createElement('option')
    o.value = value
    o.textContent = value
    select.appendChild(o)
  }
}

async function refreshBootstrap() {
  const response = await cb('bootstrap')
  if (response?.ok) {
    state.bootstrap = response.data
    document.getElementById('actorInfo').textContent = `${state.bootstrap?.actor?.name || '-'} (${state.bootstrap?.role || '-'})`
    fillFilterSelect('filterStatus', state.bootstrap?.defaults?.caseStatus || [])
    fillFilterSelect('filterType', state.bootstrap?.defaults?.caseTypes || [])
    fillFilterSelect('filterPriority', state.bootstrap?.defaults?.casePriority || [])
  }
}

function dashboardView() {
  const d = state.bootstrap?.dashboard || {}
  badgeEl.innerHTML = [
    `Offene Fälle: ${d.open_cases || 0}`,
    `Hearings heute: ${d.hearings_today || 0}`,
    `Neue Beweise: ${d.new_evidence || 0}`,
    `Versiegelte: ${d.sealed_cases || 0}`,
    `Überfällige Aufgaben: ${d.overdue_tasks || 0}`
  ].map((x) => `<div class="badge">${x}</div>`).join('')

  const activityRows = (d.latest_activity || []).map((a) => `<tr><td>${a.created_at}</td><td>${a.action}</td><td>${a.entity_type}#${a.entity_id}</td><td>${a.actor_name}</td></tr>`).join('')
  contentEl.innerHTML = h`
    <div class="grid two">
      <div class="card"><h3>Profil</h3><div class="small">${state.bootstrap?.actor?.identifier || '-'}</div></div>
      <div class="card"><h3>Systemstatus</h3><div class="small">DOJ CaseHub online</div></div>
    </div>
    <div class="card">
      <h3>Aktivitätsverlauf</h3>
      <div class="table-wrap"><table class="table"><thead><tr><th>Zeit</th><th>Aktion</th><th>Entity</th><th>Akteur</th></tr></thead><tbody>${activityRows || '<tr><td colspan="4">Keine Einträge</td></tr>'}</tbody></table></div>
    </div>
  `
}

async function loadCases() {
  const response = await cb('getCases', {
    status: document.getElementById('filterStatus').value,
    case_type: document.getElementById('filterType').value,
    priority: document.getElementById('filterPriority').value,
    page: 1, pageSize: 50
  })
  state.cases = response?.data?.items || []
}

async function openCaseDetails(caseId) {
  const res = await cb('getCaseDetails', { case_id: caseId })
  if (res.ok) {
    state.caseDetails = res.data
    state.selectedCase = res.data.case
  }
}

function casesView() {
  badgeEl.innerHTML = ''
  const caseRows = state.cases.map((c) => `<tr data-case="${c.id}"><td>${c.case_number}</td><td>${c.title}</td><td>${c.status}</td><td>${c.priority}</td><td>${c.is_sealed ? 'SEALED' : '-'}</td></tr>`).join('')
  const templateOptions = (state.bootstrap?.templates || []).map((t) => `<option value="${t.template_key}">${t.display_name}</option>`).join('')

  const detail = state.caseDetails
  const tasksRows = (detail?.tasks || []).map((t) => `<tr><td>${t.title}</td><td>${t.status}</td><td>${t.due_at || '-'}</td><td><button data-task="${t.id}" data-status="done">Done</button></td></tr>`).join('')
  const hearingRows = (detail?.hearings || []).map((h) => `<tr><td>${h.hearing_type}</td><td>${h.start_at}</td><td>${h.status}</td></tr>`).join('')
  const docRows = (detail?.documents || []).map((d) => `<tr><td>${d.title}</td><td>${d.document_type}</td><td>${d.status}</td></tr>`).join('')
  const timelineRows = (detail?.timeline || []).map((e) => `<div class="timeline-item"><b>${e.event_label}</b><div class="small">${e.created_at} · ${e.actor_name}</div></div>`).join('')

  contentEl.innerHTML = h`
    <div class="grid two">
      <div class="card">
        <h3>Neuen Fall erstellen</h3>
        <div class="row"><input id="newCaseTitle" placeholder="Titel" /></div>
        <div class="row"><select id="newCaseTemplate"><option value="">Template (optional)</option>${templateOptions}</select></div>
        <div class="row"><select id="newCaseType"></select><select id="newCasePriority"></select></div>
        <div class="row"><textarea id="newCaseDescription" placeholder="Beschreibung"></textarea></div>
        <div class="actions"><button class="primary" id="createCaseBtn">Fall anlegen</button></div>
      </div>
      <div class="card">
        <h3>Fallbearbeitung</h3>
        <div class="small">Ausgewählt: ${state.selectedCase ? `${state.selectedCase.case_number} - ${state.selectedCase.title}` : 'Kein Fall ausgewählt'}</div>
        <div class="actions">
          <button id="saveCaseBtn" ${state.selectedCase ? '' : 'disabled'}>Änderungen speichern</button>
          <button id="sealCaseBtn" ${state.selectedCase ? '' : 'disabled'}>Versiegeln</button>
          <button id="unsealCaseBtn" ${state.selectedCase ? '' : 'disabled'}>Entsiegeln</button>
          <button id="exportCaseBtn" ${state.selectedCase ? '' : 'disabled'}>Export Full</button>
        </div>
      </div>
    </div>

    <div class="detail-layout">
      <div class="card">
        <h3>Fallliste</h3>
        <div class="table-wrap"><table class="table"><thead><tr><th>Fallnr</th><th>Titel</th><th>Status</th><th>Priorität</th><th>Seal</th></tr></thead><tbody>${caseRows || '<tr><td colspan="5">Keine Fälle</td></tr>'}</tbody></table></div>
      </div>
      <div class="card">
        <h3>Fall-Details</h3>
        ${state.selectedCase ? h`<div class="row"><input id="editCaseTitle" value="${state.selectedCase.title || ''}" /></div><div class="row"><select id="editCaseStatus"></select><select id="editCasePriority"></select></div>` : '<div class="small">Bitte Fall auswählen.</div>'}
      </div>
    </div>

    <div class="grid three">
      <div class="card"><h3>Aufgaben</h3><div class="table-wrap"><table class="table"><thead><tr><th>Titel</th><th>Status</th><th>Frist</th><th>Action</th></tr></thead><tbody>${tasksRows || '<tr><td colspan="4">Keine Aufgaben</td></tr>'}</tbody></table></div></div>
      <div class="card"><h3>Hearings</h3><div class="table-wrap"><table class="table"><thead><tr><th>Typ</th><th>Start</th><th>Status</th></tr></thead><tbody>${hearingRows || '<tr><td colspan="3">Keine Hearings</td></tr>'}</tbody></table></div></div>
      <div class="card"><h3>Dokumente</h3><div class="table-wrap"><table class="table"><thead><tr><th>Titel</th><th>Typ</th><th>Status</th></tr></thead><tbody>${docRows || '<tr><td colspan="3">Keine Dokumente</td></tr>'}</tbody></table></div></div>
    </div>

    <div class="card"><h3>Timeline</h3><div class="timeline">${timelineRows || '<div class="small">Keine Timeline-Einträge</div>'}</div></div>
  `

  const typeSel = document.getElementById('newCaseType')
  const prioSel = document.getElementById('newCasePriority')
  ;(state.bootstrap?.defaults?.caseTypes || []).forEach((v) => { const o = document.createElement('option'); o.value = v; o.textContent = v; typeSel.appendChild(o) })
  ;(state.bootstrap?.defaults?.casePriority || []).forEach((v) => { const o = document.createElement('option'); o.value = v; o.textContent = v; prioSel.appendChild(o) })

  document.querySelectorAll('tr[data-case]').forEach((row) => {
    row.onclick = async () => {
      await openCaseDetails(Number(row.dataset.case))
      casesView()
    }
  })

  document.querySelectorAll('button[data-task]').forEach((btn) => {
    btn.onclick = async () => {
      await cb('updateTaskStatus', { task_id: Number(btn.dataset.task), status: btn.dataset.status })
      if (state.selectedCase) await openCaseDetails(state.selectedCase.id)
      casesView()
    }
  })

  document.getElementById('createCaseBtn').onclick = async () => {
    const response = await cb('createCase', {
      title: document.getElementById('newCaseTitle').value,
      case_type: document.getElementById('newCaseType').value,
      priority: document.getElementById('newCasePriority').value,
      description: document.getElementById('newCaseDescription').value,
      template_key: document.getElementById('newCaseTemplate').value || null
    })
    if (response.ok) {
      await loadCases()
      casesView()
    }
  }

  if (state.selectedCase) {
    const statusSel = document.getElementById('editCaseStatus')
    const prioEdit = document.getElementById('editCasePriority')
    ;(state.bootstrap?.defaults?.caseStatus || []).forEach((v) => { const o = document.createElement('option'); o.value = v; o.textContent = v; if (v === state.selectedCase.status) o.selected = true; statusSel.appendChild(o) })
    ;(state.bootstrap?.defaults?.casePriority || []).forEach((v) => { const o = document.createElement('option'); o.value = v; o.textContent = v; if (v === state.selectedCase.priority) o.selected = true; prioEdit.appendChild(o) })

    document.getElementById('saveCaseBtn').onclick = async () => {
      const response = await cb('updateCase', {
        case_id: state.selectedCase.id,
        title: document.getElementById('editCaseTitle').value,
        status: statusSel.value,
        priority: prioEdit.value
      })
      if (response.ok) {
        await loadCases(); await openCaseDetails(state.selectedCase.id); casesView()
      }
    }

    document.getElementById('sealCaseBtn').onclick = async () => {
      await cb('sealCase', { case_id: state.selectedCase.id, reason: 'Manual seal via panel' })
      await loadCases(); await openCaseDetails(state.selectedCase.id); casesView()
    }

    document.getElementById('unsealCaseBtn').onclick = async () => {
      await cb('unsealCase', { case_id: state.selectedCase.id, reason: 'Manual unseal via panel', status_after_unseal: 'under_review' })
      await loadCases(); await openCaseDetails(state.selectedCase.id); casesView()
    }

    document.getElementById('exportCaseBtn').onclick = async () => {
      const response = await cb('exportCase', { case_id: state.selectedCase.id, profile: 'full', format: 'print' })
      if (response.ok) {
        const w = window.open('', '_blank')
        w.document.write(`<html><head><title>Case Export</title><link rel="stylesheet" href="print.css"></head><body><h1>${state.selectedCase.case_number}</h1><pre>${JSON.stringify(response.data.payload, null, 2)}</pre></body></html>`)
        w.document.close()
      }
    }
  }
}

async function hearingsView() {
  badgeEl.innerHTML = ''
  const response = await cb('listHearings', {})
  state.hearings = response?.data || []
  const rows = state.hearings.map((h) => `<tr data-hearing="${h.id}"><td>${h.case_id}</td><td>${h.hearing_type}</td><td>${h.start_at}</td><td>${h.end_at}</td><td>${h.status}</td></tr>`).join('')

  contentEl.innerHTML = h`
    <div class="grid two">
      <div class="card">
        <h3>Hearing erstellen</h3>
        <div class="row"><input id="hCaseId" placeholder="Case ID" /><select id="hType"></select></div>
        <div class="row"><input id="hStart" placeholder="YYYY-MM-DD HH:MM:SS" /><input id="hEnd" placeholder="YYYY-MM-DD HH:MM:SS" /></div>
        <div class="row"><input id="hJudge" placeholder="Judge Identifier" /><input id="hProsecutor" placeholder="Prosecutor Identifier" /></div>
        <div class="row"><input id="hDefense" placeholder="Defense Identifier" /><input id="hCourtroom" placeholder="Courtroom ID" /></div>
        <div class="actions"><button class="primary" id="createHearingBtn">Erstellen</button></div>
      </div>
      <div class="card">
        <h3>Hearing bearbeiten</h3>
        <div class="small">Hearing auswählen und Status ändern.</div>
        <div class="row"><input id="editHearingId" placeholder="Hearing ID" /><select id="editHearingStatus"></select></div>
        <div class="row"><input id="editHearingStart" placeholder="Neuer Start (optional)" /><input id="editHearingEnd" placeholder="Neues Ende (optional)" /></div>
        <div class="actions"><button id="updateHearingBtn">Speichern</button></div>
      </div>
    </div>
    <div class="card"><h3>Hearings</h3><div class="table-wrap"><table class="table"><thead><tr><th>Case</th><th>Typ</th><th>Start</th><th>Ende</th><th>Status</th></tr></thead><tbody>${rows || '<tr><td colspan="5">Keine Hearings</td></tr>'}</tbody></table></div></div>
  `

  ;(state.bootstrap?.defaults?.hearingTypes || []).forEach((v) => { const o = document.createElement('option'); o.value = v; o.textContent = v; document.getElementById('hType').appendChild(o) })
  ;(state.bootstrap?.defaults?.hearingStatus || []).forEach((v) => { const o = document.createElement('option'); o.value = v; o.textContent = v; document.getElementById('editHearingStatus').appendChild(o) })

  document.querySelectorAll('tr[data-hearing]').forEach((row) => {
    row.onclick = () => {
      document.getElementById('editHearingId').value = row.dataset.hearing
    }
  })

  document.getElementById('createHearingBtn').onclick = async () => {
    await cb('createHearing', {
      case_id: Number(document.getElementById('hCaseId').value),
      hearing_type: document.getElementById('hType').value,
      start_at: document.getElementById('hStart').value,
      end_at: document.getElementById('hEnd').value,
      judge_identifier: document.getElementById('hJudge').value,
      prosecutor_identifier: document.getElementById('hProsecutor').value,
      defense_identifier: document.getElementById('hDefense').value,
      courtroom_id: Number(document.getElementById('hCourtroom').value) || null
    })
    await hearingsView()
  }

  document.getElementById('updateHearingBtn').onclick = async () => {
    await cb('updateHearing', {
      hearing_id: Number(document.getElementById('editHearingId').value),
      status: document.getElementById('editHearingStatus').value,
      start_at: document.getElementById('editHearingStart').value || null,
      end_at: document.getElementById('editHearingEnd').value || null
    })
    await hearingsView()
  }
}

async function documentsView() {
  badgeEl.innerHTML = ''
  const response = await cb('listDocuments', { case_id: state.selectedCase?.id })
  state.documents = response?.data || []
  const rows = state.documents.map((d) => `<tr data-doc="${d.id}" data-ver="${d.current_version_id || ''}"><td>${d.title}</td><td>${d.document_type}</td><td>${d.status}</td><td>${d.current_version_id || '-'}</td></tr>`).join('')

  contentEl.innerHTML = h`
    <div class="grid two">
      <div class="card">
        <h3>Dokument erstellen</h3>
        <div class="row"><input id="docTitle" placeholder="Titel" /><select id="docType"></select></div>
        <div class="row"><textarea id="docContent" placeholder="Inhalt"></textarea></div>
        <div class="actions"><button class="primary" id="createDocBtn">Erstellen</button></div>
      </div>
      <div class="card">
        <h3>Signatur / Finalisierung</h3>
        <div class="row"><input id="sigVersionId" placeholder="Document Version ID" /><input id="sigNote" placeholder="Signaturhinweis" /></div>
        <div class="actions"><button id="signDocBtn">Signieren</button><button id="verifySigBtn">Signatur prüfen</button></div>
        <div class="row"><input id="finalizeDocId" placeholder="Document ID" /><button id="finalizeBtn">Finalisieren</button></div>
      </div>
    </div>
    <div class="card"><h3>Dokumentliste</h3><div class="table-wrap"><table class="table"><thead><tr><th>Titel</th><th>Typ</th><th>Status</th><th>Version</th></tr></thead><tbody>${rows || '<tr><td colspan="4">Keine Dokumente</td></tr>'}</tbody></table></div></div>
  `

  ;(state.bootstrap?.defaults?.documentTypes || []).forEach((v) => { const o = document.createElement('option'); o.value = v; o.textContent = v; document.getElementById('docType').appendChild(o) })

  document.querySelectorAll('tr[data-doc]').forEach((row) => {
    row.onclick = () => {
      document.getElementById('finalizeDocId').value = row.dataset.doc
      document.getElementById('sigVersionId').value = row.dataset.ver
    }
  })

  document.getElementById('createDocBtn').onclick = async () => {
    await cb('createDocument', {
      title: document.getElementById('docTitle').value,
      document_type: document.getElementById('docType').value,
      content: document.getElementById('docContent').value,
      case_id: state.selectedCase?.id || null
    })
    await documentsView()
  }

  document.getElementById('signDocBtn').onclick = async () => {
    await cb('signDocument', {
      document_version_id: Number(document.getElementById('sigVersionId').value),
      note: document.getElementById('sigNote').value,
      finalize_if_fully_signed: false
    })
  }

  document.getElementById('verifySigBtn').onclick = async () => {
    const sigId = prompt('Signature ID eingeben:')
    if (!sigId) return
    const resp = await cb('verifySignature', { signature_id: Number(sigId) })
    alert(resp.ok ? `Valid: ${resp.valid}` : `Fehler: ${resp.error}`)
  }

  document.getElementById('finalizeBtn').onclick = async () => {
    await cb('finalizeDocument', { document_id: Number(document.getElementById('finalizeDocId').value), require_full_signatures: false })
    await documentsView()
  }
}

async function evidenceView() {
  badgeEl.innerHTML = ''
  contentEl.innerHTML = h`
    <div class="grid two">
      <div class="card">
        <h3>Beweis erstellen</h3>
        <div class="row"><input id="evCaseId" placeholder="Case ID" /><select id="evType"></select></div>
        <div class="row"><input id="evTitle" placeholder="Titel" /><input id="evStatus" placeholder="Status (checked_in)" /></div>
        <div class="row"><input id="evFound" placeholder="Fundort" /><input id="evStore" placeholder="Lagerort" /></div>
        <div class="row"><textarea id="evDesc" placeholder="Beschreibung"></textarea></div>
        <div class="actions"><button class="primary" id="createEvidenceBtn">Anlegen</button></div>
      </div>
      <div class="card">
        <h3>Custody Transfer</h3>
        <div class="row"><input id="custEvidenceId" placeholder="Evidence ID" /><input id="custAction" placeholder="Action (transferred)" /></div>
        <div class="row"><input id="custFrom" placeholder="From Identifier" /><input id="custTo" placeholder="To Identifier" /></div>
        <div class="row"><input id="custFromLoc" placeholder="From Location" /><input id="custToLoc" placeholder="To Location" /></div>
        <div class="row"><input id="custNote" placeholder="Notiz" /></div>
        <div class="actions"><button id="transferEvidenceBtn">Transfer</button><button id="verifyChainBtn">Chain prüfen</button></div>
      </div>
    </div>
  `

  ;(state.bootstrap?.defaults?.evidenceTypes || []).forEach((v) => { const o = document.createElement('option'); o.value = v; o.textContent = v; document.getElementById('evType').appendChild(o) })

  document.getElementById('createEvidenceBtn').onclick = async () => {
    await cb('createEvidence', {
      case_id: Number(document.getElementById('evCaseId').value),
      evidence_type: document.getElementById('evType').value,
      title: document.getElementById('evTitle').value,
      status: document.getElementById('evStatus').value || 'checked_in',
      location_found: document.getElementById('evFound').value,
      storage_location: document.getElementById('evStore').value,
      description: document.getElementById('evDesc').value
    })
  }

  document.getElementById('transferEvidenceBtn').onclick = async () => {
    await cb('transferEvidence', {
      evidence_id: Number(document.getElementById('custEvidenceId').value),
      action_type: document.getElementById('custAction').value || 'transferred',
      from_person_identifier: document.getElementById('custFrom').value,
      to_person_identifier: document.getElementById('custTo').value,
      from_location: document.getElementById('custFromLoc').value,
      to_location: document.getElementById('custToLoc').value,
      reason_note: document.getElementById('custNote').value
    })
  }

  document.getElementById('verifyChainBtn').onclick = async () => {
    const resp = await cb('verifyEvidenceChain', { evidence_id: Number(document.getElementById('custEvidenceId').value) })
    alert(resp.ok ? `Valid: ${resp.data.valid}` : `Fehler: ${resp.error}`)
  }
}

async function searchView() {
  badgeEl.innerHTML = ''
  const q = document.getElementById('globalSearch').value
  state.search = await cb('search', { query: q })
  const r = state.search?.data || {}
  contentEl.innerHTML = h`
    <div class="grid three">
      <div class="card"><h3>Fälle</h3><div class="small">${(r.cases || []).length} Treffer</div></div>
      <div class="card"><h3>Personen</h3><div class="small">${(r.people || []).length} Treffer</div></div>
      <div class="card"><h3>Fahrzeuge</h3><div class="small">${(r.vehicles || []).length} Treffer</div></div>
      <div class="card"><h3>Waffen</h3><div class="small">${(r.weapons || []).length} Treffer</div></div>
      <div class="card"><h3>Beweise</h3><div class="small">${(r.evidence || []).length} Treffer</div></div>
    </div>
  `
}

async function render() {
  pageTitleEl.textContent = state.tab
  if (state.tab === 'Dashboard') return dashboardView()
  if (state.tab === 'Fälle' || state.tab === 'Gerichtsprozesse') { await loadCases(); return casesView() }
  if (state.tab === 'Anhörungen / Hearings') return hearingsView()
  if (state.tab === 'Dokumente') return documentsView()
  if (state.tab === 'Beweise') return evidenceView()
  if (state.tab === 'Suche') return searchView()

  badgeEl.innerHTML = ''
  contentEl.innerHTML = `<div class="card"><h3>${state.tab}</h3><p class="small">Modul in Arbeit, Kernschnittstellen sind vorhanden.</p></div>`
}

window.addEventListener('message', async (event) => {
  if (event.data.action === 'open') {
    state.open = true
    state.bootstrap = event.data.payload
    state.tab = 'Dashboard'
    document.getElementById('actorInfo').textContent = `${state.bootstrap?.actor?.name || '-'} (${state.bootstrap?.role || '-'})`
    fillFilterSelect('filterStatus', state.bootstrap?.defaults?.caseStatus || [])
    fillFilterSelect('filterType', state.bootstrap?.defaults?.caseTypes || [])
    fillFilterSelect('filterPriority', state.bootstrap?.defaults?.casePriority || [])
    app.classList.remove('hidden')
    renderTabs()
    await render()
  }

  if (event.data.action === 'close') {
    state.open = false
    state.bootstrap = null
    state.selectedCase = null
    state.caseDetails = null
    app.classList.add('hidden')
  }
})

document.getElementById('closeBtn').onclick = () => cb('close')
document.getElementById('refreshBtn').onclick = async () => { await refreshBootstrap(); await render() }
document.getElementById('globalSearch').addEventListener('keydown', async (e) => {
  if (e.key !== 'Enter') return
  state.tab = 'Suche'
  renderTabs()
  await render()
})
document.getElementById('filterStatus').onchange = () => render()
document.getElementById('filterType').onchange = () => render()
document.getElementById('filterPriority').onchange = () => render()
