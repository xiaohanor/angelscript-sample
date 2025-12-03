class UBigCrackBirdLaunchedCapability : UBigCrackBirdBaseCapability
{
	FVector LaunchedLocation;
	float TargetHeight;

	const float LaunchDuration = 2.6;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Bird.bIsEgg)
			return false;

		if(!Bird.bIsPrimed)
			return false;

		if(!Bird.bIsLaunched)
			return false;

		if(Bird.IsPickedUp() || Bird.IsPickupStarted())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Bird.bIsLaunched)
			return true;

		if(!Bird.bIsPrimed)
			return true;

		if(Bird.IsPickedUp() || Bird.IsPickupStarted())
			return true;

		if(ActiveDuration >= LaunchDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(!HasControl())
			Bird.SetActorTimeDilation(0.8, this);

		LaunchedLocation = Bird.ActorLocation;
		TargetHeight = Bird.CurrentNest.HoverPoint.WorldLocation.Z - LaunchedLocation.Z;
		Bird.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Bird.CatapultToAttachTo.OnBirdDetach();
		Bird.bAttached = false;
		Bird.bIsHit = false;
		Bird.bCanDetach = false;

		UBigCrackBirdEffectHandler::Trigger_CatapultLaunch(Bird);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!HasControl())
			Bird.ClearActorTimeDilation(this);

		Bird.Attach();
		Bird.bIsLaunched = false;
		Bird.bIsHovering = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector CurrentDelta;

		if(Bird.bIsHit)
		{
			CurrentDelta = Bird.Velocity * DeltaTime;
			Bird.Velocity -= FVector::UpVector * (Bird.Gravity * DeltaTime);
		}
		else
		{
			FVector TargetLocation = LaunchedLocation + FVector::UpVector * TargetHeight * Bird.LaunchCurve.GetFloatValue(ActiveDuration);

			if(ActiveDuration >= 1)
			{
				Bird.bIsHovering = true;

				if(ActiveDuration >= 1.5)
				{
					LaunchedLocation = Math::VInterpConstantTo(LaunchedLocation, Bird.CurrentNest.ActorLocation + Bird.NestRelativeLocation, DeltaTime, 350);
					//TargetLocation = Math::VInterpConstantTo(Bird.ActorLocation, Bird.CurrentNest.ActorLocation, DeltaTime, 2000);
				}
			}

			// if(!HasControl() && ActiveDuration >= 1.5)
			// {
			// 	TargetLocation = Bird.SyncedPositionComp.Position.WorldLocation;
			// }

			CurrentDelta = TargetLocation - Bird.ActorLocation;
		}

		FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::WorldDynamic);
		Trace.UseShape(FHazeTraceShape::MakeSphere(Bird.RootComp.SphereRadius));
		Trace.IgnoreActor(Bird);
		Trace.IgnoreActor(Bird.CatapultToAttachTo.Nest);
		Trace.IgnorePlayers();
		FVector StartLocation = Bird.ActorLocation;
		FVector EndLocation = Bird.ActorLocation + CurrentDelta;

		if(!StartLocation.Equals(EndLocation))
		{
			FHitResultArray Hits = Trace.QueryTraceMulti(StartLocation, EndLocation);

			for(auto Hit : Hits.BlockHits)
			{
				auto Response = UBigCrackBirdHitResponseComponent::Get(Hit.Actor);
				if(Response != nullptr)
				{
					Bird.CrumbOnBigCrackBirdHitWall(Response);
				}
			}
		}
        
		Bird.AddActorWorldOffset(CurrentDelta);
	}
};