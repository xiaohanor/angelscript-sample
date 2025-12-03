class UDentistToothRagdollRotationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothRagdollComponent RagdollComp;
	UPlayerMovementComponent MoveComp;

	uint PreviousImpactFrame = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		RagdollComp = UDentistToothRagdollComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return false;

		if(!RagdollComp.bIsRagdolling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return true;

		if(!RagdollComp.bIsRagdolling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RagdollComp.AngularVelocity = PlayerComp.GetMeshAngularVelocity();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.IsOnWalkableGround())
		{
			const FVector AngularVelocity =  MoveComp.Velocity.CrossProduct(FVector::UpVector);
			RagdollComp.AngularVelocity = Math::VInterpTo(RagdollComp.AngularVelocity, AngularVelocity, DeltaTime, 10);
		}
		else
		{
			const FVector AngularVelocity =  MoveComp.Velocity.CrossProduct(FVector::UpVector);
			RagdollComp.AngularVelocity = Math::VInterpTo(RagdollComp.AngularVelocity, AngularVelocity * 0.3, DeltaTime, 1);
		}

		if (ActiveDuration > 0.1 && MoveComp.HasAnyValidBlockingImpacts())
		{
			if(PreviousImpactFrame < Time::FrameNumber - 1)
			{
				FHitResult FirstImpact = MoveComp.AllImpacts[0].ConvertToHitResult();
				FVector Right = -FirstImpact.Normal.CrossProduct(MoveComp.Velocity.VectorPlaneProject(FirstImpact.Normal)).GetSafeNormal();
				RagdollComp.AngularVelocity += Right * MoveComp.Velocity.Size();
			}

			PreviousImpactFrame = Time::FrameNumber;
		}

		const float RotationSpeed = (RagdollComp.AngularVelocity.Size() / Dentist::CollisionRadius);
		const FQuat DeltaQuat = FQuat(RagdollComp.AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);

		PlayerComp.AddMeshWorldRotation(DeltaQuat, this, -1, DeltaTime);
	}
};