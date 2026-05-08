const { createApp } = require("./app");
const { connectDB } = require("./db/mongoose");
const { PORT } = require("./config/env");
const http = require("http");
const { Server } = require("socket.io");
const { initSocket } = require("./socket");

async function bootstrap() {
  await connectDB();
  const app = createApp();
  const server = http.createServer(app);
  const io = new Server(server, {
    cors: { origin: "*" },
  });
  initSocket(io);

  server.listen(PORT, () => {
    console.log(`🚀 API running on http://localhost:${PORT}`);
  });
}

bootstrap().catch((err) => {
  console.error("❌ Boot error:", err);
  process.exit(1);
});
