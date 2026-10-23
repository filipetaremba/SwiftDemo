import SwiftUI

struct ContentView: View {
    @State private var casas: [CasaRenda] = RendaRepository.carregarCasas()
    @State private var anoSelecionado = Calendar.current.component(.year, from: Date())
    @State private var casaSelecionadaID: Int?
    @State private var mostrarFormularioCasa = false
    @State private var mostrarFormularioPagamento = false
    @State private var casaEmEdicaoID: Int?
    @State private var casaParaPagamentoID: Int?
    @State private var novoNomeCasa = ""
    @State private var novoInquilino = ""
    @State private var novaRenda = ""
    @State private var valorPagamento = ""
    @State private var mesPagamento = Calendar.current.component(.month, from: Date())
    @State private var dataPagamento = Date()
    @State private var notaPagamento = ""
    @State private var mensagemErro: String?

    private var casaSelecionada: CasaRenda? {
        guard let id = casaSelecionadaID else { return nil }
        return casas.first { $0.id == id }
    }

    private var totalRecebido: Double {
        casas.reduce(0) { $0 + $1.valorRecebido(no: anoSelecionado) }
    }

    private var totalEmDivida: Double {
        casas.reduce(0) { $0 + $1.divida(no: anoSelecionado) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let casa = casaSelecionada {
                    detalhesCasa(casa)
                } else {
                    listaCasas
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(casaSelecionada == nil ? "RendaFácil" : (casaSelecionada?.nome ?? "Casa"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if casaSelecionada != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            casaSelecionadaID = nil
                        } label: {
                            Label("Casas", systemImage: "chevron.left")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Editar") {
                            guard let casa = casaSelecionada else { return }
                            abrirEdicaoCasa(casa)
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            abrirNovaCasa()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Adicionar casa")
                    }
                }
            }
            .sheet(isPresented: $mostrarFormularioCasa) {
                formularioCasa
            }
            .sheet(isPresented: $mostrarFormularioPagamento) {
                formularioPagamento
            }
            .alert("Atenção", isPresented: Binding(
                get: { mensagemErro != nil },
                set: { if !$0 { mensagemErro = nil } }
            )) {
                Button("OK", role: .cancel) { mensagemErro = nil }
            } message: {
                Text(mensagemErro ?? "")
            }
        }
    }

    private var listaCasas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                anoSeletor

                HStack(spacing: 12) {
                    resumoCard(titulo: "Dívida total", valor: RendaFormatador.dinheiro(totalEmDivida), icone: "exclamationmark.circle", cor: .orange)
                    resumoCard(titulo: "Recebido no ano", valor: RendaFormatador.dinheiro(totalRecebido), icone: "checkmark.circle", cor: .green)
                }

                HStack {
                    Text("As minhas casas")
                        .font(.title3.bold())
                    Spacer()
                    Text("\(casas.count) de \(RendaConstants.limiteCasas)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if casas.isEmpty {
                    ContentUnavailableView(
                        "Nenhuma casa registada",
                        systemImage: "house",
                        description: Text("Adicione uma casa para começar a controlar as rendas.")
                    )
                } else {
                    ForEach(casas.sorted { $0.id < $1.id }) { casa in
                        Button {
                            casaSelecionadaID = casa.id
                        } label: {
                            cartaoCasa(casa)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if casas.count < RendaConstants.limiteCasas {
                    Button {
                        abrirNovaCasa()
                    } label: {
                        Label("Adicionar casa", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Text("As dívidas são calculadas com base nas rendas vencidas e nos pagamentos registados.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding()
        }
    }

    private var anoSeletor: some View {
        HStack {
            Text("Ano das rendas")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button {
                anoSelecionado -= 1
            } label: {
                Image(systemName: "chevron.left")
            }
            Text(String(anoSelecionado))
                .font(.headline.monospacedDigit())
                .frame(minWidth: 54)
            Button {
                anoSelecionado += 1
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func resumoCard(titulo: String, valor: String, icone: String, cor: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icone)
                .font(.title3)
                .foregroundStyle(cor)
            Text(titulo)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(valor)
                .font(.headline)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func cartaoCasa(_ casa: CasaRenda) -> some View {
        let divida = casa.divida(no: anoSelecionado)
        let recebido = casa.valorRecebido(no: anoSelecionado)

        return HStack(spacing: 14) {
            Image(systemName: "house.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 48, height: 48)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(casa.nome)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(casa.inquilino.isEmpty ? "Inquilino não indicado" : casa.inquilino)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Renda: \(RendaFormatador.dinheiro(casa.rendaMensal))/mês")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Recebido em \(anoSelecionado): \(RendaFormatador.dinheiro(recebido))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 6) {
                Text(divida > 0 ? "Com dívida" : "Em dia")
                    .font(.caption.bold())
                    .foregroundStyle(divida > 0 ? .orange : .green)
                Text(RendaFormatador.dinheiro(divida))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func detalhesCasa(_ casa: CasaRenda) -> some View {
        let pagamentosDoAno = casa.pagamentos
            .filter { $0.anoDaRenda == anoSelecionado }
            .sorted { $0.data > $1.data }

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(casa.inquilino.isEmpty ? "Inquilino não indicado" : casa.inquilino)
                        .font(.title3.bold())
                    Text("Renda mensal: \(RendaFormatador.dinheiro(casa.rendaMensal))")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        resumoCard(titulo: "Dívida", valor: RendaFormatador.dinheiro(casa.divida(no: anoSelecionado)), icone: "exclamationmark.circle", cor: casa.divida(no: anoSelecionado) > 0 ? .orange : .green)
                        resumoCard(titulo: "Recebido", valor: RendaFormatador.dinheiro(casa.valorRecebido(no: anoSelecionado)), icone: "checkmark.circle", cor: .green)
                    }

                    Button {
                        casaParaPagamentoID = casa.id
                        valorPagamento = ""
                        mesPagamento = Calendar.current.component(.month, from: Date())
                        dataPagamento = Date()
                        notaPagamento = ""
                        mostrarFormularioPagamento = true
                    } label: {
                        Label("Registar pagamento", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Rendas de \(anoSelecionado)")
                        .font(.title3.bold())

                    ForEach(1...12, id: \.self) { mes in
                        linhaMes(mes, casa: casa)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Histórico de pagamentos")
                        .font(.title3.bold())

                    if pagamentosDoAno.isEmpty {
                        Text("Ainda não há pagamentos registados neste ano.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(pagamentosDoAno) { pagamento in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(RendaConstants.meses[pagamento.mesDaRenda - 1]) — \(RendaFormatador.dinheiro(pagamento.valor))")
                                        .font(.subheadline.bold())
                                    Text("Pago em \(pagamento.data.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if !pagamento.nota.isEmpty {
                                        Text(pagamento.nota)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    apagarPagamento(pagamento, daCasa: casa)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Apagar pagamento")
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func linhaMes(_ mes: Int, casa: CasaRenda) -> some View {
        let anoAtual = Calendar.current.component(.year, from: Date())
        let mesAtual = Calendar.current.component(.month, from: Date())
        let mesVencido = anoSelecionado < anoAtual || (anoSelecionado == anoAtual && mes <= mesAtual)
        let aindaNaoVenceu = !mesVencido
        let pago = casa.valorPago(no: mes, do: anoSelecionado)
        let saldo = max(0, (mesVencido ? casa.rendaMensal : 0) - pago)
        let estado: String = aindaNaoVenceu ? "Ainda não venceu" : (saldo <= 0 ? "Pago" : (pago > 0 ? "Parcial" : "Pendente"))
        let cor: Color = aindaNaoVenceu ? .secondary : (saldo <= 0 ? .green : (pago > 0 ? .orange : .red))

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(RendaConstants.meses[mes - 1])
                    .font(.subheadline.bold())
                Text(estado)
                    .font(.caption)
                    .foregroundStyle(cor)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Pago: \(RendaFormatador.dinheiro(pago))")
                    .font(.subheadline)
                if saldo > 0 {
                    Text("Em falta: \(RendaFormatador.dinheiro(saldo))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var formularioCasa: some View {
        NavigationStack {
            Form {
                Section("Informação da casa") {
                    TextField("Nome da casa (ex.: Casa 1)", text: $novoNomeCasa)
                    TextField("Nome do inquilino (opcional)", text: $novoInquilino)
                    TextField("Renda mensal em MT", text: $novaRenda)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(casaEmEdicaoID == nil ? "Nova casa" : "Editar casa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { mostrarFormularioCasa = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardarCasaDoFormulario() }
                }
            }
        }
    }

    private var formularioPagamento: some View {
        NavigationStack {
            Form {
                Section("Detalhes do pagamento") {
                    TextField("Valor pago em MT", text: $valorPagamento)
                        .keyboardType(.decimalPad)

                    Picker("Mês a que se refere", selection: $mesPagamento) {
                        ForEach(1...12, id: \.self) { mes in
                            Text(RendaConstants.meses[mes - 1]).tag(mes)
                        }
                    }

                    DatePicker("Data em que pagou", selection: $dataPagamento, displayedComponents: .date)

                    TextField("Nota (opcional)", text: $notaPagamento, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Text("Se pagar apenas uma parte, registe o valor recebido. O restante ficará como dívida.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Registar pagamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { mostrarFormularioPagamento = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardarPagamento() }
                }
            }
        }
    }

    private func proximoIdLivre() -> Int {
        for numero in 1...RendaConstants.limiteCasas {
            if !casas.contains(where: { $0.id == numero }) {
                return numero
            }
        }
        return casas.count + 1
    }

    private func abrirNovaCasa() {
        guard casas.count < RendaConstants.limiteCasas else {
            mensagemErro = "A aplicação permite registar no máximo cinco casas."
            return
        }
        casaEmEdicaoID = nil
        novoNomeCasa = "Casa \(proximoIdLivre())"
        novoInquilino = ""
        novaRenda = ""
        mostrarFormularioCasa = true
    }

    private func abrirEdicaoCasa(_ casa: CasaRenda) {
        casaEmEdicaoID = casa.id
        novoNomeCasa = casa.nome
        novoInquilino = casa.inquilino
        novaRenda = String(casa.rendaMensal)
        mostrarFormularioCasa = true
    }

    private func guardarCasaDoFormulario() {
        let rendaNormalizada = novaRenda
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard let renda = Double(rendaNormalizada), renda > 0 else {
            mensagemErro = "Introduza um valor de renda válido e maior que zero."
            return
        }
        guard !novoNomeCasa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            mensagemErro = "Introduza o nome da casa."
            return
        }

        let casasAnteriores = casas
        if let id = casaEmEdicaoID, let indice = casas.firstIndex(where: { $0.id == id }) {
            casas[indice].nome = novoNomeCasa.trimmingCharacters(in: .whitespacesAndNewlines)
            casas[indice].inquilino = novoInquilino.trimmingCharacters(in: .whitespacesAndNewlines)
            casas[indice].rendaMensal = renda
        } else {
            guard casas.count < RendaConstants.limiteCasas else {
                mensagemErro = "Já existem cinco casas registadas."
                return
            }
            let id = proximoIdLivre()
            casas.append(CasaRenda(
                id: id,
                nome: novoNomeCasa.trimmingCharacters(in: .whitespacesAndNewlines),
                inquilino: novoInquilino.trimmingCharacters(in: .whitespacesAndNewlines),
                rendaMensal: renda,
                pagamentos: []
            ))
        }
        guard guardarCasas() else {
            casas = casasAnteriores
            return
        }
        mostrarFormularioCasa = false
    }

    private func guardarPagamento() {
        let valorNormalizado = valorPagamento
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        guard let valor = Double(valorNormalizado), valor > 0 else {
            mensagemErro = "Introduza um valor de pagamento válido e maior que zero."
            return
        }
        guard let id = casaParaPagamentoID, let indice = casas.firstIndex(where: { $0.id == id }) else {
            mensagemErro = "Não foi possível encontrar a casa selecionada."
            return
        }

        let pagamento = RegistoPagamento(
            valor: valor,
            data: dataPagamento,
            mesDaRenda: mesPagamento,
            anoDaRenda: anoSelecionado,
            nota: notaPagamento.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        // O pagamento fica associado ao ano/mês da renda e à data em que foi recebido.
        let casasAnteriores = casas
        casas[indice].pagamentos.append(pagamento)
        guard guardarCasas() else {
            casas = casasAnteriores
            return
        }
        mostrarFormularioPagamento = false
    }

    private func apagarPagamento(_ pagamento: RegistoPagamento, daCasa casa: CasaRenda) {
        guard let indice = casas.firstIndex(where: { $0.id == casa.id }) else { return }
        let casasAnteriores = casas
        casas[indice].pagamentos.removeAll { $0.id == pagamento.id }
        guard guardarCasas() else {
            casas = casasAnteriores
            return
        }
    }

    private func guardarCasas() -> Bool {
        do {
            try RendaRepository.guardarCasas(casas)
            return true
        } catch {
            mensagemErro = "Não foi possível guardar os dados: \(error.localizedDescription)"
            return false
        }
    }
}
