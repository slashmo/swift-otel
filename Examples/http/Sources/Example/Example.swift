import ArgumentParser

@main
struct Example: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [Server.self, Client.self])
}
