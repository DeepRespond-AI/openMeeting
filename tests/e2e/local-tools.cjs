// Tool locations for local acceptance runs; no developer-machine defaults.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const root = path.resolve(__dirname, '../..');
function testPython() {
  if (process.env.OPENMEETING_TEST_PYTHON) return process.env.OPENMEETING_TEST_PYTHON;
  const candidate = path.join(root, 'server/.venv', process.platform === 'win32' ? 'Scripts/python.exe' : 'bin/python');
  return fs.existsSync(candidate) ? candidate : process.platform === 'win32' ? 'python' : 'python3';
}
function testAdb() {
  if (process.env.OPENMEETING_ADB_BIN) return process.env.OPENMEETING_ADB_BIN;
  const sdk = process.env.ANDROID_SDK_ROOT || process.env.ANDROID_HOME;
  return sdk ? path.join(sdk, 'platform-tools', process.platform === 'win32' ? 'adb.exe' : 'adb') : 'adb';
}
function testDevice() {
  const device = process.env.OPENMEETING_E2E_DEVICE;
  if (!device) throw new Error('Set OPENMEETING_E2E_DEVICE to the dedicated test device ID from adb devices.');
  return device;
}
function testSdk() {
  const sdk = process.env.MEETING_READY_NATIVE_SDK;
  if (!sdk) throw new Error('Set MEETING_READY_NATIVE_SDK to the IM native SDK source directory.');
  return sdk;
}
function testAppData() {
  return process.env.APPDATA || path.join(os.homedir(), 'AppData/Roaming');
}
module.exports = { testPython, testAdb, testDevice, testSdk, testAppData };
