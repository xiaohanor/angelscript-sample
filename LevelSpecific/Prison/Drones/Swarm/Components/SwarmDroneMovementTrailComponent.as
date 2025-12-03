class USwarmDroneMovementTrailCrumb : UObject
{
	float GameTimeStamp;

	FVector Location;
	FVector Velocity;

	USwarmDroneMovementTrailCrumb NextCrumb = nullptr;
}

class USwarmDroneMovementTrailComponent : UActorComponent
{
	default TickGroup = ETickingGroup::TG_LastDemotable;
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// Movement-based expiration and layout
	private float AccumulatedMoveDelta;
	private const float DistancePeriod = 50.;
	private const float MaxCrumbs = 3;

	private TArray<USwarmDroneMovementTrailCrumb> Trail;
	AHazePlayerCharacter PlayerOwner;

#if EDITOR
	UHazeImmediateDrawer Drawer;
	bool bShouldDrawTrail = false;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);

		UPlayerSwarmDroneComponent PlayerSwarmDroneComponent;
		PlayerSwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		if (PlayerSwarmDroneComponent != nullptr)
		{
			PlayerSwarmDroneComponent.OnSwarmTransitionStartEvent.AddUFunction(this, n"OnSwarmTransition");
		}

#if EDITOR
		Drawer = DevMenu::RequestImmediateDevMenu(n"SwarmDroneMoveTrail", "🌠");
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AccumulatedMoveDelta += PlayerOwner.ActorVelocity.Size() * DeltaTime;
		if (AccumulatedMoveDelta >= DistancePeriod)
		{
			USwarmDroneMovementTrailCrumb NewTrailCrumb = NewObject(this, USwarmDroneMovementTrailCrumb);
			NewTrailCrumb.GameTimeStamp = Time::GameTimeSeconds;
			NewTrailCrumb.Location = PlayerOwner.ActorLocation;
			NewTrailCrumb.Velocity = PlayerOwner.ActorVelocity;

			Trail.Add(NewTrailCrumb);
			int Index = Trail.FindIndex(NewTrailCrumb);
			if (Index > 0)
			{
				Trail[Index - 1].NextCrumb = NewTrailCrumb;
			}

			// Remove oldest crumb
			if (Trail.Num() > MaxCrumbs)
				Trail.RemoveAt(0);

			AccumulatedMoveDelta = 0;
		}

#if EDITOR
		if (Drawer.IsVisible())
		{
			auto Section = Drawer.Begin();
			if (Section.Button("Toggle Draw Trail"))
				bShouldDrawTrail = !bShouldDrawTrail;
		}

		if (bShouldDrawTrail)
		{
			for (int i = 0; i < Trail.Num(); i++)
			{
				FLinearColor Color = Math::Lerp(FLinearColor::Red, FLinearColor::Green, float(i) / Trail.Num());
				Debug::DrawDebugSphere(Trail[i].Location, 10, 12, Color, 0.6);
			}
		}
#endif
	}

	const TArray<USwarmDroneMovementTrailCrumb>& GetTrail()
	{
		return Trail;
	}

	int GetTrailSize() const
	{
		return Trail.Num();
	}

	bool TrailIsMaxed() const
	{
		return Trail.Num() == MaxCrumbs;
	}

	USwarmDroneMovementTrailCrumb GetClosestTrailCrumbToLocation(FVector WorldLocation) const
	{
		float SmallestDistance = BIG_NUMBER;
		USwarmDroneMovementTrailCrumb ClosestTrailCrumb;

		for (auto TrailCrumb : Trail)
		{
			float Distance = WorldLocation.DistSquared(TrailCrumb.Location);
			if (Distance < SmallestDistance)
				ClosestTrailCrumb = TrailCrumb;
		}

		return ClosestTrailCrumb;
	}

	UFUNCTION()
	private void OnSwarmTransition(bool bSwarmActive)
	{
		SetComponentTickEnabled(bSwarmActive);
		AccumulatedMoveDelta = DistancePeriod;
		Trail.Empty();
	}
}