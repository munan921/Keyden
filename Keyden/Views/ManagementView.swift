//
//  ManagementView.swift
//  Keyden
//
//  Token management - Authenticator style
//

import SwiftUI

struct ManagementView: View {
    @Binding var isPresented: Bool
    @StateObject private var vaultService = VaultService.shared
    
    @State private var searchText = ""
    @State private var editingToken: Token?
    @State private var tokenToDelete: Token?
    @State private var showDeleteAlert = false
    
    private var filteredTokens: [Token] {
        let sorted = vaultService.vault.tokens.sorted { $0.sortOrder < $1.sortOrder }
        if searchText.isEmpty { return sorted }
        return sorted.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.account.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Accounts")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            
            Divider().opacity(0.5)
            
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            
            // List
            if filteredTokens.isEmpty {
                VStack {
                    Spacer()
                    Text("No accounts")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredTokens) { token in
                        ManageRow(
                            token: token,
                            onEdit: { editingToken = token },
                            onDelete: {
                                tokenToDelete = token
                                showDeleteAlert = true
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        .listRowBackground(Color.clear)
                    }
                    .onMove(perform: moveTokens)
                }
                .listStyle(.plain)
            }
        }
        .background(AppTheme.background)
        .sheet(item: $editingToken) { token in
            EditTokenView(token: token, isPresented: .init(
                get: { editingToken != nil },
                set: { if !$0 { editingToken = nil } }
            ))
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { tokenToDelete = nil }
            Button("Delete", role: .destructive) {
                if let token = tokenToDelete {
                    try? vaultService.deleteToken(id: token.id)
                    tokenToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(tokenToDelete?.displayName ?? "")\"?")
        }
    }
    
    private func moveTokens(from source: IndexSet, to destination: Int) {
        try? vaultService.reorderTokens(from: source, to: destination)
    }
}

// MARK: - Manage Row
struct ManageRow: View {
    let token: Token
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                Text(String(token.displayName.prefix(1)).uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 1) {
                Text(token.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .layoutPriority(1)
                if !token.account.isEmpty {
                    Text(token.account)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .layoutPriority(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            
            Spacer()
            
            // Actions
            if isHovering {
                HStack(spacing: 6) {
                    IconButton(icon: "pencil", action: onEdit)
                    IconButton(icon: "trash", color: AppTheme.danger, action: onDelete)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isHovering ? Color.secondary.opacity(0.08) : Color.clear)
        .cornerRadius(6)
        .onHover { isHovering = $0 }
    }
    
    private var iconColor: Color {
        let hash = abs(token.displayName.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.7)
    }
}

// MARK: - Icon Button
struct IconButton: View {
    let icon: String
    var color: Color = .secondary
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(isHovering ? .white : color)
                .frame(width: 22, height: 22)
                .background(isHovering ? color : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Edit Token View
struct EditTokenView: View {
    let token: Token
    @Binding var isPresented: Bool
    @StateObject private var vaultService = VaultService.shared
    
    @State private var issuer: String = ""
    @State private var account: String = ""
    @State private var label: String = ""
    @State private var isSaving = false
    @State private var error: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Account")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            
            Divider().opacity(0.5)
            
            VStack(spacing: 14) {
                EditField(label: "Name", text: $label)
                EditField(label: "Issuer", text: $issuer)
                EditField(label: "Account", text: $account)
                
                if let error = error {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.danger)
                }
            }
            .padding(14)
            
            Spacer()
            
            // Buttons
            HStack(spacing: 10) {
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.bordered)
                
                Button(action: save) {
                    if isSaving {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Text("Save")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(label.isEmpty || isSaving)
            }
            .padding(14)
        }
        .frame(width: 300, height: 280)
        .background(AppTheme.background)
        .onAppear {
            issuer = token.issuer
            account = token.account
            label = token.label.isEmpty ? token.displayName : token.label
        }
    }
    
    private func save() {
        isSaving = true
        var updated = token
        updated.issuer = issuer
        updated.account = account
        updated.label = label
        
        do {
            try vaultService.updateToken(updated)
            isPresented = false
        } catch {
            self.error = error.localizedDescription
            isSaving = false
        }
    }
}

// MARK: - Edit Field
struct EditField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
