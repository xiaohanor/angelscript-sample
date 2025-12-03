
class UDroneSwarmUpdateMeshRotationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(DroneCommonTags::DroneMeshRotationCapability);

	default DebugCategory = Drone::DebugCategory;

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	default TickGroupOrder = 200;

	UHazeMovementComponent MoveComp;
	UDroneComponent DroneComp;
	UMeshComponent DroneMesh;

	FHazeMovementComponentAttachment PreviousFollow;
	FQuat RelativeToPreviousFollow;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		DroneComp = UDroneComponent::Get(Owner);
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
		if(DroneComp.GetDroneMeshComponent() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DroneMesh = DroneComp.GetDroneMeshComponent();
		DroneMesh.SetAbsolute(false, true, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		UpdateRotationRelativeToFollow();
		UpdateMeshRotation(DeltaTime);

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

		const FVector DesiredUp = MoveComp.HasGroundContact() ? MoveComp.GetGroundContact().ImpactNormal : MoveComp.WorldUp;
		const FVector AngularVelocity =  Velocity.CrossProduct(DesiredUp);
		const float Radius = DroneComp.CollisionComponent.SphereRadius;
		float RotationSpeed = (AngularVelocity.Size() / Radius);
		RotationSpeed = Math::Clamp(RotationSpeed, -DroneComp.MovementSettings.RollMaxSpeed, DroneComp.MovementSettings.RollMaxSpeed);

		const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);
		DroneMesh.AddWorldRotation(DeltaQuat);
	}

	FVector GetVelocity() const
	{
		const FVector Velocity = UHazeRawVelocityTrackerComponent::Get(Owner).CurrentFrameTranslationVelocity;
		return Velocity - MoveComp.GetFollowVelocity();
	}
};