import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  ShoppingBasket, 
  HandCoins, 
  X, 
  Info, 
  LayoutDashboard, 
  TrendingUp, 
  PackageSearch,
  ChevronRight,
  ShieldCheck,
  Zap
} from 'lucide-react';
import { fetchNui } from '../utils/fetchNui';

interface PawnShopProps {
  data: {
    shopIndex: number;
    inventory: any[];
    playerInventory: any[];
    shopData: any;
  };
  onClose: () => void;
}

type Tab = 'overview' | 'sell' | 'buy';

export const PawnShop: React.FC<PawnShopProps> = ({ data, onClose }) => {
  const [activeTab, setActiveTab] = useState<Tab>('overview');
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [quantity, setQuantity] = useState(1);

  const handleAction = async () => {
    if (!selectedItem) return;
    
    const event = activeTab === 'sell' ? 'sellItem' : 'buyItem';
    const success = await fetchNui(event, {
      shopIndex: data.shopIndex,
      itemName: selectedItem.name,
      amount: quantity,
      basePrice: selectedItem.basePrice
    });

    if (success) {
      setSelectedItem(null);
      setQuantity(1);
    }
  };

  const getHotDeals = () => {
    return Object.keys(data?.shopData || {}).filter(name => data.shopData[name].isHot);
  };

  return (
    <motion.div 
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      className="relative w-[1100px] h-[750px] bg-[#09090b] border border-zinc-800 rounded-3xl shadow-[0_0_50px_-12px_rgba(0,0,0,0.5)] flex overflow-hidden text-zinc-100"
    >
      {/* Dashboard Sidebar */}
      <div className="w-72 bg-zinc-950/50 border-r border-zinc-800 flex flex-col">
        <div className="p-8">
          <div className="flex items-center gap-3 mb-8">
            <div className="w-12 h-12 bg-white rounded-2xl flex items-center justify-center">
              <PackageSearch className="text-black w-6 h-6" />
            </div>
            <div>
              <h1 className="font-black text-xl tracking-tighter leading-none">PAWN</h1>
              <p className="text-[10px] text-zinc-500 font-bold uppercase tracking-widest mt-1">Dashboard v1.0</p>
            </div>
          </div>

          <div className="space-y-1">
            <SidebarItem 
              icon={<LayoutDashboard size={18} />} 
              label="Overview" 
              active={activeTab === 'overview'} 
              onClick={() => { setActiveTab('overview'); setSelectedItem(null); }} 
            />
            <SidebarItem 
              icon={<HandCoins size={18} />} 
              label="Sell Items" 
              active={activeTab === 'sell'} 
              onClick={() => { setActiveTab('sell'); setSelectedItem(null); }} 
            />
            <SidebarItem 
              icon={<ShoppingBasket size={18} />} 
              label="Buy Market" 
              active={activeTab === 'buy'} 
              onClick={() => { setActiveTab('buy'); setSelectedItem(null); }} 
            />
          </div>
        </div>

        <div className="mt-auto p-8">
            <div className="p-5 bg-zinc-900/50 border border-zinc-800 rounded-2xl space-y-3">
                <div className="flex items-center gap-2 text-emerald-500">
                    <ShieldCheck size={16} />
                    <span className="text-[10px] font-black uppercase tracking-wider">Secured Session</span>
                </div>
                <p className="text-[11px] text-zinc-500 leading-relaxed font-medium">
                    All transactions are recorded and verified by the city council.
                </p>
            </div>
        </div>
      </div>

      {/* Main Dashboard View */}
      <div className="flex-1 flex flex-col bg-zinc-950/20">
        <header className="h-24 border-b border-zinc-800/50 flex items-center justify-between px-10">
          <div>
            <h2 className="text-2xl font-bold tracking-tight capitalize">{activeTab === 'buy' ? 'Marketplace' : activeTab}</h2>
            <div className="flex items-center gap-2 mt-1">
                <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                <span className="text-xs text-zinc-500 font-semibold uppercase tracking-wide">Pawn Shop Location #{data?.shopIndex || 1}</span>
            </div>
          </div>
          <button 
            onClick={onClose} 
            className="w-10 h-10 flex items-center justify-center bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-xl transition-all text-zinc-400 hover:text-white"
          >
            <X size={20} />
          </button>
        </header>

        <main className="flex-1 overflow-y-auto p-10 custom-scrollbar">
          <AnimatePresence mode="wait">
            {activeTab === 'overview' && (
              <motion.div 
                key="overview"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="space-y-8"
              >
                {/* Stats Grid */}
                <div className="grid grid-cols-3 gap-6">
                    <StatCard 
                        label="Store Liquidity" 
                        value="Excellent" 
                        icon={<TrendingUp className="text-emerald-500" size={20} />} 
                    />
                    <StatCard 
                        label="Items in Stock" 
                        value={Object.keys(data?.shopData || {}).reduce((acc, name) => acc + data.shopData[name].stock, 0)} 
                        icon={<ShoppingBasket className="text-blue-500" size={20} />} 
                    />
                    <StatCard 
                        label="Active Deals" 
                        value={getHotDeals().length} 
                        icon={<Zap className="text-orange-500" size={20} />} 
                    />
                </div>

                {/* Hot Deals Section */}
                <section>
                    <h3 className="text-sm font-black uppercase tracking-widest text-zinc-500 mb-4 flex items-center gap-2">
                        <Zap size={14} className="text-orange-500" />
                        Today's Hot Deals
                    </h3>
                    <div className="grid grid-cols-2 gap-4">
                        {getHotDeals().length > 0 ? getHotDeals().map(name => (
                            <div key={name} className="p-4 bg-orange-500/5 border border-orange-500/10 rounded-2xl flex items-center gap-4">
                                <div className="w-14 h-14 bg-zinc-900 rounded-xl p-2">
                                    <img src={`nui://ox_inventory/web/images/${name}.png`} className="w-full h-full object-contain" alt="" />
                                </div>
                                <div>
                                    <h4 className="font-bold text-sm">Best Buy: {name}</h4>
                                    <p className="text-xs text-orange-500 font-black">+50% Price Bonus Active</p>
                                </div>
                            </div>
                        )) : (
                            <div className="col-span-2 p-6 border border-dashed border-zinc-800 rounded-2xl text-center text-zinc-500 text-sm">
                                No hot deals currently active at this location.
                            </div>
                        )}
                    </div>
                </section>

                <div className="p-8 bg-zinc-900/30 border border-zinc-800/50 rounded-3xl flex items-center justify-between">
                    <div className="max-w-md">
                        <h3 className="font-bold text-lg">Looking to sell?</h3>
                        <p className="text-sm text-zinc-500 mt-1 leading-relaxed">
                            Our shop offers the best rates in the city for electronics and jewelry. Switch to the Sell tab to view your eligible items.
                        </p>
                    </div>
                    <button 
                        onClick={() => setActiveTab('sell')}
                        className="bg-zinc-100 text-black px-6 py-3 rounded-xl font-bold text-sm hover:bg-white transition-all flex items-center gap-2 group"
                    >
                        Go to Selling
                        <ChevronRight size={16} className="group-hover:translate-x-0.5 transition-transform" />
                    </button>
                </div>
              </motion.div>
            )}

            {(activeTab === 'sell' || activeTab === 'buy') && (
              <motion.div 
                key="grid"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="grid grid-cols-3 gap-5"
              >
                {activeTab === 'sell' ? (
                  data?.playerInventory?.map((item: any) => (
                    <ItemCard 
                      key={item.name} 
                      item={item} 
                      shopData={data.shopData[item.name]}
                      onClick={() => setSelectedItem(item)}
                      isSelected={selectedItem?.name === item.name}
                      type="sell"
                    />
                  ))
                ) : (
                  Object.keys(data?.shopData || {}).map((itemName) => {
                    const stockData = data.shopData[itemName];
                    if (stockData.stock <= 0) return null;
                    return (
                      <ItemCard 
                        key={itemName} 
                        item={{ name: itemName, label: itemName }}
                        shopData={stockData}
                        onClick={() => setSelectedItem({ name: itemName, ...stockData })}
                        isSelected={selectedItem?.name === itemName}
                        type="buy"
                      />
                    )
                  })
                )}
              </motion.div>
            )}
          </AnimatePresence>
        </main>
      </div>

      {/* Action Drawer */}
      <AnimatePresence>
        {selectedItem && (
            <motion.div 
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 200 }}
            className="absolute right-0 top-0 bottom-0 w-[400px] bg-zinc-950 border-l border-zinc-800 shadow-2xl p-10 flex flex-col z-50"
            >
            <button 
                onClick={() => setSelectedItem(null)}
                className="absolute top-8 right-8 text-zinc-500 hover:text-white"
            >
                <X size={24} />
            </button>

            <div className="flex-1 flex flex-col justify-center text-center">
                <motion.div 
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    className="w-48 h-48 bg-zinc-900 rounded-[40px] mx-auto mb-8 flex items-center justify-center shadow-inner relative overflow-hidden"
                >
                    <div className="absolute inset-0 bg-gradient-to-b from-white/5 to-transparent pointer-events-none" />
                    <img src={`nui://ox_inventory/web/images/${selectedItem.name}.png`} className="w-32 h-32 object-contain relative z-10" alt="" />
                </motion.div>
                
                <h3 className="text-3xl font-black tracking-tighter">{selectedItem.label}</h3>
                <p className="text-zinc-500 font-medium text-sm mt-2 uppercase tracking-[0.2em]">Transaction Value</p>
                <p className="text-4xl font-black text-white mt-2 tabular-nums">
                    ${activeTab === 'sell' ? data.shopData[selectedItem.name]?.buyPrice : selectedItem.sellPrice}
                </p>
            </div>

            <div className="space-y-8 mt-auto">
                <div className="space-y-4">
                <div className="flex justify-between items-end">
                    <label className="text-[10px] uppercase font-black text-zinc-500 tracking-widest">Select Amount</label>
                    <span className="text-xs text-zinc-400 font-bold">Max: {activeTab === 'sell' ? selectedItem.count : selectedItem.stock}</span>
                </div>
                <div className="flex items-center gap-3">
                    <button 
                    onClick={() => setQuantity(Math.max(1, quantity - 1))}
                    className="w-14 h-14 bg-zinc-900 border border-zinc-800 rounded-2xl hover:bg-zinc-800 transition-colors flex items-center justify-center font-bold text-xl"
                    >-</button>
                    <input 
                    type="number" 
                    value={quantity}
                    onChange={(e) => setQuantity(parseInt(e.target.value) || 1)}
                    className="flex-1 bg-zinc-900 border border-zinc-800 rounded-2xl h-14 text-center font-black text-xl focus:ring-2 focus:ring-white/10 outline-none transition-all tabular-nums"
                    />
                    <button 
                    onClick={() => setQuantity(Math.min(activeTab === 'sell' ? selectedItem.count : selectedItem.stock, quantity + 1))}
                    className="w-14 h-14 bg-zinc-900 border border-zinc-800 rounded-2xl hover:bg-zinc-800 transition-colors flex items-center justify-center font-bold text-xl"
                    >+</button>
                </div>
                </div>

                <div className="pt-4 border-t border-zinc-800/50">
                    <div className="flex justify-between items-center mb-6">
                        <span className="text-zinc-500 font-bold text-sm uppercase">Total Est.</span>
                        <span className="text-2xl font-black text-emerald-500">
                            ${(activeTab === 'sell' ? data.shopData[selectedItem.name]?.buyPrice : selectedItem.sellPrice) * quantity}
                        </span>
                    </div>
                    <button 
                    onClick={handleAction}
                    className="w-full bg-white text-black font-black py-5 rounded-2xl hover:scale-[1.02] active:scale-95 transition-all shadow-[0_20px_40px_-10px_rgba(255,255,255,0.1)] uppercase tracking-wider"
                    >
                    Authorize {activeTab}
                    </button>
                </div>
            </div>
            </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  );
};

const SidebarItem = ({ icon, label, active, onClick }: any) => (
  <button 
    onClick={onClick}
    className={`w-full flex items-center gap-4 px-5 py-4 rounded-2xl transition-all duration-300 group ${active ? 'bg-white text-black shadow-lg shadow-white/5' : 'text-zinc-500 hover:text-zinc-300 hover:bg-zinc-900'}`}
  >
    <span className={`${active ? 'text-black' : 'text-zinc-500 group-hover:text-zinc-300'}`}>{icon}</span>
    <span className="font-bold text-sm tracking-tight">{label}</span>
    {active && (
        <motion.div layoutId="active-indicator" className="ml-auto w-1.5 h-1.5 rounded-full bg-black" />
    )}
  </button>
);

const StatCard = ({ label, value, icon }: any) => (
    <div className="bg-zinc-900/40 border border-zinc-800/50 p-6 rounded-3xl space-y-4">
        <div className="flex items-center justify-between">
            <span className="text-[10px] font-black uppercase tracking-[0.2em] text-zinc-500">{label}</span>
            {icon}
        </div>
        <p className="text-3xl font-black tabular-nums">{value}</p>
    </div>
);

const ItemCard = ({ item, shopData, onClick, isSelected, type }: any) => {
  return (
    <motion.div 
      whileHover={{ y: -4 }}
      onClick={onClick}
      className={`group relative p-5 rounded-3xl border transition-all cursor-pointer overflow-hidden ${isSelected ? 'bg-zinc-900 border-zinc-500 shadow-2xl' : 'bg-zinc-900/40 border-zinc-800/50 hover:bg-zinc-900/60 hover:border-zinc-700'}`}
    >
      <div className="flex flex-col gap-5">
        <div className="w-full aspect-square bg-zinc-950/50 rounded-2xl flex items-center justify-center p-6 border border-zinc-800/50 relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-tr from-white/[0.02] to-transparent pointer-events-none" />
          <img src={`nui://ox_inventory/web/images/${item.name}.png`} className="w-full h-full object-contain relative z-10" alt="" />
        </div>
        <div className="space-y-1">
          <h4 className="font-bold text-sm truncate pr-8">{item.label}</h4>
          <div className="flex justify-between items-center">
             <p className="text-zinc-500 font-bold text-[10px] uppercase tracking-wider">{type === 'sell' ? `Available: ${item.count}` : `Stock: ${shopData?.stock}`}</p>
             <p className="text-emerald-500 font-black text-sm tabular-nums">${type === 'sell' ? shopData?.buyPrice : shopData?.sellPrice}</p>
          </div>
        </div>
      </div>
      {shopData?.isHot && (
        <div className="absolute top-4 right-4 w-8 h-8 bg-orange-500/10 border border-orange-500/20 rounded-full flex items-center justify-center text-orange-500 shadow-lg shadow-orange-500/5 animate-pulse">
          <Zap size={14} fill="currentColor" />
        </div>
      )}
    </motion.div>
  );
};
