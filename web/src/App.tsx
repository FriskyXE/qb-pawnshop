import React, { useState } from 'react';
import { useNuiEvent } from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';
import { PawnShop } from './views/PawnShop';
import { AnimatePresence } from 'framer-motion';

const App: React.FC = () => {
  const [visible, setVisible] = useState(false);
  const [shopData, setShopData] = useState<any>(null);

  useNuiEvent('setVisible', (data: any) => {
    setVisible(data.visible);
    if (data.shopData) setShopData(data.shopData);
  });

  const handleClose = () => {
    fetchNui('hideUI');
    setVisible(false);
  };

  return (
    <div className="nui-wrapper">
      <AnimatePresence>
        {visible && (
          <PawnShop data={shopData} onClose={handleClose} />
        )}
      </AnimatePresence>
    </div>
  );
};

export default App;
