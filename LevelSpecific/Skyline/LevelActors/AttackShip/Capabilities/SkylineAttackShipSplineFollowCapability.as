class USkylineAttackShipSplineFollowCapability : UHazeChildCapability
{
	default CapabilityTags.Add(n"SkylineAttackShipSplineFollow");
	default CapabilityTags.Add(n"SkylineAttackShipMovement");

	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

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
		if (AttackShip.Spline == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AttackShip.Spline == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplinePosition = AttackShip.Spline.GetClosestSplinePositionToWorldLocation(AttackShip.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AttackShip.SpeedScale = 1.0;
	
		AttackShip.ClearMoveToTarget(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AttackShip.SpeedScale = SplinePosition.RelativeScale3D.Y;

		if (!SplinePosition.Move(AttackShip.Settings.MovementSpeed * SplinePosition.RelativeScale3D.Y * DeltaTime))
		{
			int CurrentIndex = AttackShip.SplineOwningActors.FindIndex(SplinePosition.CurrentSpline.Owner);

			if (CurrentIndex == AttackShip.SplineOwningActors.Num() - 2)
				AttackShip.PrepareAttackReady();
//				AttackShip.AttackReady();

			if (CurrentIndex < AttackShip.SplineOwningActors.Num() - 1)
			{
				AttackShip.Spline = UHazeSplineComponent::Get(AttackShip.SplineOwningActors[CurrentIndex + 1]);
				SplinePosition = AttackShip.Spline.GetClosestSplinePositionToWorldLocation(AttackShip.ActorLocation);
			}
			else
				SplinePosition.ReverseFacing();
		}

//		Debug::DrawDebugPoint(SplinePosition.WorldLocation, 100.0, FLinearColor::Green, 0.0);
		AttackShip.AddMoveToTarget(SplinePosition.WorldLocation, this);	
	}
}