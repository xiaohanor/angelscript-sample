class USummitTeenDragonLineBanaSphereRollingCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;

	UPlayerTailTeenDragonComponent DragonComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	ASummitLineBanaSphere LineBanaSphere;

	FHazeAcceleratedFloat AccWheelSpeed;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);

		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		LineBanaSphere = Cast<ASummitLineBanaSphere>(Params.Interaction.Owner);

		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		
		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);

		if (LineBanaSphere.Camera != nullptr)
			Player.ActivateCamera(LineBanaSphere.Camera, 0.5, this);

		AccWheelSpeed.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);

		if (LineBanaSphere.Camera != nullptr)
			Player.DeactivateCamera(LineBanaSphere.Camera, 0.5);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector MovementInput = MoveComp.MovementInput;

				FVector WheelForward = LineBanaSphere.Root.ForwardVector;
				float InputDotForward = MovementInput.DotProduct(LineBanaSphere.Root.ForwardVector);

				float TargetSpeed = LineBanaSphere.MaxSpeed * InputDotForward;
				AccWheelSpeed.AccelerateTo(TargetSpeed, LineBanaSphere.AccelerationDuration, DeltaTime);
				LineBanaSphere.RollSphere(AccWheelSpeed.Value * DeltaTime);

				UInteractionComponent WheelInteractComp = LineBanaSphere.InteractComp;
				FVector TargetPos = WheelInteractComp.WorldLocation;
				Movement.AddDeltaWithCustomVelocity(TargetPos - Player.ActorLocation, WheelForward * AccWheelSpeed.Value);
				
				// Rotation
				FQuat Rotation;
				bool bRollingForward;
				if (!MoveComp.MovementInput.IsNearlyZero())
				{
					float InputDot = WheelForward.DotProduct(MoveComp.MovementInput);
					if (InputDot > 0.0)
						bRollingForward = true;
					else
						bRollingForward = false;
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
					Rotation = FQuat::MakeFromXY(Player.ActorForwardVector, LineBanaSphere.ActorRightVector);
				}
				Movement.SetRotation(Rotation);
			}
			// Remote
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(n"RollMovement");
		}
	}
}