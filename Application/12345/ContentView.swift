import SwiftUI

struct ContentView: View {
    @State private var isProxyActive = false
    @State private var statusMessage = "未启动"
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertItem: AlertItem?
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题和Logo
            VStack {
                Text("12345")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("试图 在未越狱环境 一键内购APP付费")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // 状态显示
            VStack {
                Text("代理状态:")
                    .font(.headline)
                Text(statusMessage)
                    .font(.title3)
                    .foregroundColor(isProxyActive ? .green : .red)
                    .fontWeight(.medium)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // 控制按钮
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                Button(action: toggleProxy) {
                    Text(isProxyActive ? "停止代理" : "启动代理")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(
                            isProxyActive ? Color.red : Color.green
                        )
                        .cornerRadius(10)
                }
                .buttonStyle(CustomButtonStyle())
            }
            
            Divider()
                .padding(.vertical)
            
            // 使用说明
            VStack(alignment: .leading, spacing: 15) {
                Text("使用说明:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. 点击\"启动代理\"按钮开启内购拦截")
                    Text("2. 打开任何包含内购的应用")
                    Text("3. 尝试购买内购项目（会弹出支付框）")
                    Text("4. 取消支付，内购会自动激活")
                    Text("5. 使用完成后点击\"停止代理\"")
                }
                .font(.callout)
                .padding(.leading, 10)
                
                Text("注意: 仅用于学习研究，由pxx917144686手搓")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            Spacer()
            
            // 版权信息
            Text("© 2025 12345 for pxx917144686")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            checkProxyStatus()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertItem?.title ?? "提示"),
                message: Text(alertItem?.message ?? ""),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // 切换代理状态
    private func toggleProxy() {
        isLoading = true
        
        if isProxyActive {
            // 停止代理
            NetworkExtensionManager.shared.stopNetworkExtension { success, message in
                DispatchQueue.main.async {
                    isLoading = false
                    if success {
                        isProxyActive = false
                        statusMessage = "已停止"
                    } else {
                        showAlert(title: "停止失败", message: message)
                    }
                }
            }
        } else {
            // 启动代理
            NetworkExtensionManager.shared.startNetworkExtension { success, message in
                DispatchQueue.main.async {
                    isLoading = false
                    if success {
                        isProxyActive = true
                        statusMessage = "已启动"
                    } else {
                        showAlert(title: "启动失败", message: message)
                    }
                }
            }
        }
    }
    
    // 检查当前代理状态
    private func checkProxyStatus() {
        isLoading = true
        
        NetworkExtensionManager.shared.getStatus { active, message in
            DispatchQueue.main.async {
                isLoading = false
                isProxyActive = active
                statusMessage = active ? "已启动" : "未启动"
            }
        }
    }
    
    // 显示警告
    private func showAlert(title: String, message: String) {
        alertItem = AlertItem(
            title: title,
            message: message
        )
        showAlert = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}