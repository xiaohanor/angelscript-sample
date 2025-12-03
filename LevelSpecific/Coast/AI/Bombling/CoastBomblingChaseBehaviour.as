
// Move towards enemy
class UCoastBomblingChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UCoastBomblingSettings Settings;
	UBasicAICharacterMovementComponent MoveComp;

	float CollisionCheckInterval = 0.5;
	float CollisionCheckTime;
	bool bChase;
	const float OverlapInterval = 0.2;
	float OverlapTime;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(TargetComp.Target == nullptr)
			return;
		if(Settings == nullptr)
			return;

		// if(Time::GetGameTimeSince(CollisionCheckTime) > CollisionCheckInterval)
		// {
		// 	FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		// 	Trace.UseLine();
		// 	Trace.IgnoreActor(Owner);
		// 	Trace.IgnoreActor(Game::Mio);
		// 	Trace.IgnoreActor(Game::Zoe);

		// 	FVector Dir = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation).GetSafeNormal();
		// 	float Distance = Math::Min(Settings.ChaseObstacleAvoidDetectionDistance, TargetComp.Target.ActorCenterLocation.Distance(Owner.ActorCenterLocation));
		// 	FHitResult Hit = Trace.QueryTraceSingle(Owner.ActorCenterLocation, Owner.ActorCenterLocation + Dir * Distance);
		// 	bChase = !Hit.bBlockingHit;
		// 	CollisionCheckTime = Time::GetGameTimeSeconds();
		// }		
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastBomblingSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		AHazeCharacter Character = Cast<AHazeCharacter>(Owner);
		if(Character != nullptr)
			Radius = Character.CapsuleComponent.CapsuleRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		// if(!bChase)
		// 	return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		// if(!bChase)
		// 	return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ChaseLocation = TargetComp.Target.ActorLocation;

		if (Owner.ActorLocation.IsWithinDist(ChaseLocation, BasicSettings.ChaseMinRange))
		{
			Cooldown.Set(BasicSettings.ChaseMinRangeCooldown);
			return;
		}

		DestinationComp.MoveTowards(ChaseLocation, BasicSettings.ChaseMoveSpeed);

		FVector Dir = (ChaseLocation - Owner.ActorLocation).GetSafeNormal();
		FVector Step = (Owner.ActorLocation + Dir * DestinationComp.MinMoveDistance);
		if(DoStop(Step))
			Cooldown.Set(1.0);
	}

	private bool DoStop(FVector Dest)
	{
		if(DestinationComp.MoveFailed())
			return true;

		if(MoveComp.HasWallContact())
			return true;

		if(Time::GetGameTimeSince(OverlapTime) > OverlapInterval)
		{
			OverlapTime = Time::GetGameTimeSeconds();
			auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseSphereShape(Radius);
			FVector OverlapLocation = Dest;
			FOverlapResultArray Result = Trace.QueryOverlaps(OverlapLocation);
			if(!Result.HasBlockHit())
			{
				//Debug::DrawDebugSphere(OverlapLocation, LineColor = FLinearColor::Red, Duration = OverlapInterval);
				return true;
			}
			//Debug::DrawDebugSphere(OverlapLocation, Duration = OverlapInterval);
		}
		
		return false;
	}
}