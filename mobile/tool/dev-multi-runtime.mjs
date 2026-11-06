// Lifecycle primitives shared by the launcher and its deterministic protocol checks.
export class SerialOperations {
  #tail = Promise.resolve();
  #stopped = false;
  run(operation) {
    const result = this.#tail.then(() => {
      if (this.#stopped) throw new Error('Development session is stopping.');
      return operation();
    });
    this.#tail = result.catch(() => {});
    return result;
  }
  stop() { this.#stopped = true; }
}

export function machineRpc(stdin, timeoutMs = 90_000) {
  let sequence = 0;
  let closed;
  const pending = new Map();
  const fail = error => {
    closed = error;
    for (const entry of pending.values()) entry.reject(error);
    pending.clear();
  };
  stdin.on('error', fail); // EPIPE must reject operations, never crash the supervisor.
  return {
    fail,
    accept(message) {
      const entry = pending.get(message.id);
      if (!entry) return;
      pending.delete(message.id);
      if (message.error) entry.reject(new Error(JSON.stringify(message.error)));
      else entry.resolve(message.result);
    },
    call(method, params) {
      if (closed || stdin.destroyed || stdin.writableEnded) return Promise.reject(closed || new Error('Flutter input is closed.'));
      return new Promise((resolve, reject) => {
        const id = ++sequence;
        const timer = setTimeout(() => { pending.delete(id); reject(new Error(`${method} timed out.`)); }, timeoutMs);
        pending.set(id, {
          resolve: result => { clearTimeout(timer); resolve(result); },
          reject: error => { clearTimeout(timer); reject(error); },
        });
        stdin.write(JSON.stringify([{ id, method, params }]) + '\n', error => { if (error) fail(error); });
      });
    },
  };
}
