class UDentistToothAirMovementCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::Tags::ToothMovement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	UDentistToothMovementSettings MovementSettings;

	UPlayerMovementComponent MoveComp;
	UDentistToothMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MovementSettings = UDentistToothMovementSettings::GetSettings(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UDentistToothMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsOnWalkableGround())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsOnWalkableGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if (HasControl())
		{
			MoveData.AddOwnerVerticalVelocity();

			FVector HorizontalVelocity = MoveComp.GetHorizontalVelocity();

			FVector Input = MoveComp.GetMovementInput();
			FVector TargetHorizontalVelocity = Input * MovementSettings.AirMaxSpeed;
			const FVector ToTarget = TargetHorizontalVelocity - HorizontalVelocity;
			const bool bNoInput = Input.IsNearlyZero();
			const bool bTargetIsDeceleration = HorizontalVelocity.DotProduct(TargetHorizontalVelocity) > 0 && (TargetHorizontalVelocity.Size() < HorizontalVelocity.Size());
			const bool bInputtingDeceleration = bTargetIsDeceleration && Input.DotProduct(ToTarget) > 0;

			if (bNoInput)
			{
				// Decelerate to a full stop
				HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, MovementSettings.AirDeceleration);
			}
			else if (bTargetIsDeceleration && !bInputtingDeceleration)
			{
				// We want to keep going forwards, but our target is deceleration, this means that we would decelerate faster when giving
				// input than if we are not giving input, which is not nice, so we don't do that
				HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, TargetHorizontalVelocity, DeltaTime, MovementSettings.AirDeceleration);
			}
			else
			{
				// We are giving input!
				HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, TargetHorizontalVelocity, DeltaTime, MovementSettings.AirAcceleration);
			}

			MoveData.AddHorizontalVelocity(HorizontalVelocity);

			MoveData.AddGravityAcceleration();

			if(!Player.IsCapabilityTagBlocked(Dentist::Tags::OrientToVelocity))
			{
				if(!HorizontalVelocity.IsNearlyZero() && !Input.IsNearlyZero())
					MoveData.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, HorizontalVelocity), MovementSettings.AirRotationSpeed);
			}
			
			MoveData.AddPendingImpulses();
			MoveData.RequestFallingForThisFrame();
			MoveData.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakeValue(25));
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);
	}
};