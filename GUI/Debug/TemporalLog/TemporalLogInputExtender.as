class UTemporalLogInputExtender : UTemporalLogUIExtender
{
	int SizeX = 400;
	int SizeY = 200;

	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Input";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
		return true;
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{
		auto Root = Drawer.BeginCanvasPanel();

		FString ControllerType;
		TemporalLog.GetStringData(Report.ReportedPath+"/ControllerType", Report.ReportedFrame, ControllerType);
		if (ControllerType == "Keyboard")
			return;

#if EDITOR
		FSlateBrush Brush;
		Brush.ResourceObject = LoadObject(nullptr, "/Game/GUI/ControllerLayout/ControllerLayoutMaterial_PS5.ControllerLayoutMaterial_PS5");
		Brush.DrawAs = ESlateBrushDrawType::Image;

		auto Paint = Root
			.SlotAnchors(0.5, 0.5)
			.SlotAlignment(0.5, 0.5)
			.SlotAutoSize(true)
			.BorderBox()
				.HeightOverride(SizeY)
				.WidthOverride(SizeX)
				.BackgroundBrush(Brush)
			.PaintCanvas().Size(FVector2D(SizeX, SizeY));

		DrawButton(Paint, Report, EKeys::Gamepad_FaceButton_Left, 0.675, 0.53, 0.03);
		DrawButton(Paint, Report, EKeys::Gamepad_FaceButton_Right, 0.78, 0.53, 0.03);
		DrawButton(Paint, Report, EKeys::Gamepad_FaceButton_Top, 0.73, 0.44, 0.03);
		DrawButton(Paint, Report, EKeys::Gamepad_FaceButton_Bottom, 0.73, 0.62, 0.03);

		DrawSquareButton(Paint, Report, EKeys::Gamepad_DPad_Down, 0.255, 0.60, 0.022, 0.022);
		DrawSquareButton(Paint, Report, EKeys::Gamepad_DPad_Up, 0.255, 0.45, 0.022, 0.022);
		DrawSquareButton(Paint, Report, EKeys::Gamepad_DPad_Left, 0.21, 0.54, 0.022, 0.022);
		DrawSquareButton(Paint, Report, EKeys::Gamepad_DPad_Right, 0.30, 0.54, 0.022, 0.022);

		DrawSquareButton(Paint, Report, EKeys::Gamepad_LeftShoulder, 0.25, 0.27, 0.05, 0.022);
		DrawSquareButton(Paint, Report, EKeys::Gamepad_RightShoulder, 0.74, 0.27, 0.05, 0.022);

		DrawSquareButton(Paint, Report, EKeys::Gamepad_LeftTrigger, 0.27, 0.16, 0.04, 0.022);
		DrawSquareButton(Paint, Report, EKeys::Gamepad_RightTrigger, 0.73, 0.16, 0.04, 0.022);

		DrawStick(Paint, Report, n"LeftStickRawX", n"LeftStickRawY", 0.37, 0.75, 0.06, 4);
		DrawStick(Paint, Report, n"RightStickRawX", n"RightStickRawY", 0.62, 0.75, 0.06, 4);
#endif
	}

	void DrawButton(FHazeImmediatePaintCanvasHandle Paint, FHazeTemporalLogReport Report,
		FKey Button, float PosX, float PosY, float Size) const
	{
		bool bPressed = false;
		TemporalLog.GetBoolData(
			Report.ReportedPath + "/Controller;"+Button.ToString(),
			Report.ReportedFrame,
			bPressed
		);

		FLinearColor Color;
		if (bPressed)
			Color = FLinearColor(1.00, 0.00, 0.95, 0.80);
		else
			Color = FLinearColor(1.0, 1.0, 1.0, 0.0);

		Paint.CircleFill(
			FVector2D(PosX * SizeX, PosY * SizeY),
			Size * SizeX, Color,
		);
	}

	void DrawSquareButton(FHazeImmediatePaintCanvasHandle Paint, FHazeTemporalLogReport Report,
		FKey Button, float PosX, float PosY, float Width, float Height) const
	{
		bool bPressed = false;
		TemporalLog.GetBoolData(
			Report.ReportedPath + "/Controller;"+Button.ToString(),
			Report.ReportedFrame,
			bPressed
		);

		FLinearColor Color;
		if (bPressed)
			Color = FLinearColor(1.00, 0.00, 0.95, 0.80);
		else
			Color = FLinearColor(1.0, 1.0, 1.0, 0.0);

		int OffsetX = Math::FloorToInt(Width * SizeX);
		int OffsetY = Math::FloorToInt(Height * SizeX);
		Paint.RectFill(
			FVector2D(PosX * SizeX - OffsetX, PosY * SizeY - OffsetY),
			FVector2D(PosX * SizeX + OffsetX, PosY * SizeY + OffsetY),
			Color,
		);
	}

	void DrawStick(FHazeImmediatePaintCanvasHandle Paint, FHazeTemporalLogReport Report,
		FName AxisX, FName AxisY, float PosX, float PosY, float Length, float Width) const
	{
		float32 XValue = 0.0;
		TemporalLog.GetFloatData(Report.ReportedPath+"/Axes;"+AxisX, Report.ReportedFrame, XValue);

		float32 YValue = 0.0;
		TemporalLog.GetFloatData(Report.ReportedPath+"/Axes;"+AxisY, Report.ReportedFrame, YValue);
		YValue *= -1.0;

		Paint.CircleFill(
			FVector2D(PosX * SizeX, PosY * SizeY),
			SizeX * Length, FLinearColor(0.1, 0.1, 0.1)
		);

		Paint.Circle(
			FVector2D(PosX * SizeX, PosY * SizeY),
			SizeX * Length, FLinearColor::White, 1.0
		);

		Paint.CircleFill(
			FVector2D(PosX * SizeX, PosY * SizeY),
			Width - 1, FLinearColor::White
		);

		Paint.Line(
			PosX * SizeX,
			PosY * SizeY,
			PosX * SizeX + XValue * Length * SizeX,
			PosY * SizeY + YValue * Length * SizeX,
			FLinearColor::Red,
			Width
		);
	}
}