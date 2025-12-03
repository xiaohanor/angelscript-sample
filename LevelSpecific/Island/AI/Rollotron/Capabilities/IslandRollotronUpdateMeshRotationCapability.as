/**
 * Based on UMagnetDroneUpdateMeshRotationCapability
 */
class UIslandRollotronUpdateMeshRotationCapability : UHazeCapability
{
	default DebugCategory = n"IslandRollotron";

	default CapabilityTags.Add(n"IslandRollotronUpdateMeshRotation");

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = 100;
	
	UHazeMovementComponent MoveComp;
	UPoseableMeshComponent Mesh;
	UCapsuleComponent CollisionComponent; // ought to be a sphere 

	USceneComponent PreviousSurfaceComponent;
	FTransform PreviousSurfaceTransform;
	FHazeAcceleratedVector AccMeshRelativeRight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
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
		AAIIslandRollotron Rollotron = Cast<AAIIslandRollotron>(Owner);
		Mesh = Rollotron.RollotronMesh;
		CollisionComponent = Rollotron.CapsuleComponent;
		Mesh.SetAbsolute(false, true, false);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{	
		UpdateRotationRelativeToSurface();
		UpdateMeshRotation(DeltaTime);

		// Optional
		//if (CanStraighten())
		//	UpdateRollStraighten(DeltaTime);
	}

	private bool CanStraighten() const
	{
		// if(!Settings.bStraightenWhileAirborne && !MoveComp.IsOnAnyGround())
		// 	return false;

		return true;
	}

	private void UpdateRotationRelativeToSurface()
	{
		USceneComponent CurrentGround = nullptr;

		if(CurrentGround == nullptr && MoveComp.HasGroundContact())
			CurrentGround = MoveComp.GetGroundContact().Component;

		if(CurrentGround != nullptr)
		{
			const FTransform CurrentGroundTransform = CurrentGround.GetWorldTransform();

			if(PreviousSurfaceComponent != nullptr && PreviousSurfaceComponent == CurrentGround)
			{
				const FQuat RelativeRotation = PreviousSurfaceTransform.InverseTransformRotation(Mesh.GetWorldRotation().Quaternion());
				Mesh.SetWorldRotation(CurrentGroundTransform.TransformRotation(RelativeRotation));
			}

			PreviousSurfaceTransform = CurrentGroundTransform;
			PreviousSurfaceComponent = CurrentGround;
		}
		else
		{
			PreviousSurfaceComponent = nullptr;
		}
	}

	private void UpdateMeshRotation(float DeltaTime)
	{
		const FVector DesiredUp = MoveComp.HasGroundContact() ? MoveComp.GetGroundContact().ImpactNormal : MoveComp.WorldUp;
		FVector AngularVelocity;

		AngularVelocity = MoveComp.Velocity.CrossProduct(DesiredUp);
		float Radius = CollisionComponent.BoundsRadius;
		const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), -1.0 * DeltaTime * MoveComp.Velocity.Size()/Radius); // Rotate around AngularVelocity as axis, flip sign as positive direction is determined by the lefthand rule.

		Mesh.AddWorldRotation(DeltaQuat);
	}

	private void UpdateRollStraighten(float DeltaTime)
	{
		const float Speed = MoveComp.Velocity.DotProduct(Owner.ActorForwardVector);

		if(Speed > 100) // Settings.StartStraighteningSpeed
		{			
			float bStraightenDuration = 1.0; //Settings.RollStraightenDuration;

			// Convert to relative space
			const FRotator DroneMeshRelativeRotation = Owner.ActorTransform.InverseTransformRotation(Mesh.WorldRotation);

			// Get the current forward and right vectors
			const FVector DroneMeshRelativeForward = DroneMeshRelativeRotation.ForwardVector;
			AccMeshRelativeRight.Value = DroneMeshRelativeRotation.RightVector;

			// Try to move the relative right towards a perfect right to straighten out
			// We flip the right vector based on the current direction to prevent interpolating to the wrong side
			FVector TargetVector = AccMeshRelativeRight.Value.Y > 0.0 ? FVector::RightVector : -FVector::RightVector;
			AccMeshRelativeRight.AccelerateTo(TargetVector, bStraightenDuration, DeltaTime);

			// Use the original relative forward as the second vector to retain the original rolling rotation, but use the new right to shift it towards straight
			FRotator NewDroneMeshRelativeRotation = FRotator::MakeFromYX(AccMeshRelativeRight.Value, DroneMeshRelativeForward);
			FQuat DroneMeshWorldRotation = Owner.ActorTransform.TransformRotation(NewDroneMeshRelativeRotation.Quaternion());
			Mesh.SetWorldRotation(DroneMeshWorldRotation);
		}
		else
		{
			// We are too slow to straighten out, just make sure to keep the relative right updated for when we need it again
			AccMeshRelativeRight.Value = Owner.ActorTransform.InverseTransformVectorNoScale(Mesh.RightVector);
			AccMeshRelativeRight.Velocity = FVector::ZeroVector;	// FB TODO: Should we set this to something to get a smoother in blend?
		}
	}
}