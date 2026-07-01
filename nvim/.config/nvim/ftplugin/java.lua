local root_dir = vim.fs.root(0, {
	"gradlew",
	"mvnw",
	"pom.xml",
	"build.gradle",
	"build.gradle.kts",
	"settings.gradle",
	"settings.gradle.kts",
	".git",
})
if not root_dir then
	vim.notify("jdtls not started: no Java project root found", vim.log.levels.WARN)
	return
end

if vim.fn.executable("jdtls") ~= 1 then
	vim.notify("jdtls not started: command not found in PATH", vim.log.levels.ERROR)
	return
end

local project_name = vim.fn.fnamemodify(root_dir, ":t")
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. project_name
local java_home = vim.fn.expand("~/.local/share/mise/installs/java/temurin-21.0.11+10.0.LTS")

local bundles = {}
local java_debug_bundle = vim.fn.glob(vim.fn.stdpath("data") .. "/java-debug/com.microsoft.java.debug.plugin-*.jar", 1)
if java_debug_bundle ~= "" then
	table.insert(bundles, java_debug_bundle)
end

local java_test_bundles = vim.split(vim.fn.glob(vim.fn.stdpath("data") .. "/vscode-java-test/server/*.jar", 1), "\n", {
	trimempty = true,
})
local excluded = {
	["com.microsoft.java.test.runner-jar-with-dependencies.jar"] = true,
	["jacocoagent.jar"] = true,
}

for _, java_test_jar in ipairs(java_test_bundles) do
	local filename = vim.fn.fnamemodify(java_test_jar, ":t")
	if not excluded[filename] then
		table.insert(bundles, java_test_jar)
	end
end

local config = {
	name = "jdtls",
	cmd = { "jdtls", "-data", workspace_dir },
	root_dir = root_dir,
	cmd_env = {
		JAVA_HOME = java_home,
	},
	capabilities = require("blink.cmp").get_lsp_capabilities(),
	init_options = {
		bundles = bundles,
	},
}

require("jdtls").start_or_attach(config)

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = true, desc = desc })
end

map("<leader>vm", function()
	require("jdtls").test_nearest_method()
end, "Debug nearest Java test method")

map("<leader>vT", function()
	require("jdtls").test_class()
end, "Debug current Java test class")

map("<leader>vj", function()
	if vim.fn.exists(":JdtUpdateDebugConfig") == 2 then
		vim.cmd("JdtUpdateDebugConfig")
	elseif vim.fn.exists(":JdtUpdateConfig") == 2 then
		vim.cmd("JdtUpdateConfig")
	end
end, "Refresh Java debug config")
