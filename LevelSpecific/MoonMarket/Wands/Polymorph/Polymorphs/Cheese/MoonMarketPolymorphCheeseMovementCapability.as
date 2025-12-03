class UMoonMarketPolymorphCheeseMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;

	UStaticMeshComponent Mesh;
	UPlayerMovementComponent MoveComp;
	UMoonMarketShapeshiftComponent ShapeshiftComp;
	USweepingMovementData MoveData;
	const float MaxAcceleration = 800;
	const float MaxRotationSpeed = 20;

	FHazeAcceleratedVector AccVectorRight;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(USweepingMovementData);
		ShapeshiftComp = UMoonMarketShapeshiftComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(PlayerMovementTags::CoreMovement, this);
		Mesh = UStaticMeshComponent::Get(UMoonMarketShapeshiftComponent::Get(Player).ShapeshiftShape.CurrentShape);
		Mesh.AttachParent.bAbsoluteRotation = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);
		Player.UnblockCapabilities(PlayerMovementTags::CoreMovement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(WasActionStarted(ActionNames::MovementJump) && MoveComp.HasGroundContact())
		{
			MoveComp.AddPendingImpulse(FVector::UpVector * 500, this);
			UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(ShapeshiftComp.ShapeshiftShape.CurrentShape, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));
			UMoonMarketPolymorphedOwnerEventHandler::Trigger_OnBounceOrJump(Owner, FMoonMarketPolymorphEventParams(ShapeshiftComp.ShapeData.ShapeTag, Owner));
		}

		if(MoveComp.HasAnyValidBlockingImpacts())
		{
			for(auto Impact : MoveComp.AllImpacts)
			{
				if(MoveComp.AllImpacts.Num() > 1 && MoveComp.HasGroundContact() && MoveComp.GroundContact.Actor == Impact.Actor)
					continue;

				FHitResult FirstImpact = Impact.ConvertToHitResult();

				FVector HorizontalVelocity = MoveComp.Velocity.VectorPlaneProject(FirstImpact.Normal);
				FVector VerticalVelocity = MoveComp.PreviousVelocity.ProjectOnToNormal(FirstImpact.Normal);

				FVector ReflectedVelocity = VerticalVelocity.GetReflectionVector(FirstImpact.Normal) * 0.8;

				if(ReflectedVelocity.Size() > 300)
					Player.PlayForceFeedback(ForceFeedback::Default_Medium_Short, this);

				Owner.SetActorVelocity(HorizontalVelocity + ReflectedVelocity);
			}
		}

		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			CalculateMovement(DeltaTime);
		}
		else
		{
			if(MoveComp.IsOnAnyGround())
				MoveData.ApplyCrumbSyncedGroundMovement();
			else
				MoveData.ApplyCrumbSyncedAirMovement();
		}

		float Freq = 20.0;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = 1.0 + Math::Sin(ActiveDuration * Freq);
		FF.RightMotor = 1.0 + Math::Sin(ActiveDuration * -Freq);
		float Intensity = 0.0;
		if (MoveComp.Velocity.IsNearlyZero())
			Intensity = 0.0;
		else
			Intensity = Math::Saturate(MoveComp.Velocity.Size() / 4200.0);

		Player.SetFrameForceFeedback(FF, 0.05 * Intensity);

		MoveComp.ApplyMove(MoveData);
		
		Owner.SetActorRotation(MoveComp.Velocity.VectorPlaneProject(FVector::UpVector).ToOrientationRotator());
		UpdateMeshRotation(DeltaTime);
	}

	void CalculateMovement(float DeltaTime)
	{
		const float HorizontalSpeedGroundAcceleration = 3;
		const float HorizontalSpeedAirAcceleration = 1;
		const float HorizontalSpeedGroundDeceleration = 1;
		const float HorizontalSpeedAirDeceleration = 0.5;
		FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
		FVector VerticalVelocity = MoveComp.VerticalVelocity;
		
		FVector Forward = Player.GetCameraDesiredRotation().ForwardVector.VectorPlaneProject(FVector::UpVector);
		FVector Right = Forward.CrossProduct(FVector::UpVector);

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		if(!Math::IsNearlyZero(Input.Size()))
		{
			FVector TargetVelocity = Forward * Input.X * MaxAcceleration + Right * -Input.Y * MaxAcceleration;

			if(MoveComp.HasGroundContact())
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, TargetVelocity, DeltaTime, HorizontalSpeedGroundAcceleration);
			else
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, TargetVelocity, DeltaTime, HorizontalSpeedAirAcceleration);
		}
		else
		{
			if(MoveComp.HasGroundContact())
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, HorizontalSpeedGroundDeceleration);
			else
				HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, HorizontalSpeedAirDeceleration);
		}

		MoveData.AddVelocity(HorizontalVelocity + VerticalVelocity);
		MoveData.AddGravityAcceleration();
		MoveData.AddPendingImpulses();
	}

	void UpdateMeshRotation(float DeltaTime)
	{
		const FVector Velocity = MoveComp.Velocity;

		if(Velocity.IsNearlyZero())
			return;

		FQuat MeshRotation = Mesh.AttachParent.ComponentQuat;

		const FVector DesiredUp = MoveComp.GroundContact.ConvertToHitResult().IsValidBlockingHit() ? MoveComp.GroundContact.ImpactNormal : MoveComp.WorldUp;
		const FVector AngularVelocity =  Velocity.CrossProduct(DesiredUp);

		float RotationSpeed = (AngularVelocity.Size() / 30);
		RotationSpeed = Math::Clamp(RotationSpeed, -MaxRotationSpeed, MaxRotationSpeed);

		const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);
		MeshRotation = DeltaQuat * MeshRotation;

		UpdateRollStraighten(DeltaTime, MoveComp.Velocity, 100, 0.5, Owner.ActorTransform, MeshRotation, AccVectorRight);
		
	
		Mesh.AttachParent.SetWorldRotation(MeshRotation);
	}

	void UpdateRollStraighten(
		float DeltaTime,
		FVector Velocity,
		float StartStraighteningSpeed,
		float RollStraightenDuration,
		FTransform ActorTransform,
		FQuat& MeshRotation,
		FHazeAcceleratedVector& AccRelativeRight,
		)
	{
		const float Speed = Velocity.DotProduct(ActorTransform.Rotation.ForwardVector);

		if(Speed > StartStraighteningSpeed)
		{
			float StraightenDuration = RollStraightenDuration;

			// Convert to relative space
			const FQuat DroneMeshRelativeRotation = ActorTransform.InverseTransformRotation(MeshRotation);

			// Get the current forward and right vectors
			const FVector DroneMeshRelativeForward = DroneMeshRelativeRotation.ForwardVector;
			AccRelativeRight.Value = DroneMeshRelativeRotation.RightVector;

			// Try to move the relative right towards a perfect right to straighten out
			// We flip the right vector based on the current direction to prevent interpolating to the wrong side
			FVector TargetVector = AccRelativeRight.Value.Y > 0.0 ? FVector::RightVector : -FVector::RightVector;
			AccRelativeRight.AccelerateTo(TargetVector, StraightenDuration, DeltaTime);

			// Use the original relative forward as the second vector to retain the original rolling rotation, but use the new right to shift it towards straight
			FRotator NewDroneMeshRelativeRotation = FRotator::MakeFromYX(AccRelativeRight.Value, DroneMeshRelativeForward);
			FQuat DroneMeshWorldRotation = ActorTransform.TransformRotation(NewDroneMeshRelativeRotation.Quaternion());
			MeshRotation = DroneMeshWorldRotation;}
		else
		{
			// We are too slow to straighten out, just make sure to keep the relative right updated for when we need it again
			AccRelativeRight.Value = ActorTransform.InverseTransformVectorNoScale(MeshRotation.RightVector);
			AccRelativeRight.Velocity = FVector::ZeroVector;	// FB TODO: Should we set this to something to get a smoother in blend?
		}
	}
};