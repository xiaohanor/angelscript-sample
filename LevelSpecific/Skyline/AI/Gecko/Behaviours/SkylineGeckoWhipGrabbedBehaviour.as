// Behaviour when grabbed by whip while alive
class USkylineGeckoWhipGrabbedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UBasicAICharacterMovementComponent MoveComp;
	USkylineGeckoComponent GeckoComp;
	UGravityWhippableComponent WhippableComp;
	UGravityWhipResponseComponent WhipResponse;
	UBasicAIHealthComponent HealthComp;
	UWallclimbingComponent WallclimbingComp;
	ASkylineTorReferenceManager Arena;
	USkylineGeckoSettings GeckoSettings;

	bool bWasThrown;
	float LastThrownTime = -BIG_NUMBER;
	FHitResult LastThrownObstruction;
	FSplinePosition SplineDestination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		WhippableComp = UGravityWhippableComponent::Get(Owner);
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		WallclimbingComp = UWallclimbingComponent::Get(Owner);
	
		WhippableComp.OnImpact.AddUFunction(this, n"OnWhipThrownImpact");
		WhipResponse.OnThrown.AddUFunction(this, n"OnWhipThrown");

		GeckoSettings = USkylineGeckoSettings::GetSettings(Owner);
		Arena = TListedActors<ASkylineTorReferenceManager>().GetSingle();
	}

	UFUNCTION()
	private void OnWhipThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		LastThrownObstruction = HitResult;
		LastThrownTime = Time::GameTimeSeconds;
		GeckoComp.Team.LastThrownAtTarget = HitResult.Actor;

		// Note that we do not set bWasThrown here; we wait until a movement capability has confirmed throw
	}

	UFUNCTION()
	private void OnWhipThrownImpact()
	{
		if (!IsActive())
			return;
		HealthComp.SetStunned();
		USkylineGeckoEffectHandler::Trigger_OnGravityWhipThrownImpact(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!WhippableComp.bGrabbed && !WhippableComp.bThrown)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (!WhippableComp.bGrabbed && !WhippableComp.bThrown)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bWasThrown = WhippableComp.bThrown;
		if (WhippableComp.bThrown)
			AnimComp.RequestFeature(FeatureTagGecko::ThrownByWhip, EBasicBehaviourPriority::Medium, this);
		else
		{
			AnimComp.RequestFeature(FeatureTagGecko::GrabbedByWhip, EBasicBehaviourPriority::Medium, this);
			USkylineGeckoEffectHandler::Trigger_OnGravityWhipGrabbed(Owner);
		}
		SplineDestination = FSplinePosition();	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		LastThrownObstruction = FHitResult();
		LastThrownTime = -BIG_NUMBER;
		GeckoComp.Team.LastThrownAtTarget = nullptr;	
		WallclimbingComp.DestinationUpVector.Clear(this);
		if (SplineDestination.IsValid() && Owner.ActorLocation.IsWithinDist(SplineDestination.WorldLocation, 40.0))
		{
			// We've landed at spline
			GeckoComp.CurrentClimbSpline = SplineDestination.CurrentSpline;	
			DestinationComp.FollowSplinePosition = SplineDestination;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bWasThrown && WhippableComp.bThrown)
		{
			bWasThrown = true;
			AnimComp.RequestFeature(FeatureTagGecko::ThrownByWhip, EBasicBehaviourPriority::Medium, this);
			AdjustThrownVelocity();
		}
	}

	void AdjustThrownVelocity()
	{
		// Tweak actor velocity to hit climb splines etc. 
		FVector OwnLoc = Owner.ActorLocation;
		FVector ThrowDir = Owner.ActorVelocity;
		const float ArenaRadius = 2000.0;
		if ((Time::GetGameTimeSince(LastThrownTime) < 1.0) && LastThrownObstruction.bBlockingHit)
		{
			if ((LastThrownObstruction.Actor != nullptr) &&	(UGravityWhipImpactResponseComponent::Get(LastThrownObstruction.Actor) != nullptr))
			{
				// Proper target detected, don't tweak
				WallclimbingComp.DestinationUpVector.Apply(LastThrownObstruction.ImpactNormal, this);	
				return; 
			}
	
			if (LastThrownObstruction.Location.IsWithinDist(Arena.ArenaCenter.ActorLocation, ArenaRadius))
			{
				// We'll impact near or inside arena, don't tweak
				WallclimbingComp.DestinationUpVector.Apply(LastThrownObstruction.ImpactNormal, this);	
				return; 
			}

			ThrowDir = (LastThrownObstruction.Location - OwnLoc);	
			WallclimbingComp.DestinationUpVector.Apply(LastThrownObstruction.ImpactNormal, this);	
		}

		ThrowDir = ThrowDir.GetSafeNormal();
		FLineSphereIntersection Intersection = Math::GetInfiniteLineSphereIntersectionPoints(OwnLoc, ThrowDir, Arena.ArenaCenter.ActorLocation, ArenaRadius + 500.0);
		FVector ProbeLoc = Intersection.MaxIntersection;
		if (!Intersection.bHasIntersection)
			ProbeLoc = OwnLoc + ThrowDir * 1000.0; // We're being thrown wholly outside arena

		// Check if we should tweak velocity so we land at arena edge or a climb spline
		FSplinePosition BestPos = Arena.CircleMovementSplineActor.Spline.GetClosestSplinePositionToWorldLocation(ProbeLoc);
		FVector BestDir = (BestPos.WorldLocation - OwnLoc).GetSafeNormal();
		float BestDot = ThrowDir.DotProduct(BestDir);
		for (ASkylineGeckoClimbSplineActor GeckoClimb : GeckoComp.ClimbSplines)
		{
			FSplinePosition SplinePos = GeckoClimb.ClimbSpline.GetClosestSplinePositionToWorldLocation(ProbeLoc);
			FVector Dir = (SplinePos.WorldLocation - OwnLoc).GetSafeNormal();
			float Dot = ThrowDir.DotProduct(Dir);
			if (Dot < BestDot)
				continue;
			BestDot = Dot;
			BestPos = SplinePos;
			BestDir = Dir;
		}
		if (BestDot > 0.95)
		{
			// Throw at spline
			FVector AdjustedVel = BestDir * Owner.ActorVelocity.Size();
			Owner.SetActorVelocity(AdjustedVel);
			SplineDestination = BestPos;
			WallclimbingComp.DestinationUpVector.Apply(SplineDestination.WorldUpVector, this);	
			return;
		}
		
		// Could not find a good spot to throw at, keep calm and carry on.
	}
}