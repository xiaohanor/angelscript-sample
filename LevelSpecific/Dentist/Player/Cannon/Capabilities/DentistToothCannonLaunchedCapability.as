struct FDentistToothCannonLaunchedActivateParams
{
	bool bWasLaunched = false;
	FTraversalTrajectory Trajectory;
	float PlayRate = 1.0;
};

class UDentistToothCannonLaunchedCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default BlockExclusionTags.Add(Dentist::Cannon::DentistCannonBlockExclusionTag);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 51;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothCannonComponent CannonComp;

	UPlayerMovementComponent MoveComp;
	UDentistToothMovementData MoveData;

	FTraversalTrajectory Trajectory;
	float SpinAngle;
	float PlayRate = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		CannonComp = UDentistToothCannonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UDentistToothMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistToothCannonLaunchedActivateParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!CannonComp.IsLaunched())
			return false;

		Params.Trajectory = CannonComp.GetLaunchTrajectory();
		Params.PlayRate = CannonComp.GetCannon().LaunchPlayRate;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!CannonComp.IsLaunched())
			return true;

		if(MoveComp.HasAnyValidBlockingImpacts())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistToothCannonLaunchedActivateParams Params)
	{
		Trajectory = Params.Trajectory;
		PlayRate = Params.PlayRate;

		const FVector LaunchDirection = Trajectory.LaunchVelocity.GetSafeNormal();
		const FQuat VelocityRotation = FQuat::MakeFromZX(LaunchDirection, FVector::UpVector).Inverse();
		const FQuat RotationOffset = PlayerComp.GetMeshWorldRotation() * VelocityRotation.Inverse();
		SpinAngle = RotationOffset.GetTwistAngle(LaunchDirection);
		
		MoveComp.AddMovementIgnoresActor(this, CannonComp.GetCannon());

		UDentistToothCannonEventHandler::Trigger_OnStartLaunched(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CannonComp.Reset();
		MoveComp.RemoveMovementIgnoresActor(this);

		UDentistToothCannonEventHandler::Trigger_OnStopLaunched(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				const float Time = ActiveDuration * PlayRate;
				FVector Location = Trajectory.GetLocation(Time);
				FVector Velocity = Trajectory.GetVelocity(Time);

				MoveData.AddDeltaFromMoveToPositionWithCustomVelocity(Location, Velocity);

				FQuat Rotation = FQuat::MakeFromZX(FVector::UpVector, Velocity);
				MoveData.SetRotation(Rotation);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);
		}

		TickMeshRotation(DeltaTime);
	}

	void TickMeshRotation(float DeltaTime)
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return;

		const float RotationSpeed = 10;
		SpinAngle += RotationSpeed * DeltaTime;

		const FQuat VelocityRotation = FQuat::MakeFromZX(MoveComp.Velocity.GetSafeNormal(), -FVector::UpVector);
		const FQuat SpinRelativeRotation = FQuat(FVector::UpVector, SpinAngle);

		FQuat Rotation = VelocityRotation * SpinRelativeRotation;

		if(Dentist::Cannon::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(Rotation, this, -1, DeltaTime);
	}
};