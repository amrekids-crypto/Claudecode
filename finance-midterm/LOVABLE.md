# Как выложить Finance Midterm Trainer на Lovable (лидерборд + облачное сохранение)

Схема та же, что в морском бое: статичный HTML на Lovable и Supabase как база.

1. В Lovable создай проект и подключи **Supabase** (кнопка Supabase / Connect).
2. В Supabase открой **SQL Editor**, вставь весь `supabase_leaderboard.sql` и нажми **Run**.
   Скрипт создаёт таблицу `leaderboard` и закрытую таблицу `cloud_saves` с функциями
   `cloud_login`, `cloud_save`, `cloud_load`. Запускать повторно безопасно.
3. В Supabase: **Project Settings → API**. Скопируй `Project URL` и `anon public` key.
4. Положи `index.html` из этой папки в проект Lovable как `public/game.html`.
5. В `game.html` перед первым `<script>` добавь строку:

   ```html
   <script>window.LB_CONFIG={supabaseUrl:'https://ТВОЙ-ПРОЕКТ.supabase.co',supabaseKey:'ТВОЙ_ANON_KEY'};</script>
   ```

   Anon key можно держать в клиенте: лидерборд защищён политиками RLS, а таблица
   сохранений вообще закрыта для прямого доступа, с ней работают только функции.
6. Опубликуй проект.

Что получит игрок во вкладке **Лидерборд**:

- **Аккаунт**: ник + PIN из 4–12 цифр. Если ник свободен, аккаунт создаётся, если занят, нужен его PIN.
  После 5 неверных PIN подряд вход по этому нику блокируется на 15 минут.
- **Облачное сохранение**: весь прогресс (игра, профиль и внешность инспектора, питомец, альбом,
  достижения, тесты, карточки, ошибки) сохраняется сам каждые 20 секунд при изменениях и при
  закрытии вкладки. Есть кнопки «Сохранить сейчас» и «Загрузить из облака».
- **Другое устройство**: вход с тем же ником и PIN подтягивает прогресс. Если на устройстве уже есть
  свой прогресс, игра спросит, какой оставить. При открытии страницы более новая облачная версия
  подгружается сама.
- **Лидерборд**: ник аккаунта автоматически становится ником в рейтинге, результат обновляется после
  каждого игрового дня.

Готовый промпт для Lovable:

> Add the attached static HTML file as public/game.html and make the site root (/) show it full-screen (redirect / to /game.html). Do not change the HTML file except adding the LB_CONFIG script line I give you before the first script tag. Supabase is connected; I will run the SQL myself.
