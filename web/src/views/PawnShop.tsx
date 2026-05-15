import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { ShoppingBasket, HandCoins, X, Info } from 'lucide-react';
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

export const PawnShop: React.FC<PawnShopProps> = ({ data, onClose }) => {
  const [activeTab, setActiveTab] = useState<'sell' | 'buy'>('sell');
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

  return (
    <motion.div 
      initial={{ opacity: 0, scale: 0.9, y: 20 }}
      animate={{ opacity: 1, scale: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.9, y: 20 }}
      className="relative w-[1000px] h-[700px] bg-zinc-950/95 border border-zinc-800 rounded-2xl shadow-2xl flex overflow-hidden backdrop-blur-xl"
    >
      {/* Sidebar */}
      <div className="w-64 border-r border-zinc-800 flex flex-col p-6 gap-8">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-emerald-500/10 rounded-xl flex items-center justify-center border border-emerald-500/20">
            <HandCoins className="text-emerald-500 w-6 h-6" />
          </div>
          <div>
            <h1 className="font-bold text-lg tracking-tight">PAWN SHOP</h1>
            <p className="text-[10px] text-zinc-500 uppercase tracking-widest">Store #{data?.shopIndex || 1}</p>
          </div>
        </div>

        <nav className="flex flex-col gap-2">
          <button 
            onClick={() => setActiveTab('sell')}
            className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${activeTab === 'sell' ? 'bg-zinc-900 text-white shadow-inner border border-zinc-800' : 'text-zinc-500 hover:text-zinc-300 hover:bg-zinc-900/50'}`}
          >
            <HandCoins size={20} />
            <span className="font-medium">Sell Items</span>
          </button>
          <button 
            onClick={() => setActiveTab('buy')}
            className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${activeTab === 'buy' ? 'bg-zinc-900 text-white shadow-inner border border-zinc-800' : 'text-zinc-500 hover:text-zinc-300 hover:bg-zinc-900/50'}`}
          >
            <ShoppingBasket size={20} />
            <span className="font-medium">Buy Items</span>
          </button>
        </nav>

        <div className="mt-auto p-4 bg-zinc-900/50 border border-zinc-800/50 rounded-xl">
          <div className="flex items-center gap-2 mb-2 text-zinc-400">
            <Info size={14} />
            <span className="text-[10px] font-bold uppercase tracking-wider">Note</span>
          </div>
          <p className="text-xs text-zinc-500 leading-relaxed">
            Prices change based on stock. The more we have, the less we pay.
          </p>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0">
        <header className="h-20 border-b border-zinc-800 flex items-center justify-between px-8">
          <div>
            <h2 className="text-xl font-semibold capitalize">{activeTab} Items</h2>
            <p className="text-xs text-zinc-500">Browse and trade items with the shop</p>
          </div>
          <button onClick={onClose} className="p-2 hover:bg-zinc-900 rounded-full transition-colors text-zinc-500 hover:text-white">
            <X size={20} />
          </button>
        </header>

        <div className="flex-1 overflow-y-auto p-8 grid grid-cols-3 gap-4 custom-scrollbar">
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
                  item={{ name: itemName, label: itemName }} // Simplified for now
                  shopData={stockData}
                  onClick={() => setSelectedItem({ name: itemName, ...stockData })}
                  isSelected={selectedItem?.name === itemName}
                  type="buy"
                />
              )
            })
          )}
        </div>
      </div>

      {/* Action Sidebar */}
      {selectedItem && (
        <motion.div 
          initial={{ x: 300 }}
          animate={{ x: 0 }}
          className="w-80 bg-zinc-900/50 border-l border-zinc-800 p-8 flex flex-col"
        >
          <div className="text-center mb-8">
            <div className="w-32 h-32 bg-zinc-950 border border-zinc-800 rounded-3xl mx-auto mb-4 flex items-center justify-center shadow-2xl">
               <img src={`nui://ox_inventory/web/images/${selectedItem.name}.png`} className="w-20 h-20 object-contain" alt="" />
            </div>
            <h3 className="text-xl font-bold">{selectedItem.label}</h3>
            <p className="text-emerald-500 font-mono text-lg mt-1">
              ${activeTab === 'sell' ? data.shopData[selectedItem.name]?.buyPrice : selectedItem.sellPrice}
            </p>
          </div>

          <div className="space-y-6">
            <div className="space-y-3">
              <label className="text-[10px] uppercase font-bold text-zinc-500 tracking-widest">Quantity</label>
              <div className="flex items-center gap-2">
                <button 
                  onClick={() => setQuantity(Math.max(1, quantity - 1))}
                  className="w-10 h-10 border border-zinc-800 rounded-xl hover:bg-zinc-800 transition-colors"
                >-</button>
                <input 
                  type="number" 
                  value={quantity}
                  onChange={(e) => setQuantity(parseInt(e.target.value) || 1)}
                  className="flex-1 bg-zinc-950 border border-zinc-800 rounded-xl h-10 text-center font-mono focus:ring-1 focus:ring-emerald-500 outline-none"
                />
                <button 
                  onClick={() => setQuantity(Math.min(activeTab === 'sell' ? selectedItem.count : selectedItem.stock, quantity + 1))}
                  className="w-10 h-10 border border-zinc-800 rounded-xl hover:bg-zinc-800 transition-colors"
                >+</button>
              </div>
            </div>

            <button 
              onClick={handleAction}
              className="w-full bg-white text-black font-bold py-4 rounded-2xl hover:bg-zinc-200 transition-all shadow-lg active:scale-95"
            >
              Confirm {activeTab}
            </button>
          </div>
        </motion.div>
      )}
    </motion.div>
  );
};

const ItemCard = ({ item, shopData, onClick, isSelected, type }: any) => {
  return (
    <div 
      onClick={onClick}
      className={`group relative p-4 rounded-2xl border transition-all cursor-pointer ${isSelected ? 'bg-zinc-900 border-zinc-600 shadow-xl scale-[1.02]' : 'bg-zinc-900/30 border-zinc-800 hover:border-zinc-700 hover:bg-zinc-900/50'}`}
    >
      <div className="flex flex-col gap-4">
        <div className="w-full aspect-square bg-zinc-950/50 rounded-xl flex items-center justify-center p-4 border border-zinc-800 group-hover:border-zinc-700">
          <img src={`nui://ox_inventory/web/images/${item.name}.png`} className="w-full h-full object-contain" alt="" />
        </div>
        <div>
          <h4 className="font-semibold text-sm truncate">{item.label}</h4>
          <div className="flex justify-between items-center mt-1">
             <p className="text-zinc-500 text-xs">{type === 'sell' ? `Owned: ${item.count}` : `Stock: ${shopData?.stock}`}</p>
             <p className="text-emerald-500 font-mono text-sm">${type === 'sell' ? shopData?.buyPrice : shopData?.sellPrice}</p>
          </div>
        </div>
      </div>
      {shopData?.isHot && (
        <div className="absolute top-2 right-2 px-2 py-1 bg-orange-500/10 border border-orange-500/20 rounded-lg flex items-center gap-1">
          <span className="text-[10px] font-bold text-orange-500 tracking-tighter uppercase">Hot</span>
        </div>
      )}
    </div>
  );
};
