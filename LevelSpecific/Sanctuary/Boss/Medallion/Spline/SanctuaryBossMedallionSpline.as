UCLASS(NotBlueprintable)
class ASanctuaryBossMedallionSpline : ASplineActor
{
	UPROPERTY(Transient)
	TArray<USanctuaryMedallionSplineEventComponent> EventComponents;

	private uint LastRefreshFrame = 0;

#if EDITOR
	default Spline.EditingSettings.SplineColor = ColorDebug::Watermelon;

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
		RefreshEventComponents();
		LastRefreshFrame = Time::FrameNumber;
	}

	UFUNCTION(CallInEditor)
	void RefreshEventComponents()
	{
		if (LastRefreshFrame == Time::FrameNumber)
			return;

		EventComponents.Reset();
		GetComponentsByClass(EventComponents);

		for (auto CamSettingComp : EventComponents)
			CamSettingComp.DistanceAlongSpline = Spline.GetClosestSplineDistanceToWorldLocation(CamSettingComp.WorldLocation);

		EventComponents.Sort();
	}


// YW shamelessly stolen from AJetskiSpline, thanks findity
// @return False if only one or no components are valid
	bool GetSplineEventComponents(float DistanceAlongSpline, USanctuaryMedallionSplineEventComponent&out Previous, USanctuaryMedallionSplineEventComponent&out Next, float&out Alpha) const
	{
		if(EventComponents.Num() == 0)
		{
			Previous = nullptr;
			Next = nullptr;
			Alpha = 0;
			return false;
		}

		if(EventComponents.Num() == 1)
		{
			Previous = nullptr;
			Next = EventComponents[0];
			Alpha = 1;
			return false;
		}

		if(DistanceAlongSpline < KINDA_SMALL_NUMBER || DistanceAlongSpline < EventComponents[0].DistanceAlongSpline)
		{
			// Before the spline or the first look component
			Previous = EventComponents[0];
			Next = EventComponents[1];
			Alpha = 0;
			return true;
		}

		if(DistanceAlongSpline > Spline.SplineLength - KINDA_SMALL_NUMBER || DistanceAlongSpline > EventComponents[EventComponents.Num() - 1].DistanceAlongSpline)
		{
			// After the spline or the last look component
			Previous = EventComponents[EventComponents.Num() - 2];
			Next = EventComponents[EventComponents.Num() - 1];
			Alpha = 1;
			return true;
		}

		// FB TODO: Faster search?
		for(int i = 1; i < EventComponents.Num(); i++)
		{
			USanctuaryMedallionSplineEventComponent PreviousComp = EventComponents[i - 1];
			if(PreviousComp.DistanceAlongSpline > DistanceAlongSpline)
				continue;

			USanctuaryMedallionSplineEventComponent NextComp = EventComponents[i];
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