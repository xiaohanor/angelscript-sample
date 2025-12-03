struct FMeltdownEndingLevelData
{

}

class AMeltdownEndingManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere, Interp)
	float MiddleSplitSize = 0.0;

	UPROPERTY(EditAnywhere, Interp)
	float ProjectionOffsetPercentage = 0.0;

	UPROPERTY(EditAnywhere, Interp)
	bool bIsFullscreen = false;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor MiddleCameraActor;

	bool bManagerActive = false;
	AHazeAdditionalCameraUser MiddleCamUser;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
	}

	UFUNCTION()
	void ActivateMeltdownEnding()
	{
		if (bManagerActive)
			return;

		bManagerActive = true;
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::ManualViews);

		MiddleCamUser = SpawnActor(AMultiScreenCameraUser);
		MiddleCamUser.CameraUser.ChangeSplitScreenPosition(EHazeSplitScreenPosition::ThirdScreen);
		MiddleCamUser.ActivateCamera(MiddleCameraActor, 0.0, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION()
	void DeactivateMeltdownEnding()
	{
		if (!bManagerActive)
			return;

		bManagerActive = false;
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);

		for (auto Player : Game::Players)
		{
			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			ViewPoint.ClearOffCenterProjectionOffset(this);
		}
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TArray<FHazeManualView> ActiveViews;

		if (bIsFullscreen)
		{
			FHazeManualView View;
			View.TopLeft.X = 0.0;
			View.TopLeft.Y = 0.0;
			View.BottomRight.X = 1.0;
			View.BottomRight.Y = 1.0;
			ActiveViews.Add(View);
		}
		else
		{
			// Mio's view
			{
				FHazeManualView View;
				View.TopLeft.X = 0.0;
				View.TopLeft.Y = 0.0;
				View.BottomRight.X = 0.5 - (MiddleSplitSize * 0.5);
				View.BottomRight.Y = 1.0;
				ActiveViews.Add(View);
			}

			// Zoe's view
			{
				FHazeManualView View;
				View.TopLeft.X = 0.5 + (MiddleSplitSize * 0.5);
				View.TopLeft.Y = 0.0;
				View.BottomRight.X = 1.0;
				View.BottomRight.Y = 1.0;
				ActiveViews.Add(View);
			}

			if (MiddleSplitSize > 0.0)
			{
				// Rader's view
				FHazeManualView View;
				View.TopLeft.X = 0.5 - (MiddleSplitSize * 0.5);
				View.TopLeft.Y = 0.0;
				View.BottomRight.X = 0.5 + (MiddleSplitSize * 0.5);
				View.BottomRight.Y = 1.0;
				ActiveViews.Add(View);
			}
		}

		for (auto Player : Game::Players)
		{
			float OffCenterTarget = Player.IsMio() ? -1.0 : 1.0;
			if (bIsFullscreen)
				OffCenterTarget = 0.0;

			auto ViewPoint = Cast<UHazeCameraViewPoint>(Player.GetViewPoint());
			ViewPoint.ApplyOffCenterProjectionOffset(
				FVector2D(Math::Lerp(0.0, OffCenterTarget, ProjectionOffsetPercentage), 0.0),
				this
			);
		}

		SceneView::SetManualViews(ActiveViews);
	}
};