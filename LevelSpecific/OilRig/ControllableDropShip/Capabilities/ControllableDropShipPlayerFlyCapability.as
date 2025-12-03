class UControllableDropShipPlayerFlyCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AControllableDropShip DropShip;

	float CurrentMoveSpeed = 0.0;

	float YawRate = 0.0;

	float PitchRate = 0.0;
	float CurrentPitch = 0.0;

	FSplinePosition SplinePos;
	FVector2D CurrentSplineOffset = FVector2D::ZeroVector;
	FVector2D TargetSplineOffset = FVector2D::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DropShip = Cast<AControllableDropShip>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DropShip.bFlying)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DropShip.bFlying)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplinePos = FSplinePosition(DropShip.FlyFollowSpline.Spline, DropShip.FlyFollowSpline.Spline.GetClosestSplineDistanceToWorldLocation(DropShip.ActorLocation), true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (DropShip.SyncedShipPosition.HasControl())
		{
			CurrentMoveSpeed = Math::Clamp(CurrentMoveSpeed + ControllableDropShip::FlyingAccelerationSpeed * DeltaTime, 0.0, ControllableDropShip::FlyingMaxMoveSpeed);
			// DropShip.AddActorWorldOffset(DropShip.DropShipRoot.ForwardVector * CurrentMoveSpeed * DeltaTime);

			if (!DropShip.VeerTimeLike.IsPlaying())
			{
				YawRate = Math::FInterpTo(YawRate, DropShip.PilotInput.X, DeltaTime, 5.0);
				float TargetYaw = DropShip.OriginalYaw + (YawRate * ControllableDropShip::FlyingMaxYaw);
				DropShip.CurrentYaw = Math::FInterpTo(DropShip.CurrentYaw, TargetYaw, DeltaTime, 2.0);
				DropShip.SetActorRotation(FRotator(0.0, DropShip.CurrentYaw, 0.0));
			}

			PitchRate = Math::FInterpTo(PitchRate, DropShip.PilotInput.Y, DeltaTime, 5.0);
			float TargetPitch = 5.0 + (PitchRate * ControllableDropShip::FlyingMaxPitch);
			CurrentPitch = Math::FInterpTo(CurrentPitch, TargetPitch, DeltaTime, 1.0);
			DropShip.CurrentRoll = Math::FInterpTo(DropShip.CurrentRoll, YawRate * ControllableDropShip::FlyingMaxRoll, DeltaTime, 2.0);

			DropShip.DropShipRoot.SetRelativeRotation(FRotator(CurrentPitch, 0.0, DropShip.CurrentRoll));
			DropShip.SyncedShipPitch.SetValue(CurrentPitch);

			SplinePos.Move(CurrentMoveSpeed * DeltaTime);
			TargetSplineOffset.X = Math::Clamp(TargetSplineOffset.X + (YawRate * ControllableDropShip::FlyingStrafeSpeed * DeltaTime), -ControllableDropShip::FlyingMaxOffset.X, ControllableDropShip::FlyingMaxOffset.X);
			TargetSplineOffset.Y = Math::Clamp(TargetSplineOffset.Y + (PitchRate * ControllableDropShip::FlyingStrafeSpeed * DeltaTime), -ControllableDropShip::FlyingMaxOffset.Y, ControllableDropShip::FlyingMaxOffset.Y);
			CurrentSplineOffset = Math::Vector2DInterpTo(CurrentSplineOffset, TargetSplineOffset, DeltaTime, 4.0);
			DropShip.CurrentSplineOffset = CurrentSplineOffset;

			FVector Loc = SplinePos.WorldLocation;
			Loc += SplinePos.WorldRotation.RightVector * CurrentSplineOffset.X;
			Loc += SplinePos.WorldRotation.UpVector * CurrentSplineOffset.Y;

			DropShip.SetActorLocation(Loc);


			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnoreActor(DropShip);
			Trace.IgnorePlayers();
			Trace.UseBoxShape(FVector(700.0, 400.0, 200.0), FQuat(DropShip.DropShipRoot.WorldRotation));

			FVector TraceStartLoc = DropShip.DropShipRoot.WorldLocation + (FVector::UpVector * 200.0);
			FHitResult Hit = Trace.QueryTraceSingle(TraceStartLoc, TraceStartLoc + FVector::UpVector);
			if (Hit.bBlockingHit && Game::Mio.GetGodMode() != EGodMode::God)
			{
				AControllableDropShipFallingObject FallingObject = Cast<AControllableDropShipFallingObject>(Hit.Actor);
				if (FallingObject != nullptr)
				{
					FallingObject.Crash();
					DropShip.CurrentDamageTaken += 25;
					if (DropShip.CurrentDamageTaken >= DropShip.MaxHealth)
						DropShip.CrumbCrash();
				}
				else
					DropShip.CrumbCrash();
			}
		}
		else
		{
			DropShip.SetActorLocationAndRotation(DropShip.SyncedShipPosition.Position.WorldLocation, DropShip.SyncedShipPosition.Position.WorldRotation);
			DropShip.DropShipRoot.SetRelativeRotation(FRotator(DropShip.SyncedShipPitch.Value, 0.0, 0.0));
		}
	}
}