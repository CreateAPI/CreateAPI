import PackagePlugin
import Foundation

@main
struct CreateAPIPlugin {

}

// MARK: - BuildToolPlugin
extension CreateAPIPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let generator = CommandGenerator(
            pluginWorkDirectory: context.pluginWorkDirectory,
            moduleName: target.name,
            tool: try context.tool(named: "create-api"),
            directory: target.directory
        )

        return [
            generator.command()
        ]
    }
}

// MARK: - XcodeBuildToolPlugin
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension CreateAPIPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let generator = CommandGenerator(
            pluginWorkDirectory: context.pluginWorkDirectory,
            moduleName: target.product?.name ?? target.displayName,
            tool: try context.tool(named: "create-api"),
            directory: context.xcodeProject.directory
        )

        return [
            generator.command()
        ]
    }
}
#endif

// MARK: - Command Generator
struct CommandGenerator {
    let pluginWorkDirectory: PackagePlugin.Path
    let moduleName: String
    let tool: PackagePlugin.PluginContext.Tool
    let directory: PackagePlugin.Path

    func command() -> Command {
        let config = directory.appending("create-api.yaml")
        let schema = directory.appending("schema.yaml")

        return .buildCommand(
            displayName: "Generate with CreateAPI",
            executable: tool.path,
            arguments: [
                "generate",
                "--module", moduleName,
                "--config", config,
                "--output", pluginWorkDirectory,
                schema
            ],
            inputFiles: [
                config,
                schema
            ],
            outputFiles: [
                pluginWorkDirectory.appending("Entities.swift"),
                pluginWorkDirectory.appending("Paths.swift")
            ]
        )
    }
}
