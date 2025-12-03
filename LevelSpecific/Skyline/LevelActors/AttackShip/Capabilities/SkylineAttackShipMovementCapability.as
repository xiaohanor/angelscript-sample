class USkylineAttackShipMovementCapability : UHazeChildCapability
{
	default CapabilityTags.Add(n"SkylineAttackShipMovement");

	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	ASkylineAttackShip AttackShip;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<ASkylineAttackShip>(Owner);
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			AttackShip.Acceleration -= AttackShip.Velocity * AttackShip.Settings.Drag;

			AttackShip.Velocity += AttackShip.Acceleration * DeltaTime;

	/*
			FVector Torque = AttackShip.ActorTransform.InverseTransformVectorNoScale(AttackShip.ActorForwardVector.CrossProduct(AttackShip.Acceleration.SafeNormal) * 1.0)
						+ AttackShip.ActorTransform.InverseTransformVectorNoScale(AttackShip.ActorUpVector.CrossProduct(FVector::UpVector) * 1.0)
						- AttackShip.AngularVelocity * 1.0;
	*/
			FVector TargetDirection = (AttackShip.MoveToTarget.Get() - AttackShip.ActorLocation).SafeNormal;
			if (!AttackShip.TargetDirection.IsDefaultValue())
			{
				PrintToScreenScaled("TargetDirection Found", 0.0, FLinearColor::Green, 1.0);
				TargetDirection = AttackShip.TargetDirection.Get();
			}

			FVector Torque;

			if (!AttackShip.bIsCrashing)
			{
			Torque = AttackShip.ActorTransform.InverseTransformVectorNoScale(AttackShip.ActorUpVector.CrossProduct(AttackShip.Acceleration.SafeNormal) * 0.4) // Tilt towards Acceleration
						+ AttackShip.ActorTransform.InverseTransformVectorNoScale(AttackShip.ActorUpVector.CrossProduct(FVector::UpVector) * 3.0) // Try to stay upright
						+ AttackShip.ActorTransform.InverseTransformVectorNoScale(AttackShip.ActorForwardVector.CrossProduct(TargetDirection) * 2.0); // Try to keep look at direction
//						- AttackShip.AngularVelocity * 1.0;
			}

			Torque -= AttackShip.AngularVelocity * 1.0;

			AttackShip.AngularVelocity += AttackShip.AngularImpulse;
			AttackShip.Velocity += AttackShip.Impulse;

			AttackShip.AngularAcceleration += Torque;
			AttackShip.AngularVelocity += AttackShip.AngularAcceleration * DeltaTime;

			FQuat Rotation = AttackShip.ActorQuat * FQuat(AttackShip.AngularVelocity.SafeNormal, AttackShip.AngularVelocity.Size() * DeltaTime);

			AttackShip.SetActorRotation(Rotation);
			AttackShip.AddActorWorldOffset(AttackShip.Velocity * DeltaTime);
		
			AttackShip.Acceleration = FVector::ZeroVector;
			AttackShip.AngularAcceleration = FVector::ZeroVector;
			AttackShip.Impulse = FVector::ZeroVector;
			AttackShip.AngularImpulse = FVector::ZeroVector;

			AttackShip.CrumbSyncedVectorComponent.SetValue(AttackShip.ActorLocation);
			AttackShip.CrumbSyncedRotatorComponent.SetValue(AttackShip.ActorRotation);
		}
		else
		{
			AttackShip.ActorLocation = AttackShip.CrumbSyncedVectorComponent.Value;
			AttackShip.ActorRotation = AttackShip.CrumbSyncedRotatorComponent.Value;
		}
	}
}