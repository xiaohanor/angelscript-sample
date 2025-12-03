class USkylineAttackShipCrashCapability : UHazeChildCapability
{
	default CapabilityTags.Add(n"SkylineAttackShipCrash");
	default CapabilityTags.Add(n"SkylineAttackShipMovement");

	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	ASkylineAttackShip AttackShip;

	FSplinePosition SplinePosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<ASkylineAttackShip>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AttackShip.bIsCrashing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!AttackShip.bIsCrashing)
			return true;

//		if (ActiveDuration > 4.0)
//			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("OnActivated Crashing", 0.1, FLinearColor::Green);

		if (AttackShip.Spline == AttackShip.CrashSpline)
			SplinePosition = AttackShip.Spline.GetClosestSplinePositionToWorldLocation(AttackShip.ActorLocation);
	
		AttackShip.BlockCapabilities(n"SkylineAttackShipSplineFollow", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AttackShip.UnblockCapabilities(n"SkylineAttackShipSplineFollow", this);
		AttackShip.Explode();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AttackShip.Spline == AttackShip.CrashSpline)
		{	
			{	
				float SpeedScale = Math::Clamp(ActiveDuration - 2.0, 0.0, 3.0);
				if (SplinePosition.Move(AttackShip.Settings.MovementSpeed * SpeedScale * SplinePosition.RelativeScale3D.Y * DeltaTime))
				{
					AttackShip.AddMoveToTarget(SplinePosition.WorldLocation, this);
					AttackShip.ClearLookAtTarget(AttackShip);
					AttackShip.AttackTarget.Empty();
					AttackShip.AddLookAtTarget(SplinePosition.WorldLocation, this);
					AttackShip.SpeedScale = 6.0; // 3.0

					// Add Local spin
					AttackShip.AngularAcceleration += AttackShip.ActorTransform.InverseTransformVectorNoScale((FVector::UpVector + (FVector::RightVector * 0.25)) * 2.0);
				}
				else
					AttackShip.bIsCrashing = false;
			}
//			Debug::DrawDebugPoint(SplinePosition.WorldLocation, 100.0, FLinearColor::Green, 0.0);
		}
		else
		{
			AttackShip.Acceleration += -FVector::UpVector * 2500.0;
			AttackShip.AngularAcceleration += AttackShip.ActorTransform.InverseTransformVectorNoScale(AttackShip.ActorUpVector.CrossProduct(AttackShip.ActorForwardVector) * 0.3)
										    + AttackShip.ActorTransform.InverseTransformVectorNoScale(AttackShip.ActorUpVector.CrossProduct(AttackShip.ActorRightVector) * 0.3);
		
			if (ActiveDuration > 4.0)
				AttackShip.bIsCrashing = false;
		}
	}
}