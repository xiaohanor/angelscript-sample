class ASanctuaryArenaClampCameraFocusSpline : ASplineActor
{

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	private uint LastRefreshFrame = 0;

	UPROPERTY(Transient)
	TArray<USanctuaryArenaClampCameraFocusSplineComponent> ClampComponents;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		Spline.UpdateSpline();
		RefreshAll();
		Spline.EditingSettings.VisualizeScale = 1;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RefreshAll();
	}

	UFUNCTION(CallInEditor)
	void RefreshAll()
	{
		if(LastRefreshFrame == Time::FrameNumber)
			return;
		RefreshClampComponents();
		LastRefreshFrame = Time::FrameNumber;
	}

	UFUNCTION(CallInEditor)
	void RefreshClampComponents()
	{
		if (LastRefreshFrame == Time::FrameNumber)
			return;

		ClampComponents.Reset();
		GetComponentsByClass(ClampComponents);

		for (USanctuaryArenaClampCameraFocusSplineComponent CamSettingComp : ClampComponents)
			CamSettingComp.DistanceAlongSpline = Spline.GetClosestSplineDistanceToWorldLocation(CamSettingComp.WorldLocation);

		// ClampComponents.Sort();
	}


// YW shamelessly stolen from AJetskiSpline, thanks findity
// @return False if only one or no components are valid
	bool GetSplineClampComponents(float DistanceAlongSpline, USanctuaryArenaClampCameraFocusSplineComponent&out Previous, USanctuaryArenaClampCameraFocusSplineComponent&out Next, float&out Alpha) const
	{
		if (ClampComponents.Num() == 0)
		{
			Previous = nullptr;
			Next = nullptr;
			Alpha = 0;
			return false;
		}

		if (ClampComponents.Num() == 1)
		{
			Previous = nullptr;
			Next = ClampComponents[0];
			Alpha = 1;
			return false;
		}

		if (DistanceAlongSpline < KINDA_SMALL_NUMBER || DistanceAlongSpline < ClampComponents[0].DistanceAlongSpline)
		{
			// Before the spline or the first look component
			Previous = ClampComponents[0];
			Next = ClampComponents[1];
			Alpha = 0;
			return true;
		}

		if (DistanceAlongSpline > Spline.SplineLength - KINDA_SMALL_NUMBER || DistanceAlongSpline > ClampComponents[ClampComponents.Num() - 1].DistanceAlongSpline)
		{
			// After the spline or the last look component
			Previous = ClampComponents[ClampComponents.Num() - 2];
			Next = ClampComponents[ClampComponents.Num() - 1];
			Alpha = 1;
			return true;
		}

		// FB TODO: Faster search?
		for (int i = 1; i < ClampComponents.Num(); i++)
		{
			USanctuaryArenaClampCameraFocusSplineComponent PreviousComp = ClampComponents[i - 1];
			if(PreviousComp.DistanceAlongSpline > DistanceAlongSpline)
				continue;

			USanctuaryArenaClampCameraFocusSplineComponent NextComp = ClampComponents[i];
			if(NextComp.DistanceAlongSpline < DistanceAlongSpline)
				continue;
			
			Previous = PreviousComp;
			Next = NextComp;

			Alpha = Math::NormalizeToRange(DistanceAlongSpline, PreviousComp.DistanceAlongSpline, NextComp.DistanceAlongSpline);
			return true;
		}

		check(false);
		return false;
	}
};