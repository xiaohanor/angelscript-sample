class UCoastWaterskiJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Waterski");
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::Jump);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 99;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	UCoastWaterskiPlayerComponent WaterskiComp;
	UCoastWaterskiSettings Settings;
	bool bShouldJump = true;
	FVector JumpDirection;
	float LastNonAirborneTime;

	int PreviousTrickIndex;

	const float AnimationJumpDelay = 0;
	FHazePlayRndSequenceData Tricks;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		Settings = UCoastWaterskiSettings::GetSettings(Player);
		Tricks = WaterskiComp.JumpFeature.AnimData.Tricks;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!WaterskiComp.IsAirborne())
			LastNonAirborneTime = Time::GetGameTimeSeconds();

		if(WaterskiComp.bCurrentlyJumping && MoveComp.VerticalSpeed < 0.0)
			WaterskiComp.bCurrentlyJumping = false;
	}

#if !RELEASE
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("bCurrentlyJumping", WaterskiComp.bCurrentlyJumping);
	}
#endif

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCoastWaterskiJumpActivatedParams& Params) const
	{
		if(!WaterskiComp.IsWaterskiing())
			return false;

		if(DeactiveDuration < 0.5)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, 0.2))
			return false;

		if(WaterskiComp.IsAirborne() && Time::GetGameTimeSince(LastNonAirborneTime) > 0.2)
			return false;

		FVector CurrentJumpDirection = MoveComp.GroundContact.ImpactNormal;
		if(!MoveComp.HasGroundContact())
            CurrentJumpDirection = FVector::UpVector;

		Params.JumpDirection = CurrentJumpDirection;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FCoastWaterskiJumpDeactivatedParams& Params) const
	{
		if(ActiveDuration < AnimationJumpDelay)
			return false;

		Params.TrickIndex = Tricks.GetIndexFromAnimation(Tricks.GetRandomAnimation());
		if(Params.TrickIndex == PreviousTrickIndex)
			Params.TrickIndex = (Params.TrickIndex + 1) % Tricks.NumAnimations;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCoastWaterskiJumpActivatedParams Params)
	{
		UCoastWaterskiEffectHandler::Trigger_OnJump(Player);
		JumpDirection = Params.JumpDirection;
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCoastWaterskiJumpDeactivatedParams Params)
	{
		if(IsBlocked())
			return;

		PreviousTrickIndex = Params.TrickIndex;
		WaterskiComp.AnimData.JumpTrickIndex = Params.TrickIndex;

		if(bShouldJump)
		{
			ACoastWaterskiBoostZone CurrentBoostZone = WaterskiComp.CurrentBoostZone;
			float AdditionalImpulse = 0;
			if(CurrentBoostZone != nullptr)
				AdditionalImpulse = CurrentBoostZone.AdditionalJumpImpulse;

			MoveComp.AddPendingImpulse(JumpDirection * (Settings.JumpImpulse + AdditionalImpulse));
			MoveComp.AddPendingImpulse(FVector::UpVector * -MoveComp.VerticalSpeed);
			WaterskiComp.bCurrentlyJumping = true;
		}

		WaterskiComp.TimeOfJump = Time::GetGameTimeSeconds();

		if(Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"WaterskiJump", this);
	}
}

struct FCoastWaterskiJumpActivatedParams
{
	FVector JumpDirection;
}

struct FCoastWaterskiJumpDeactivatedParams
{
	int TrickIndex;
}