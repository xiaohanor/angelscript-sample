

class ADiagonalSplitManager : ACustomMergeSplitManager
{
	UPROPERTY(EditAnywhere)
	float StartingAngle = 0.0;

	UPROPERTY(EditAnywhere)
	float StartingSplitPercentage = 0.5;

	UPROPERTY(EditAnywhere)
	FHazeRange CameraHorizontalOffsets(-0.3, 0.3);

	UPROPERTY(EditAnywhere)
	FHazeRange CameraVerticalOffsets(-0.6, 0.3);

	UPROPERTY()
	TSubclassOf<UDiagonalSplitOverlayWidget> DiagonalOverlayWidget;

	private float CurrentDiagonalAngle = 0.0;
	private float CurrentSplitPercentage = 0.5;
	private UDiagonalSplitOverlayWidget OverlayWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		CurrentDiagonalAngle = StartingAngle;
		CurrentSplitPercentage = StartingSplitPercentage;
		OnStateUpdated();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//SetDiagonalAngle(280.0);
		//SetDiagonalAngle(Math::Fmod(Time::GameTimeSeconds * 40.0, 360.0));
		//SetSplitPercentage(0.8);
		//SetSplitPercentage(Math::Abs(Math::Sin(Time::GameTimeSeconds / 5.0)));
		//OnStateUpdated();

		Super::Tick(DeltaSeconds);
	}

	/**
	 * Set the split percentage between the two views.
	 * 0 is fully mio, 1 is fully zoe.
	 */
	UFUNCTION()
	void SetSplitPercentage(float SplitPct)
	{
		CurrentSplitPercentage = SplitPct;
		OnStateUpdated();
	}

	/**
	 * Set the diagonal split angle in degrees.
	 * 0 is a normal horizontal splitscreen, 90 is a normal vertical splitscreen
	 */
	UFUNCTION()
	void SetDiagonalAngle(float AngleDegrees)
	{
		CurrentDiagonalAngle = AngleDegrees;
		OnStateUpdated();
	}

	void DeactivateCustomSplit() override
	{
		Super::DeactivateCustomSplit();

		if (OverlayWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(OverlayWidget);
			OverlayWidget = nullptr;
		}
	}

	void ActivateCustomSplit() override
	{
		Super::ActivateCustomSplit();
		OnStateUpdated();

		if (DiagonalOverlayWidget.IsValid())
		{
			OverlayWidget = Widget::AddFullscreenWidget(DiagonalOverlayWidget);
			OverlayWidget.SplitAngle = CurrentDiagonalAngle;
		}
	}

	private void OnStateUpdated()
	{
		float OffsetAngle = Math::DegreesToRadians(CurrentDiagonalAngle + 90.0);

		float UpLength = Math::Abs(Math::Tan(OffsetAngle)) + 1.0;
		float OffsetLength = Math::Abs(UpLength * Math::Cos(OffsetAngle));

		float SplitOffsetPct = (0.5 - CurrentSplitPercentage) * 2.0;
		float OffsetX = Math::Cos(OffsetAngle) * SplitOffsetPct * OffsetLength;
		float OffsetY = Math::Sin(OffsetAngle) * SplitOffsetPct * OffsetLength;

		if (SplitScreenInstance != nullptr)
		{
			SplitScreenInstance.SetScalarParameterValue(n"SplitAngle", Math::DegreesToRadians(CurrentDiagonalAngle));
			SplitScreenInstance.SetScalarParameterValue(n"SplitPercentage", CurrentSplitPercentage);

			SplitScreenInstance.SetScalarParameterValue(n"SplitOffsetX", OffsetX);
			SplitScreenInstance.SetScalarParameterValue(n"SplitOffsetY", OffsetY);
		}

		if (bEnabled)
		{
			for (auto Player : Game::Players)
			{
				float PerpAngle = CurrentDiagonalAngle;
				if (Player.IsMio())
					PerpAngle += 90.0;
				else
					PerpAngle -= 90.0;

				FVector2D Offset;
				Offset.X = -OffsetX;
				Offset.Y = -OffsetY;

				float PctX = Math::Cos(Math::DegreesToRadians(PerpAngle));
				if (PctX > 0.0)
					Offset.X += PctX * CameraHorizontalOffsets.Min;
				else
					Offset.X += -PctX * CameraHorizontalOffsets.Max;

				float PctY = Math::Sin(Math::DegreesToRadians(PerpAngle));
				if (PctY > 0.0)
					Offset.Y += PctY * CameraVerticalOffsets.Min;
				else
					Offset.Y += -PctY * CameraVerticalOffsets.Max;

				float VisiblePct;
				if (Player.IsMio())
					VisiblePct = CurrentSplitPercentage;
				else
					VisiblePct = 1.0 - CurrentSplitPercentage;

				float CenterAlpha = Math::GetMappedRangeValueClamped(
					FVector2D(0.5, 0.8),
					FVector2D(0.0, 1.0),
					VisiblePct
				);
				Offset = Math::Lerp(Offset, FVector2D(0.0, 0.0), CenterAlpha);

				auto CameraView = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
				CameraView.ApplyOffCenterProjectionOffset(Offset, this);
			}
		}

		if (OverlayWidget != nullptr)
		{
			OverlayWidget.SplitAngle = CurrentDiagonalAngle;
			OverlayWidget.CenterOffsetX = OffsetX;
			OverlayWidget.CenterOffsetY = OffsetY;
		}
	}
};

UCLASS(Abstract)
class UDiagonalSplitOverlayWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float SplitAngle = 0.0;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float CenterOffsetX = 0.0;
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float CenterOffsetY = 0.0;

	UFUNCTION(BlueprintOverride)
	void OnPaint(FPaintContext& Context) const
	{
		FVector2D Size = Context.AllottedGeometry.LocalSize;

		FVector2D Center(0.5, 0.5);
		Center.X += CenterOffsetX * 0.5;
		Center.Y -= CenterOffsetY * 0.5;

		float Radius = 1.0;

		FVector2D Start;
		Start.X = Center.X - Math::Cos(Math::DegreesToRadians(SplitAngle)) * Radius;
		Start.Y = Center.Y + Math::Sin(Math::DegreesToRadians(SplitAngle)) * Radius;

		FVector2D End;
		End.X = Center.X + (Math::Cos(Math::DegreesToRadians(SplitAngle)) * Radius);
		End.Y = Center.Y - (Math::Sin(Math::DegreesToRadians(SplitAngle)) * Radius);

		FVector2D LocalStart(Start.X * Size.X, Start.Y * Size.Y);
		FVector2D LocalEnd(End.X * Size.X, End.Y * Size.Y);

		Context.DrawLine(
			LocalStart, LocalEnd,
			FLinearColor::Black, 4.0);
	}
};
