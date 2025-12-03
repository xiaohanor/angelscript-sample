class USanctuarySnakeSelfCollisionCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	default CapabilityTags.Add(n"SanctuarySnakeSelfCollision");

	USanctuarySnakeSettings Settings;

	USanctuarySnakeComponent SanctuarySnakeComponent;
	USanctuarySnakeTailComponent TailComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USanctuarySnakeSettings::GetSettings(Owner);

		SanctuarySnakeComponent = USanctuarySnakeComponent::Get(Owner);
		TailComponent = USanctuarySnakeTailComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SanctuarySnakeComponent.bSelfCollision = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SanctuarySnakeComponent.bSelfCollision = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		SanctuarySnakeComponent.bSelfCollision = false;

		float Radius = 300.0;

		for (auto Segment : TailComponent.TailSegments)
		{
			FVector Location = Segment.WorldLocation + Segment.UpVector * 100.0;

			if (Owner.ActorLocation.IsWithinDist(Location, Radius))
			{
				FVector ToSegment = (Location - Owner.ActorLocation).GetSafeNormal();
			
				FVector Direction = Owner.ActorVelocity.GetSafeNormal();
			
				if (Owner.ActorVelocity.IsNearlyZero())
					Direction = Owner.ActorForwardVector;

				float ToSegmentDot = Direction.DotProduct(ToSegment);
				if (ToSegmentDot > 0.0)
					SanctuarySnakeComponent.bSelfCollision = true;
			}
		}
	
		if (SanctuarySnakeComponent.bSelfCollision)
		{
			PrintScaled("IJDOSFJDJIOFD");
		//	Debug::DrawDebugSphere(Owner.ActorLocation, 500.0, 12, FLinearColor::Red, 20.0, 2.0);
		}
	}
}