struct FTeenDragonRollImpulseActivationParams
{
	bool bBlockAirControl = false;
}

class UTeenDragonRollImpulseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 30;
	default SeparateInactiveTick(EHazeTickGroup::InfluenceMovement, 50);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollComponent RollComp;

	UHazeMovementComponent MoveComp;
	UTeenDragonRollMovementData Movement;

	UTeenDragonRollSettings RollSettings;

	FVector InputVelocity;
	FVector HorizontalVelocity;

	bool bBlockAirControl = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = Cast<UTeenDragonRollMovementData>(MoveComp.SetupMovementData(UTeenDragonRollMovementData));

		RollSettings = UTeenDragonRollSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTeenDragonRollImpulseActivationParams& Params) const
	{
		if (!RollComp.IsRolling())
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;
		
		if(!MoveComp.HasImpulse())
			return false;

		if(!MoveComp.HasImpulse(WithInstigator = TeenDragonCapabilityTags::TeenDragonRollImpulseBlockAirControl))
			Params.bBlockAirControl = false;
		else
			Params.bBlockAirControl = true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasImpulse())
			return false;

		if (!RollComp.IsRolling())
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if (MoveComp.IsOnAnyGround())
			return true;

		if(MoveComp.HasWallContact())
			return true;
		
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FTeenDragonRollImpulseActivationParams Params)
	{
		RollComp.RollingInstigators.AddUnique(this);
		bBlockAirControl = Params.bBlockAirControl;
		InputVelocity = FVector::ZeroVector;
		HorizontalVelocity = MoveComp.HorizontalVelocity + MoveComp.PendingImpulse.ConstrainToPlane(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RollComp.RollingInstigators.RemoveSingleSwap(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.HasAnyValidBlockingContacts())
		{
			RollComp.RollUntilImpactInstigators.Reset();
		}

		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(MoveComp.HasImpulse())
				{
					FVector Impulse = Movement.GetPendingImpulse();
					FVector HorizontalImpulse = Impulse.ConstrainToPlane(MoveComp.WorldUp);
					HorizontalVelocity = HorizontalImpulse;

					FVector VerticalImpulse = Impulse - HorizontalImpulse;
					Movement.AddVerticalVelocity(VerticalImpulse);
				}
				
				FVector MovementInput = MoveComp.GetMovementInput().GetSafeNormal();
				if (MovementInput.IsNearlyZero())
					MovementInput = Player.ActorForwardVector;
				
				FVector Steering = Math::VInterpNormalRotationTo(Player.ActorForwardVector, MovementInput, DeltaTime, RollSettings.RollAirTurnRate);
				Movement.SetRotation(FRotator::MakeFromXZ(Steering, MoveComp.WorldUp));

				FVector NewHorizontalVelocity = HorizontalVelocity;

				if(!bBlockAirControl)
				{
					InputVelocity += MovementInput * RollSettings.RollSidewaysInputAcceleration * DeltaTime;
					float InputSpeedBackwards = InputVelocity.DotProduct(-Player.ActorForwardVector);
					FVector InputVelocityAlignedWithBackwards = -Player.ActorForwardVector * InputSpeedBackwards;
					InputVelocity -= InputVelocityAlignedWithBackwards;
					InputVelocity = InputVelocity.GetClampedToMaxSize(RollSettings.RollImpulseInputMaxSpeed);
					NewHorizontalVelocity += InputVelocity;
				}

				Movement.AddHorizontalVelocity(NewHorizontalVelocity);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}
			// Remote
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(TeenDragonLocomotionTags::RollMovement);
		}
	}
};