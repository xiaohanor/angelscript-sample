class UAudioDebugLoudness : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Loudness; }
	
	FString GetTitle() override
	{
		return "Loudness";
	}

	bool bRegisteredWithCallback = false;

	void RegisterBusMetering()
	{
		if (bRegisteredWithCallback)
			return;

		// Master bus ID - 3803692087
		uint32 MasterBusID = 3803692087;
		AudioUtility::RegisterBusMetering(int(MasterBusID));
		LoudnessDuration = Time::RealTimeSeconds;
		bRegisteredWithCallback = true;
	}

	const float MinLKFS = -96.;
	const float Epsilon = 1e-37;
	const float RelativeThresholdLoudness = Math::Pow( 10.0, -10.0/10.0 );
	const float AbsoluteThresholdLoudness = Math::Pow( 10.0, -70.0/10.0 );
	
	FVector2D MinMaxMomentary = FVector2D(0,-70);
	FVector2D MinMaxShortTerm = FVector2D(0,-70);
	FVector2D MinMaxIntegrated = FVector2D(0,-70);
	float LoudnessDuration = 0;

	private bool bWasTurnedOff = false;
	float GraphHeightOffset = 24;
	bool bShowMomentary = true;
	bool bShowShortTerm = false;

	// Extracted from Wwise and how they treat the MeanPower values.
	float GetIntegrated(const FAudioProfilingWeightedPowerLoudnessData& Data)
	{
		// The relative threshold is computed by subtracting RelativeThresholdLoudness LKFS to the 
		// absolutely-gated loudness.
		float fRelativeThreshold = Data.CumulAvg * RelativeThresholdLoudness;
		if ( fRelativeThreshold < AbsoluteThresholdLoudness )	// relative threshold should be more restrictive.
			fRelativeThreshold = AbsoluteThresholdLoudness;

		// Now, compute the loudness gated with the relative threshold.
		int32 uNumGatedWnd = 0;
		float64 dblValue = 0;
		for (int i=0; i < Data.SortedWindows.Num(); ++i)
		{
			auto Value = Data.SortedWindows[i];
			if (Value < fRelativeThreshold || !Math::IsFinite(Value))
			{
				continue;
			}

			dblValue += Value;

			++uNumGatedWnd;
		}

		if ( uNumGatedWnd > 0 )
			return ( -0.691 + 10 * Math::LogX(10, dblValue / float64(uNumGatedWnd)) );

		return MinLKFS;
	}

	float GetCurrentWeightedValue(const FAudioProfilingWeightedPowerLoudnessData& Data)
	{
		if (Data.WeightedPower.Num() == 0)
			return 0;

		// Return last complete window.
		int32 uIdxLastComplete = ( Data.CurrentIndex > 0 ) ? (Data.CurrentIndex-1)%Data.WeightedPower.Num() : 0;
		float fValue = Data.WeightedPower[uIdxLastComplete];
		return ConvertWeightedPower(fValue);
	}

	float ConvertWeightedPower(const float& fValue)
	{
		return -0.691 + 10. * Math::LogX(10, fValue + Epsilon );
	}

	void Setup(UAudioDebugManager DebugManager) override
	{
		Super::Setup(DebugManager);
		
		FAngelscriptGameThreadScopeWorldContext WorldScope(DebugManager);

		if (AudioDebug::IsEnabled(EHazeAudioDebugType::Loudness))
		{
			RegisterBusMetering();
		}
		else
		{
			bRegisteredWithCallback = false;
		}
	}

	void Menu(UHazeAudioDevMenu DevMenu, UAudioDebugManager DebugManager,
			  const FHazeImmediateScrollBoxHandle& Section) override
	{
		Super::Menu(DevMenu, DebugManager, Section);

		RegisterBusMetering();

		auto LoudnessSection = Section.Section("Loudness", true);
		if (LoudnessSection.Button("Reset Loudness").Padding(20,0))	
		{
			AudioUtility::ResetLoudnessData(); 

			MinMaxMomentary = FVector2D(0,-70);
			MinMaxShortTerm = FVector2D(0,-70);
			MinMaxIntegrated = FVector2D(0,-70);
			LoudnessDuration = 0;

			if (DebugManager != nullptr)
			{
				FAngelscriptGameThreadScopeWorldContext WorldScope(DebugManager);
				LoudnessDuration = Time::RealTimeSeconds;
			}
		}

		if (LoudnessSection.Button("Toggle Momentary").Padding(20,0))
		{
			bShowMomentary = !bShowMomentary;
		}

		if (LoudnessSection.Button("Toggle ShortTerm").Padding(20,0))
		{
			bShowShortTerm = !bShowShortTerm;
		}
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		Super::Draw(DebugManager, Section);
		
		// This will pull async data collected in audio callbacks.
		const auto& LoudnessData = AudioUtility::GetLoudnessData();

		if (bShowMomentary)
		{
			PaintGraph(LoudnessData.Momentary, Section, FLinearColor::Blue);
			Section.Text(f"Momentary: {GetAndSetMinMax(LoudnessData.Momentary, MinMaxMomentary)}, Min: {MinMaxMomentary.X}, Max: {MinMaxMomentary.Y}");
			Section.Text(f"Integrated: {GetIntegrated(LoudnessData.Momentary)}, Duration: {Time::GetRealTimeSince(LoudnessDuration)}");
		}

		if (bShowShortTerm)
		{
			PaintGraph(LoudnessData.ShortTerm, Section, FLinearColor::Red);
			Section.Text(f"ShortTerm: {GetAndSetMinMax(LoudnessData.ShortTerm, MinMaxShortTerm)}, Min: {MinMaxShortTerm.X}, Max: {MinMaxShortTerm.Y}");
		}
	}

	float GetAndSetMinMax(const FAudioProfilingWeightedPowerLoudnessData& Data, FVector2D& MinMax)
	{
		auto CurrentValue = GetCurrentWeightedValue(Data);
		
		// Let us get a few valid values first.
		if (Data.CurrentIndex > 60)
			MinMax.X = Math::Min(MinMax.X, CurrentValue);
		MinMax.Y = Math::Max(MinMax.Y, CurrentValue);

		return CurrentValue;
	}

	void PaintGraph(const FAudioProfilingWeightedPowerLoudnessData& Data, const FHazeImmediateSectionHandle& Section, FLinearColor LineColor)
	{
		const float GraphWidthSeconds = 60.0 * 3;
		const float GraphHeightKbps = 40.0;
		const float WidthOffset = 35;

		auto LeftBox = Section
			.HorizontalBox()
			.SlotFill()
			.VerticalBox()
			.SlotMaxHeight(250)
			.BorderBox();

		auto GraphPaint = LeftBox.PaintCanvas();
		FVector2D GraphSize = GraphPaint.WidgetGeometrySize;
		float KbpsToHeight = (GraphSize.Y - 15) / GraphHeightKbps;

		// Line data
		int StartIndex = Math::Max(0, Data.CurrentIndex - int(GraphWidthSeconds));
		int PointCount = Math::Min(int(GraphWidthSeconds), Data.CurrentIndex);

		auto GreyLineColor = FLinearColor::White;
		GreyLineColor.A = .5;

		int StepSize = 3;
		int MaxStepValue = Math::IntegerDivisionTrunc(54, StepSize);
		for (int i=2; i < MaxStepValue; ++i)
			DrawGraphDBLine(GraphPaint, GraphSize, GreyLineColor, KbpsToHeight, i * StepSize);

		float PointSpacing = (GraphSize.X - WidthOffset) / GraphWidthSeconds;
		for (int i = 1; i < PointCount; ++i)
		{
			int PointIndex = StartIndex + i;
			auto SecondData = Math::Abs(ConvertWeightedPower(Data.WeightedPower[PointIndex]));
			auto PrevSecondData = Math::Abs(ConvertWeightedPower(Data.WeightedPower[PointIndex - 1]));

			float PointRecvHeight = (SecondData) * KbpsToHeight - GraphHeightOffset;
			float PrevPointRecvHeight = (PrevSecondData) * KbpsToHeight - GraphHeightOffset;

			auto CurrentColor = GetColorBasedOnValue(-SecondData);
			auto PreviousColor = GetColorBasedOnValue(-PrevSecondData);

			auto LineColorBasedOnValueAlhpa = FLinearColor::LerpUsingHSV(PreviousColor, CurrentColor, 0.5);

			GraphPaint.Line(
				FVector2D(WidthOffset + (i - 1) * PointSpacing, PrevPointRecvHeight),
				FVector2D(WidthOffset + i * PointSpacing, PointRecvHeight),
				LineColorBasedOnValueAlhpa,
				2.0);
		}
		
		// Axes
		GraphPaint.Line(
			FVector2D(WidthOffset, 0.0),
			FVector2D(WidthOffset, GraphSize.Y),
			FLinearColor::White,
			1.0);

		GraphPaint.Line(
			FVector2D(0.0, GraphSize.Y - 30.0),
			FVector2D(GraphSize.X, GraphSize.Y - 30.0),
			FLinearColor::White,
			1.0);
	}

	FLinearColor GetColorBasedOnValue(const float& Value)
	{
		if (Value > -18)
			return FLinearColor::Red;

		if (Value > -22)
			return FLinearColor::Yellow;

		if (Value > -36)
			return FLinearColor::Green;

		return FLinearColor::Gray;
	}

	void DrawGraphDBLine(const FHazeImmediatePaintCanvasHandle& GraphPaint, const FVector2D& GraphSize, const FLinearColor& Color, const float& KbpsToHeight, const float& Value)
	{
		GraphPaint.Text(FVector2D(0, (Value) * KbpsToHeight - GraphHeightOffset), f"-{Value}", Color);
		GraphPaint.Line(
			FVector2D(0.0, (Value) * KbpsToHeight - GraphHeightOffset),
			FVector2D(GraphSize.X, (Value) * KbpsToHeight - GraphHeightOffset),
			Color,
			1.0);
	}
}