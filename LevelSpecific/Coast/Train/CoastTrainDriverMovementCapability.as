
class UCoastTrainDriverMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 25;

	ACoastTrainDriver Driver;
	float CurrentMovementSpeed = 0.0;

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
	void Setup()
	{
		Driver = Cast<ACoastTrainDriver>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentMovementSpeed = Driver.CalculateTrainMovementSpeed();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FSplinePosition PreviousPosition = Driver.CurrentPosition;

			float CurveDelta = 0.0;

			if (Driver.ForwardMovementCurveMagnitude > 0.0 && Driver.ForwardMovementCurvePeriod > 0.0)
			{
				Driver.ForwardCurveTimer += DeltaTime * ((2.0 * PI) / Driver.ForwardMovementCurvePeriod);
				float NewForwardCurveDist = Math::Sin(Driver.ForwardCurveTimer) * Driver.ForwardMovementCurveMagnitude;

				CurveDelta = (NewForwardCurveDist - Driver.ForwardCurveCurrent);
				Driver.ForwardCurveCurrent = NewForwardCurveDist;
			}

			float WantedMovementSpeed = Driver.CalculateTrainMovementSpeed();

			CurrentMovementSpeed = Math::FInterpConstantTo(CurrentMovementSpeed, WantedMovementSpeed, DeltaTime, Driver.Acceleration);
			if (CurrentMovementSpeed > 0.0)
				Driver.CurrentPosition.Move(CurrentMovementSpeed * DeltaTime + CurveDelta);

			Driver.UpdateTrainParking(PreviousPosition, Driver.CurrentPosition);
			Driver.UpdateSpin(DeltaTime, Driver.CurrentPosition);

			Driver.CrumbPosition.ApplySplineRelativePositionSync(this, Driver.CurrentPosition);

			FQuat DriverRotation = Driver.CurrentPosition.WorldRotation;
			DriverRotation = DriverRotation * FQuat(FVector::ForwardVector, Math::DegreesToRadians(Driver.CurrentSpin));

			Driver.SetActorLocation(Driver.CurrentPosition.WorldLocation);
			Driver.SetActorRotation(DriverRotation);
			Driver.SetActorVelocity(Driver.CurrentPosition.WorldForwardVector * CurrentMovementSpeed);
		}
		else
		{
			FHazeSyncedActorPosition SyncedPosition = Driver.CrumbPosition.GetPosition();
			CurrentMovementSpeed = SyncedPosition.WorldVelocity.Size();

			UHazeSplineComponent OnSpline = Cast<UHazeSplineComponent>(SyncedPosition.RelativeComponent);
			if (OnSpline != nullptr)
			{
				FSplinePosition PreviousPosition = Driver.CurrentPosition;
				Driver.CurrentPosition = FSplinePosition(OnSpline, SyncedPosition.RelativeSplineDistance, SyncedPosition.bRelativeSplineForward);

#if !RELEASE
				TEMPORAL_LOG(this)
					.Value("SplineDistance", Driver.CurrentPosition.CurrentSplineDistance)
					.Value("SplineVelocity", (Driver.CurrentPosition.CurrentSplineDistance - PreviousPosition.CurrentSplineDistance) / DeltaTime)
				;
#endif
				
				Driver.SetActorLocation(Driver.CurrentPosition.WorldLocation);
				Driver.SetActorRotation(Driver.CurrentPosition.WorldRotation);
				Driver.SetActorVelocity(SyncedPosition.WorldVelocity);
			}
			else
			{
				Driver.SetActorLocation(SyncedPosition.WorldLocation);
				Driver.SetActorRotation(SyncedPosition.WorldRotation.Quaternion());
				Driver.SetActorVelocity(SyncedPosition.WorldVelocity);
			}
		}

		// Update all child carts
		FSplinePosition ChildPosition = Driver.CurrentPosition;
		for(auto Cart : Driver.Carts)
		{
			if (Cart.Cart.bCartDisabled)
				continue;

			if (!Cart.Cart.bCartDisconnected)
			{
				ChildPosition.Move(-Cart.DistanceFromCartInFront);
				Cart.Cart.CurrentMovementSpeed = CurrentMovementSpeed;
				Cart.Cart.UpdateSpin(DeltaTime, ChildPosition);
				Cart.Cart.UpdateMovement(DeltaTime, ChildPosition);
			}
			else
			{
				Cart.Cart.UpdateDisconnectedMovement(DeltaTime);
			}
		}

		// update Connection beam anchors after all carts have moved
		for(auto Cart : Driver.Carts)
		{
			Cart.Cart.MoveNiagaraConnectionBeamAnchors();
		}

		// Any spins that have ended and can no longer affect any carts should be removed
		for (int i = 0, Count = Driver.ActiveSpins.Num(); i < Count; ++i)
		{
			auto& ActiveSpin = Driver.ActiveSpins[i];
			if (!ActiveSpin.bHasEnded)
				continue;

			FCoastTrainCartInfo LastCart = Driver.Carts.Last();
			if (!ActiveSpin.EndPosition.IsBetweenPositionsWithPolarity(
				LastCart.Cart.CurrentPosition, Driver.CurrentPosition,
				ESplineMovementPolarity::Positive
			))
			{
				Driver.ActiveSpins.RemoveAt(i);
				--i; --Count;
			}
		}
	}
}