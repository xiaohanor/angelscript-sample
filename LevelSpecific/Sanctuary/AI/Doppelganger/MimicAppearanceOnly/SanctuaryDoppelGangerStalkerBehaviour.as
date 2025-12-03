class USanctuaryDoppelGangerStalkerBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USanctuaryDoppelgangerSettings DoppelSettings;
	USanctuaryDoppelgangerComponent DoppelComp;
	AHazePlayerCharacter StalkingTarget;
	float IsInFrontDuration = 0.0;
	float CloseBehindDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(Owner);
		DoppelComp = USanctuaryDoppelgangerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked())
			return;
		if (!IsActive() && (StalkingTarget != nullptr) && !IsBehind(StalkingTarget))
			Cooldown.Set(DoppelSettings.StalkerCaughtCooldown);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::FullMimic)
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::WantsFullMimic)
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return false;
		if (!IsBehind(GetStalkingTarget()))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::FullMimic)
			return true;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::WantsFullMimic)
			return true;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return true;
		if (!TargetComp.IsValidTarget(StalkingTarget))
			return true;
		return false;
	}

	AHazePlayerCharacter GetStalkingTarget() const 
	{
		if (DoppelComp.MimicTarget == nullptr)
			return nullptr;
		if (!TargetComp.IsValidTarget(DoppelComp.MimicTarget.OtherPlayer))
			return nullptr;
		return DoppelComp.MimicTarget.OtherPlayer;
	}

	bool IsBehind(AHazePlayerCharacter Target) const
	{
		if (Target == nullptr)
			return false;
		return (Target.ActorForwardVector.DotProduct(Owner.ActorLocation - Target.ActorLocation) < 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		StalkingTarget = GetStalkingTarget();
		IsInFrontDuration = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Walk behind the other player, all innocent-like...
		AnimComp.RequestFeature(LocomotionFeatureAISanctuaryTags::DoppelgangerMimicMovement, EBasicBehaviourPriority::Low, this);
		FVector Destination = StalkingTarget.ActorLocation - StalkingTarget.ActorForwardVector * DoppelSettings.StalkerDistance;
		float MoveSpeed = DoppelComp.MimicTarget.ActorVelocity.Size();
		DestinationComp.MoveTowards(Destination, MoveSpeed);

		DestinationComp.RotateTowards(StalkingTarget.FocusLocation);

		if (IsBehind(StalkingTarget))
		{
			IsInFrontDuration = 0.0;
			if (Owner.ActorLocation.IsWithinDist(Destination, 60.0))
				CloseBehindDuration += DeltaTime;
			else
				CloseBehindDuration = 0.0;
		}
		else
		{
			CloseBehindDuration = 0.0;
			IsInFrontDuration += DeltaTime;
			if ((IsInFrontDuration > 1.0) || StalkingTarget.ActorLocation.IsWithinDist(Owner.ActorLocation, DoppelSettings.StalkerDistance))
				Cooldown.Set(DoppelSettings.StalkerCaughtCooldown);
		}

		if (CloseBehindDuration > DoppelSettings.StalkerCloseMaxDuration)
			Cooldown.Set(DoppelSettings.StalkerCaughtCooldown);
	}
}


