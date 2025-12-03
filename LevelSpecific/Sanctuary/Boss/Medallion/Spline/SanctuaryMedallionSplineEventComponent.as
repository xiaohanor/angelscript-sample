event void FSanctuaryMedallionSplineEvent(ESanctuaryMedallionSplineEventType EventType, FSanctuaryMedallionSplineEventData EventData);

enum ESanctuaryMedallionSplineEventType
{
	None,
	LoopBack,
	LoopBackBack,
}

struct FSanctuaryMedallionSplineEventData
{
	UPROPERTY(VisibleInstanceOnly, Transient)
	float SplineDistance = 0.0;
	// add hydra enum
}

UCLASS(NotBlueprintable)
class USanctuaryMedallionSplineEventComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Spline Event")
	ESanctuaryMedallionSplineEventType EventType;

	UPROPERTY(EditAnywhere, Category = "Spline Event")
	FSanctuaryMedallionSplineEventData EventData;

	UPROPERTY(VisibleInstanceOnly, Transient)
	float DistanceAlongSpline = -1;

	bool bPlanePassed = false;

	private UHazeSplineComponent SplineComp;

	FLinearColor GetDebugColor()
	{
		switch (EventType)
		{
			case ESanctuaryMedallionSplineEventType::None:
				return ColorDebug::Gray;
			case ESanctuaryMedallionSplineEventType::LoopBack:
				return ColorDebug::Cerulean;
			case ESanctuaryMedallionSplineEventType::LoopBackBack:
				return ColorDebug::Ultramarine;
		}
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		RefreshDistanceAlongSpline();
		SnapToSpline();
	}
	#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RefreshDistanceAlongSpline();
	}

	void RefreshSpline()
	{
		SplineComp = Spline::GetGameplaySpline(Owner);
		check(HasValidSpline());
	}

	void SnapToSpline()
	{
		if(!ensure(HasValidSpline()))
			return;

		if(!ensure(DistanceAlongSpline >= 0))
			return;

		FTransform SplineTransform = SplineComp.GetWorldTransformAtSplineDistance(DistanceAlongSpline);
		SetWorldLocationAndRotation(SplineTransform.Location, SplineTransform.Rotation);
	}

	void RefreshDistanceAlongSpline()
	{
		if(!(HasValidSpline()))
			RefreshSpline();
		DistanceAlongSpline = SplineComp.GetClosestSplineDistanceToWorldLocation(WorldLocation);
		EventData.SplineDistance = DistanceAlongSpline;
	}

	bool HasValidSpline() const
	{
		if(SplineComp == nullptr)
			return false;

		if(SplineComp.SplinePoints.Num() < 2)
			return false;

		if(SplineComp.SplineLength < 1)
			return false;

		return true;
	}

	int opCmp(USanctuaryMedallionSplineEventComponent Other) const
	{
		if(DistanceAlongSpline > Other.DistanceAlongSpline)
			return 1;
		else
			return -1;
	}
};

#if EDITOR
class USanctuaryMedallionSplineEventComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryMedallionSplineEventComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ChaseEventComp = Cast<USanctuaryMedallionSplineEventComponent>(Component);
		if(ChaseEventComp == nullptr)
			return;

		auto Spline = Cast<ASanctuaryBossMedallionSpline>(ChaseEventComp.Owner);
		if(Spline == nullptr)
			return;

		const FVector Location = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(ChaseEventComp.WorldLocation);
		DrawWireSphere(Location, 350, ChaseEventComp.GetDebugColor(), 1, 12, true);
		DrawWireSphere(Location, 50, ChaseEventComp.GetDebugColor(), 3, 12, true);
		FString Text = GetSaneName(ChaseEventComp);
		DrawWorldString(Text, Location, FLinearColor::White, 1.6,  30000, true, true);
	}

	private FString GetSaneName(USanctuaryMedallionSplineEventComponent ChaseEventComp) const
	{
		FString Unused;
		FString Used;
		FString EnumString = "" + ChaseEventComp.EventType;
		FString Splitter = ":";
		String::Split(EnumString, Splitter, Unused, Used, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
		return Used;
	}
};

class USanctuaryAddMedallionSplineEventContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
	                           UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(ASanctuaryBossMedallionSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Medallion Spline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		{
			FHazeContextOption AddSplineEvent;
			AddSplineEvent.DelegateParam = n"AddSplineEvent";
			AddSplineEvent.Label = "Add Spline Event";
			AddSplineEvent.Icon = n"Icons.Plus";
			Menu.AddOption(AddSplineEvent, MenuDelegate);
		}

		ASanctuaryBossMedallionSpline Medallion = Cast<ASanctuaryBossMedallionSpline>(Spline.Owner);
		if(Medallion == nullptr)
			return;

		USanctuaryMedallionSplineEventComponent Previous;
		USanctuaryMedallionSplineEventComponent Next;
		float Alpha;		
		Medallion.GetSplineEventComponents(ClickedDistance, Previous, Next, Alpha);

		if(Previous != nullptr)
		{
			FHazeContextOption DuplicatePreviousSplineEvent;
			DuplicatePreviousSplineEvent.DelegateParam = n"DuplicatePreviousSplineEvent";
			DuplicatePreviousSplineEvent.Label = "Duplicate Previous Spline Event";
			DuplicatePreviousSplineEvent.Icon = n"GenericCommands.Duplicate";
			Menu.AddOption(DuplicatePreviousSplineEvent, MenuDelegate);
		}

		if(Next != nullptr)
		{
			FHazeContextOption DuplicateNextSplineEvent;
			DuplicateNextSplineEvent.DelegateParam = n"DuplicateNextSplineEvent";
			DuplicateNextSplineEvent.Label = "Duplicate Next Spline Event";
			DuplicateNextSplineEvent.Icon = n"GenericCommands.Duplicate";
			Menu.AddOption(DuplicateNextSplineEvent, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddSplineEvent")
		{
			auto AddedSplineEvent = USanctuaryMedallionSplineEventComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineEvent.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineEvent);
			Spline.Owner.Modify();
			return;
		}

		ASanctuaryBossMedallionSpline ChaseSpline = Cast<ASanctuaryBossMedallionSpline>(Spline.Owner);
		if(ChaseSpline == nullptr)
			return;

		USanctuaryMedallionSplineEventComponent Previous;
		USanctuaryMedallionSplineEventComponent Next;
		float Alpha;		
		ChaseSpline.GetSplineEventComponents(MenuClickedDistance, Previous, Next, Alpha);

		if(Previous != nullptr && OptionName == n"DuplicatePreviousSplineEvent")
		{
			auto AddedSplineEvent = USanctuaryMedallionSplineEventComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineEvent.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineEvent);
			Spline.Owner.Modify();
			return;
		}

		if(Next != nullptr && OptionName == n"DuplicateNextSplineEvent")
		{
			auto AddedSplineEvent = USanctuaryMedallionSplineEventComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineEvent.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineEvent);
			Spline.Owner.Modify();
			return;
		}
	}
};
#endif