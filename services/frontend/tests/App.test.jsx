import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { cleanup, render, screen } from '@testing-library/react';
import App from '../src/App.jsx';
const products = [{id:1,name:'Keyboard',price:'199.00'}];
const orders = [{id:1,item:'Keyboard',quantity:2,unit_price:'199.00',status:'pending'}];
beforeEach(()=>{global.fetch=vi.fn(async (url,opts)=>{
 if(opts?.method==='POST') return {ok:true,json:async()=>({id:2})};
 if(String(url).includes('/api/products')) return {ok:true,json:async()=>products};
 if(String(url).includes('/api/orders')) return {ok:true,json:async()=>orders};
 return {ok:true,json:async()=>({status:'ok'})};
});});
afterEach(()=>{cleanup();vi.restoreAllMocks()});
describe('Store app',()=>{
 it('renders products and orders',async()=>{render(<App/>); expect(await screen.findByText('Keyboard')).toBeTruthy(); expect(await screen.findByText(/Order #1/)).toBeTruthy();});
 it('renders both creation forms',async()=>{render(<App/>); expect(await screen.findByRole('button',{name:'Add product'})).toBeTruthy(); expect(await screen.findByRole('button',{name:'Create order'})).toBeTruthy();});
});
