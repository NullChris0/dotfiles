local current_file = vim.api.nvim_buf_get_name(0)
local launch_cwd = vim.loop.cwd()
local search_start = current_file ~= "" and vim.fs.dirname(current_file) or launch_cwd

local function has_file(dir, name)
	return vim.uv.fs_stat(vim.fs.joinpath(dir, name)) ~= nil
end

local function is_maven_aggregator(dir)
	if not has_file(dir, "pom.xml") then
		return false
	end

	local pom_lines = vim.fn.readfile(vim.fs.joinpath(dir, "pom.xml"), "", 120)
	local pom_text = table.concat(pom_lines, "\n")
	return pom_text:find("<packaging>%s*pom%s*</packaging>") ~= nil
end

local function detect_root_dir()
	if launch_cwd and (
		has_file(launch_cwd, ".git")
		or has_file(launch_cwd, "pom.xml")
		or has_file(launch_cwd, "mvnw")
		or has_file(launch_cwd, "settings.gradle")
		or has_file(launch_cwd, "settings.gradle.kts")
		or has_file(launch_cwd, "build.gradle")
		or has_file(launch_cwd, "build.gradle.kts")
		or has_file(launch_cwd, "gradlew")
	) then
		return launch_cwd
	end

	local git_root = vim.fs.root(search_start, { ".git" })
	if git_root and is_maven_aggregator(git_root) then
		return git_root
	end

	local gradle_root = vim.fs.root(search_start, {
		"settings.gradle",
		"settings.gradle.kts",
		"build.gradle",
		"build.gradle.kts",
		"gradlew",
	})
	if gradle_root then
		return gradle_root
	end

	local maven_root = vim.fs.root(search_start, { "mvnw", "pom.xml" })
	if maven_root then
		return maven_root
	end

	return git_root
end

local root_dir = detect_root_dir()
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
local jdtls_java_home = vim.fn.expand("~/.local/share/mise/installs/java/temurin-21.0.11+10.0.LTS")

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function mise_exec(args)
	local result = vim.system(args, { cwd = root_dir, text = true }):wait()
	if result.code ~= 0 then
		local err = trim((result.stderr or "") ~= "" and result.stderr or (result.stdout or ""))
		return nil, err
	end

	local output = (result.stdout or "") ~= "" and result.stdout or (result.stderr or "")
	return trim(output)
end

local function runtime_name_from_version(version)
	if version:match("^1%.8") then
		return "JavaSE-1.8"
	end

	local major = version:match("^(%d+)")
	if not major then
		return nil
	end

	return "JavaSE-" .. major
end

local function detect_project_runtime()
	if vim.fn.executable("mise") ~= 1 then
		return nil, "mise command not found in PATH"
	end

	local runtime_path, path_err = mise_exec({ "mise", "where", "java" })
	if not runtime_path or runtime_path == "" then
		return nil, path_err ~= "" and path_err or "mise did not return a Java install path"
	end

	local version_out, version_err = mise_exec({ "mise", "exec", "--", "java", "-version" })
	if not version_out or version_out == "" then
		return nil, version_err ~= "" and version_err or "failed to detect Java version from mise"
	end

	local version = version_out:match('version%s+"([^"]+)"')
	if not version then
		return nil, "failed to parse Java version from: " .. version_out
	end

	local runtime_name = runtime_name_from_version(version)
	if not runtime_name then
		return nil, "failed to map Java version to jdtls runtime name: " .. version
	end

	return {
		name = runtime_name,
		path = runtime_path,
		version = version,
		default = true,
	}
end

local project_runtime, runtime_err = detect_project_runtime()
if runtime_err then
	vim.notify("jdtls runtime detection: " .. runtime_err, vim.log.levels.WARN)
end

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
		JAVA_HOME = jdtls_java_home,
	},
	capabilities = require("blink.cmp").get_lsp_capabilities(),
	init_options = {
		bundles = bundles,
	},
	settings = {
		java = {
			configuration = {
				runtimes = project_runtime and { project_runtime } or nil,
			},
		},
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

vim.api.nvim_buf_create_user_command(0, "JdtRuntimeInfo", function()
	local client = vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1]
	local info = {
		root_dir = root_dir,
		workspace_dir = workspace_dir,
		jdtls_java_home = jdtls_java_home,
		project_runtime = project_runtime,
		runtime_error = runtime_err,
		client_cmd = client and client.config.cmd or nil,
		client_cmd_env = client and client.config.cmd_env or nil,
	}
	vim.notify(vim.inspect(info), vim.log.levels.INFO, { title = "JdtRuntimeInfo" })
end, { desc = "Show jdtls runtime configuration" })

vim.api.nvim_buf_create_user_command(0, "LspStatus", function()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	local names = {}
	for _, client in ipairs(clients) do
		table.insert(names, client.name)
	end
	vim.notify(vim.inspect({
		bufnr = vim.api.nvim_get_current_buf(),
		filetype = vim.bo.filetype,
		clients = names,
	}), vim.log.levels.INFO, { title = "LspStatus" })
end, { desc = "Show active LSP clients for current buffer" })
