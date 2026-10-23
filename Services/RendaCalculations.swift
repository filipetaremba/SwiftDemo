import Foundation

extension CasaRenda {
    func valorRecebido(no ano: Int) -> Double {
        pagamentos
            .filter { $0.anoDaRenda == ano }
            .reduce(0) { $0 + $1.valor }
    }

    func valorPago(no mes: Int, do ano: Int) -> Double {
        pagamentos
            .filter { $0.anoDaRenda == ano && $0.mesDaRenda == mes }
            .reduce(0) { $0 + $1.valor }
    }

    func divida(no ano: Int, hoje: Date = Date()) -> Double {
        let calendario = Calendar.current
        let anoAtual = calendario.component(.year, from: hoje)
        let mesAtual = calendario.component(.month, from: hoje)
        let mesesVencidos: Int

        if ano < anoAtual {
            mesesVencidos = 12
        } else if ano > anoAtual {
            mesesVencidos = 0
        } else {
            mesesVencidos = mesAtual
        }

        let totalDevido = rendaMensal * Double(mesesVencidos)
        let totalPago = pagamentos
            .filter { $0.anoDaRenda == ano && $0.mesDaRenda <= mesesVencidos }
            .reduce(0) { $0 + $1.valor }

        return max(0, totalDevido - totalPago)
    }
}

enum RendaFormatador {
    static func dinheiro(_ valor: Double) -> String {
        let formatador = NumberFormatter()
        formatador.numberStyle = .decimal
        formatador.maximumFractionDigits = 2
        formatador.minimumFractionDigits = 0
        formatador.groupingSeparator = " "
        let numero = formatador.string(from: NSNumber(value: valor)) ?? "0"
        return "\(numero) MT"
    }
}
