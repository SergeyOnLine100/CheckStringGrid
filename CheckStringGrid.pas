unit CheckStringGrid;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Dialogs, Grids, StdCtrls;

type
  TCheckStringGrid = class(TStringGrid)
  private
    FCheckboxColumn: Integer;
    FCheckboxVisible : Boolean;
    procedure SetCheckboxColumn(const Value: Integer);
    procedure DrawCheckbox(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure SetCheckboxVisible(const Value: Boolean);
  protected
    procedure DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    function IsCheckboxChecked(ARow: Integer): Boolean; // Вернем состояние чекбокса в нужной строке
  published
    property CheckboxColumn: Integer read FCheckboxColumn write SetCheckboxColumn default 0;
    property CheckboxVisible: Boolean read FCheckboxVisible write SetCheckboxVisible default True;
  end;

implementation

{ TCheckStringGrid}

procedure TCheckStringGrid.DrawCheckbox(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  CheckState: DWORD;
  BoxRect: TRect;
  i, n: Integer;
begin
  if (ACol = FCheckboxColumn) and (ARow > 0) then
  begin
    BoxRect := Rect;
    InflateRect(BoxRect, -2, -2);
    CheckState := DFCS_BUTTONCHECK;
    if Boolean(Objects[ACol, ARow]) then
      CheckState := CheckState or DFCS_CHECKED;
    DrawFrameControl(Canvas.Handle, BoxRect, DFC_BUTTON, CheckState);
  end;
  if (ACol = FCheckboxColumn) and (ARow = 0) then
  begin
    // Проверка общего состояния флажков
    n := 0;
    for i := 1 to RowCount - 1 do
      if Boolean(Objects[FCheckboxColumn, i]) then
         n := n + 1;

    CheckState := DFCS_BUTTONCHECK;

    if n = RowCount - 1 then
      CheckState := CheckState or DFCS_CHECKED;

    if (n > 0) and (n < RowCount - 1) Then
      CheckState := DFCS_BUTTON3STATE or DFCS_CHECKED;

    BoxRect := Rect;
    InflateRect(BoxRect, -2, -2);

    DrawFrameControl(Canvas.Handle, BoxRect, DFC_BUTTON, CheckState);
  end;
end;

procedure TCheckStringGrid.DrawCell(ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
begin
  if FCheckboxVisible and (ACol = FCheckboxColumn) then
    DrawCheckbox(ACol, ARow, Rect, State)
  else
    inherited DrawCell(ACol, ARow, Rect, State);
end;

procedure TCheckStringGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i, n, ACol, ARow: Integer;
  CellChecked, newState: Boolean;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if Button = mbLeft then
  begin
    MouseToCell(X, Y, ACol, ARow);
    if ACol = FCheckboxColumn then
    begin
      CellChecked := not Boolean(Objects[ACol, ARow]);
      Objects[ACol, ARow] := TObject(CellChecked);

      // Проверка, все ли флажки в нижних строках выбраны
      n := 0;
      for i := 1 to RowCount - 1 do
        if Boolean(Objects[FCheckboxColumn, i]) then
           n := n + 1;

      if n = RowCount - 1 then 
        Objects[FCheckboxColumn, 0] := TObject(True);
      if (n > 0) and (n < (RowCount - 1)) then
        Objects[FCheckboxColumn, 0] := nil;
      if n = 0 then
        Objects[FCheckboxColumn, 0] := TObject(False);

      // Распространение состояния флажка на все строки
      if (ACol = FCheckboxColumn) and (ARow = 0) then
      begin
        newState := not Boolean(Objects[FCheckboxColumn, 0]);
        for i := 1 to RowCount - 1 do
          Objects[ACol, i] := TObject(newState);
      end;
      Invalidate;
    end;
  end;
end;

procedure TCheckStringGrid.SetCheckboxColumn(const Value: Integer);
begin
   FCheckboxColumn := Value;
end;

function TCheckStringGrid.IsCheckboxChecked(ARow: Integer): Boolean;
begin
  // Возвращаем состояние чекбокса для указанной строки
  Result := Boolean(Objects[FCheckboxColumn, ARow]);
end;

procedure TCheckStringGrid.SetCheckboxVisible(const Value: Boolean);
var
  i: Integer;
begin
  if FCheckboxVisible <> Value then
  begin
    FCheckboxVisible := Value;

    if FCheckboxVisible then
    begin
      // Создание новой колонки для чекбоксов
      ColCount := ColCount + 1;
      // Если FCheckboxColumn равен 0 и FixedCols равен 0, устанавливаем FixedCols в 1
      if (FCheckboxColumn = 0) and (FixedCols = 0) then FixedCols := 1;

      // Копирование данных из предыдущих колонок в новую колонку
      for i := ColCount-1 downto FCheckboxColumn+1 do
      begin
        Cols[i].Assign(Cols[i-1]); // Копирование данных
        ColWidths[i]:=ColWidths[i-1]; // Копирование ширины
      end;
      Cols[FCheckboxColumn].Text:='';     // Очистка текста в колонке с чекбоксами
      ColWidths[FCheckboxColumn] := 20;   // Установка ширины колонки с чекбоксами в 20 пикселей
    end
    else
    begin
      // Удаление колонки с чекбоксами
      for i := FCheckboxColumn+1 to ColCount - 1 do
        begin
          Cols[i-1].Assign(Cols[i]); // Копирование данных из колонки i в колонку i-1
          ColWidths[i-1]:=ColWidths[i]; // Копирование ширины колонки i в колонку i-1
        end;
      // Уменьшение ColCount на 1
      ColCount := ColCount - 1;
      // Если FCheckboxColumn равен 0 и FixedCols равен 1, устанавливаем FixedCols в 0
      if (FCheckboxColumn = 0) and (FixedCols = 1) then FixedCols := 0;
    end;

    Invalidate;
  end;
end;


constructor TCheckStringGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCheckboxColumn := 0; // Индекс столбца для чекбоксов по умолчанию
  FCheckboxVisible := False; // Видимость столбца с чекбоксами по умолчанию
end;

end.
 
