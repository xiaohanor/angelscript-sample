class UDentistToothGroundMovementCapability : UHazePlayerCapability
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

		if(!MoveComp.IsOnWalkableGround())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!MoveComp.IsOnWalkableGround())
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

			if(!Input.IsNearlyZero())
			{
				FVector TargetHorizontalVelocity = Input * MovementSettings.GroundMaxSpeed;

				float Acceleration = MovementSettings.GroundAcceleration;
				if(HorizontalVelocity.DotProduct(TargetHorizontalVelocity) < 0)
				{
					Acceleration *= MovementSettings.ReboundFactor;
				}

				HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, TargetHorizontalVelocity, DeltaTime, Acceleration);
				MoveData.AddHorizontalVelocity(HorizontalVelocity);

				if(!HorizontalVelocity.IsNearlyZero())
					MoveData.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, HorizontalVelocity), MovementSettings.GroundRotationSpeed);
			}
			else
			{
				HorizontalVelocity = Math::VInterpConstantTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, MovementSettings.GroundDeceleration);
				MoveData.AddHorizontalVelocity(HorizontalVelocity);
			}

			if(MoveComp.GroundContact.IsOnUnstableEdge())
			{
				MoveData.AddVelocity(MoveComp.GroundContact.EdgeResult.EdgeNormal * 10); 
			}

			MoveData.AddGravityAcceleration();

			MoveData.AddPendingImpulses();
			MoveData.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakeValue(25));
			MoveData.ApplyUnstableEdgeIsUnwalkable();
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);
	}
};