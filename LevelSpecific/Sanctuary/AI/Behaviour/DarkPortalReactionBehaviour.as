
class UDarkPortalReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 

	UDarkPortalResponseComponent DarkPortalComp;
	UDarkPortalTargetComponent DarkPortalTargetComp;
	FHazeAcceleratedFloat AccSpeed;
	USanctuaryReactionSettings ReactionSettings;
	float NextEscapeAttemptTime = BIG_NUMBER;
	float EscapeBurstTime = 0.0;
	FVector EscapeVelocity = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DarkPortalComp = UDarkPortalResponseComponent::Get(Owner);	
		DarkPortalTargetComp = UDarkPortalTargetComponent::Get(Owner);	
		ReactionSettings = USanctuaryReactionSettings::GetSettings(Owner);

		Owner.BlockCapabilities(SanctuaryAICapabilityTags::LightProjectileCollision, this);
		Owner.BlockCapabilities(SanctuaryAICapabilityTags::DarkProjectileCollision, this);
		Owner.BlockCapabilities(SanctuaryAICapabilityTags::LightBeamCollision, this);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())		
			return false;

		if (!DarkPortalComp.IsGrabbed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())		
			return true;

		if (!DarkPortalComp.IsGrabbed())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AccSpeed.SnapTo(0.0);
		NextEscapeAttemptTime = Time::GameTimeSeconds + Math::RandRange(1.0, 3.0);
		EscapeBurstTime = 0.0;

		Owner.UnblockCapabilities(SanctuaryAICapabilityTags::LightProjectileCollision, this);
		Owner.UnblockCapabilities(SanctuaryAICapabilityTags::LightBeamCollision, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		Owner.BlockCapabilities(SanctuaryAICapabilityTags::LightProjectileCollision, this);
		Owner.BlockCapabilities(SanctuaryAICapabilityTags::LightBeamCollision, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Pull towards dark portal using impulse (we do not want to follow a path!)
		FVector AccumulatedVelocity = FVector::ZeroVector;

		AccSpeed.AccelerateTo(ReactionSettings.DarkPortalPullSpeed, ReactionSettings.DarkPortalPullAccelerationDuration, DeltaTime);
		FVector OwnLoc = Owner.ActorCenterLocation;
		FVector PullLoc = OwnLoc - FVector::UpVector;
		FVector AwayDir = FVector::UpVector;
		for (auto Grab : DarkPortalComp.Grabs)
		{
			PullLoc = Grab.Portal.ActorLocation + Grab.Portal.ActorForwardVector * 200.0;
			AccumulatedVelocity += (PullLoc - OwnLoc).GetSafeNormal() * AccSpeed.Value;
			AwayDir = Grab.Portal.ActorForwardVector;
		}

		// Should we struggle against portal pull?		
		float CurTime = Time::GameTimeSeconds;
		if ((CurTime > NextEscapeAttemptTime) && OwnLoc.IsWithinDist(PullLoc, 500.0))
		{
			EscapeBurstTime = CurTime + Math::RandRange(0.5, 2.0);	
			NextEscapeAttemptTime = EscapeBurstTime + Math::RandRange(1.0, 3.0);
			EscapeVelocity = Math::GetRandomConeDirection(AwayDir, PI * 0.5, 0.0) * 1000.0;
		}
		if (CurTime < EscapeBurstTime)
		{
			// Ongoing escape attempt
			AccumulatedVelocity += EscapeVelocity;
		}
		
		Owner.AddMovementImpulse(AccumulatedVelocity * DeltaTime, n"DartPortalReaction");
	}
}
