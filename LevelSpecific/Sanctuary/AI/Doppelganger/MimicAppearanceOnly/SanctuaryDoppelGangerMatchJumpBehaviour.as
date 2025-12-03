class USanctuaryDoppelGangerMatchJumpBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USanctuaryDoppelgangerSettings DoppelSettings;
	USanctuaryDoppelgangerComponent DoppelComp;
	UBasicAICharacterMovementComponent MoveComp;

	float MimicJumpTime = BIG_NUMBER;
	float MimicJumpSpeed = 100.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(Owner);
		DoppelComp = USanctuaryDoppelgangerComponent::Get(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);

		UMovementGravitySettings::SetGravityScale(Owner, 2.0, this, EHazeSettingsPriority::Defaults);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MimicJumpTime < BIG_NUMBER)
			return;

		if (!ShouldDetectJump())
		{
			MimicJumpTime = BIG_NUMBER;
			return;
		}

		if (DoppelComp.MimicTarget.IsAnyCapabilityActive(PlayerMovementTags::Jump))
		{
			MimicJumpTime = Time::GameTimeSeconds;
			MimicJumpSpeed = Math::Max(DoppelComp.MimicTarget.ActorVelocity.DotProduct(DoppelComp.MimicTarget.ActorUpVector), DoppelSettings.MatchJumpMinSpeed);
		}
	}

	bool ShouldDetectJump()
	{
		if (IsBlocked())
			return false;
		if (DoppelComp.MimicTarget == nullptr) 
			return false;
		if (IsActive())
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::FullMimic)
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::FullMimic)
			return false;
		if (DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return false;
		if (Time::GameTimeSeconds < MimicJumpTime + DoppelSettings.MatchJumpDelay)
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
		if (DoppelComp.MimicState == EDoppelgangerMimicState::Reveal)
			return true;
		if (!MoveComp.IsInAir())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AnimComp.RequestFeature(LocomotionFeatureAISanctuaryTags::DoppelgangerMimicJump, EBasicBehaviourPriority::Low, this);
		Owner.AddMovementImpulse(Owner.ActorUpVector * MimicJumpSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(DoppelSettings.MatchJumpCooldown);
		MimicJumpTime = BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > 1.0)
			Cooldown.Set(DoppelSettings.MatchJumpCooldown);
	}
}


