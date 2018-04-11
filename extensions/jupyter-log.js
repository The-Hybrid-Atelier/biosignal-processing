// Jupyter Notebook extension that logs various cell data on user generated events
// Borrows heavily from: 
// https://github.com/ipython-contrib/jupyter_contrib_nbextensions/blob/master/src/jupyter_contrib_nbextensions/nbextensions/execute_time/ExecuteTime.js


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

        var log_handler = function () {
            console.info('Logging Extension Loaded');
            // console.log(Jupyter.notebook)

            events.on('execute.CodeCell', log_cell_data_and_update);

            update_cells()


            function log_cell_data_and_update(evt, data) {
                var cell = data.cell;
                console.log(cell.get_text())

                // Log cursor position
                // cell.get_post_cursor()
                // cell.get_pre_cursor()

                // Need to look into what this does ?
                // cell.bind_events()

                // Gives you input div element
                // cell.input 

                // var i = <cell index> how to get??
                // Jupyter.notebook.get_cell_element(i)[0].innerText

                // cell.code_mirror 
                // gives access to underlying CodeMirror library, including line counts
                // presumably text on each line, etc.

                update_cells()
            }

            function update_cells(evt, data) {
                console.log('Updating Cells')
                cells = Jupyter.notebook.get_cells()

                for (var i = 0; i < cells.length; i++) {
                    var cell = cells[i];

                    // How to get text content of a cell
                    //console.log(cell.get_text())

                    // How to bind jQuery events to a cell - fires all events right now
                    // https://stackoverflow.com/questions/7439570/how-do-you-log-all-events-fired-by-an-element-in-jquery
                    if (cell instanceof codecell.CodeCell) {
                        var ce = cell.element;

                        $(ce).on("click mousedown mouseup focus blur keydown change",function(e) {
                            console.log(e);
                        });
                    }
                }
            }

        };

        var action = {
            icon: 'fa-bug', // a font-awesome class used on buttons, etc
            help    : 'Log Hello World',
            help_index : 'zz',
            handler : log_handler
        };
        var prefix = 'my_extension';
        var action_name = 'log-data';

        var full_action_name = Jupyter.actions.register(action, action_name, prefix); // returns 'my_extension:show-alert'
        Jupyter.toolbar.add_buttons_group([full_action_name]);
    }

    return {
        load_ipython_extension: load_ipython_extension
    };
});