<div class="new_editor">
  <div class="ui">
    <a class="ui" href="/">Thread list</a>
    <a class="uir" target="_blank" href="/!sqlite">SQL console</a><a class="uir" href="/!settings">Settings</a>
  </div>
  <form id="editform" action="/!sqlite/" method="post">
    <p>SQL statement:</p>
    <textarea class="sql_editor" name="source" id="source">[source]</textarea>
    <div class="panel">
      <input type="submit" value="Exec" >
      <input type="reset" value="Revert" >
    </div>
  </form>
</div>