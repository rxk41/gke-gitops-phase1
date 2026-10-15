import { useCallback, useEffect, useState } from "react";
const money = (v) => new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 2 }).format(Number(v));
export default function App() {
  const [products,setProducts]=useState([]), [orders,setOrders]=useState([]);
  const [name,setName]=useState(""), [price,setPrice]=useState(""), [item,setItem]=useState(""), [quantity,setQuantity]=useState("1"), [unitPrice,setUnitPrice]=useState("");
  const [error,setError]=useState(""), [message,setMessage]=useState(""), [busy,setBusy]=useState(false);
  const refresh=useCallback(async()=>{
    try { const [p,o]=await Promise.all([fetch('/api/products'),fetch('/api/orders')]); if(!p.ok||!o.ok) throw new Error('API request failed'); setProducts(await p.json()); setOrders(await o.json()); }
    catch { setError('Could not reach the APIs. Check service and database health.'); }
  },[]);
  useEffect(()=>{refresh()},[refresh]);
  async function submit(path, body) { setBusy(true); setError(''); setMessage(''); try { const r=await fetch(path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)}); const data=await r.json(); if(!r.ok) throw new Error(data.detail||`HTTP ${r.status}`); setMessage('Saved successfully.'); await refresh(); return true; } catch(e){setError(e.message||'Request failed');return false;} finally{setBusy(false)} }
  return <main className="page">
    <header className="topbar"><div className="brand-mark">S</div><div><p className="eyebrow">DEMO STORE · PHASE 1</p><h1>Products & Orders</h1></div><span className="status"><span/> APIs online</span></header>
    <section className="intro"><p className="eyebrow">SIMPLE MICROSERVICES</p><h2>One frontend. Two APIs. Persistent data.</h2><p className="subtext">React · FastAPI Product API · FastAPI Order API · PostgreSQL · GKE</p></section>
    <section className="content-grid">
      <div className="panel"><div className="section-heading"><div><p className="eyebrow">INVENTORY</p><h3>Products</h3></div><span className="count">{products.length} items</span></div>
        {products.length===0?<p className="empty">No products yet.</p>:<div className="product-list">{products.map(p=><article className="product-row" key={p.id}><div className="product-icon">{p.name.slice(0,1).toUpperCase()}</div><div className="product-info"><strong>{p.name}</strong><span>Product #{p.id}</span></div><strong className="price">{money(p.price)}</strong></article>)}</div>}
        <form onSubmit={async e=>{e.preventDefault();if(await submit('/api/products',{name:name.trim(),price:Number(price)})){setName('');setPrice('')}}}><h3>Add product</h3><label htmlFor="pname">Product name</label><input id="pname" value={name} onChange={e=>setName(e.target.value)} required maxLength={120}/><label htmlFor="pprice">Price (INR)</label><input id="pprice" type="number" min="0" step="0.01" value={price} onChange={e=>setPrice(e.target.value)} required/><button disabled={busy}>Add product</button></form>
      </div>
      <div className="panel"><div className="section-heading"><div><p className="eyebrow">FULFILMENT</p><h3>Orders</h3></div><span className="count">{orders.length} orders</span></div>
        {orders.length===0?<p className="empty">No orders yet.</p>:<div className="product-list">{orders.map(o=><article className="product-row" key={o.id}><div className="product-icon">#{o.id}</div><div className="product-info"><strong>{o.item} × {o.quantity}</strong><span>Order #{o.id} · {o.status}</span></div><strong className="price">{money(Number(o.unit_price)*o.quantity)}</strong></article>)}</div>}
        <form onSubmit={async e=>{e.preventDefault();if(await submit('/api/orders',{item:item.trim(),quantity:Number(quantity),unit_price:Number(unitPrice)})){setItem('');setQuantity('1');setUnitPrice('')}}}><h3>Create order</h3><label htmlFor="item">Item</label><input id="item" value={item} onChange={e=>setItem(e.target.value)} required maxLength={120}/><label htmlFor="quantity">Quantity</label><input id="quantity" type="number" min="1" max="10000" value={quantity} onChange={e=>setQuantity(e.target.value)} required/><label htmlFor="unitPrice">Unit price (INR)</label><input id="unitPrice" type="number" min="0" step="0.01" value={unitPrice} onChange={e=>setUnitPrice(e.target.value)} required/><button disabled={busy}>Create order</button></form>
      </div>
    </section>{message&&<p className="notice success">{message}</p>}{error&&<p className="notice error" role="alert">{error}</p>}<footer>PHASE 1 · NO ISTIO · NO CLOUD SQL</footer>
  </main>
}
