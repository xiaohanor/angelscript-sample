class AFullscreenTransitionInner : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	AHazeAdditionalCameraUser CameraUser;
	float Timer;
	float BlendDuration;
	float TotalDuration;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void TransitionToFullscreen(AHazeCameraActor Camera, float BlendTime = 1.0, float Duration = 1.0)
	{
		Timer = 0.0;
		BlendDuration = BlendTime;
		TotalDuration = Duration;

		CameraUser = SpawnActor(AMultiScreenCameraUser);
		CameraUser.CameraUser.ChangeSplitScreenPosition(EHazeSplitScreenPosition::ThirdScreen);
		CameraUser.ActivateCamera(Camera, 0.0, this, EHazeCameraPriority::Medium);

		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::ManualViews);
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;
		if (Timer >= TotalDuration)
		{
			SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);
			SetActorTickEnabled(false);

			CameraUser.DestroyActor();
		}
		else
		{
			float Alpha = Math::Saturate(Timer / BlendDuration);

			TArray<FHazeManualView> ActiveViews;

			{
				FHazeManualView View;
				View.TopLeft.X = 0.0;
				View.TopLeft.Y = 0.0;
				View.BottomRight.X = 0.5 - 0.5 * Alpha;
				View.BottomRight.Y = 1.0;
				ActiveViews.Add(View);
			}
			{
				FHazeManualView View;
				View.TopLeft.X = 0.5 + 0.5 * Alpha;
				View.TopLeft.Y = 0.0;
				View.BottomRight.X = 1.0;
				View.BottomRight.Y = 1.0;
				ActiveViews.Add(View);
			}
			{
				FHazeManualView View;
				View.TopLeft.X = 0.5 - 0.5 * Alpha;
				View.TopLeft.Y = 0.0;
				View.BottomRight.X = 0.5 + 0.5 * Alpha;
				View.BottomRight.Y = 1.0;
				ActiveViews.Add(View);
			}

			SceneView::SetManualViews(ActiveViews);
		}
	}
};