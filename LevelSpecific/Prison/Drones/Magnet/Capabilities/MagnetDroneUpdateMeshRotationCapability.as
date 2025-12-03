class UMagnetDroneUpdateMeshRotationCapability : UHazePlayerCapability
{
	// Local since we are always active
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneUpdateMeshRotation);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttachedSocket);

	default BlockExclusionTags.Add(MagnetDroneTags::AttachToBoatBlockExclusionTag);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 100;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttractionComponent AttractionComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UHazeMovementComponent MoveComp;

	bool bHasInitialized = false;
	UPoseableMeshComponent DroneMesh;

	FHazeMovementComponentAttachment PreviousFollow;
	FQuat RelativeToPreviousFollow;

	FHazeAcceleratedVector AccDroneMeshRelativeRight;

	FVector PreviousLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DroneComp.GetDroneMeshComponent() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
		if(!bHasInitialized)
		{
			DroneMesh = Cast<UPoseableMeshComponent>(DroneComp.GetDroneMeshComponent());

			auto RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");

			bHasInitialized = true;
		}

		PreviousLocation = Owner.ActorLocation;
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{	
		UpdateRotationRelativeToFollow();
		UpdateMeshRotation(DeltaTime);

		if(CanStraighten())
			UpdateRollStraighten(DeltaTime);

		// Store our relative rotation to our follow so that we can use it next frame
		if(PreviousFollow.IsValid())
			RelativeToPreviousFollow = PreviousFollow.GetWorldTransform().InverseTransformRotation(DroneMesh.ComponentQuat);
	}

	void UpdateRotationRelativeToFollow()
	{
		const FHazeMovementComponentAttachment& CurrentFollow = MoveComp.GetCurrentMovementFollowAttachment();

		if(CurrentFollow.IsValid())
		{
			const FTransform CurrentFollowTransform = CurrentFollow.GetWorldTransform();

			if(PreviousFollow.IsValid() && PreviousFollow.IsSameFollowTarget(CurrentFollow))
			{
				const FQuat NewRotation = CurrentFollowTransform.TransformRotation(RelativeToPreviousFollow);

				if(!DroneMesh.ComponentQuat.Equals(NewRotation))
					DroneMesh.SetWorldRotation(NewRotation);
			}

			PreviousFollow = CurrentFollow;
		}
		else
		{
			PreviousFollow.Clear();
			RelativeToPreviousFollow = FQuat::Identity;
		}
	}

	void UpdateMeshRotation(float DeltaTime)
	{
		const FVector Velocity = GetVelocity();

		if(Velocity.IsNearlyZero())
			return;

		FQuat MeshRotation = DroneMesh.ComponentQuat;

		if(AttractionComp.IsAttracting())
		{
			// While attracting, add some extra rotation the more parallel our velocity is to our world up, this fixes issues where we barely rotate
			// when attracting in the world up direction
			const float ExtraRotation = Math::Abs(MoveComp.WorldUp.DotProduct(Velocity.GetSafeNormal()));
			const float SpinSpeed = Math::GetMappedRangeValueClamped(FVector2D(0, 500), FVector2D(3, 10), Velocity.Size());
			const FVector RightVector = MoveComp.WorldUp.CrossProduct(Velocity).GetSafeNormal();
			MeshRotation = FQuat(RightVector, ExtraRotation * SpinSpeed * DeltaTime) * MeshRotation;
		}

		MagnetDrone::UpdateMeshRotation(
			DeltaTime,
			MoveComp.GroundContact.ConvertToHitResult(),
			MoveComp.WorldUp,
			Velocity,
			DroneComp.MovementSettings.RollMaxSpeed,
			MagnetDrone::Radius,
			MeshRotation
		);

		DroneMesh.SetWorldRotation(MeshRotation);

		PreviousLocation = Owner.ActorLocation;
	}

	bool CanStraighten() const
	{
		if(!DroneComp.Settings.bStraightenWhileAttracting && AttractionComp.IsAttracting())
			return false;

		if(!DroneComp.Settings.bStraightenWhileAirborne && !MoveComp.IsOnAnyGround())
			return false;

		return true;
	}

	void UpdateRollStraighten(float DeltaTime)
	{
		const FVector Velocity = GetVelocity();

		if(Velocity.IsNearlyZero())
			return;

		FQuat MeshRotation = DroneMesh.ComponentQuat;

		MagnetDrone::UpdateRollStraighten(
			DeltaTime,
			Velocity,
			DroneComp.Settings.StartStraighteningSpeed,
			DroneComp.Settings.RollStraightenDuration,
			DroneComp.IsDashing(),
			DroneComp.Settings.DashRollStraightenDuration,
			MoveComp.WorldUp,
			MeshRotation,
			AccDroneMeshRelativeRight
		);

		DroneMesh.SetWorldRotation(MeshRotation);
	}

	FVector GetVelocity() const
	{
		if(Owner.bIsControlledByCutscene)
			return (Owner.ActorLocation - PreviousLocation) / Time::GetActorDeltaSeconds(Owner);
		
		return MoveComp.Velocity;
	}

	UFUNCTION()
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		DroneMesh.SetWorldRotation(RespawnedPlayer.ActorRotation);
	}
};

namespace MagnetDrone
{
	void UpdateMeshRotation(float DeltaTime, FHitResult GroundContact, FVector WorldUp, FVector Velocity, float RollMaxSpeed, float Radius, FQuat& MeshRotation)
	{
		const FVector DesiredUp = GroundContact.IsValidBlockingHit() ? GroundContact.ImpactNormal : WorldUp;
		const FVector AngularVelocity =  Velocity.CrossProduct(DesiredUp);

		float RotationSpeed = (AngularVelocity.Size() / Radius);
		RotationSpeed = Math::Clamp(RotationSpeed, -RollMaxSpeed, RollMaxSpeed);

		const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);
		MeshRotation = DeltaQuat * MeshRotation;
	}

	void UpdateRollStraighten(
		float DeltaTime,
		FVector Velocity,
		float StartStraighteningSpeed,
		float RollStraightenDuration,
		bool bIsDashing,
		float DashRollStraightenDuration,
		FVector WorldUp,
		FQuat& MeshRotation,
		FHazeAcceleratedVector& AccRelativeRight,
		)
	{
		const FVector HorizontalVelocity = Velocity.VectorPlaneProject(WorldUp);
		const float HorizontalSpeed = HorizontalVelocity.Size();

		if(Math::IsNearlyZero(HorizontalSpeed))
			return;

		const FQuat ReferenceRotation = FQuat::MakeFromZX(WorldUp, HorizontalVelocity);

		if(AccRelativeRight.Value.IsNearlyZero())
		{
			// Snap to an initial value
			AccRelativeRight.SnapTo(FQuat::GetRelative(ReferenceRotation, MeshRotation).RightVector);
		}

		if(HorizontalSpeed > StartStraighteningSpeed)
		{
			float StraightenDuration = RollStraightenDuration;
			if(bIsDashing)
				StraightenDuration = DashRollStraightenDuration;

			// Convert to relative space
			const FQuat DroneMeshRelativeRotation = FQuat::GetRelative(ReferenceRotation, MeshRotation);

			// Get the current forward and right vectors
			const FVector DroneMeshRelativeForward = DroneMeshRelativeRotation.ForwardVector;
			AccRelativeRight.Value = DroneMeshRelativeRotation.RightVector;

			// Try to move the relative right towards a perfect right to straighten out
			// We flip the right vector based on the current direction to prevent interpolating to the wrong side
			FVector TargetVector = AccRelativeRight.Value.Y > 0.0 ? FVector::RightVector : -FVector::RightVector;
			AccRelativeRight.AccelerateTo(TargetVector, StraightenDuration, DeltaTime);

			// Use the original relative forward as the second vector to retain the original rolling rotation, but use the new right to shift it towards straight
			FRotator NewDroneMeshRelativeRotation = FRotator::MakeFromYX(AccRelativeRight.Value, DroneMeshRelativeForward);
			FQuat DroneMeshWorldRotation = FQuat::ApplyRelative(ReferenceRotation, NewDroneMeshRelativeRotation.Quaternion());
			MeshRotation = DroneMeshWorldRotation;
		}
		else
		{
			// We are too slow to straighten out, just make sure to keep the relative right updated for when we need it again
			AccRelativeRight.Value = FQuat::GetRelative(ReferenceRotation, MeshRotation).RightVector;
			AccRelativeRight.Velocity = Math::VInterpTo(AccRelativeRight.Velocity, FVector::ZeroVector, DeltaTime, 1);
		}
	}
}