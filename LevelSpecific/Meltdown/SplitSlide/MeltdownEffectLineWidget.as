struct FMeltdownEffectLineDistortionSphere
{
	AHazePlayerCharacter PlayerScreen;
	FVector Center;
	float ScreenWidth = 0.03;
	float ScreenHeight= 0.08;
}

class UMeltdownEffectLineWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UCanvasPanel MainCanvas;

	UPROPERTY()
	TSubclassOf<UMeltdownEffectLineDistortionWidget> DistortionWidgetClass;

	TArray<FMeltdownEffectLineDistortionSphere> DistortionSpheres;
	TArray<UMeltdownEffectLineDistortionWidget> DistortionWidgets;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		float DistortionCenterX = 0.5;

		int DistortionIndex = 0;

		for (FMeltdownEffectLineDistortionSphere& Sphere : DistortionSpheres)
		{
			FVector2D ScreenPos;
			if (!SceneView::ProjectWorldToScreenPosition(Sphere.PlayerScreen, Sphere.Center, ScreenPos))
				continue;

			float DistortionDistance = Math::Abs(ScreenPos.X - DistortionCenterX);
			if (DistortionDistance > Sphere.ScreenWidth)
				continue;

			float DistortionSize = Math::GetMappedRangeValueClamped(
				FVector2D(Sphere.ScreenWidth, 0.0),
				FVector2D(0.0, 1.0),
				DistortionDistance
			);

			if (!DistortionWidgets.IsValidIndex(DistortionIndex))
			{
				auto NewWidget = Widget::CreateWidget(this, DistortionWidgetClass);
				MainCanvas.AddChild(NewWidget);
				DistortionWidgets.Add(NewWidget);
			}

			auto DistortionSlot = Cast<UCanvasPanelSlot>(DistortionWidgets[DistortionIndex].Slot);

			float DistortionHeight = Sphere.ScreenHeight * DistortionSize;
			float PixelYPos = (ScreenPos.Y - DistortionHeight) * MyGeometry.LocalSize.Y;
			float PixelHeight = (DistortionHeight * 2.0) * MyGeometry.LocalSize.Y;

			DistortionSlot.SetAnchors(FAnchors(0, 0, 1, 0));
			DistortionSlot.SetOffsets(FMargin(0, PixelYPos, 0, PixelHeight));

			++DistortionIndex;
		}

		while (DistortionIndex < DistortionWidgets.Num())
		{
			DistortionWidgets.Last().RemoveFromParent();
			DistortionWidgets.RemoveAt(DistortionWidgets.Num() - 1);
		}
	}
}

class UMeltdownEffectLineDistortionWidget : UHazeUserWidget
{
}