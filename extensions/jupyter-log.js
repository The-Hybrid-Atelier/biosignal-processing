// Jupyter Notebook extension that logs various cell data on user generated events

// Most of my code borrows heavily from: 
// https://github.com/ipython-contrib/jupyter_contrib_nbextensions/blob/master/src/jupyter_contrib_nbextensions/nbextensions/execute_time/ExecuteTime.js

// define([...], function(...) {..}) syntax is needed for require.js
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
        // This function is executed when the bug button is clicked
        // Should ideally set everything up and bind all events/callbacks
        var log_handler = function () {
            // TODO: Turn logging on and off when button is toggled

            console.info('Logging Extension Loaded');

            // TODO: Figure out what other events are defined in Jupyter codebase
            // (I stole this one from ExecuteTime.js and can't figure out how to console hack the rest)
            //
            // Idea: if certain events (e.g. change selected cell, cell generates output vs. no output), are well-defined
            // in Juptyer, then we won't have to hack away at jQuery events to infer what happened
            //
            // However, jQuery events might be useful for timing/rhythms
            //
            // Other events I know of from ExecuteTime.js: notebook_loaded.Notebook, kernel_restarting.Kernel
            events.on('execute.CodeCell', log_cell_data_and_update);


            // TODO: Define a full hierarchy of events (here is a rough draft):
            //
            // MICRO EVENTS (events we can easily collect in JS):
            // - clicks
            // - keypresses
            // - cell execution
            // + more if we figure out Jupyter events (e.g. switch active cell, kernel restart, new cell)
            // + cell contents, time stamp for each event
            //
            // MACRO EVENTS (things we want to infer from micro actions):
            // - clicks
            //     - move_cursor (within cell)
            //     - switch_cell
            // - copy / paste
            //     - word
            //     - line
            //     - block
            //     + source
            //         - within codebase
            //         - outside codebase
            //             - stackoverflow
            //             - piazza
            // - comment / uncomment
            //     - line
            //     - block
            // - undo / redo
            // - execute cell
            //     - success / error
            // - twiddles (how to define?)


            // TODO: Define a data structure that captures entire notebook
            // This might already be predefined in Jupyter.notebook
            // 
            // should contain:
            // - list of cells with cell types
            // - cell contents
            // - cell outputs

            // IDEA
            // Each micro event logs a JSON file, something like
            // log = {type: <event_type>, 
            //        data: <notebook_data>}
            // 
            // From these logs we could then infer the macro events with post-processing, but my goal 
            // is to make the micro events as coarse/rich as possible

            function log_cell_data_and_update(evt, data) {
                // Logs cell data 
                var cell = data.cell;
                console.log(cell.get_text())

                cells = Jupyter.notebook.get_cells()

                for (var i = 0; i < cells.length; i++) {
                    var cell = cells[i];

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
                        // presumably text on each line, etc.

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
                }
                
            }
        };

        // Defines button object
        var action = {
            icon: 'fa-bug', // a font-awesome class used on buttons, etc
            help    : 'Log Hello World',
            help_index : 'zz',
            handler : log_handler
        };
        var prefix = 'my_extension';
        var action_name = 'log-data';

        // Binds action to button and adds button to toolbar
        var full_action_name = Jupyter.actions.register(action, action_name, prefix); // returns 'my_extension:show-alert'
        Jupyter.toolbar.add_buttons_group([full_action_name]);
    }

    return {
        load_ipython_extension: load_ipython_extension
    };
});