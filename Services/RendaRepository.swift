import Foundation

enum RendaRepository {
    static func carregarCasas() -> [CasaRenda] {
        guard let dados = UserDefaults.standard.data(forKey: RendaConstants.chaveDados) else {
            return casasIniciais()
        }

        do {
            return try JSONDecoder().decode([CasaRenda].self, from: dados)
        } catch {
            print("Não foi possível carregar as casas guardadas: \(error)")
            return casasIniciais()
        }
    }

    static func guardarCasas(_ casas: [CasaRenda]) throws {
        let dados = try JSONEncoder().encode(casas)
        UserDefaults.standard.set(dados, forKey: RendaConstants.chaveDados)
    }

    private static func casasIniciais() -> [CasaRenda] {
        (1...RendaConstants.limiteCasas).map { numero in
            CasaRenda(
                id: numero,
                nome: "Casa \(numero)",
                inquilino: "",
                rendaMensal: 0,
                pagamentos: []
            )
        }
    }
}
