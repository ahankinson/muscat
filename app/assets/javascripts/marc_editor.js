function marc_editor_discard_changes_leaving( ) {
    if (marc_editor_form_changed) {
       return "The modifications on the title will be lost 2";
   }
}

// init the tags
// called from the edit_wide.rhtml partial
function marc_editor_init_tags( id ) {
    $(".sortable").sortable();

    /* Bind to the global railsAutocomplete. event, thrown when someone selects
       from an autocomplete field. It is a delegated method so dynamically added
       forms can handle it
    */
    $("#marc_editor_panel").on('railsAutocomplete.select', 'input.ui-autocomplete-input', function(event, data){
        input = $(event.target); // Get the autocomplete id

        // havigate up to the <li> and down to the hidden elem
        toplevel_li = input.parents("li");
        hidden = toplevel_li.children(".autocomplete_target")

        // the data-field in the hidden tells us which
        // field write in the input value. Default is id
        field = hidden.data("field")

        // Set the value from the id of the autocompleted elem
        if (data.item[field] == "") {
            alert("Please select a valid item from the list");
            input.val("");
            hidden.val("");
        } else {
            hidden.val(data.item[field]);
        }
    })

    // Add save and preview hotkeys
    $(document).on('keydown', null, 'alt+ctrl+s', function(){
        marc_editor_send_form('marc_editor_panel', marc_editor_get_model());
    });

    $(document).on('keydown', null, 'alt+ctrl+p', function(){
        marc_editor_show_hide_preview();
    });

    $(document).on('keydown', null, 'alt+ctrl+n', function(){
        window.location.href = "/" +  marc_editor_get_model() + "/new";
    });
}

function marc_editor_incipit(clef, keysig, timesig, incipit, target, width) {
    // width is option
    width = typeof width !== 'undefined' ? width : 720;

    pae = "@start:pae-file\n";
    pae = pae + "@clef:" + clef + "\n";
    pae = pae + "@keysig:" + keysig + "\n";
    pae = pae + "@key:\n";
    pae = pae + "@timesig:" + timesig + "\n";
    pae = pae + "@data: " + incipit + "\n";
    pae = pae + "@end:pae-file\n";

    // Do the call to the verovio helper
    render_music(pae, 'pae', target, width);
}

// This is the last non-ujs function remaining
// it is called when ckicking the "+" button
// near a repeatable field. It makes a copy
// of it
function marc_editor_add_subfield(id) {

    grid = id.parents("tr");
    //ul = grid.siblings(".repeating_subfield");
    ul = $(".repeating_subfield", grid);

    li_all = $("li", ul);

    li_original = $(li_all[li_all.length - 1]);

    new_li = li_original.clone();
    $(".serialize_marc", new_li).each(function() {
        $(this).val("");
    });

    ul.append(new_li);
    new_li.fadeIn('fast');

}

// Serialize marc to JSON and do an ajax call to save it
// Ajax sends back and URL tor erirect to
// or an error
function marc_editor_send_form(form_name, rails_model) {
    form = $('form', "#" + form_name);
    json_marc = serialize_marc_editor_form(form);

    url = "/admin/" + rails_model + "/marc_editor_save";

    // A bit of hardcoded stuff
    // block the main editor and sidebar
    $('#main_content').block({ message: "" });
    $('#sections_sidebar_section').block({ message: "Saving..." });

    $.ajax({
        success: function(data) {
            new_url = data.redirect;
            window.onbeforeunload = false;
            window.location.href = new_url;
        },
        data: {
            marc: JSON.stringify(json_marc),
            id: $('#id').val(),
            lock_version: $('#lock_version').val()
        },
        dataType: 'json',
        timeout: 20000,
        type: 'post',
        url: url,
        error: function (jqXHR, textStatus, errorThrown) {
                if (errorThrown == "Conflict") {
                    alert ("Error saving page: this is a stale version");

                    $('.flashes').empty();
                    $('<div/>', {
                        "class": 'flash flash_error',
                        text: 'This page will not be saved: STALE VERSION. Please reload.'
                    }).appendTo('.flashes');

                    $('#main_content').unblock();
                    $('#sections_sidebar_section').unblock();
                } else {
                    alert ("Error saving page! Please reload the page. ("
                            + textStatus + " "
                            + errorThrown + ")");
                }
        }
    });
}

function marc_editor_preview( source_form, destination, rails_model ) {
    form = $('form', "#" + source_form);
    json_marc = serialize_marc_editor_form(form);

    url = "/admin/" + rails_model + "/marc_editor_preview";

    $.ajax({
        success: function(data) {
            marc_editor_show_panel(destination);
        },
        data: {
            marc: JSON.stringify(json_marc),
            marc_editor_dest: destination,
            id: $('#id').val()
        },
        dataType: 'script',
        timeout: 20000,
        type: 'post',
        url: url,
        error: function (jqXHR, textStatus, errorThrown) {
            alert ("Error loading preview. ("
                    + textStatus + " "
                    + errorThrown);
        }
    });
}

function marc_editor_version( version_id, destination, rails_model ) {
    url = "/admin/" + rails_model + "/marc_editor_version";
    $("#" + destination).block({message: ""});

    $.ajax({
        success: function(data) {
            //marc_editor_show_panel(destination);
            $("#" + destination).unblock();
        },
        data: {
            marc_editor_dest: destination,
            version_id: version_id
        },
        dataType: 'script',
        timeout: 20000,
        type: 'post',
        url: url,
        error: function (jqXHR, textStatus, errorThrown) {
            alert ("Error loading version. ("
                    + textStatus + " "
                    + errorThrown);
        }
    });
}

function marc_editor_version_diff( version_id, destination, rails_model ) {
    url = "/admin/" + rails_model + "/marc_editor_version_diff";
    $("#" + destination).block({message: ""});

    $.ajax({
        success: function(data) {
            //marc_editor_show_panel(destination);
            $("#" + destination).unblock();
            $(".subfield_diff_content").each(function() {
                $(this).html( diffString( $(this).children('.diff_old').html(), $(this).children('.diff_new').html() ) );
            });
            $('#marc_editor_historic_view .panel').each(function(){
                if($(this).find(".version_diff").length == 0){
                    $(this).hide();
                }
            });


        },
        data: {
            marc_editor_dest: destination,
            version_id: version_id
        },
        dataType: 'script',
        timeout: 20000,
        type: 'post',
        url: url,
        error: function (jqXHR, textStatus, errorThrown) {
            alert ("Error loading diff. ("
                    + textStatus + " "
                    + errorThrown);
        }
    });
}

function marc_editor_cancel_form( ) {
    marc_editor_form_changed = true;
    var loc=location.href.substring(location.href.lastIndexOf("/"), -1);
    window.location=loc;
}

// Hardcoded for marc_editor_panel
function marc_editor_get_model() {
    return $("#marc_editor_panel").data("editor-model");
}

function marc_editor_show_hide_preview() {
    // Use the commodity function in marc_editor.js
    // model comes from the marc_editor_panel div
    model = marc_editor_get_model();

    if ($('#marc_editor_preview').not(':visible')) {
        // this function gets the show data via ajax
        // it will automatically hide the editor on success
        // or do nothing if there is an error
        marc_editor_preview('marc_editor_panel','marc_editor_preview', model);
    } else {
        marc_editor_show_panel("marc_editor_preview");
    }

    window.scrollTo(0, 0);
}

function marc_editor_show_panel(panel_name) {
    // Hide all the panels
    $(".panel-hidable").each(function() {
        $(this).hide();
    });

    $('#' + panel_name).show();
}
