#include <iostream>
#include <unordered_set>
#include <unordered_map>
#include <vector>
#include <string>
#include <format>
#include <filesystem>
#include <ranges>
#include <fstream>

#include <version>


namespace fs = std::filesystem;


void print(auto _fmt, const auto&... _vals)
{
	std::cout << std::format(_fmt, _vals...);
};
void println(auto _fmt, const auto&... _vals)
{
	std::cout << std::format(_fmt, _vals...) << '\n';
};

void println_err(auto _fmt, const auto&... _vals)
{
	println("ERROR : {}", std::format(_fmt, _vals...));
};



struct option_arg_spec
{
	std::string name;
	bool required = true;
};

struct option_spec
{
	std::string full_name{};
	std::string description{};

	std::vector<std::string> names{};
	std::vector<option_arg_spec>  args{};
};

// option specs
const auto defined_options = []()
{
	std::vector<option_spec> _options
	{
		option_spec
		{
			"minimal install", 
			"prevents installing of documentation or other non-essential files",
			{ "-m", "--minimal" }
		},
		option_spec
		{
			"echo",
			"prints the command that was used to invoke the program",
			{ "-e", "--echo" }
		},
		option_spec
		{
			"help",
			"prints the help message",
			{ "-h", "--help" }
		},
		option_spec
		{
			"verbose",
			"prints messages more frequently and with higher detail",
			{ "-v", "--verbose" }
		},
		option_spec
		{
			"debug-ignored",
			"prints debug messages when ignoring files / directories",
			{ "--debug-ignored" }
		}
	};
	return _options;
}();	

const auto option_names = []()
{
	std::unordered_map<std::string, const option_spec*> _names{};
	for (const auto& v : defined_options)
	{
		for (auto& n : v.names)
		{
			_names.insert({ n, &v });
		};
	};
	return _names;
}();







auto parse_command_line(const std::vector<std::string>& _args)
{
	const int _nargs = _args.size();
	if (_nargs == 1)
	{
		std::cout << "use -h or --help for help" << '\n';
	};

	std::unordered_map<const option_spec*, std::vector<std::string>> options{};
	std::vector<std::string> arguements{};


	const auto setopt = [&options](const option_spec& _option, std::vector<std::string> _args)
	{
		options.insert({ &_option,  _args });
	};
	int i = 1;
	const auto readopt = [&options, &i, _nargs, &_args, &setopt](const option_spec& _option, const std::string_view _gotName)
	{
		const auto next = [&i, _nargs, _gotName](const auto& _arg)
		{
			++i;
			if (i == _nargs)
			{
				if (_arg.required)
				{
					println_err("missing required argument \"{}\" for option \"{}\"", _arg.name, _gotName);
					return -1;
				}
				else
				{
					return 0;
				};
			};
			return i;
		};

		std::vector<std::string> _optionArgs{};
		for (auto& a : _option.args)
		{
			auto _good = next(a);
			if (_good > 0)
			{
				_optionArgs.push_back(_args[_good]);
			}
			else if (_good == 0)
			{
				break;
			}
			else
			{
				println_err("failed to parse option \"{}\"", _gotName);
				return -1;
			};
		};

		setopt(_option, _optionArgs);
		return 0;
	};

	const auto parseopt = [&readopt](const std::string& _gotName)
	{
		auto it = option_names.find(_gotName);
		if (it != option_names.end())
		{
			return readopt(*it->second, _gotName);
		}
		else
		{
			println_err("unrecognized option \"{}\"", _gotName);
			return -1;
		};
	};

	for (i = 1; i != _nargs; ++i)
	{
		std::string _arg = _args[i];
		if (_arg.starts_with("--"))
		{
			// multi-char option
			auto _result = parseopt(_arg);
			if (_result != 0)
			{
				exit(_result);
			};
		}
		else if (_arg.starts_with('-'))
		{
			if (_arg.size() == 2)
			{
				// single char option
				auto _result = parseopt(_arg);
				if (_result != 0)
				{
					exit(_result);
				};
			}
			else
			{
				// multiple char options
				for (auto c : std::string_view{ _arg.begin() + 1, _arg.end() })
				{
					auto _result = parseopt(std::string{ '-' } += c);
					if (_result != 0)
					{
						exit(_result);
					};
				};
			};
		}
		else
		{
			arguements.push_back(_arg);
		};
	};

	return std::pair{ arguements, options };
};

int rmain(const std::vector<std::string>& _args)
{
	const auto[_arguements, _options] = parse_command_line(_args);
	
	auto _sourceRoot = fs::path(OS_SOURCE);
	auto _buildRoot = fs::current_path();


	const auto _verbose = _options.contains(option_names.at("--verbose"));
	const auto _debugIgnored = _options.contains(option_names.at("--debug-ignored"));
	const auto _minimal = _options.contains(option_names.at("--minimal"));



	// look for destination arguement
	if (!_arguements.empty())
	{
		_buildRoot = fs::absolute(_arguements[0]);
		if (!fs::exists(_buildRoot))
		{
			println_err("specified install root \"{}\" does not exist", _buildRoot.string());
		};
	};

	if (_verbose)
	{
		println("set install root to {}", _buildRoot.string());
	};


	// echo option
	if (_options.contains(option_names.at("--echo")))
	{
		std::string _argstr = fs::path(_args[0]).filename().string();

		for (auto& v : _args | std::views::drop(1))
		{
			_argstr += " ";
			_argstr.append(v);
		};
		println(_argstr);
	};

	// help option
	if (_options.contains(option_names.at("--help")))
	{
		println("usage:\n\t[install/root/path] [options]");
		println("\noptions:");

		for (auto& v : defined_options)
		{
			{
				auto _name = v.names.begin();
				const auto _end = v.names.end();

				if (_name != _end)
				{
					print("{}", *_name);
					++_name;
				};
				while (_name != _end)
				{
					print(", {}", *_name);
					++_name;
				};
			};

			print("\t");
			for (auto& a : v.args)
			{
				const auto _fmt = (a.required) ? " {}" : " [{}]";
				print(_fmt, a.name);
			};
			println("\n\t   {}\n", v.description);
		};

		return 0;
	};


	for (auto& v : fs::recursive_directory_iterator{ _sourceRoot })
	{
		const auto& _sourcePath = v.path();
		fs::path _destPath = _buildRoot;
		_destPath.append(fs::relative(_sourcePath, _sourceRoot).string());
		



		if (v.is_directory())
		{
			if (!_sourcePath.filename().string().starts_with('.'))
			{
				if (_verbose)
				{
					println("{} -> {}", _sourcePath.string(), _destPath.string());
				};

				std::error_code _err{};
				fs::create_directory(_destPath, _err);
				if (_err)
				{
					println_err("{}", _err.message());
				};
			}
			else
			{
				if (_debugIgnored)
				{
					println("ignored {}", _sourcePath.string());
				};
			};
		}
		else
		{
			const auto _sourceExt = _sourcePath.extension().string();

			if (_minimal)
			{
				if (_sourcePath.filename().string().find(".doc") != std::string::npos)
				{
					if (_debugIgnored)
					{
						println("ignored {}", _sourcePath.string());
					};

					continue;
				};
			};

			if (_sourceExt == ".lua")
			{
				if (_verbose)
				{
					println("{} -> {}", _sourcePath.string(), _destPath.string());
				};
				
				std::error_code _err{};
				fs::copy_file(_sourcePath, _destPath, fs::copy_options::overwrite_existing, _err);
				if (_err)
				{
					println_err("{}", _err.message());
				};
			};
		};
	};



	return 0;
};


int main(int _nargs, const char* _args[])
{
	std::vector<std::string> _argvec{};
	for (int n = 0; n != _nargs; ++n)
	{
		_argvec.push_back(_args[n]);
	};
	return rmain(_argvec);
};
