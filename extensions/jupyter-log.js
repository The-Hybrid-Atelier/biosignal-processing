// Jupyter Notebook extension that logs various cell data on user generated events

// Most of my code borrows heavily from: 
// https://github.com/ipython-contrib/jupyter_contrib_nbextensions/blob/master/src/jupyter_contrib_nbextensions/nbextensions/execute_time/ExecuteTime.js

// define([...], function(...) {..}) syntax is needed for require.js

var loggingEnabled = false

define([
    'require',
    'jquery',
    'base/js/namespace',
    'base/js/events',
    'notebook/js/codecell'
], function (
    requirejs,
    $,
    Jupyter,
    events,
    codecell
) {
    function load_ipython_extension() {

        var logData = [] // list log file that eventually gets saved to disk

        // This function is executed when the bug button is clicked
        // Should ideally set everything up and bind all events/callbacks
        var logHandler = function () {

            // TODO: Turn logging on and off when button is toggled
            // this doesn't work because events are bound
            // need to find a way to easy bind and unbind

            loggingEnabled = !loggingEnabled

            if (!loggingEnabled) {
                console.info('Logging disabled')
                // unbind events
                return
            }

            console.info('Logging Extension Loaded');

            // TODO: Figure out what other events are defined in Jupyter codebase
            // (I stole this one from ExecuteTime.js and can't figure out how to console hack the rest)
            //
            // Idea: if certain events (e.g. change selected cell, cell generates output vs. no output), are well-defined
            // in Juptyer, then we won't have to mine jQuery events to infer what happened. However, jQuery events 
            // might be useful for timing/rhythms.
            //
            // Other events I know of from ExecuteTime.js: notebook_loaded.Notebook, kernel_restarting.Kernel
            events.on('execute.CodeCell', logCellDataAndUpdate);

            // This function gets called every time a cell is executed. 
            // Each event should append to 
            function logCellDataAndUpdate(evt, data) {
                // Logs cell inner text content
                var cell = data.cell;
                console.log(cell.get_text())

                cells = Jupyter.notebook.get_cells() // gets all cell objects in notebook

                for (var i = 0; i < cells.length; i++) { // iterates through all sells
                    var cell = cells[i]; 


                    // TODO: Define a full hierarchy of events and how to classify each
                    // below are some starters

                    // Get text content of a cell (does not log output)
                        // console.log(cell.get_text())

                        // Jupyter.notebook.get_cell_element(i)[0].innerText
                        // --> returns full HTML text of cell, including Input and Output


                    // Get cursor position (within selected cell)
                        // cell.get_pre_cursor()
                        // cell.get_cursor_cursor()
                        //
                        // e.g. "def fn|(x):"
                        //     pre --> "def fn"
                        //     post --> "(x)"

                    // TODO: look into what this does, seems useful
                        // cell.bind_events()

                    // Get input div element (HTML)
                        // cell.input 

                    // Get underlying CodeMirror object
                        // cell.code_mirror 
                        //
                        // gives access to underlying CodeMirror library, including line counts
                        // presumably text on each line, etc. Could be useful?

                    if (cell instanceof codecell.CodeCell) {
                        var ce = cell.element;

                        // Bind jQuery events to a cell
                        // Is there a more efficient way of doing this?
                        $(ce).unbind()
                        $(ce).on("click mousedown mouseup keydown change",function(e) {
                            console.log(e);

                            // TODO: Break down jQuery events into subevents
                            // e.g.
                            // if 'click' --> did they change cells? change cursor? 
                            // if 'keydown' --> copy/paste? delete? undo/redo? type?

                        });
                    }

                    // dummy log data that will be pushed to master log that is saved later
                    log = {"type": "test", 
                            "time": Date.now()
                            "data": [0, 0, 0]}

                    logData.push(log)
                }
            }
        };

        // Defines log button
        var log_action = {
            icon: 'fa-bug', // a font-awesome class used on buttons, https://fontawesome.com/icons
            help    : 'Log Jupyter Actions',
            help_index : 'z',
            handler : logHandler
        };
        var prefix = 'a';
        var log_action_name = 'log-data';

        // Binds action to button and adds button to toolbar
        var full_log_action_name = Jupyter.actions.register(log_action, log_action_name, prefix); // returns 'my_extension:show-alert'
        Jupyter.toolbar.add_buttons_group([full_log_action_name]);

        // Function that is called when save button is pressed
        var saveLog = function () {
            var data = JSON.stringify(logData, null, 4) // converts JSON to string
            var blob = new File([data], {type: "application/json;charset=utf-8"});
            var timestamp = Date.now().toString()
            saveAs(blob, "log_data_" + timestamp + ".json");
        }

        // Defines save button
        var save_action = {
            icon: 'fa-save', // we should probably use a different icon – already in use
            help    : 'Save Jupyter logs',
            help_index : 'zz',
            handler : saveLog
        };
        var prefix = 'b';
        var save_action_name = 'log-data';

        // Binds action to button and adds button to toolbar
        var full_save_action_name = Jupyter.actions.register(save_action, save_action_name, prefix); // returns 'my_extension:show-alert'
        Jupyter.toolbar.add_buttons_group([full_save_action_name]);
    }

    return {
        load_ipython_extension: load_ipython_extension
    };
});

// TODO: how to include/require FileSaver.js without copy-paste
// source: https://github.com/eligrey/FileSaver.js/blob/master/src/FileSaver.js

var saveAs = saveAs || (function(view) {
    "use strict";
    // IE <10 is explicitly unsupported
    if (typeof view === "undefined" || typeof navigator !== "undefined" && /MSIE [1-9]\./.test(navigator.userAgent)) {
        return;
    }
    var
          doc = view.document
          // only get URL when necessary in case Blob.js hasn't overridden it yet
        , get_URL = function() {
            return view.URL || view.webkitURL || view;
        }
        , save_link = doc.createElementNS("http://www.w3.org/1999/xhtml", "a")
        , can_use_save_link = "download" in save_link
        , click = function(node) {
            var event = new MouseEvent("click");
            node.dispatchEvent(event);
        }
        , is_safari = /constructor/i.test(view.HTMLElement) || view.safari
        , is_chrome_ios =/CriOS\/[\d]+/.test(navigator.userAgent)
        , setImmediate = view.setImmediate || view.setTimeout
        , throw_outside = function(ex) {
            setImmediate(function() {
                throw ex;
            }, 0);
        }
        , force_saveable_type = "application/octet-stream"
        // the Blob API is fundamentally broken as there is no "downloadfinished" event to subscribe to
        , arbitrary_revoke_timeout = 1000 * 40 // in ms
        , revoke = function(file) {
            var revoker = function() {
                if (typeof file === "string") { // file is an object URL
                    get_URL().revokeObjectURL(file);
                } else { // file is a File
                    file.remove();
                }
            };
            setTimeout(revoker, arbitrary_revoke_timeout);
        }
        , dispatch = function(filesaver, event_types, event) {
            event_types = [].concat(event_types);
            var i = event_types.length;
            while (i--) {
                var listener = filesaver["on" + event_types[i]];
                if (typeof listener === "function") {
                    try {
                        listener.call(filesaver, event || filesaver);
                    } catch (ex) {
                        throw_outside(ex);
                    }
                }
            }
        }
        , auto_bom = function(blob) {
            // prepend BOM for UTF-8 XML and text/* types (including HTML)
            // note: your browser will automatically convert UTF-16 U+FEFF to EF BB BF
            if (/^\s*(?:text\/\S*|application\/xml|\S*\/\S*\+xml)\s*;.*charset\s*=\s*utf-8/i.test(blob.type)) {
                return new Blob([String.fromCharCode(0xFEFF), blob], {type: blob.type});
            }
            return blob;
        }
        , FileSaver = function(blob, name, no_auto_bom) {
            if (!no_auto_bom) {
                blob = auto_bom(blob);
            }
            // First try a.download, then web filesystem, then object URLs
            var
                  filesaver = this
                , type = blob.type
                , force = type === force_saveable_type
                , object_url
                , dispatch_all = function() {
                    dispatch(filesaver, "writestart progress write writeend".split(" "));
                }
                // on any filesys errors revert to saving with object URLs
                , fs_error = function() {
                    if ((is_chrome_ios || (force && is_safari)) && view.FileReader) {
                        // Safari doesn't allow downloading of blob urls
                        var reader = new FileReader();
                        reader.onloadend = function() {
                            var url = is_chrome_ios ? reader.result : reader.result.replace(/^data:[^;]*;/, 'data:attachment/file;');
                            var popup = view.open(url, '_blank');
                            if(!popup) view.location.href = url;
                            url=undefined; // release reference before dispatching
                            filesaver.readyState = filesaver.DONE;
                            dispatch_all();
                        };
                        reader.readAsDataURL(blob);
                        filesaver.readyState = filesaver.INIT;
                        return;
                    }
                    // don't create more object URLs than needed
                    if (!object_url) {
                        object_url = get_URL().createObjectURL(blob);
                    }
                    if (force) {
                        view.location.href = object_url;
                    } else {
                        var opened = view.open(object_url, "_blank");
                        if (!opened) {
                            // Apple does not allow window.open, see https://developer.apple.com/library/safari/documentation/Tools/Conceptual/SafariExtensionGuide/WorkingwithWindowsandTabs/WorkingwithWindowsandTabs.html
                            view.location.href = object_url;
                        }
                    }
                    filesaver.readyState = filesaver.DONE;
                    dispatch_all();
                    revoke(object_url);
                }
            ;
            filesaver.readyState = filesaver.INIT;

            if (can_use_save_link) {
                object_url = get_URL().createObjectURL(blob);
                setImmediate(function() {
                    save_link.href = object_url;
                    save_link.download = name;
                    click(save_link);
                    dispatch_all();
                    revoke(object_url);
                    filesaver.readyState = filesaver.DONE;
                }, 0);
                return;
            }

            fs_error();
        }
        , FS_proto = FileSaver.prototype
        , saveAs = function(blob, name, no_auto_bom) {
            return new FileSaver(blob, name || blob.name || "download", no_auto_bom);
        }
    ;

    // IE 10+ (native saveAs)
    if (typeof navigator !== "undefined" && navigator.msSaveOrOpenBlob) {
        return function(blob, name, no_auto_bom) {
            name = name || blob.name || "download";

            if (!no_auto_bom) {
                blob = auto_bom(blob);
            }
            return navigator.msSaveOrOpenBlob(blob, name);
        };
    }

    // todo: detect chrome extensions & packaged apps
    //save_link.target = "_blank";

    FS_proto.abort = function(){};
    FS_proto.readyState = FS_proto.INIT = 0;
    FS_proto.WRITING = 1;
    FS_proto.DONE = 2;

    FS_proto.error =
    FS_proto.onwritestart =
    FS_proto.onprogress =
    FS_proto.onwrite =
    FS_proto.onabort =
    FS_proto.onerror =
    FS_proto.onwriteend =
        null;

    return saveAs;
}(
       typeof self !== "undefined" && self
    || typeof window !== "undefined" && window
    || this
));