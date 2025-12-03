struct FSkylineBallBossChargeLaserButtonExitBackflipPlayerDeactivateParams
{
	bool bNormalDeactivate = false;
}

class USkylineBallBossChargeLaserButtonExitBackflipPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData MoveData;

	FVector StartVelocity;

	const float BackflipImpulseStrength = 2500.0;
	const float BackflipDuration = 0.5;
	const float BackflipTimedilation = 0.8;

	USkylineBallBossChargeLaserButtonMashExtrudePlayerComponent PlayerLaserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupSweepingMovementData();
		PlayerLaserComp = USkylineBallBossChargeLaserButtonMashExtrudePlayerComponent::Get(Owner);
	} 

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerLaserComp.bDoBackflip)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineBallBossChargeLaserButtonExitBackflipPlayerDeactivateParams & DeactivationParams) const
	{
		if (!PlayerLaserComp.bDoBackflip)
			return true;
		if (ActiveDuration > BackflipDuration)
		{
			DeactivationParams.bNormalDeactivate = true;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartVelocity = (-Player.GetGravityDirection() + -Player.ActorForwardVector).GetSafeNormal() * BackflipImpulseStrength; // backwards
		MoveComp.Reset(true);
	
		if (PlayerLaserComp.AnimationSettings.BackflipAnimation != nullptr)
		{
			Player.PlaySlotAnimation(Animation =PlayerLaserComp.AnimationSettings.BackflipAnimation, bLoop = true);
			Player.SetSlotAnimationPlayRate(PlayerLaserComp.AnimationSettings.BackflipAnimation, 2.5);
		}
	
		Player.BlockCapabilities(PlayerMovementTags::AirMotion, this);
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(PlayerMovementTags::Swimming, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineBallBossChargeLaserButtonExitBackflipPlayerDeactivateParams DeactivationParams)
	{
		PlayerLaserComp.bDoBackflip = false;

		if (PlayerLaserComp.AnimationSettings.BackflipAnimation != nullptr)
		{
			Player.SetSlotAnimationPlayRate(PlayerLaserComp.AnimationSettings.BackflipAnimation, 1.0);
			Player.StopSlotAnimation();
		}

		Player.UnblockCapabilities(PlayerMovementTags::AirMotion, this);
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(PlayerMovementTags::Swimming, this);
		Player.ClearActorTimeDilation(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / BackflipDuration);
		
		const float TimeDilation = Math::Lerp(1, BackflipTimedilation, Alpha);
		Player.SetActorTimeDilation(TimeDilation, this);

		if(MoveComp.PrepareMove(MoveData, -Player.GetGravityDirection()))
		{
			FVector Velocity = Math::Lerp(StartVelocity, FVector::ZeroVector, Alpha);
			MoveData.AddVelocity(Velocity);
			MoveComp.ApplyMove(MoveData);
		}
	}
}
