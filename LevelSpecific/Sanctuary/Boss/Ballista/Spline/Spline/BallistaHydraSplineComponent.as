event void FSanctuaryBallistaHydraSplineEvent(ESanctuaryBallistaHydraSplineEventType EventType, FSanctuaryBallistaHydraSplineEventData EventData);

enum ESanctuaryBallistaHydraSplineEventType
{
	PlatformsFullySurfaced,
	PlatformsStartSink,
}

struct FSanctuaryBallistaHydraSplineEventData
{
	UPROPERTY(VisibleInstanceOnly, Transient)
	float SplineDistance = 0.0;
}

UCLASS(NotBlueprintable)
class USanctuaryBallistaHydraSplineEventComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Spline Event")
	ESanctuaryBallistaHydraSplineEventType EventType;

	UPROPERTY(EditAnywhere, Category = "Spline Event")
	FSanctuaryBallistaHydraSplineEventData EventData;

	UPROPERTY(VisibleInstanceOnly, Transient)
	float DistanceAlongSpline = -1;

	bool bPlanePassed = false;

	private UHazeSplineComponent SplineComp;

	FLinearColor GetDebugColor()
	{
		if (EventType == ESanctuaryBallistaHydraSplineEventType::PlatformsFullySurfaced)
			return ColorDebug::Yellow;
		if (EventType == ESanctuaryBallistaHydraSplineEventType::PlatformsStartSink)
			return ColorDebug::Magenta;
		return ColorDebug::Gray;
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

	int opCmp(USanctuaryBallistaHydraSplineEventComponent Other) const
	{
		if(DistanceAlongSpline > Other.DistanceAlongSpline)
			return 1;
		else
			return -1;
	}
};

#if EDITOR
class USanctuaryBallistaHydraSplineEventComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryBallistaHydraSplineEventComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ChaseEventComp = Cast<USanctuaryBallistaHydraSplineEventComponent>(Component);
		if(ChaseEventComp == nullptr)
			return;

		auto Spline = Cast<ABallistaHydraSpline>(ChaseEventComp.Owner);
		if(Spline == nullptr)
			return;

		const FVector Location = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(ChaseEventComp.WorldLocation);
		DrawWireSphere(Location, 100, ChaseEventComp.GetDebugColor(), 3, 12, true);
		FString Text = "" + ChaseEventComp.EventType;
		DrawWorldString(Text, Location, FLinearColor::White, 1.2, 10000, true, true);
	}
};

class USanctuaryAddBallistaHydraSplineEventContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
	                           UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(ABallistaHydraSpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "BallistaHydra Spline";
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

		ABallistaHydraSpline BallistaHydra = Cast<ABallistaHydraSpline>(Spline.Owner);
		if(BallistaHydra == nullptr)
			return;

		USanctuaryBallistaHydraSplineEventComponent Previous;
		USanctuaryBallistaHydraSplineEventComponent Next;
		float Alpha;		
		BallistaHydra.GetSplineEventComponents(ClickedDistance, Previous, Next, Alpha);

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
			auto AddedSplineEvent = USanctuaryBallistaHydraSplineEventComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineEvent.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineEvent);
			Spline.Owner.Modify();
			return;
		}

		ABallistaHydraSpline ChaseSpline = Cast<ABallistaHydraSpline>(Spline.Owner);
		if(ChaseSpline == nullptr)
			return;

		USanctuaryBallistaHydraSplineEventComponent Previous;
		USanctuaryBallistaHydraSplineEventComponent Next;
		float Alpha;		
		ChaseSpline.GetSplineEventComponents(MenuClickedDistance, Previous, Next, Alpha);

		if(Previous != nullptr && OptionName == n"DuplicatePreviousSplineEvent")
		{
			auto AddedSplineEvent = USanctuaryBallistaHydraSplineEventComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineEvent.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineEvent);
			Spline.Owner.Modify();
			return;
		}

		if(Next != nullptr && OptionName == n"DuplicateNextSplineEvent")
		{
			auto AddedSplineEvent = USanctuaryBallistaHydraSplineEventComponent::Create(Spline.Owner);
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