event void FSkylineBallBossChaseSplineEvent(ESkylineBallBossChaseEventType EventType, FSkylineBallBossChaseSplineEventData EventData);

UCLASS(NotBlueprintable)
class ASkylineBallBossChaseSpline : ASplineActor
{
	UPROPERTY(Transient)
	TArray<USkylineBallBossChaseSplineEventComponent> EventComponents;

	UPROPERTY(EditAnywhere, Category = "Chase Spline")
	float OverrideLaserSpeed = -1.0;

	UPROPERTY(EditAnywhere, Category = "Chase Spline")
	bool bAutoProceedToNext = true;

	UPROPERTY(EditAnywhere, Category = "Chase Spline")
	bool bAutoKillPlayer = true;

	private uint LastRefreshFrame = 0;

#if EDITOR
	default Spline.EditingSettings.SplineColor = OverrideLaserSpeed > KINDA_SMALL_NUMBER ? ColorDebug::Grape : ColorDebug::Watermelon;

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
	bool GetSplineEventComponents(float DistanceAlongSpline, USkylineBallBossChaseSplineEventComponent&out Previous, USkylineBallBossChaseSplineEventComponent&out Next, float&out Alpha) const
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
			USkylineBallBossChaseSplineEventComponent PreviousComp = EventComponents[i - 1];
			if(PreviousComp.DistanceAlongSpline > DistanceAlongSpline)
				continue;

			USkylineBallBossChaseSplineEventComponent NextComp = EventComponents[i];
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

#if EDITOR
class USkylineBallBossChaseSplineAutoRadiusContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
	                           UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(ASkylineBallBossChaseSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Ball Boss Chase Spline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		ASkylineBallBossChaseSpline ChaseSpline = Cast<ASkylineBallBossChaseSpline>(Spline.Owner);
		if(ChaseSpline == nullptr)
			return;

		{
			FHazeContextOption AddSplineEvent;
			AddSplineEvent.DelegateParam = n"SetAutoRadius";
			AddSplineEvent.Label = "Set Auto Radius";
			AddSplineEvent.Icon = n"Icons.Plus";
			Menu.AddOption(AddSplineEvent, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;
		ASkylineBallBossChaseSpline ChaseSpline = Cast<ASkylineBallBossChaseSpline>(Spline.Owner);
		if(ChaseSpline == nullptr)
			return;

		if (OptionName == n"SetAutoRadius")
		{
			const float AutoRadius = 3900.0; // The "radius" of the car garage in level Skyline_CarTower_P
			for (int i = 0; i < Selection.MultiplePoints.Num(); ++i)
			{
				int PointIndex = Selection.MultiplePoints[i];
				FVector RelativeLocation = ChaseSpline.Spline.SplinePoints[PointIndex].RelativeLocation;
				float PreviousZ = RelativeLocation.Z;
				RelativeLocation.Z = 0.0;
				ChaseSpline.Spline.SplinePoints[PointIndex].RelativeLocation = RelativeLocation.GetSafeNormal() * AutoRadius;
				ChaseSpline.Spline.SplinePoints[PointIndex].RelativeLocation.Z = PreviousZ;
			}
			Editor::SelectComponent(ChaseSpline.Spline);
			Spline.Owner.Modify();
			return;
		}
	}
};
#endif