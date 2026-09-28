# Как выложить Finance Midterm Trainer на Lovable с глобальным лидербордом

1. В Lovable создай новый проект и подключи **Supabase** (кнопка Supabase / Connect в проекте).
2. В Supabase открой **SQL Editor**, вставь содержимое `supabase_leaderboard.sql` и нажми Run.
3. В Supabase: **Project Settings → API**. Скопируй `Project URL` и `anon public` key.
4. Положи файл `index.html` из этой папки в проект Lovable как `public/game.html`
   (или попроси Lovable: «Serve public/game.html as the whole site at /»).
5. В начале `game.html`, перед первым `<script>`, добавь:

   ```html
   <script>window.LB_CONFIG={supabaseUrl:'https://ТВОЙ-ПРОЕКТ.supabase.co',supabaseKey:'ТВОЙ_ANON_KEY'};</script>
   ```

   Anon key можно держать в клиенте: доступ ограничен политиками RLS из SQL-файла.
6. Опубликуй проект. Во вкладке **Лидерборд** появится «Глобальный рейтинг подключён».
   Каждый игрок вводит ник, а результат сам обновляется после каждого дня в режиме МИКС.

Готовый промпт для Lovable:

> Add the attached static HTML file as public/game.html and make the site root (/) show it full-screen (redirect / to /game.html). Do not change the HTML file. Supabase is connected; I will run the SQL myself.
