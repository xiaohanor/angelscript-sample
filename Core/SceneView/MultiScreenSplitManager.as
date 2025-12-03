
struct FManualViewBlend
{
	UPROPERTY()
	FHazeManualView Source;
	UPROPERTY()
	FHazeManualView Target;
};

class AMultiScreenSplitManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	TArray<FHazeManualView> ActiveViews;

	TArray<AHazeAdditionalCameraUser> ExtraCameraUsers;
	TArray<FManualViewBlend> Blends;
	float CurrentBlendTimer = 0.0;
	float CurrentBlendDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void DeactivateViews()
	{
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);
		CurrentBlendDuration = 0.0;
		Blends.Reset();
		ActiveViews.Reset();
	}

	void SnapViews(TArray<FHazeManualView> TargetViews)
	{
		ActiveViews = TargetViews;
		CurrentBlendDuration = 0.0;
		Blends.Reset();
		SceneView::SetManualViews(ActiveViews);
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::ManualViews);
	}

	void BlendViews(TArray<FManualViewBlend> TargetBlends, float BlendDuration)
	{
		Blends = TargetBlends;
		CurrentBlendTimer = 0.0;
		CurrentBlendDuration = BlendDuration;

		for (int i = 0, BlendCount = Blends.Num(); i < BlendCount; ++i)
		{
			// If we have a non-zero view blended in for this slot, we blend from that instead of the specified source
			if (i < ActiveViews.Num()
				&& (ActiveViews[i].TopLeft.X != ActiveViews[i].BottomRight.X 
					|| ActiveViews[i].TopLeft.Y != ActiveViews[i].BottomRight.Y)
				)
			{
				Blends[i].Source = ActiveViews[i];
			}
		}

		ActiveViews.SetNum(TargetBlends.Num());
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::ManualViews);
	}

	void ActivateCameraOnView(int ViewIndex, AHazeCameraActor Camera, float BlendTime)
	{
		if (Camera == nullptr)
			return;

		if (ViewIndex < 2)
		{
			AHazePlayerCharacter Player = Game::GetPlayer(EHazePlayer(ViewIndex));
			Player.ActivateCamera(Camera, BlendTime, this);
		}
		else
		{
			AHazeAdditionalCameraUser CamUser;
			if (ExtraCameraUsers.IsValidIndex(ViewIndex - 2))
			{
				CamUser = ExtraCameraUsers[ViewIndex-2];
			}
			if (CamUser == nullptr)
			{
				CamUser = SpawnActor(AMultiScreenCameraUser);

				switch (ViewIndex)
				{
					case 2:
						CamUser.CameraUser.ChangeSplitScreenPosition(EHazeSplitScreenPosition::ThirdScreen);
					break;
					case 3:
						CamUser.CameraUser.ChangeSplitScreenPosition(EHazeSplitScreenPosition::FourthScreen);
					break;
					case 4:
						CamUser.CameraUser.ChangeSplitScreenPosition(EHazeSplitScreenPosition::FifthScreen);
					break;
				}

				ExtraCameraUsers.SetNum(ViewIndex-1);
				ExtraCameraUsers[ViewIndex-2] = CamUser;
			}

			CamUser.ActivateCamera(Camera, BlendTime, this, EHazeCameraPriority::Low);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CurrentBlendDuration != 0.0)
		{
			CurrentBlendTimer += DeltaSeconds;

			if (CurrentBlendTimer > CurrentBlendDuration)
			{
				CurrentBlendDuration = 0.0;
				for (int i = 0, BlendCount = Blends.Num(); i < BlendCount; ++i)
					ActiveViews[i] = Blends[i].Target;
				Blends.Reset();
			}
			else
			{
				float BlendPct = CurrentBlendTimer / CurrentBlendDuration;

				for (int i = 0, BlendCount = Blends.Num(); i < BlendCount; ++i)
				{
					FHazeManualView Source = Blends[i].Source;
					FHazeManualView Target = Blends[i].Target;

					FHazeManualView View;
					View.TopLeft.X = Math::Lerp(Source.TopLeft.X, Target.TopLeft.X, BlendPct);
					View.TopLeft.Y = Math::Lerp(Source.TopLeft.Y, Target.TopLeft.Y, BlendPct);
					View.BottomRight.X = Math::Lerp(Source.BottomRight.X, Target.BottomRight.X, BlendPct);
					View.BottomRight.Y = Math::Lerp(Source.BottomRight.Y, Target.BottomRight.Y, BlendPct);

					ActiveViews[i] = View;
				}
			}

			SceneView::SetManualViews(ActiveViews);
		}
	}
};