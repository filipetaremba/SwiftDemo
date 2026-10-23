import Foundation

enum RendaConstants {
    static let meses = [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]
    static let chaveDados = "rendaFacil.dados.v1"
    static let limiteCasas = 5
}

struct RegistoPagamento: Identifiable, Codable {
    var id = UUID()
    var valor: Double
    var data: Date
    var mesDaRenda: Int
    var anoDaRenda: Int
    var nota: String
}

struct CasaRenda: Identifiable, Codable {
    var id: Int
    var nome: String
    var inquilino: String
    var rendaMensal: Double
    var pagamentos: [RegistoPagamento]
}
