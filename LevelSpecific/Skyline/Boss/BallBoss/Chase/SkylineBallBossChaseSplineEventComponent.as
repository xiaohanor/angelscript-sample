enum ESkylineBallBossChaseEventTriggerType
{
	OnlyFirstPlayer,
	ForBothPlayers,
	RequireBothPlayers,
	OnlyZoe,
	OnlyMio,
	BallBoss,
	None
}

enum ESkylineBallBossChaseEventType
{
	NextChaseSpline,
	EventSpline,
	OverrideSpeed,
	OverrideHeight,

	ActivateLaser,
	DeactivateLaser,

	Trapdoor,
	TrapPlayersOnElevator,
}

struct FSkylineBallBossChaseSplineEventData
{
	UPROPERTY(EditAnywhere)
	FName Text;
	UPROPERTY(EditAnywhere)
	int Int = 0;
	UPROPERTY(EditAnywhere)
	float Float = 0.0;
	UPROPERTY(VisibleInstanceOnly, Transient)
	float SplineDistance = 0.0;
}

UCLASS(NotBlueprintable)
class USkylineBallBossChaseSplineEventComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Spline Event")
	ESkylineBallBossChaseEventType EventType;

	UPROPERTY(EditAnywhere, Category = "Spline Event")
	FSkylineBallBossChaseSplineEventData EventData;

	UPROPERTY(EditAnywhere, Category = "Spline Event")
	ESkylineBallBossChaseEventTriggerType TriggeredBy;

	bool bMioPassed = false;
	bool bZoePassed = false;
	bool bBallPassed = false;

	UPROPERTY(VisibleInstanceOnly, Transient)
	float DistanceAlongSpline = -1;

	private UHazeSplineComponent SplineComp;

	FLinearColor GetDebugColor()
	{
		if (TriggeredBy == ESkylineBallBossChaseEventTriggerType::BallBoss)
			return ColorDebug::Cerulean;
		if (TriggeredBy == ESkylineBallBossChaseEventTriggerType::OnlyMio)
			return ColorDebug::Ruby;
		if (TriggeredBy == ESkylineBallBossChaseEventTriggerType::OnlyZoe)
			return ColorDebug::Leaf;
		if (TriggeredBy == ESkylineBallBossChaseEventTriggerType::RequireBothPlayers)
			return ColorDebug::Flaxen;
		if (TriggeredBy == ESkylineBallBossChaseEventTriggerType::ForBothPlayers)
			return ColorDebug::Grapefruit;
		if (TriggeredBy == ESkylineBallBossChaseEventTriggerType::OnlyFirstPlayer)
			return ColorDebug::Yellow;
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

	int opCmp(USkylineBallBossChaseSplineEventComponent Other) const
	{
		if(DistanceAlongSpline > Other.DistanceAlongSpline)
			return 1;
		else
			return -1;
	}
};

#if EDITOR
class USkylineBallBossChaseSplineEventComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USkylineBallBossChaseSplineEventComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ChaseEventComp = Cast<USkylineBallBossChaseSplineEventComponent>(Component);
		if(ChaseEventComp == nullptr)
			return;

		auto Spline = Cast<ASkylineBallBossChaseSpline>(ChaseEventComp.Owner);
		if(Spline == nullptr)
			return;

		const FVector Location = Spline.Spline.GetClosestSplineWorldLocationToWorldLocation(ChaseEventComp.WorldLocation);
		DrawWireSphere(Location, 100, ChaseEventComp.GetDebugColor(), 3, 12, true);
		FString Text = "" + ChaseEventComp.EventType;
		if (!ChaseEventComp.EventData.Text.IsNone())
			Text += "\n" + ChaseEventComp.EventData.Text;
		if (ChaseEventComp.EventData.Int != 0)
			Text += "\n" + ChaseEventComp.EventData.Int;
		if (!Math::IsNearlyEqual(ChaseEventComp.EventData.Float, 0.0, KINDA_SMALL_NUMBER))
			Text += "\n" + ChaseEventComp.EventData.Float;
		DrawWorldString(Text, Location, FLinearColor::White, 1.2, 10000, true, true);
	}
};

class USkylineBallBossAddChaseSplineEventContextMenuExtension : UHazeSplineContextMenuExtension
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
		
		{
			FHazeContextOption AddSplineEvent;
			AddSplineEvent.DelegateParam = n"AddSplineEvent";
			AddSplineEvent.Label = "Add Spline Event";
			AddSplineEvent.Icon = n"Icons.Plus";
			Menu.AddOption(AddSplineEvent, MenuDelegate);
		}

		ASkylineBallBossChaseSpline ChaseSpline = Cast<ASkylineBallBossChaseSpline>(Spline.Owner);
		if(ChaseSpline == nullptr)
			return;

		USkylineBallBossChaseSplineEventComponent Previous;
		USkylineBallBossChaseSplineEventComponent Next;
		float Alpha;		
		ChaseSpline.GetSplineEventComponents(ClickedDistance, Previous, Next, Alpha);

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
			auto AddedSplineEvent = USkylineBallBossChaseSplineEventComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineEvent.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineEvent);
			Spline.Owner.Modify();
			return;
		}

		ASkylineBallBossChaseSpline ChaseSpline = Cast<ASkylineBallBossChaseSpline>(Spline.Owner);
		if(ChaseSpline == nullptr)
			return;

		USkylineBallBossChaseSplineEventComponent Previous;
		USkylineBallBossChaseSplineEventComponent Next;
		float Alpha;		
		ChaseSpline.GetSplineEventComponents(MenuClickedDistance, Previous, Next, Alpha);

		if(Previous != nullptr && OptionName == n"DuplicatePreviousSplineEvent")
		{
			auto AddedSplineEvent = USkylineBallBossChaseSplineEventComponent::Create(Spline.Owner);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedSplineEvent.SetWorldTransform(Transform);
			Editor::SelectComponent(AddedSplineEvent);
			Spline.Owner.Modify();
			return;
		}

		if(Next != nullptr && OptionName == n"DuplicateNextSplineEvent")
		{
			auto AddedSplineEvent = USkylineBallBossChaseSplineEventComponent::Create(Spline.Owner);
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