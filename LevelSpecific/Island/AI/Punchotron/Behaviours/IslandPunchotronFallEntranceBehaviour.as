class UIslandPunchotronFallEntranceBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UHazeMovementComponent MoveComp;
	UHazeActorRespawnableComponent RespawnComp;

	private bool bHasFinished;
	private bool bHasTracedGround = false;
	private bool bHasLanded = false;
	float LandedDelayTimer = 0.75;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MoveComp = UHazeMovementComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bHasFinished = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bHasFinished)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::FallStart, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (bHasFinished)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		AnimComp.ClearFeature(this);
		if (!bHasTracedGround)
		{
			UIslandPunchotronEffectHandler::Trigger_OnLanded(Owner, FIslandPunchotronOnLandedParams());
		}
		bHasTracedGround = false;
		bHasLanded = false;
		LandedDelayTimer = 0.75;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// This part checks for ground in order to delay movement for the duration of the LandedDelayTimer.
		if (MoveComp.IsOnAnyGround())
		{
			if (!bHasLanded)
			{
				bHasLanded = true;
				UIslandPunchotronEffectHandler::Trigger_OnLanded(Owner, FIslandPunchotronOnLandedParams());
			}

			LandedDelayTimer -= DeltaTime;
			if (LandedDelayTimer < 0.0)
				bHasFinished = true;
		}
		
		// Trace for ground here for making sure that animation has time to blend from fall MH to landing.
		FHazeTraceSettings TraceSettings = Trace::InitProfile(n"EnemyCharacter");
		TraceSettings.UseLine();
		if (bHasTracedGround)
			return;

		FHitResult HitResult;
		const float AnimationGroundContactTime = 0.05 + Network::PingOneWaySeconds;
		float LookAhead = Owner.ActorVerticalVelocity.Size() * (AnimationGroundContactTime);
		HitResult = TraceSettings.QueryTraceSingle(Owner.ActorLocation, Owner.ActorLocation + Owner.ActorUpVector * -1.0 * LookAhead);
		if (HitResult.bBlockingHit)
		{
			if (HasControl())
				CrumbClearFeature();
			else
			{
				AnimComp.ClearFeature(this);
				bHasTracedGround = true;
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbClearFeature()
	{
		AnimComp.ClearFeature(this);
		bHasTracedGround = true;
	}
}
