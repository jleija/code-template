local template = require("template")()

local test_text = [=[
    [[double bracket]]
    zero indent

    |->
    post indent
    A |->
    B |->
    C
    B <-|
    A <-|

    pre indent
    A
    |->B
    |->C
    <-|B
    <-|A

    indent and unindent
    |->A<-|
    |->B<-|
    |->C<-|
    <-|

    multi-indent
    A |->>
    B |->>
    C
    B <<-|
    C <<-|

    expressions+indentation
    <% a + b %>
    |-><% a + b %>
    |-> <% a + b %>
    <% a + b %><-|
    <% a + b %> <-|

    <% a %> + <% b %> = <% a + b %>  |->
    <% a %> + <% b %> = <% a + b %>  
    <% a %> + <% b %> = <% a + b %>  <-|

    indents and loops
    <? for i = 1,3 do ?>
        i = <% i %>
    <? end ?>

    <? for i = 1,3 do ?>|->
        i = <% i %>
    <? end ?>

    |->
    <? for i = 1,3 do ?>
        i = <% i %> <-|
    <? end ?>

    <-|
    <? for i = 1,3 do ?>
     |->i = <% i %>
    <? end ?>

    |->
    <? for i = 1,3 do ?>
     <-|i = <% i %>
    <? end ?>

    nested/sub templates
    begin
    <% apply_template(nested_message) %>
    end
]=]

local vars = { 
    a = 1, 
    b = 2,
    nested_message = [[
        ^ at parent identation level
        |->one more indentation in nested template application
        |->
        ... and two indentations 
        <<-| ^ (undo sub/nested indentations) ]],
    apply_template = function(txt)
        return template(txt, {})
    end
}

print(template(test_text, vars))

