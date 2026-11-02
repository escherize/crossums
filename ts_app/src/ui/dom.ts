type Child = Node | string | number | null | undefined | false

/** Tiny element builder: el('div.card.big', { onclick }, 'text', childEl). */
export function el<K extends keyof HTMLElementTagNameMap>(
  spec: `${K}` | `${K}.${string}`,
  attrs: Record<string, unknown> = {},
  ...children: Child[]
): HTMLElementTagNameMap[K] {
  const [tag, ...classes] = spec.split('.')
  const node = document.createElement(tag as K)
  if (classes.length) node.className = classes.join(' ')
  for (const [k, v] of Object.entries(attrs)) {
    if (v === undefined || v === null || v === false) continue
    if (k.startsWith('on') && typeof v === 'function') node.addEventListener(k.slice(2), v as EventListener)
    else if (k === 'style' && typeof v === 'object') Object.assign(node.style, v)
    else if (k in node && k !== 'class') (node as unknown as Record<string, unknown>)[k] = v
    else node.setAttribute(k, String(v))
  }
  append(node, children)
  return node
}

export function append(parent: Node, children: Child[]): void {
  for (const c of children) {
    if (c === null || c === undefined || c === false) continue
    parent.appendChild(typeof c === 'object' ? c : document.createTextNode(String(c)))
  }
}

export function clear(node: Node): void {
  while (node.firstChild) node.removeChild(node.firstChild)
}

export function money(n: number): string {
  return n < 0 ? `-$${-n}` : `$${n}`
}

export function clock(seconds: number): string {
  const s = Math.max(0, Math.floor(seconds))
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`
}
