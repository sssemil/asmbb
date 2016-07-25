<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>[special:title]</title>
  <link rel="stylesheet" href="/templates/all.css">

  <link rel="apple-touch-icon" sizes="57x57" href="/images/favicons/apple-touch-icon-57x57.png">
  <link rel="apple-touch-icon" sizes="60x60" href="/images/favicons/apple-touch-icon-60x60.png">
  <link rel="apple-touch-icon" sizes="72x72" href="/images/favicons/apple-touch-icon-72x72.png">
  <link rel="apple-touch-icon" sizes="76x76" href="/images/favicons/apple-touch-icon-76x76.png">
  <link rel="apple-touch-icon" sizes="114x114" href="/images/favicons/apple-touch-icon-114x114.png">
  <link rel="apple-touch-icon" sizes="120x120" href="/images/favicons/apple-touch-icon-120x120.png">
  <link rel="apple-touch-icon" sizes="144x144" href="/images/favicons/apple-touch-icon-144x144.png">
  <link rel="apple-touch-icon" sizes="152x152" href="/images/favicons/apple-touch-icon-152x152.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/images/favicons/apple-touch-icon-180x180.png">
  <link rel="icon" type="image/png" href="/images/favicons/favicon-32x32.png" sizes="32x32">
  <link rel="icon" type="image/png" href="/images/favicons/favicon-194x194.png" sizes="194x194">
  <link rel="icon" type="image/png" href="/images/favicons/favicon-96x96.png" sizes="96x96">
  <link rel="icon" type="image/png" href="/images/favicons/android-chrome-192x192.png" sizes="192x192">
  <link rel="icon" type="image/png" href="/images/favicons/favicon-16x16.png" sizes="16x16">
  <link rel="manifest" href="/images/favicons/manifest.json">
  <link rel="mask-icon" href="/images/favicons/safari-pinned-tab.svg" color="#d80027">
  <link rel="shortcut icon" href="/images/favicons/favicon.ico">
  <meta name="msapplication-TileColor" content="#ffffff">
  <meta name="msapplication-TileImage" content="/images/favicons/mstile-144x144.png">
  <meta name="msapplication-config" content="/images/favicons/browserconfig.xml">
  <meta name="theme-color" content="#d80027">

  <meta name="majestic-site-verification" content="MJ12_bc129603-7485-4ef7-926e-5107cec9b5de">
</head>

<body>
  <div class="header">
    <div class="login_interface">
      [case:[special:userid]|<a href="/!login/">Login</a><br><a href="/!register/">Register</a>|
      <a href="/!logout">Logout ( [special:username] )</a><br><a href="/!userinfo/[special:username]">User profile</a>]
    </div>
    <form class="tags" id="search_form" action="[case:[special:dir][special:thread]|/|[case:[special:search]||../]]!search/" method="get" >
      <input class="search_line" type="edit" size="40" name="s" placeholder="search" value="[special:search]"><input class="icon_btn"  type="image" src="/images/search.svg" alt="?" >
    </form>
    <h1>AsmBB demo</h1>
  </div>

<div class="tags"><a class="taglink" title="Show all threads" href="/"><img src="/images/posts.svg" alt="All"></a>[special:alltags]</div>

