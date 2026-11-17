import { createApp } from 'vue';
import App from './App.vue';
import './style.css';
import { applyUiTheme } from './uiTheme';

// ใส่ธีมของหน้าเว็บก่อน mount เพื่อไม่ให้กะพริบจากสว่างเป็นมืด
applyUiTheme();
createApp(App).mount('#app');
