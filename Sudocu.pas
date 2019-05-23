{Данная курсовая работа написана студентом УрТИСИ СибГУТИ первого курса, группы ПЕ-81б
 Мирославским Игорем Станиславовичем (Весна 2019-го года) в качестве курсового проекта}

{$reference System.Windows.Forms.dll}
Uses GraphABC,ABCObjects,ABCButtons,System.Windows.Forms, System.Threading;
Const B=10; //Количество кнопок
Type SudokuGrid=array[1..9,1..9] of byte;         //Тип массива "матрица обработки судоку"
     SquareMas =array[1..9, 1..9] of SquareABC;   //Тип массива "графические квадраты"
     SudokuSolver=array[1..9,1..9,1..10] of byte; //Тип массива "куб генерации"
var Buttons: array[1..B] of ButtonABC;            //Массив для хранения кнопок (нужен для их быстрого удаления)
    MasStartData: SudokuGrid;                     //Массив хранящий начальные значения
    MasGameData : SudokuGrid;                     //Массив хранящий все значения игрового поля
    Cell        : SquareMas;                      //Массив хранящий все графические клетки игрового поля
    Numbers     : array[1..9] of ButtonABC;       //Массив кнопок ввода цифры
    Menu        : ButtonABC;                      //Кнопка возвращения в меню. Нужна как локальная переменная, т.к часто задействуется
    Background  : PictureABC;                     //Игровой фон
    SetOfHelp   : byte;                           //Переменная хранящая количество начальных значений (подсказок)
    Lx,Ly,Li,Lj : byte;                           //Хранилища последних координат на граф. поле и в матрице (нужно для ввода цифры)
    AllRight    : Boolean;                        //Соответствует ли поле условиям судоку?
    InGame      : Boolean;                        //Игрок начал игру?
    InCheck     : Boolean;                        //Игрок начал проверку?
    InDifMenu   : Boolean;                        //Игрок выбирает сложность?
    BackIsEmpty : Boolean;                        //Фон был выбрат?
    DifValue    : byte;                           //Значение выбранной сложности


{----------------------------------------------------Консольная генерация игрового варианта----------------------------------------------------}

Procedure CheckSquare(Board:SudokuGrid; var CheckResult: boolean); //Проверка по квадратам 3 на 3 (из которых состоит игровое поле)
{Параметры процедуры:
 Board - массив хранящий данные о начальных цифрах на игровом поле (игровой вариант)
 CheckResult - переменная результата проверки генерации}
begin
var Sq3na3  : array[1..3,1..3] of byte; //Массив хранящий значения квадрата 3 на 3. Нужен для поиска одинаковых элементов в нём
var LineMas : array[1..9] of byte; //Массив для более быстрой проверки одинаковости
var n: byte; //Переменная "c" - счётчик просмотренных квадратов
 for var c:=1 to 9 do //Прогон каждого квадрата
  begin
   case c of //Заполнение квадрата проверки данными в соответствии с его расположением на поле
   {1|2|3
    4|5|6
    7|8|9}
    1: for var i:=1 to 3 do
        for var j:=1 to 3 do
         Sq3na3[i,j]:=Board[i,j];
    2: for var i:=1 to 3 do
        for var j:=1 to 3 do
         Sq3na3[i,j]:=Board[i,j+3];
    3: for var i:=1 to 3 do
        for var j:=1 to 3 do
         Sq3na3[i,j]:=Board[i,j+6];
    4: for var i:=1 to 3 do
        for var j:=1 to 3 do
         Sq3na3[i,j]:=Board[i+3,j];
    5: for var i:=1 to 3 do
        for var j:=1 to 3 do
         Sq3na3[i,j]:=Board[i+3,j+3];
    6: for var i:=1 to 3 do
        for var j:=1 to 3 do
         Sq3na3[i,j]:=Board[i+3,j+6];
    7: for var i:=1 to 3 do
        for var j:=1 to 3 do
         Sq3na3[i,j]:=Board[i+6,j];
    8: for var i:=1 to 3 do
        for var j:=1 to 3 do
         Sq3na3[i,j]:=Board[i+6,j+3];
    9: for var i:=1 to 3 do
        for var j:=1 to 3 do
         Sq3na3[i,j]:=Board[i+6,j+6]; 
   end;
   n:=0;
   {Перевод двумерного массива в одномерный.
    Оптимизирует проверку}
    for var i:=1 to 3 do
     for var j:=1 to 3 do
      begin
       inc(n);
       LineMas[n]:=Sq3na3[i,j];
      end;
    {Непосредственно проверка}
    for var i:=1 to 8 do 
     for var j:=i+1 to 9 do 
      if (LineMas[i] = LineMas[j]) and (LineMas[i]<>0) then 
       begin
        CheckResult:=False;
        exit
       end;
  end;
end;

Procedure CheckCross(Board:SudokuGrid; var CheckResult: boolean);
{Поклеточная проверка по направлениям "Вверх, вниз, влево, вправо", от проверяемой клетки
 Параметры процедуры:
 Board - массив хранящий данные о начальных цифрах на игровом поле (игровой вариант)
 CheckResult - переменная результата проверки генерации}
begin
var x,y:byte;  //"x" и "y" - переменные хранящие значения перемещений проверки по полю
 for var i:=1 to 9 do
  begin
   for var j:=1 to 9 do
    begin
     if CheckResult=False then exit; //Если обнаружены повторы - выход из процедуры
     if i>1 then //Проверка по столбцу: все ячейки над клеткой
      begin
       x:=j;   y:=i;
       repeat
        dec(y);
        if (Board[y,x]=Board[i,j]) and (Board[i,j]<>0) then
           CheckResult:=False;
       until (y=1) or (CheckResult=False);
      end;
     if CheckResult=False then exit; //Если обнаружены повторы - выход из процедуры
   
     if (i<9) and (CheckResult=True) then //Проверка по столбцу: все ячейки под клеткой
      begin
       x:=j;   y:=i;
       repeat
        inc(y);
        if (Board[y,x]=Board[i,j]) and (Board[i,j]<>0)  then
           CheckResult:=False;
       until (y=9) or (CheckResult=False);
      end;
     if CheckResult=False then exit; //Если обнаружены повторы - выход из процедуры

     if (j>1) and (CheckResult=True) then //Проверка по строчке: все ячейки слева от клетки
      begin
       x:=j;   y:=i;
       repeat
        dec(x);
        if (Board[y,x]=Board[i,j]) and (Board[i,j]<>0)  then
           CheckResult:=False;
       until (x=1) or (CheckResult=False);
      end;
     if CheckResult=False then exit; //Если обнаружены повторы - выход из процедуры

     if (j<9) and (CheckResult=True) then //Проверка по строчке: все ячейки справа от клетки
      begin
       x:=j;   y:=i;
       repeat
        inc(x);
        if (Board[y,x]=Board[i,j]) and (Board[i,j]<>0)  then
           CheckResult:=False;
       until (x=9) or (CheckResult=False);
      end;
     if CheckResult=False then exit; //Если обнаружены повторы - выход из процедуры
    end;
   end;
end;

Procedure SolvingGeneration(var Cube:SudokuSolver; LastI,LastJ:byte; var TheEnd:Boolean; Add:Boolean);
{Прорешивание пустого поля для составления матрицы судоку, имеющей как минимум одно решение (но их может быть и больше)}
begin
 if TheEnd=False then
  begin
   var d:byte;
   var i:byte:=LastI;
   var j:byte:=LastJ;
   if Add=True then //Если переход идёт на следующую клетку
    begin
     inc(i);
     d:=1;
     if i=10 then
      begin
       i:=1;
       inc(j);
      end;
    end
   else //То есть если переход идёт на предыдущую клетку (Add=False)
    begin
     dec(i);
     if i=0 then
      begin
       i:=9;
       dec(j);
      end;
    end;
   if j=10 then TheEnd:=True;
   if TheEnd=False then
    begin
     if Add=True then
      for var c:=2 to 10 do Cube[i,j,c]:=0 //Обнуление актуального массива ошибок
     else
      begin
       for var c:=2 to 10 do //Число проверяется на ошибочность (есть ли оно в массиве ошибок?)
        begin
         if Cube[i,j,c]=0 then
          begin
           d:=c;
           break; //Если в поиске было достигнуто нулевое значение ячейки ошибок, то свободное место есть и нет смысла продолжать поиск (заполнение последовательно)
          end;
        end;
       Cube[i,j,d]:=Cube[LastI,LastJ,1]; //В актуальный массив ошибок добавляется значение предыдущей просмотренной ячейки
       Cube[LastI,LastJ,1]:=0;           //Последняя ячейка приравнивается к нулю
       Cube[i,j,1]:=0;                   //На всякий случай и актуальная ячейка обнуляется
      end;
   if Cube[i,j,3]>0 then SolvingGeneration(Cube,i,j,TheEnd,False); //Если массив ошибок переполнен, то вернуться к предыдущей ячейке
   if TheEnd=False then
    repeat {Тело рекурсивного генератора}
     if TheEnd=True then continue;
     repeat {Генерация ячейки не входящей во множество ошибок}
      AllRight:=True; //По умолчанию считается, что число корректно
      Cube[i,j,1]:=random(1,9); //Ячейке фундамента (т.е будущей матрицы судоку) присваивается случайное значение в соответствии с правилами игры
      for var c:=2 to 10 do //Число проверяется на ошибочность (есть ли оно в массиве ошибок?)
      begin
       if Cube[i,j,1]=Cube[i,j,c] then //Если в массиве ошибок найдено текущее значение ячейки, то поиск прекращается и начинается перегенерация числа
        begin
         AllRight:=False; //Число некорректно
         break;  //Выход из цикла анализа массива ошибок
        end
       else if Cube[i,j,c]=0 then
        begin
         d:=c;
         break; //Если в поиске было достигнуто нулевое значение ячейки ошибок, то свободное место есть и нет смысла продолжать поиск (заполнение последовательно)
        end;
       end;
      until (AllRight=True) or (Cube[i,j,10]>0); //Число генерируется пока не будет сгенерировано корректное значение, или пока не заполнится массив ошибок
     if (AllRight=True) and (Cube[i,j,10]=0) then
      begin
       {Копирование фундамента куба в двумерный массив, что нужно для проверки}
       for var k:=1 to 9 do
        for var m:=1 to 9 do
         MasStartData[k,m]:=Cube[k,m,1];
       {Проверка фундамента на соответствие правилам судоку}
       CheckSquare(MasStartData,AllRight); //Проверка малых квадратов 3*3 на уникальность наборов цифр
       if AllRight=True then CheckCross(MasStartData,AllRight); //Если предыдущая проверка не провалилась, то проверяются столбцы и строки
       if TheEnd=False then
        begin
         if (AllRight=True) and (Cube[i,j,10]=0) then SolvingGeneration(Cube,i,j,TheEnd,True) //Если обе проверки были успешны, то перейти к следующей ячейке
         else Cube[i,j,d]:=Cube[i,j,1];
        end
       else
        if (AllRight=True) and (i=9) and (j=9) then
         begin
          TheEnd:=True;
          exit;
         end
      end;
    if TheEnd=False then
     if Cube[i,j,10]>0 then
      begin
       for var c:=2 to 10 do //Раз алгоритм возвращается на шаг назад, то массив ошибок для текущей клетки нужно обнулить
        Cube[i,j,c]:=0;
       MasStartData[i,j]:=0;
       Cube[i,j,1]:=0;//Аналогично, нужно обнулять и значение текущей клетки     
       SolvingGeneration(Cube,i,j,TheEnd,False);  //Если массив ошибок переполнен, то вернуться к предыдущей ячейке
       if (AllRight=True) and (i=9) and (j=9) then
        begin
         TheEnd:=True;
        end;
      end
    until TheEnd=True;
   end;
  end;
end;

Procedure GenerationBoard(var MasStartData:SudokuGrid; var MasGameData:SudokuGrid; SetOfHelp:byte);
begin
var Cube:SudokuSolver; //Куб данных
var TheEnd:=False; //Переменная заканчивающая рекурсию
var Addition:=True;//Назад или вперёд?
 {Обнуление куба данных}
 for var a:=1 to 9 do
  for var b:=1 to 9 do
   begin
    MasStartData[a,b]:=0;
    MasGameData[a,b]:=0;
    for var c:=1 to 9 do
     Cube[a,b,c]:=0;
   end;
 {Запуск рекурсии, прорешивающей пустое поле и тем самым создающей судоку}
 SolvingGeneration(Cube,0,1,TheEnd,Addition);
 {Нижний уровень куба (фундамент) является готовой матрицей судоку. Его нужно присвоить массиву начальных игровых данных}
var k:byte:=81; //Сколько стартовых клеток ещё заполнено
 repeat {Удаление лишних элементов из решённой матрицы (то есть оставить лишь заданное количество клеток)}
  Li:=random(1,9); //Переменные Li и Lj - глобальные, поэтому для экономии памяти их можно задействовать здесь как "i" и "j"
  Lj:=random(1,9);
  if MasStartData[Li,Lj]>0 then
   begin
    MasStartData[Li,Lj]:=0;
    Dec(k);
   end;
 until k=SetOfHelp;
end;

{----------------------------------------------------Переход к графической части------------------------------------------------------}

Procedure MouseDown(x,y,mb:integer); //Взаимодействие мыши с игровым полем
begin;
 var i:byte;
 var j:byte;
 if (ObjectUnderPoint(x,y)=nil) or ((InGame=False) and (InDifMenu=False)) or (InCheck=True) then //Работает только при щелчке по объекту
       exit;
 if InGame=True then //Условие для этапа игры
  begin
   if (x.InRange(50,500)) and (y.InRange(75,525)) then //Условия для матрицы судоку
    begin
     if (Lx<>0) and (Ly<>0) then
      begin
       if (MasGameData[Li,Lj]=0) and (MasStartData[Li,Lj]=0) then Cell[Li,Lj].FontColor:=ClWhite;
       if MasStartData[Li,Lj]=0 then Cell[Li,Lj].Color:=ClWhite;
      end;
     {Координатный поиск ячейки, на которую нажал игрок}
     var Nashlo:Boolean:=False;
     for i:=1 to 9 do
      begin
       for j:=1 to 9 do
        if (x.InRange(50*i,50*(i+1))) and (y.InRange(25+50*j,25+50*(j+1))) then
         begin
          Nashlo:=True;
          break;
         end;
       if Nashlo=True then break;
      end;
     if (mb=1) and (MasStartData[i,j]=0) then //Что произойдёт при лкм?
      begin
       if MasGameData[i,j]=0 then Cell[i,j].FontColor:=ClGainsboro;
       Cell[i,j].Color:=ClGainsboro;
      end;  
     if (mb=2) and (MasStartData[i,j]=0) then //Что произойдёт при пкм?
      begin
       Cell[i,j].Color:=ClWhite;
       Cell[i,j].FontColor:=ClWhite;
       Cell[i,j].Number:=0;
       MasGameData[i,j]:=0;
      end;
     Lx:=x;    Ly:=y;    Li:=i;    Lj:=j;
   {Корректировка линий на игровом поле}
   SetPenWidth(5);
   for var z:=0 to 3 do line(50,75+50*3*z,500,75+50*3*z);
   for var z:=0 to 3 do line(50+50*3*z,75,50+50*3*z,525);
    end;
  end;
 if (mb=1) and (InDifMenu=True) and (ObjectUnderPoint(x,y).ToString='ABCObjects.RegularPolygonABC') then
 //Работает только для треугольных кнопок, т.е. полигонов ABC
  begin
   if x<275 then //Левая треугольная кнопка
    begin
     dec(DifValue);
     if DifValue=0 then DifValue:=4;
    end;
   if x>575 then //Правая треугольная кнопка
    begin
     inc(DifValue);
     if DifValue=5 then DifValue:=1;
    end;
   {Подобие кнопочной анимации}
   ObjectUnderPoint(x,y).MoveOn(0,1);
   sleep(200);
   ObjectUnderPoint(x,y).MoveOn(0,-1);
   {Реакция на нажатие в окне сложности}
   case DifValue of
    1:begin
       SetOfHelp:=30;
       ObjectUnderPoint(280,190).Text:='|  Легко  |';
       ObjectUnderPoint(180,255).Text:='Количество открытых ячеек: 30';
      end;
    2:begin
       SetOfHelp:=26;
       ObjectUnderPoint(280,190).Text:='|Нормально|';
       ObjectUnderPoint(180,255).Text:='Количество открытых ячеек: 26';
      end;
    3:begin
       SetOfHelp:=22;
       ObjectUnderPoint(280,190).Text:='| Сложно  |';
       ObjectUnderPoint(180,255).Text:='Количество открытых ячеек: 22';
      end;
    4:begin
       SetOfHelp:=18;
       ObjectUnderPoint(280,190).Text:='| Безумие |';
       ObjectUnderPoint(180,255).Text:='Количество открытых ячеек: 18';
      end;
   end;
  end;
end;

Procedure InGameTest(BoardGame:SudokuGrid; var CheckResult:boolean); //Проверка игрового поля
begin
 CheckResult:=True;                    //Каждая новая генерация по умолчанию корректна
 CheckSquare(BoardGame,CheckResult); //Проверка квадратов на соответствие
 if CheckResult=True then              //Если проверка квадратов пройдена, то..
  CheckCross(BoardGame,CheckResult); //..запускается крестообразная проверка каждого элемента
end;

Procedure Check(); //Проверка поля из игрового меню
begin
 InCheck:=True;
 InGameTest(MasGameData,AllRight);
 var Test:=True;
 for var i:=1 to 9 do
  if Test=True then
   for var j:=1 to 9 do
    if MasGameData[i,j]=0 then
     begin
      Test:=False;
      break;
     end;
 var FloatWindow:=new SquareABC(50,75,450,ClWhite);
 if (AllRight=True) and (Test=True) then
  begin
   FloatWindow.Color:=ClLawnGreen;
   FloatWindow.Text:='    Ух ты!!!!!!    '+char(10)+
                     ''                   +char(10)+
                     'ГОЛОВОЛОМКА РЕШЕНА!'+char(10)+
                     ''                   +char(10)+
                     '   ВЫ - МОЛОДЕЦ!   '+char(10);
  end
 else
  begin
   if AllRight=True then
    begin
     FloatWindow.Color:=ClKhaki;
     FloatWindow.Text:='   Ошибок нет!   '+char(10)+
                       ''                 +char(10)+
                       'но только пока...'+char(10)+
                       ''                 +char(10);
    end
   else
    begin
     FloatWindow.Color:=ClTomato;
     FloatWindow.Text:='         ОПАСНОСТЬ!'+char(10)+
                       ''                   +char(10)+
                       'ОБНАРУЖЕНА ОШИБКА!' +char(10)+
                       ''                   +char(10)+
                       'АННИГИЛИРУЙТЕ ЕЁ!!';
    end;
  end;
 var BigPinkButton:=new CircleABC(500,500,75,ClHotPink);
 var Countdown:byte:=5;
 repeat
  BigPinkButton.Number:=Countdown;
  Dec(Countdown);
  sleep(1000);
 until Countdown=0;
 FloatWindow.Destroy;
 BigPinkButton.Destroy;
 SetPenWidth(5);
 for var z:=0 to 3 do line(50,75+50*3*z,500,75+50*3*z);
 for var z:=0 to 3 do line(50+50*3*z,75,50+50*3*z,525);
 InCheck:=False;
end;

Procedure CheckTest();
begin
var Th:Thread;
 Th :=new Thread(Check);
 Th.SetApartmentState(ApartmentState.STA);
 Th.Start();
end;


procedure SavingSudoku(); //Сохранение партии в файл
begin 
 var SFD:= new SaveFileDialog();
 SFD.AddExtension:=True;        SFD.CheckPathExists:=True;
 SFD.Filter:='Текстовые файлы (*.txt)|*.txt';
 SFD.InitialDirectory:=GetCurrentDir;
 SFD.ShowDialog();
 if SFD.FileName<>'' then
  begin
   var SFN:string:=SFD.FileName; //SFN - SudokuFileName
   var Sud:text;
   for var i:=1 to 9 do
    for var j:=1 to 9 do
     if MasStartData[i,j]>0 then MasGameData[i,j]:=MasStartData[i,j];
   Assign(Sud,SFN);
   Rewrite(Sud);
   {Сначала записывать начальные условия, а затем дополненное игроком}
   for var i:=1 to 9 do
    begin
     for var j:=1 to 9 do Write(Sud,MasStartData[j,i]);
     if i<9 then writeln(Sud,'');
    end;
   writeln(Sud,'');
   writeln(Sud,'-');
   for var i:=1 to 9 do
    begin
     for var j:=1 to 9 do Write(Sud,MasGameData[j,i]);
     if i<9 then writeln(Sud,'');
    end;
   Close(Sud);
   var FloatWindow:=new SquareABC(50,75,450,ClWhite);
   FloatWindow.Color:=ClChartreuse;     FloatWindow.Text:='Готово';
   var BigPinkButton:=new CircleABC(500,500,75,ClHotPink);
   var Countdown:byte:=5;
   repeat
    BigPinkButton.Number:=Countdown;
    Dec(Countdown);
    sleep(1000);
   until Countdown=0;
   FloatWindow.Destroy;
   BigPinkButton.Destroy;
   SetPenWidth(5);
   for var z:=0 to 3 do line(50,75+50*3*z,500,75+50*3*z);
   for var z:=0 to 3 do line(50+50*3*z,75,50+50*3*z,525);
   SFD.Dispose;
 end;
end;

Procedure SaveGame(); //Процедура сохранения игры
begin
var Th:Thread;
 Th :=new Thread(SavingSudoku);
 Th.SetApartmentState(ApartmentState.STA);
 Th.Start();
end;

Procedure GenBoard(); //Перегенерация доски (для кнопки в игровом меню)
begin
 GenerationBoard(MasStartData,MasGameData,SetOfHelp) //Новый вариант генерируется только если не был открыт вариант из файла
end;

Procedure NewMatrice(); //Отрисовка сетки судоку
begin
 InGame:=True;
var z:byte; //Переменная-счётчик
 if Objects.Count>0 then //Если это не первая генерация за сессию, все предыдущие объекты удаляются
  repeat
   if Objects[z].ToString<>'ABCObjects.PictureABC' then Objects[z].Destroy
   else  inc(z);
  until Objects.Count=z;
  for var i:=1 to 9 do
   for var j:=1 to 9 do
    begin
     Cell[i,j]:=new SquareABC(50*i,25+50*j,50,ClWhite); //Создаётся сетка 9 на 9 из квадратов-объектов
     {Параметры создания: расстояние относительно окна (x,y) - 50*i и 25+50*j
                          сторона ячейки - 50;    цвет ячейки - ClWhite}
     if MasStartData[i,j]>0 then //В графическое окно выводятся только ненулевые значения начального массива
      begin
       Cell[i,j].Number:=MasStartData[i,j];
       Cell[i,j].FontStyle:=fsBold;
       Cell[i,j].FontColor:=ClBlack;
       Cell[i,j].Color:=ClWheat;
      end;
     if (MasGameData[i,j]>0) and (MasStartData[i,j]=0) then //Если играть была открыта, то в граф. окно выводятся и ненулевые значения игрового массива
      begin
       Cell[i,j].Number:=MasGameData[i,j];
       Cell[i,j].FontStyle:=fsNormal;
      end;
    end;
 for var i:=1 to 9 do
  for var j:=1 to 9 do
   if (MasGameData[i,j]=0) and (MasStartData[i,j]>0) then
    MasGameData[i,j]:=MasStartData[i,j];
 SetPenWidth(5);
 for z:=0 to 3 do line(50,75+50*3*z,500,75+50*3*z);
 for z:=0 to 3 do line(50+50*3*z,75,50+50*3*z,525);
end;

Procedure SetTime(); {Таймер партии}
begin
 var Time:= new RectangleABC(590,425,180,50,ClWhite);
 var Tsec:byte:=0;
 var Tmin:byte:=0;
 var Th:byte:=0;
 while InGame do
  begin
   var TimeString:=string.Format('{0:d2}:{1:d2}:{2:d2}',Th,Tmin,Tsec);
   Time.Text:=TimeString;
   inc(Tsec);
   if Tsec=60 then
    begin
     inc(Tmin);
     Tsec:=0;
    end;
   if Tmin=60 then
    begin
     inc(TH);
     Tmin:=0;
    end;
   sleep(1000);
  end;
end;

Procedure NewGame; //Вызывается из меню с матрицей или как часть процедуры NewGameFromMenu
begin
 GenBoard;
 NewMatrice;
var TimeThread:Thread; {Под время партии создаётся отдельный поток, для исключения зависания остальной программы}
 TimeThread:=new Thread(SetTime);
 TimeThread.SetApartmentState(ApartmentState.STA);
 TimeThread.Start;
end;

Procedure NumbButton(a,b,n:byte; var MassivIgrovihDannih:SudokuGrid; var GraphicheskayaKletka:SquareMas); //Присвоение ячейке значения
begin
 if (a<>0) and (b<>0) then
  begin
   if MasStartData[a,b]=0 then 
    begin
     MassivIgrovihDannih[a,b]:=n;
     GraphicheskayaKletka[a,b].Number:=n;
     GraphicheskayaKletka[a,b].FontColor:=ClBlack;
     SetPenWidth(5);
     for var z:=0 to 3 do line(50,75+50*3*z,500,75+50*3*z);
     for var z:=0 to 3 do line(50+50*3*z,75,50+50*3*z,525);
    end;
   end
 else exit;
end;

Procedure NB1; //Кнопка с цифрой "1"
begin
 NumbButton(Li,Lj,1,MasGameData,Cell)
end;
Procedure NB2; //Кнопка с цифрой "2"
begin
 NumbButton(Li,Lj,2,MasGameData,Cell)
end;
Procedure NB3; //Кнопка с цифрой "3"
begin
 NumbButton(Li,Lj,3,MasGameData,Cell)
end;
Procedure NB4; //Кнопка с цифрой "4"
begin
 NumbButton(Li,Lj,4,MasGameData,Cell)
end;
Procedure NB5; //Кнопка с цифрой "5"
begin
 NumbButton(Li,Lj,5,MasGameData,Cell)
end;
Procedure NB6; //Кнопка с цифрой "6"
begin
 NumbButton(Li,Lj,6,MasGameData,Cell)
end;
Procedure NB7; //Кнопка с цифрой "7"
begin
 NumbButton(Li,Lj,7,MasGameData,Cell)
end;
Procedure NB8; //Кнопка с цифрой "8"
begin
 NumbButton(Li,Lj,8,MasGameData,Cell)
end;
Procedure NB9; //Кнопка с цифрой "9"
begin
 NumbButton(Li,Lj,9,MasGameData,Cell)
end;

Procedure NewBoard; //Процедура графического создания поля и начала игры
begin
var TimeThread:Thread;
 TimeThread:=new Thread(SetTime);
 TimeThread.SetApartmentState(ApartmentState.STA);
 TimeThread.Start;
 Li:=0; Lj:=0;
 InGame:=True;
var n:byte; //Переменная промежуточных результатов
 for var i:=1 to B do
  if not(Buttons[i]=nil) then Buttons[i].Destroy;
 if BackIsEmpty=False then Background.Redraw;
 for var i:=1 to 9 do
  if n=0 then
   for var j:=1 to 9 do
    if MasGameData[i,j]>0 then
     begin
      inc(n); //Здесь n отображает, были ли найдены ненулевые значения. Если да, то игра была открыта а не сгенерирована
      break;
     end;
 if n=0 then
 for var i:=1 to 9 do
  for var j:=1 to 9 do
   begin
    MasGameData[i,j]:=MasStartData[i,j];
   end;
  n:=1; //Переменная n теперь хранит количество квадратов ввода числа
  for var j:=1 to 3 do
   for var i:=1 to 3 do
    begin
     Numbers[n]:=new ButtonABC(595+5*i+50*(i-1),190+5*j+50*(j-1),50,'',ClWhite);
     Numbers[n].Height:=50;
     Numbers[n].Number:=n;
     inc(n);
    end;
 Numbers[1].OnClick:=NB1;           Numbers[2].OnClick:=NB2;          Numbers[3].OnClick:=NB3;
 Numbers[4].OnClick:=NB4;           Numbers[5].OnClick:=NB5;          Numbers[6].OnClick:=NB6;
 Numbers[7].OnClick:=NB7;           Numbers[8].OnClick:=NB8;          Numbers[9].OnClick:=NB9;
 Buttons[8]:=new ButtonABC(590,75,180,50,  'Новая игра',ClWhite);     Buttons[8].OnClick:=NewGame;
 Buttons[9]:=new ButtonABC(590,135,180,50, 'Сохранить ',ClWhite);     Buttons[9].OnClick:=SaveGame;
 Buttons[10]:=new ButtonABC(590,365,180,50,'Проверить ',ClWhite);     Buttons[10].OnClick:=CheckTest;
 Menu.MoveTo(590,485);              Menu.Visible:=True;               Menu.Text:='Меню';
 Menu.Width:=180;                   Menu.Height:=50;                  Menu.Color:=ClWhite;
end;

Procedure NewGameFromMenu(); //Начало новой игры из главного меню
begin
 NewBoard;
 NewGame;
 InGame:=True;
end;

{----------------------------------------------------Интерфейсы дополнительного функционала------------------------------------------------------}

Procedure ReadingSudoku(var MasStartData:SudokuGrid); //Отдельной процедурой для экономии памяти и присвоения кнопке "Открыть игру" процедуры "OpenGame"
begin
 InGame:=False;
 var OFD:= new OpenFileDialog();
 OFD.AddExtension:=True;     OFD.Multiselect:=False;
 OFD.CheckFileExists:=True;  OFD.CheckPathExists:=True;
 OFD.Filter:='Текстовые файлы(*.txt)|*.txt';
 if OFD.ShowDialog=System.Windows.Forms.DialogResult.OK then
  begin
   var SFN:string:={Путь к файлу +}OFD.FileName; //SFN - SudokuFileName
   if FileExists(SFN)=true then
    begin
     var Sud:text;
     var i:byte:=1;
     var j:byte:=1;
     Assign(Sud,SFN);
     Reset(Sud);
     var Stroka:string;
     var a:integer;
     var err:integer;
     repeat
      readln(Sud,Stroka);
      val(Stroka,a,err);
      if (err=0) or (Stroka='-') then
       begin
        if Stroka='-' then break
        else
         begin
          repeat
           val(copy(Stroka,i,1),a,err);
           if err=0 then MasStartData[i,j]:=a;
           inc(i);
          until i=10;
          i:=1;
          inc(j);
        end
       end
      else exit;
     until Stroka='-';
     i:=1;   j:=1;
     repeat
      readln(Sud,Stroka);
      repeat
       val(copy(Stroka,i,1),a,err);
       if err=0 then MasGameData[i,j]:=a;
       inc(i);
      until i=10;
      i:=1;
      inc(j);
     until Eof(Sud);
     Close(Sud);
    end;
   NewMatrice;
   NewBoard;
   SetPenWidth(5);
   for var z:=0 to 3 do line(50,75+50*3*z,500,75+50*3*z);
   for var z:=0 to 3 do line(50+50*3*z,75,50+50*3*z,525);
   InGame:=True;
   OFD.Dispose;
  end
end;

Procedure ConnectForOpen; //Связь процедуры открытия игры с другими процедурами
begin
 ReadingSudoku(MasStartData);
end;

Procedure OpenGame(); //Процедура открытия игры
begin
var Th:Thread;
 Th:=new Thread(ConnectForOpen);
 Th.SetApartmentState(ApartmentState.STA);
 Th.Start;
end;

Procedure SelectDifficulity(var SetOfHelp:byte); //Процедура выбора сложности игры
begin
 Window.Clear;
 if BackIsEmpty=False then Background.Redraw;
 DifValue:=1;
 InGame:=False;
 InDifMenu:=True;
 for var i:=1 to B do
  if not(Buttons[i]=nil) then Buttons[i].Destroy;
 var WindowName:=new RoundRectABC(175,50,500,75,15,ClWhite);       WindowName.Text:='Выберите сложность';
 var DifType:=new RoundRectABC(275,150,300,75,15,ClWhite);
 var LeftTriangle:= new RegularPolygonABC(225,185,35,3,ClWhite);   LeftTriangle.Angle:=-90; //Переключатель сложности "влево"
 var RightTriangle:=new RegularPolygonABC(625,185,35,3,ClWhite);   RightTriangle.Angle:=90; //Переключатель сложности "вправо"
 var Description:=new RoundRectABC(175,250,500,225,15,ClWhite);
 case SetOfHelp of
  30:begin
      DifValue:=1;
      ObjectUnderPoint(280,190).Text:='|  Легко  |';
      ObjectUnderPoint(180,255).Text:='Количество открытых ячеек: 30';
     end;
  26:begin
      DifValue:=2;
      ObjectUnderPoint(280,190).Text:='|Нормально|';
      ObjectUnderPoint(180,255).Text:='Количество открытых ячеек: 26';
     end;
  22:begin
      DifValue:=3;
      ObjectUnderPoint(280,190).Text:='| Сложно  |';
      ObjectUnderPoint(180,255).Text:='Количество открытых ячеек: 22';
     end;
  18:begin
      DifValue:=4;
      ObjectUnderPoint(280,190).Text:='| Безумие |';
      ObjectUnderPoint(180,255).Text:='Количество открытых ячеек: 18';
     end;
 end;
 Menu.MoveTo(175,495);     Menu.Text:='Вернуться в меню';
 Menu.Width:=500;          Menu.Height:=75;       Menu.Color:=ClWhite;
 if (Menu.Visible=False) then Menu.Visible:=True;
end;

Procedure Difficulity(); //Переключатель сложности игры
begin
 SelectDifficulity(SetOfHelp);
end;

Procedure ChooseBackground(var Background:PictureABC; var BackIsEmpty:Boolean); //Процедура выбора игрового фона
begin
 InGame:=False;
 var SFD:= new OpenFileDialog();
 SFD.AddExtension:=True;        SFD.CheckPathExists:=True;
 SFD.Filter:='Файлы изображений (*.bmp, *.jpg, *.png)|*.bmp;*.jpg;*.png';
 SFD.ShowDialog();
 var BFN:string:=SFD.FileName; //BFN - BackgroundFileName
 if BFN<>'' then
  begin
   Background:= new PictureABC(0,0,BFN);
   BackIsEmpty:=False;
   Background.Height:=Window.Height;
   Background.Width:=Window.Width;
  end;
end;

Procedure ConnectBackground;
begin
 ChooseBackground(Background,BackIsEmpty);
end;

Procedure AcceptBackground(); //Поток смены фона
begin
var Th:Thread:= new Thread(ConnectBackground);
 Th.SetApartmentState(ApartmentState.STA);
 Th.Start();
end;

Procedure FAQ(); //Процедура вывода справки
begin
 InGame:=False;
 for var i:=1 to B do
  if not(Buttons[i]=nil) then Buttons[i].Destroy;
 if BackIsEmpty=False then Background.Redraw;
 var FAQWindow:=new RoundRectABC(175,50,500,400,15,ClWhite);
 Menu.MoveTo(175,470);     Menu.Text:='Всё понятно! Вернуться в меню!';
 Menu.Width:=500;          Menu.Height:=100;       Menu.Color:=ClWhite;
 if (Menu.Visible=False) then Menu.Visible:=True;
 FAQWindow.Text:='       Как играть в судоку?'+char(10)+
                 ''+char(10)+
                 'Цель игрока - подставлять '+char(10)+
                 'цифры, в изначально пустые'+char(10)+
                 'клетки, таким образом,'+char(10)+
                 'что бы не было повторений:'+char(10)+
                 '1) В квадратах 3 на 3;'+char(10)+
                 '2) По строкам;'+char(10)+
                 '3) По столбцам.'
end;

Procedure About();
begin
 InGame:=False;
 for var i:=1 to B do
  if not(Buttons[i]=nil) then Buttons[i].Destroy;
 if BackIsEmpty=False then Background.Redraw;
 var AboutWindow:=new RoundRectABC(175,50,500,400,15,ClWhite);
 Menu.MoveTo(175,470);     Menu.Text:='Всё понятно! Вернуться в меню!';
 Menu.Width:=500;          Menu.Height:=100;       Menu.Color:=ClWhite;
 if (Menu.Visible=False) then Menu.Visible:=True;
 AboutWindow.Text:='          О программе:'+char(10)+
                   ''+char(10)+
                   'Данная программа реализует'+char(10)+
                   '    одну из общеизвестных'+char(10)+
                   'игр-головоломок - "СУДОКУ".'+char(10)+
                   ''+char(10)+
                   'Она создавалась в качестве'+char(10)+
                   ' курсовой работы студента'+char(10)+
                   'первого курса, группы ПЕ-81б'+char(10)+
                   '      Мирославского И.С.'+char(10)+
                   ''+char(10)+
                   ''+char(10)+
                   '          УрТИСИ 2019';
end;

Procedure GetOutMenu();
begin
Lx:=0;    Ly:=0;    Li:=0;    Lj:=0;
 for var i:=1 to 9 do
  for var j:=1 to 9 do
   begin
    MasGameData[i,j]:=0;
    MasStartData[i,j]:=0;
   end;
 Menu.Text:='';
 Menu.Height:=5;   Menu.Width:=5;   Menu.MoveTo(840,590);   Menu.Visible:=False;
 InDifMenu:=False;
 InGame:=False;
 Window.Clear;
 if BackIsEmpty=False then Background.Redraw;
var z:byte; //Переменная-счётчик
 if Objects.Count>0 then //Если это не первая генерация за сессию, все предыдущие объекты удаляются
  repeat
   if Objects[z].ToString<>'ABCObjects.PictureABC' then Objects[z].Destroy
   else  inc(z);
  until Objects.Count=z;
 for var i:=1 to B do
  if not(Buttons[i]=nil) then Buttons[i].Destroy;
 for var i:=1 to 9 do
  if not(Numbers[i]=nil) then Numbers[i].Destroy;
 Buttons[1]:=new ButtonABC(95,125,315,70,' Новая игра  ',ClWhite);       Buttons[1].FontStyle:=fsBold;      Buttons[1].OnClick:=NewGameFromMenu;
 Buttons[2]:=new ButtonABC(440,125,315,70,'Открыть игру ',ClWhite);      Buttons[2].FontStyle:=fsBold;      Buttons[2].OnClick:=OpenGame;
 Buttons[3]:=new ButtonABC(95,214,315,70,'  Сложность  ',ClWhite);       Buttons[3].FontStyle:=fsBold;      Buttons[3].OnClick:=Difficulity;
 Buttons[4]:=new ButtonABC(440,214,315,70,'     Фон     ',ClWhite);      Buttons[4].FontStyle:=fsBold;      Buttons[4].OnClick:=AcceptBackground;
 Buttons[5]:=new ButtonABC(95,307,315,70,' Как играть? ',ClWhite);       Buttons[5].FontStyle:=fsBold;      Buttons[5].OnClick:=FAQ;
 Buttons[6]:=new ButtonABC(440,307,315,70,'О программе ',ClWhite);       Buttons[6].FontStyle:=fsBold;      Buttons[6].OnClick:=About;
 Buttons[7]:=new ButtonABC(95,405,660,70,'Выход из игры',ClWhite);       Buttons[7].FontStyle:=fsBold;      Buttons[7].OnClick:=Window.Close;
end;

{----------------------------------------------------Тело программы------------------------------------------------------}
Begin
 Window.Title:='Классическая судоку ®Мирославский И.С.';
 SetWindowSize(850,600);
 Window.IsFixedSize:=True;
 InDifMenu:=False;
 BackIsEmpty:=True;
 SetOfHelp:=30; //Сложность по умолчанию равна лёгкой, то есть 30-и открытым ячейкам.
 if FileExists('Paper1.jpg') then //Фон по умолчанию
  begin
   Background:= new PictureABC(0,0,'Paper1.jpg');
   BackIsEmpty:=False;
   Background.Height:=Window.Height;
   Background.Width:=Window.Width;   
  end;
 Menu:=new ButtonABC(840,590,5,5,'Меню',ClWhite);
 Menu.Visible:=False;   Menu.OnClick:=GetOutMenu;
 GetOutMenu;
 OnMouseDown:=MouseDown;
End.
