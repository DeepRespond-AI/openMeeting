<template>
  <div class="login-wrap">
    <el-card class="login-card" shadow="always">
      <div class="title">
        <el-icon :size="28" color="#409eff"><Microphone /></el-icon>
        <h1>OpenMeeting 管理端</h1>
      </div>
      <p class="muted sub">请输入管理员密码登录</p>
      <el-form @submit.prevent="submit">
        <el-form-item>
          <el-input
            v-model="password"
            type="password"
            show-password
            size="large"
            placeholder="管理员密码"
            autofocus
            :prefix-icon="Lock"
          />
        </el-form-item>
        <el-button type="primary" size="large" native-type="submit" :loading="loading" :disabled="!password" style="width: 100%">
          登录
        </el-button>
      </el-form>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Lock } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { api } from '@/api'
import { setAuthed } from '@/router'

const password = ref('')
const loading = ref(false)
const router = useRouter()
const route = useRoute()

async function submit() {
  if (!password.value) return
  loading.value = true
  try {
    await api.login(password.value)
    setAuthed(true)
    ElMessage.success('登录成功')
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/dashboard'
    router.replace(redirect.startsWith('/') && !redirect.startsWith('/login') ? redirect : '/dashboard')
  } catch {
    /* error shown by http layer */
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-wrap {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #001529 0%, #0b3b6f 100%);
  padding: 16px;
  box-sizing: border-box;
}
.login-card {
  width: 380px;
  max-width: 100%;
  padding: 12px 8px;
}
.title {
  display: flex;
  align-items: center;
  gap: 10px;
}
.title h1 {
  font-size: 22px;
  margin: 0;
}
.sub {
  margin: 8px 0 24px;
  font-size: 13px;
}
</style>
