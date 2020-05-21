{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.kakoune;

  commonOptions = {

    tabStop = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      description = ''
        The width of a tab in spaces. The kakoune default is
        <literal>6</literal>.
      '';
    };

    indentWidth = mkOption {
      type = types.nullOr types.ints.unsigned;
      default = null;
      description = ''
        The width of an indentation in spaces.
        The kakoune default is <literal>4</literal>.
        If <literal>0</literal>, a tab will be used instead.
      '';
    };

    incrementalSearch = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Execute a search as it is being typed.
      '';
    };

    alignWithTabs = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Use tabs for the align command.
      '';
    };

    autoInfo = mkOption {
      type =
        types.nullOr (types.listOf (types.enum [ "command" "onkey" "normal" ]));
      default = null;
      example = [ "command" "normal" ];
      description = ''
        Contexts in which to display automatic information box.
        The kakoune default is <literal>[ "command" "onkey" ]</literal>.
      '';
    };

    autoComplete = mkOption {
      type = types.nullOr (types.listOf (types.enum [ "insert" "prompt" ]));
      default = null;
      description = ''
        Modes in which to display possible completions.
        The kakoune default is <literal>[ "insert" "prompt" ]</literal>.
      '';
    };

    autoReload = mkOption {
      type = types.nullOr (types.enum [ "yes" "no" "ask" ]);
      default = null;
      description = ''
        Reload buffers when an external modification is detected.
        The kakoune default is <literal>"ask"</literal>.
      '';
    };

    scrollOff = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          lines = mkOption {
            type = types.ints.unsigned;
            default = 0;
            description = ''
              The number of lines to keep visible around the cursor.
            '';
          };

          columns = mkOption {
            type = types.ints.unsigned;
            default = 0;
            description = ''
              The number of columns to keep visible around the cursor.
            '';
          };
        };
      });
      default = null;
      description = ''
        How many lines and columns to keep visible around the cursor.
      '';
    };

    showMatching = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Highlight the matching char of the character under the
        selections' cursor using the <literal>MatchingChar</literal>
        face.
      '';
    };

    wrapLines = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          enable = mkEnableOption "the wrap lines highlighter";

          word = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Wrap at word boundaries instead of codepoint boundaries.
            '';
          };

          indent = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Preserve line indentation when wrapping.
            '';
          };

          maxWidth = mkOption {
            type = types.nullOr types.ints.unsigned;
            default = null;
            description = ''
              Wrap text at maxWidth, even if the window is wider.
            '';
          };

          marker = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "⏎";
            description = ''
              Prefix wrapped lines with marker text.
              If not <literal>null</literal>,
              the marker text will be displayed in the indentation if possible.
            '';
          };
        };
      });
      default = null;
      description = ''
        Settings for the wrap lines highlighter.
      '';
    };

    numberLines = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          enable = mkEnableOption "the number lines highlighter";

          relative = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Show line numbers relative to the main cursor line.
            '';
          };

          highlightCursor = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Highlight the cursor line with a separate face.
            '';
          };

          separator = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              String that separates the line number column from the
              buffer contents. The kakoune default is
              <literal>"|"</literal>.
            '';
          };
        };
      });
      default = null;
      description = ''
        Settings for the number lines highlighter.
      '';
    };

    showWhitespace = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          enable = mkEnableOption "the show whitespace highlighter";

          lineFeed = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              The character to display for line feeds.
              The kakoune default is <literal>"¬"</literal>.
            '';
          };

          space = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              The character to display for spaces.
              The kakoune default is <literal>"·"</literal>.
            '';
          };

          nonBreakingSpace = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              The character to display for non-breaking spaces.
              The kakoune default is <literal>"⍽"</literal>.
            '';
          };

          tab = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              The character to display for tabs.
              The kakoune default is <literal>"→"</literal>.
            '';
          };

          tabStop = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              The character to append to tabs to reach the width of a tabstop.
              The kakoune default is <literal>" "</literal>.
            '';
          };
        };
      });
      default = null;
      description = ''
        Settings for the show whitespaces highlighter.
      '';
    };

    keyMappings = mkOption {
      type = types.listOf keyMapping;
      default = [ ];
      description = ''
        User-defined key mappings. For documentation, see
        <link xlink:href="https://github.com/mawww/kakoune/blob/master/doc/pages/mapping.asciidoc"/>.
      '';
    };

  };

  fileType = types.submodule {
    options = {
      formatCmd = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The external command used to format this file type.
        '';
      };

      hooks = mkOption {
        type = types.listOf hook;
        default = [ ];
        description = ''
          Hooks for the file type. For documentation, see
          <link xlink:href="https://github.com/mawww/kakoune/blob/master/doc/pages/hooks.asciidoc"/>.
        '';
      };

    } // commonOptions;
  };

  hook = types.submodule {
    options = {

      name = mkOption {
        type = types.enum [
          "NormalBegin"
          "NormalIdle"
          "NormalEnd"
          "NormalKey"
          "InsertBegin"
          "InsertIdle"
          "InsertEnd"
          "InsertKey"
          "InsertChar"
          "InsertDelete"
          "InsertMove"
          "WinCreate"
          "WinClose"
          "WinResize"
          "WinDisplay"
          "WinSetOption"
          "BufSetOption"
          "BufNewFile"
          "BufOpenFile"
          "BufCreate"
          "BufWritePre"
          "BufWritePost"
          "BufReload"
          "BufClose"
          "BufOpenFifo"
          "BufReadFifo"
          "BufCloseFifo"
          "RuntimeError"
          "ModeChange"
          "PromptIdle"
          "GlobalSetOption"
          "KakBegin"
          "KakEnd"
          "FocusIn"
          "FocusOut"
          "RawKey"
          "InsertCompletionShow"
          "InsertCompletionHide"
          "InsertCompletionSelect"
          "ModuleLoaded"
        ];
        example = "SetOption";
        description = ''
          The name of the hook. For a description, see
          <link xlink:href="https://github.com/mawww/kakoune/blob/master/doc/pages/hooks.asciidoc#default-hooks"/>.
        '';
      };

      once = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Remove the hook after running it once.
        '';
      };

      group = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Add the hook to the named group.
        '';
      };

      option = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "filetype=latex";
        description = ''
          Additional option to pass to the hook.
        '';
      };

      extraBody = mkOption {
        type = types.lines;
        default = "";
        example = "set-option window indentwidth 2";
        description = ''
          Extra statements appended verbatim to the hook's body.
        '';
      };

      body = mkOption {
        type = types.nullOr (types.submodule { options = commonOptions; });
        default = null;
        description = ''
          The body of the hook.
        '';
      };
    };
  };

  keyMapping = types.submodule {
    options = {
      mode = mkOption {
        type = types.enum [
          "insert"
          "normal"
          "prompt"
          "menu"
          "user"
          "goto"
          "view"
          "object"
        ];
        example = "user";
        description = ''
          The mode in which the mapping takes effect.
        '';
      };

      docstring = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Optional documentation text to display in info boxes.
        '';
      };

      key = mkOption {
        type = types.str;
        example = "<a-x>";
        description = ''
          The key to be mapped. See
          <link xlink:href="https://github.com/mawww/kakoune/blob/master/doc/pages/mapping.asciidoc#mappable-keys"/>
          for possible values.
        '';
      };

      effect = mkOption {
        type = types.str;
        example = ":wq<ret>";
        description = ''
          The sequence of keys to be mapped.
        '';
      };
    };
  };

  configModule = types.submodule {
    options = {
      fileTypes = mkOption {
        type = types.attrsOf fileType;
        default = { };
        description = ''
          Configuration for individual file types.
        '';
      };

      colorScheme = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Set the color scheme. To see available schemes, enter
          <command>colorscheme</command> at the kakoune prompt.
        '';
      };

      ui = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            setTitle = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Change the title of the terminal emulator.
              '';
            };

            statusLine = mkOption {
              type = types.enum [ "top" "bottom" ];
              default = "bottom";
              description = ''
                Where to display the status line.
              '';
            };

            assistant = mkOption {
              type = types.enum [ "clippy" "cat" "dilbert" "none" ];
              default = "clippy";
              description = ''
                The assistant displayed in info boxes.
              '';
            };

            enableMouse = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to enable mouse support.
              '';
            };

            changeColors = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Change color palette.
              '';
            };

            wheelDownButton = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Button to send for wheel down events.
              '';
            };

            wheelUpButton = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ''
                Button to send for wheel up events.
              '';
            };

            shiftFunctionKeys = mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              description = ''
                Amount by which shifted function keys are offset. That
                is, if the terminal sends F13 for Shift-F1, this
                should be <literal>12</literal>.
              '';
            };

            useBuiltinKeyParser = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Bypass ncurses key parser and use an internal one.
              '';
            };
          };
        });
        default = null;
        description = ''
          Settings for the ncurses interface.
        '';
      };

      hooks = mkOption {
        type = types.listOf hook;
        default = [ ];
        description = ''
          Global hooks. For documentation, see
          <link xlink:href="https://github.com/mawww/kakoune/blob/master/doc/pages/hooks.asciidoc"/>.
        '';
      };

    } // commonOptions;
  };

  configFile = let
    wrapOptions = c:
      with c.wrapLines;
      concatStrings [
        "${optionalString word " -word"}"
        "${optionalString indent " -indent"}"
        "${optionalString (marker != null) " -marker ${marker}"}"
        "${optionalString (maxWidth != null) " -width ${toString maxWidth}"}"
      ];

    numberLinesOptions = c:
      with c.numberLines;
      concatStrings [
        "${optionalString relative " -relative "}"
        "${optionalString highlightCursor " -hlcursor"}"
        "${optionalString (separator != null) " -separator ${separator}"}"
      ];

    showWhitespaceOptions = c:
      with c.showWhitespace;
      concatStrings [
        (optionalString (tab != null) " -tab ${tab}")
        (optionalString (tabStop != null) " -tabpad ${tabStop}")
        (optionalString (space != null) " -spc ${space}")
        (optionalString (nonBreakingSpace != null) " -nbsp ${nonBreakingSpace}")
        (optionalString (lineFeed != null) " -lf ${lineFeed}")
      ];

    uiOptions = with cfg.config.ui;
      concatStringsSep "\n" (
        ["# UI options #"]
        ++ ["ncurses_set_title=${if setTitle then "true" else "false"}"]
        ++ ["ncurses_status_on_top=${
          if (statusLine == "top") then "true" else "false"
        }"]
        ++ ["ncurses_assistant=${assistant}"]
        ++ ["ncurses_enable_mouse=${if enableMouse then "true" else "false"}"]
        ++ ["ncurses_change_colors=${if changeColors then "true" else "false"}"]
        ++ (optional (wheelDownButton != null) "ncurses_wheel_down_button=${wheelDownButton}")
        ++ (optional (wheelUpButton != null) "ncurses_wheel_up_button=${wheelUpButton}")
        ++ (optional (shiftFunctionKeys != null) "ncurses_shift_function_key=${toString shiftFunctionKeys}")
        ++ ["ncurses_builtin_key_parser=${
          if useBuiltinKeyParser then "true" else "false"
        }"]
      );

    keyMappingString = scope: km:
      concatStringsSep " " [
        "map ${scope}"
        "${km.mode} ${km.key} '${km.effect}'"
        "${optionalString (km.docstring != null)
        "-docstring '${km.docstring}'"}"
      ];

    hookString = scope: h:
      concatStringsSep " " (
        ["hook"]
        ++ (optional (h.group != null) "-group ${group}")
        ++ (optional (h.once) "-once")
        ++ [scope]
        ++ [h.name]
        ++ (optional (h.option != null) h.option)
        ++ [(concatStringsSep "\n" (
           ["%{"]
            ++ (optional (h.body != null) (commonCfgStr scope h.body))
            ++ [h.extraBody]
            ++ ["}"]
           ))]
      );

    fileTypeString = f: c:
      concatStringsSep "\n" (
        ["hook window SetOption filetype=${f} %{"]
        ++ ["set-option window formatcmd ${c.formatCmd}"]
        ++ [(commonCfgStr "window" c)]
        ++ (map (hookString "window") c.hooks)
        ++ ["}\n"]
      );

    commonCfgStr = scope: c:
      with c;
      concatStringsSep "\n"
        ((optional (tabStop != null)
          "set-option ${scope} tabstop ${toString tabStop}")

        ++ (optional (indentWidth != null)
          "set-option ${scope} indentwidth ${toString indentWidth}")

        ++ (optional (!incrementalSearch)
          "set-option ${scope} incsearch false")

        ++ (optional (alignWithTabs) "set-option ${scope} aligntab true")

        ++ (optional (autoInfo != null)
          "set-option ${scope} autoinfo ${concatStringsSep "|" autoInfo}")

        ++ (optional (autoComplete != null)
          "set-option ${scope} autocomplete ${
            concatStringsSep "|" autoComplete
          }")

        ++ (optional (autoReload != null)
          "set-option ${scope} autoreload ${autoReload}")

        ++ (optional (wrapLines != null && wrapLines.enable)
          "add-highlighter ${scope}/ wrap${wrapOptions c}")

        ++ (optional (numberLines != null && numberLines.enable)
          "add-highlighter ${scope}/ number-lines${numberLinesOptions c}")

        ++ (optional showMatching "add-highlighter ${scope}/ show-matching")

        ++ (optional (showWhitespace != null && showWhitespace.enable)
          "add-highlighter ${scope}/ show-whitespaces${showWhitespaceOptions}")

        ++ (optional (scrollOff != null)
          "set-option ${scope} scrolloff ${toString scrollOff.lines},${toString scrollOff.columns}")

        ++ (optional (keyMappings != [])"\n# Key mappings #")
        ++ (map (keyMappingString scope) keyMappings));

    configString = concatStringsSep "\n" (
      ["# Generated by home-manager #"]
      ++ (optional (cfg.config.colorScheme != null)
        "colorscheme ${colorScheme}")

      ++ [(commonCfgStr "global" cfg.config)]
      ++ [uiOptions]
      ++ ["\n# File types #"]
      ++ (mapAttrsToList fileTypeString cfg.config.fileTypes)
      ++ [ "\n# Global hooks #" ]
      ++ (map (hookString "global") cfg.config.hooks)
      ++ (optional (cfg.extraConfig != "") "\n# Extra config #")
      ++ [ cfg.extraConfig ]);
  in pkgs.writeText "kakrc" (optionalString (cfg.config != null)
     configString);

in {
  options = {
    programs.kakoune = {
      enable = mkEnableOption "the kakoune text editor";

      config = mkOption {
        type = types.nullOr configModule;
        default = { };
        description = "kakoune configuration options.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration lines to add to
          <filename>~/.config/kak/kakrc</filename>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.kakoune ];
    xdg.configFile."kak/kakrc".source = configFile;
  };
}
