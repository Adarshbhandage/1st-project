-- SmartFeed Schema v2 - WITH MESS CODES
-- COPY AND PASTE THIS INTO YOUR SUPABASE SQL EDITOR AND HIT RUN
-- This will WIPE old tables and recreate them cleanly.

-- Drop old tables (order matters due to foreign keys)
DROP TABLE IF EXISTS public.meal_attendance CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.messes CASCADE;

-- 1. Create messes table WITH unique join code
CREATE TABLE public.messes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  mess_code TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.messes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Messes are viewable by everyone." ON public.messes FOR SELECT USING (true);
CREATE POLICY "Anyone can create a mess." ON public.messes FOR INSERT WITH CHECK (true);

-- 2. Create user profiles (linking to Supabase Auth)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT CHECK (role IN ('student', 'owner')) NOT NULL,
  mess_id UUID REFERENCES public.messes(id) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Anyone can insert a profile." ON public.profiles FOR INSERT WITH CHECK (true);

-- 3. Create meal attendance table (real-time data)
CREATE TABLE public.meal_attendance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  mess_id UUID REFERENCES public.messes(id) NOT NULL,
  meal_type TEXT CHECK (meal_type IN ('b', 'l', 'd')) NOT NULL,
  meal_date DATE NOT NULL,
  status TEXT CHECK (status IN ('yes', 'no')) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(student_id, meal_type, meal_date)
);

ALTER TABLE public.meal_attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Meal attendance is viewable by everyone." ON public.meal_attendance FOR SELECT USING (true);
CREATE POLICY "Students can insert their own attendance." ON public.meal_attendance FOR INSERT WITH CHECK (true);
CREATE POLICY "Students can update their own attendance." ON public.meal_attendance FOR UPDATE USING (true);

-- 4. Enable Realtime on meal_attendance
DROP PUBLICATION IF EXISTS supabase_realtime;
CREATE PUBLICATION supabase_realtime;
ALTER PUBLICATION supabase_realtime ADD TABLE public.meal_attendance;

-- 5. Daily Menus (owner sets what's being served)
CREATE TABLE public.daily_menus (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mess_id UUID REFERENCES public.messes(id) NOT NULL,
  meal_date DATE NOT NULL,
  meal_type TEXT CHECK (meal_type IN ('b', 'l', 'd')) NOT NULL,
  menu_text TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(mess_id, meal_date, meal_type)
);

ALTER TABLE public.daily_menus ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Menus are viewable by everyone." ON public.daily_menus FOR SELECT USING (true);
CREATE POLICY "Anyone can insert menus." ON public.daily_menus FOR INSERT WITH CHECK (true);
CREATE POLICY "Anyone can update menus." ON public.daily_menus FOR UPDATE USING (true);
