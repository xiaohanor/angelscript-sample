

class UAudioGraphWidget : UHazeAudioGraphWidget
{
	UPROPERTY()
	UFont TextFont;

	float CurrentLinePosition;
	float FontSize = 12;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		auto MousePosition = WidgetLayout::GetMousePositionOnViewport();
		MousePosition = MyGeometry.AbsoluteToLocal(MousePosition);
		CurrentLinePosition = Math::Clamp(MousePosition.X, 1, MyGeometry.LocalSize.X);

		TArray<FName> ToRemove;

		for (auto KeyValuePair: GraphEntries.Entries)
		{
			// Let it live at least one frame, if zero.
			if (KeyValuePair.Value.Duration < 0)
			{
				ToRemove.Add(KeyValuePair.Key);
				continue;
			}

			KeyValuePair.Value.Duration -= InDeltaTime;
		}

		for (const auto Key: ToRemove)
		{
			GraphEntries.Entries.Remove(Key);
		}

		if (GraphEntries.Entries.Num() == 0)
			RemoveFromDebugging();
	}

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		FGeometry Geometry = GetCachedGeometry();

		float TextPercentage = 0.05;
		float YReservedTextSpace = (Geometry.LocalSize.Y * TextPercentage) * (GraphEntries.Entries.Num() + 1);
		// Scale the position of the lines with the size of the graph
		float XScale = Geometry.LocalSize.X / Math::Max(1, GraphEntries.MaxSamples);
		float YOffset = Geometry.LocalSize.Y - YReservedTextSpace;

		float LinePositionX = CurrentLinePosition == GraphEntries.MaxSamples ?  Geometry.LocalSize.X : CurrentLinePosition;
		float Counter = 1;

		int MaxSampleCount = 0;
		for (auto& Pair: GraphEntries.Entries)
		{
			const FHazeAudioGraphEntry& Entry = Pair.Value;
			MaxSampleCount = Math::Max(MaxSampleCount, Entry.Samples.Num());
		}

		TArray<FVector2D> Line;
		for (auto& Pair: GraphEntries.Entries)
		{
			const FHazeAudioGraphEntry& Entry = Pair.Value;

			if (Entry.Samples.Num() == 0) 
			{
				continue;
			}	

			// float YScale = Geometry.LocalSize.Y / Entry.MaxYValue * -1.0;
			int StartIndex = Math::Max(0,  Entry.Samples.Num() - int(GraphEntries.MaxSamples));
			int PointCount = Math::Min(int(GraphEntries.MaxSamples), Entry.Samples.Num());
			float XOffset = GraphEntries.MaxSamples - MaxSampleCount;

			Line.SetNum(MaxSampleCount * 2);

			float HoveredValue = Entry.HoveredValue;
			SetLineEntries(
				PointCount, MaxSampleCount, StartIndex, 
				Entry.Samples, Line, HoveredValue,
				XScale, Entry.MaxValue, Entry.MinValue, 
				XOffset, YOffset);
			Widget::DrawLines(Context, Line, Entry.Color, false, 1.0);

			const FString KeyValue = Entry.ID + 
				", Max: " + Entry.MaxValue + 
				", Min: " + Entry.MinValue + 
				", Current: " + Entry.Samples[0] +
				", Cursor: " + HoveredValue;
			const FText Text = FText::FromString(KeyValue);
			
			float ApproxWidth = KeyValue.Len() * 17.5 * XScale;

			FVector2D TextPosition = 
				FVector2D(ApproxWidth, YOffset + Counter * (Geometry.LocalSize.Y * TextPercentage));
			TextPosition.X -= ApproxWidth;
			Widget::DrawTextFormatted(Context, Text, TextPosition, TextFont, FontSize, Tint = Entry.Color);
			++Counter;
		}

		// Line to show most recent value
		Widget::DrawLine(
			Context,
			FVector2D(LinePositionX, 0.0),
			FVector2D(LinePositionX, YOffset),
			FLinearColor::Yellow, false, 1.0
		);
	}

	void SetLineEntries(int PointCount, int MaxPointCount, int StartIndex, 
		const TArray<float32>& Elements, TArray<FVector2D>& Line, float& HoveredValue,
		float XScale, float MaxY, float MinY, float XOffset, float YOffset) const
	{
		FVector2D Previous;
		float LinePositionX = CurrentLinePosition == GraphEntries.MaxSamples ? GraphEntries.MaxSamples - XOffset : CurrentLinePosition;
		LinePositionX = Math::RoundToInt(LinePositionX);

		bool bFoundHoveredValue = false;
		int FillerCount = MaxPointCount - PointCount;
		
		// Note: Not final
		// Always fill the whole graph, fill out with the last value
		for(int i = 0; i < MaxPointCount; ++i)
		{
			// Invert flow
			int InverseIndex = i < FillerCount ?
				PointCount - 1 :
				PointCount - 1 - (i - FillerCount + StartIndex);
				
			const auto& Sample = Elements[InverseIndex + StartIndex];
			
			FVector2D Current;
			Current.X = Math::RoundToInt(((XOffset + i) * XScale));
			if (Math::IsNearlyEqual(Current.X, LinePositionX) ||
				(LinePositionX > Previous.X && LinePositionX < Current.X))
			{
				bFoundHoveredValue = true;
				HoveredValue = Sample;
			}

			Current.Y = Math::RoundToInt(Math::GetPercentageBetween(MaxY, MinY, Sample) * YOffset);
			
			// Add line the drawlist
			if(i == 0)
			{
				Line[i*2] = Current;
			}
			else
			{
				Line[i*2] = Previous;
			}

			Line[i*2 + 1] = Current;

			Previous = Current;
		}

		if (!bFoundHoveredValue)
		{
			// The latest value
			HoveredValue = Elements[0];
		}
	}

	UFUNCTION(BlueprintEvent)
	UTextBlock GetFloatText() property
	{
		return nullptr;
	}

	UFont GetFontForText()
	{
		FSlateFontInfo FontInfo = FloatText.GetFont();

		return Cast<UFont>(FontInfo.FontObject);
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		TextFont = GetFontForText();
	}
}