// define(['base/js/namespace'],function(IPython){

//     function _on_load(){

//     	var logHelloWorld = {
//     		help: 'Logs Hello World',
//     		icon : 'fa-recycle',
//     		help_index : '',
//     		handler : function (env) {
// 		        var on_success = undefined;
// 		        var on_error = undefined;
// 		        console.info('Hello World!');
//     		}
// 		}

// 		var key = IPython.keyboard_manager.actions.register(logHelloWorld, 'log-hello-world', 'hello-world')
//     	IPython.toolbar.add_buttons_group(['logHelloWorld'])
//     }

    

//     return {load_ipython_extension: _on_load };
// })

define(['base/js/namespace'], function(Jupyter) {
    function load_ipython_extension() {

        var handler = function () {
            console.info('Hello World!');
        };

        var action = {
            icon: 'fa-hand-paper-o', // a font-awesome class used on buttons, etc
            help    : 'Log Hello World',
            help_index : 'zz',
            handler : handler
        };
        var prefix = 'my_extension';
        var action_name = 'hello-world';

        var full_action_name = Jupyter.actions.register(action, action_name, prefix); // returns 'my_extension:show-alert'
        Jupyter.toolbar.add_buttons_group([full_action_name]);
    }

    return {
        load_ipython_extension: load_ipython_extension
    };
});