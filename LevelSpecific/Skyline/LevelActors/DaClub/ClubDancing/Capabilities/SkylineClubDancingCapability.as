class USkylineClubDancingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineClubDancing");

	default TickGroup = EHazeTickGroup::Gameplay;

	UHazeInputComponent InputComp;
	USkylineClubDancingUserComponent UserComp;
	UAnimSequence DanceAnimation;

	float LastMovementTime = 0.0;
	float AnimationTime = 0.0;
	float Delay = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USkylineClubDancingUserComponent::Get(Player);
		DanceAnimation = (Player.IsMio() ? UserComp.MioDance : UserComp.ZoeDance);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 1.0)
			return false;

		if (!IsIdle())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsIdle())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(GravityBladeTags::GravityBladeWield, this);

		UserComp.bIsDancing = true;
		Player.PlaySlotAnimation(Animation = DanceAnimation, StartTime = AnimationTime, BlendTime = 0.5, bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(GravityBladeTags::GravityBladeWield, this);

		UserComp.bIsDancing = false;
		Player.StopSlotAnimationByAsset(DanceAnimation, BlendTime = 0.2);
		AnimationTime = Math::Wrap(AnimationTime + ActiveDuration, 0.0, DanceAnimation.SequenceLength);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	bool IsIdle() const
	{
		if (!Player.IsOnWalkableGround())
			return false;

		if (Time::GameTimeSeconds < LastMovementTime + Delay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!Player.ActorVelocity.IsNearlyZero() || IsActioning(ActionNames::PrimaryLevelAbility) || IsActioning(ActionNames::SecondaryLevelAbility))
			LastMovementTime = Time::GameTimeSeconds;
	}
};