let ioInstance = null;

function initSocket(io) {
    ioInstance = io;

    io.on("connection", (socket) => {
        socket.on("join", ({ userId }) => {
            if (userId) {
                socket.join(`user:${userId}`);
            }
        });
    });
}

function getIo() {
    if (!ioInstance) {
        throw new Error("Socket.io not initialized");
    }
    return ioInstance;
}

module.exports = { initSocket, getIo };
