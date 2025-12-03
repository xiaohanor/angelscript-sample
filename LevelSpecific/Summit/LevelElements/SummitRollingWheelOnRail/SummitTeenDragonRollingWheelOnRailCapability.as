class USummitTeenDragonRollingWheelOnRailCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;

	UPlayerTailTeenDragonComponent DragonComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	ASummitRollingWheelOnRail Wheel;

	FHazeAcceleratedFloat AccWheelSpeed;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		Wheel = Cast<ASummitRollingWheelOnRail>(Params.Interaction.Owner);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		
		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		if (Wheel.Camera != nullptr)
			Player.ActivateCamera(Wheel.Camera, 0.5, this);

		AccWheelSpeed.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		Player.TeleportActor(Wheel.ExitLocation.WorldLocation, Wheel.ExitLocation.WorldRotation, this);

		if (Wheel.Camera != nullptr)
			Player.DeactivateCamera(Wheel.Camera, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;

				FVector WheelForward = Wheel.Root.ForwardVector;
				float RollInput;

				if(DragonComp.bSimplifiedRollingWheelOnRailInput)
					RollInput = MovementInput.Y;
				else 
					RollInput = MovementInput.DotProduct(Wheel.Root.ForwardVector);

				float TargetSpeed = Wheel.MaxSpeed * RollInput;
				AccWheelSpeed.AccelerateTo(TargetSpeed, Wheel.AccelerationDuration, DeltaTime);

				UInteractionComponent WheelInteractComp = Wheel.InteractComp;
				FVector TargetPos = WheelInteractComp.WorldLocation;
				Movement.AddDeltaWithCustomVelocity(TargetPos - Player.ActorLocation, WheelForward * AccWheelSpeed.Value);
				
				// Rotation
				FQuat Rotation;
				bool bRollingForward;
				if (!MoveComp.MovementInput.IsNearlyZero())
				{
					if(DragonComp.bSimplifiedRollingWheelOnRailInput)
					{
						if(MovementInput.Y > 0)
							bRollingForward = true;
						else
							bRollingForward = false;
					}
					else
					{
						float InputDot = WheelForward.DotProduct(MoveComp.MovementInput);
						if (InputDot > 0.0)
							bRollingForward = true;
						else
							bRollingForward = false;
					}
					
					FRotator WheelRotation = FRotator::MakeFromX(WheelForward);
					if (!bRollingForward)
						WheelRotation = FRotator::MakeFromX(-WheelForward);

					Rotation = Math::QInterpConstantTo(
						Player.ActorQuat,
						WheelRotation.Quaternion(),
						DeltaTime,
						4.0 * PI
					);
				}
				else
				{
					Rotation = FQuat::MakeFromXY(Player.ActorForwardVector, Wheel.ActorRightVector);
				}
				Movement.SetRotation(Rotation);
				Wheel.SyncedRollSpeed.Value = AccWheelSpeed.Value;
				Wheel.MoveWheel(AccWheelSpeed.Value * DeltaTime);
			}
			// Remote
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
				Wheel.MoveWheel(Wheel.SyncedRollSpeed.Value * DeltaTime);
			}

			MoveComp.ApplyMove(Movement);
			FName LocomotionTag = TeenDragonLocomotionTags::RollMovement;
			// if(MoveComp.MovementInput.IsNearlyZero())
			// 	LocomotionTag = TeenDragonLocomotionTags::Movement;
			DragonComp.RequestLocomotionDragonAndPlayer(LocomotionTag);
		}
	}
}