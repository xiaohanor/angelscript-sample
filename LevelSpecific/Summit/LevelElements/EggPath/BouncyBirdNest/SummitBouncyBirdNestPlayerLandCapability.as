struct FSummitBouncyBirdNestPlayerLandActivationParams
{
	ASummitBouncyBirdNest BirdNestLandedOn;
}

struct FSummitBouncyBirdNestPlayerLandDeactivationParams
{
	bool bDeactivatedNaturally = false;
}

class USummitBouncyBirdNestPlayerLandCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ASummitBouncyBirdNest BirdNestCurrentlyOn;
	UPlayerMovementComponent MoveComp;
	UPlayerJumpComponent JumpComp;

	float HighestAngleThisUndulation;
	bool bHasBeenOnPlatformSinceStart = false;
	bool bHasImpulsedPlatformSinceActivation = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSummitBouncyBirdNestPlayerLandActivationParams& Params) const
	{
		if(!MoveComp.HasGroundContact())
			return false;

		auto GroundContact = MoveComp.GroundContact;
		auto BirdNest = Cast<ASummitBouncyBirdNest>(GroundContact.Actor); 
		if(BirdNest == nullptr)
			return false;

		Params.BirdNestLandedOn = BirdNest;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSummitBouncyBirdNestPlayerLandDeactivationParams& Params) const
	{
		if(IsAboveLaunchAngle()
		&& bHasBeenOnPlatformSinceStart)
		{
			Params.bDeactivatedNaturally = true;
			return true;
		}

		if(JumpComp.IsJumping())
		{
			Params.bDeactivatedNaturally = true;
			return true;
		}


		if(!MoveComp.HasGroundContact())
		{
			Params.bDeactivatedNaturally = true;
			return true;
		}
		else
		{
			auto GroundContact = MoveComp.GroundContact;
			auto BirdNest = Cast<ASummitBouncyBirdNest>(GroundContact.Actor); 
			if(BirdNest != nullptr)
				return false;

			Params.bDeactivatedNaturally = true;
			return true;
		}

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSummitBouncyBirdNestPlayerLandActivationParams Params)
	{
		BirdNestCurrentlyOn = Params.BirdNestLandedOn;
		if(!bHasImpulsedPlatformSinceActivation)
		{
			BirdNestCurrentlyOn.ApplyLandImpulse();
			
			USummitBouncyBirdNestEventHandler::Trigger_OnLand(BirdNestCurrentlyOn);
		}

		HighestAngleThisUndulation = -MAX_flt;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSummitBouncyBirdNestPlayerLandDeactivationParams Params)
	{
		auto TemporalLog = TEMPORAL_LOG(BirdNestCurrentlyOn);
		TemporalLog.Value("Deactivated Naturally", Params.bDeactivatedNaturally);

		if(Params.bDeactivatedNaturally)
		{
			float ImpulseSize = BirdNestCurrentlyOn.PlayerLaunchImpulseSize;
			float VelocityUpwards = MoveComp.Velocity.DotProduct(FVector::UpVector);
			if(VelocityUpwards > 0)
				ImpulseSize -= VelocityUpwards;
			FVector Impulse = FVector::UpVector * ImpulseSize;
			TemporalLog.Value("Impulse", Impulse);
			Player.AddPlayerLaunchMovementImpulse(Impulse);

			Player.KeepLaunchVelocityDuringAirJumpUntilLanded();
			Player.FlagForLaunchAnimations(Impulse);
			JumpComp.StopJumpGracePeriod(0.2);

			Player.PlayForceFeedback(BirdNestCurrentlyOn.LaunchRumble, false, true, this);
			Player.PlayCameraShake(BirdNestCurrentlyOn.LaunchCameraShake, this);
			
			BirdNestCurrentlyOn.LaunchAllEggsOnBirdNest();
			USummitBouncyBirdNestEventHandler::Trigger_OnLaunch(BirdNestCurrentlyOn);
		}

		bHasBeenOnPlatformSinceStart = false;
		bHasImpulsedPlatformSinceActivation = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(BirdNestCurrentlyOn.RotateRoot.RelativeRotation.Roll > HighestAngleThisUndulation)
			HighestAngleThisUndulation = BirdNestCurrentlyOn.RotateRoot.RelativeRotation.Roll;
		
		if(BirdNestCurrentlyOn.RotateRoot.RelativeRotation.Roll > BirdNestCurrentlyOn.StartRoll)
			bHasBeenOnPlatformSinceStart = true;
	}

	private bool IsAboveLaunchAngle() const
	{
		const float LaunchThreshold = HighestAngleThisUndulation * BirdNestCurrentlyOn.FractionOfLowestDipToLaunch;
		return BirdNestCurrentlyOn.RotateRoot.RelativeRotation.Roll < LaunchThreshold;
	}
};