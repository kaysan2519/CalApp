import { app } from './app.js';
import { config } from './config/env.js';

app.listen(config.port, () => {
  console.log(`[Cal Server] Server running on port ${config.port} in ${config.nodeEnv} mode.`);
});
