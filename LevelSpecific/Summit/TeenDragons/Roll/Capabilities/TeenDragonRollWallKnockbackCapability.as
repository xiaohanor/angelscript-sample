struct FTeenDragonRollWallKnockbackParams
{
	TOptional<FVector> AdditionalImpulse;
	FHazeCameraImpulse CameraImpulse;
}
class UTeenDragonRollWallKnockBackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 100;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;	
	UTeenDragonChaseComponent ChaseComp;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	UTeenDragonMovementSettings MovementSettings;
	UTeenDragonRollWallKnockbackSettings KnockbackSettings;

	const float KnockbackAirHorizontalVelocityAccelerationWithInput = 0.2;
	const float KnockbackAirHorizontalVelocityAccelerationWithoutInput = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		ChaseComp = UTeenDragonChaseComponent::Get(Player);


		MoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		MovementSettings = UTeenDragonMovementSettings::GetSettings(Player);
		KnockbackSettings = UTeenDragonRollWallKnockbackSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonRollWallKnockbackParams& Params) const
	{
		if (ChaseComp.bIsInChase)
			return false;
		
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!RollComp.KnockbackParams.IsSet())
			return false;

		Params = RollComp.KnockbackParams.Value;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		if(ActiveDuration > KnockbackSettings.WallKnockbackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonRollWallKnockbackParams Params)
	{
		Player.PlayCameraShake(RollComp.RollWallKnockBackCameraShake, this);
		Player.PlayForceFeedback(RollComp.RollWallKnockBackRumble, false, false, this);

		Player.ApplyCameraImpulse(Params.CameraImpulse, this);

		if(Params.AdditionalImpulse.IsSet())
			MoveComp.AddPendingImpulse(Params.AdditionalImpulse.Value);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RollComp.KnockbackParams.Reset();
		RollComp.bRollIsStarted = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				float InputSize = MoveComp.MovementInput.Size();

				// Calculate the target speed
				float SpeedAlpha = Math::Clamp((InputSize - MovementSettings.MinimumInput) / (1.0 - MovementSettings.MinimumInput), 0.0, 1.0);
				float TargetSpeed = Math::Lerp(MovementSettings.AirHorizontalMinMoveSpeed, MovementSettings.AirHorizontalMaxMoveSpeed, SpeedAlpha) * MoveComp.MovementSpeedMultiplier;

				float InterpSpeed = KnockbackAirHorizontalVelocityAccelerationWithInput;
				if (InputSize < KINDA_SMALL_NUMBER)
				{
					TargetSpeed = 0.0;
					InterpSpeed = KnockbackAirHorizontalVelocityAccelerationWithoutInput;
				}

				FVector TargetDirection = MoveComp.MovementInput.GetSafeNormal();

				TArray<FMovementHitResult> Contacts = MoveComp.AllImpacts;

				for (FMovementHitResult Hit : Contacts)
				{
					auto ResponseComp = UTeenDragonTailAttackResponseComponent::Get(Hit.Actor);

					if (ResponseComp != nullptr && ResponseComp.bOverrideNormalDirectionWithForward)
					{
						TargetDirection = ResponseComp.ForwardVector;
					} 
				}

				FVector CurrentHorizontalVelocity = Math::VInterpTo(MoveComp.HorizontalVelocity, TargetDirection * TargetSpeed, DeltaTime, InterpSpeed);
				Movement.AddHorizontalVelocity(CurrentHorizontalVelocity);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddPendingImpulses();
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::TailTeenHitWall);
		}
	}
};