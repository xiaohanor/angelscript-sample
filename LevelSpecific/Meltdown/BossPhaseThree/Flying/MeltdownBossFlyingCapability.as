class UMeltdownBossFlyingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1;

	UPlayerMovementComponent MoveComp;
	USweepingMovementData Movement;
	UMeltdownBossFlyingComponent FlyingComp;
	UMeltdownBossFlyingSettings Settings;

	bool bIsDashing = false;
	float DashOnCooldownUntil = 0.0;
	float DashTimer = 0.0;

	FHazeAcceleratedVector2D AccBlendSpace;

	FDashMovementCalculator DashCalculator;
	FVector2D DashDirection;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		FlyingComp = UMeltdownBossFlyingComponent::Get(Player);
		Settings = UMeltdownBossFlyingSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
		if (!FlyingComp.bIsFlying)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		if (!FlyingComp.bIsFlying)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FHazePointOfInterestFocusTargetInfo PoiTarget;
		PoiTarget.SetFocusToActor(FlyingComp.CenterPoint);

		FHazeCameraClampSettings PoiClamps;
		PoiClamps.ApplyClampsPitch(Settings.CameraPointOfInterestClampPitch, Settings.CameraPointOfInterestClampPitch);
		PoiClamps.ApplyClampsYaw(Settings.CameraPointOfInterestClampYaw, Settings.CameraPointOfInterestClampYaw);
		
		FApplyClampPointOfInterestSettings PoiSettings;
		PoiSettings.ClampFullFreedomAnglePercentage = 0.33;

		Player.ApplyClampedPointOfInterest(this, PoiTarget, PoiSettings, PoiClamps, 2.0);
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

				if (WasActionStarted(ActionNames::MovementDash))
				{
					if (!bIsDashing && Time::GameTimeSeconds > DashOnCooldownUntil)
					{
						bIsDashing = true;
						DashCalculator = FDashMovementCalculator(
							GetCapabilityDeltaTime(),
							Settings.DashDistance, Settings.DashDuration,
							Settings.DashAccelerationDuration, Settings.DashDecelerationDuration,
							Player.ActorVelocity.Size(), Settings.DashExitSpeed,
						);
						DashOnCooldownUntil = Time::GameTimeSeconds + Settings.DashCooldown;
						DashDirection = RawStick.GetSafeNormal();
						DashTimer = 0.0;
					}
				}

				if (IsActioning(ActionNames::MovementVerticalDown))
				{
					RawStick.Y = -1;
					RawStick = RawStick.GetClampedToMaxSize(1.0);
				}
				else if (IsActioning(ActionNames::MovementVerticalUp))
				{
					RawStick.Y = 1;
					RawStick = RawStick.GetClampedToMaxSize(1.0);
				}

				if (bIsDashing)
					FlyingComp.DashDirection = DashDirection;
				AccBlendSpace.AccelerateTo(FVector2D(RawStick.X, RawStick.Y), 1.0, DeltaTime);
				FlyingComp.MovementBlendSpaceValue = AccBlendSpace.Value;

				FTransform CenterTransform = FlyingComp.CenterPoint.ActorTransform;

				FVector LocalPlayerLocation = CenterTransform.InverseTransformPositionNoScale(Player.ActorLocation);
				FVector LocalPlayerVelocity = CenterTransform.InverseTransformVectorNoScale(Player.ActorVelocity);

				FVector ForwardAxis = LocalPlayerLocation.GetSafeNormal();

				FVector UpAxis = CenterTransform.InverseTransformVectorNoScale(MoveComp.WorldUp);
				FRotator LocalRotation = FRotator::MakeFromXZ(ForwardAxis, UpAxis);
				FVector RightAxis = LocalRotation.RightVector;

				float CurrentDistance = LocalPlayerLocation.Size();

				// Debug::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + RightAxis * 500.0, FLinearColor::Red);

				float HorizontalVelocity = LocalPlayerVelocity.DotProduct(RightAxis);
				float VerticalVelocity = LocalPlayerVelocity.DotProduct(UpAxis);

				float HorizontalDelta = 0;
				float VerticalDelta = 0;

				// Handle the soft boundaries by slowing down the movement near them
				float HorizontalMultiplier = 0.0;
				if ((!bIsDashing && RawStick.X > 0) || (bIsDashing && DashDirection.X > 0))
				{
					HorizontalMultiplier = Math::GetMappedRangeValueClamped(
						FVector2D(Settings.MinimumYaw, Settings.MinimumYaw * (1.0 - Settings.BoundaryClampEdgeWidth)),
						FVector2D(0.0, 1.0),
						LocalRotation.Yaw
					);
				}
				else
				{
					HorizontalMultiplier = Math::GetMappedRangeValueClamped(
						FVector2D(Settings.MaximumYaw, Settings.MaximumYaw * (1.0 - Settings.BoundaryClampEdgeWidth)),
						FVector2D(0.0, 1.0),
						LocalRotation.Yaw
					);
				}

				float VerticalMultiplier = 0.0;
				if ((!bIsDashing && RawStick.Y < 0) || (bIsDashing && DashDirection.Y < 0))
				{
					VerticalMultiplier = Math::GetMappedRangeValueClamped(
						FVector2D(Settings.MinimumPitch, Settings.MinimumPitch * (1.0 - Settings.BoundaryClampEdgeWidth)),
						FVector2D(0.0, 1.0),
						LocalRotation.Pitch
					);
				}
				else
				{
					VerticalMultiplier = Math::GetMappedRangeValueClamped(
						FVector2D(Settings.MaximumPitch, Settings.MaximumPitch * (1.0 - Settings.BoundaryClampEdgeWidth)),
						FVector2D(0.0, 1.0),
						LocalRotation.Pitch
					);
				}

				if (bIsDashing)
				{
					float DashDelta = 0;
					float DashVelocity = 0;

					DashCalculator.CalculateMovement(
						DashTimer, DeltaTime,
						DashDelta, DashVelocity
					);
					DashTimer += DeltaTime;

					HorizontalVelocity = DashDirection.X * DashVelocity * HorizontalMultiplier;
					HorizontalDelta = DashDirection.X * DashDelta * HorizontalMultiplier;

					VerticalVelocity = -DashDirection.Y * DashVelocity * VerticalMultiplier;
					VerticalDelta = -DashDirection.Y * DashDelta * VerticalMultiplier;

					if (DashCalculator.IsFinishedAtTime(DashTimer))
					{
						bIsDashing = false;
					}
				}
				else
				{
					float WantedHorizontalVelocity = RawStick.X * Settings.HorizontalSpeed * HorizontalMultiplier;
					HorizontalVelocity = Math::FInterpConstantTo(HorizontalVelocity, WantedHorizontalVelocity, DeltaTime, Settings.HorizontalAcceleration);
					HorizontalDelta = HorizontalVelocity * DeltaTime;
					
					float WantedVerticalVelocity = -RawStick.Y * Settings.VerticalSpeed * VerticalMultiplier;
					VerticalVelocity = Math::FInterpConstantTo(VerticalVelocity, WantedVerticalVelocity, DeltaTime, Settings.VerticalAcceleration);
					VerticalDelta = VerticalVelocity * DeltaTime;
				}

				// Apply the movement
				LocalRotation.Yaw -= Math::RadiansToDegrees(HorizontalDelta / CurrentDistance);
				LocalRotation.Yaw = Math::Clamp(LocalRotation.Yaw, Settings.MinimumYaw, Settings.MaximumYaw);

				LocalRotation.Pitch -= Math::RadiansToDegrees(VerticalDelta / CurrentDistance);
				LocalRotation.Pitch = Math::Clamp(LocalRotation.Pitch, Settings.MinimumPitch, Settings.MaximumPitch);

				// Lerp the distance to the center
				if (FlyingComp.KnockbackImpulse > 0)
				{
					CurrentDistance += FlyingComp.KnockbackImpulse * DeltaTime;
					FlyingComp.KnockbackImpulse *= Math::Pow(0.01, DeltaTime);
				}
				CurrentDistance = Math::FInterpTo(CurrentDistance, FlyingComp.Distance, DeltaTime, 1.0);

				// Convert sideways movement to rotational
				FVector TargetLocation = LocalRotation.ForwardVector * CurrentDistance;
				FVector VelocityAtTargetLocation
					= LocalRotation.RightVector * HorizontalVelocity
					+ UpAxis * VerticalVelocity;

				Movement.AddDeltaWithCustomVelocity(
					CenterTransform.TransformPositionNoScale(TargetLocation) - Player.ActorLocation,
					CenterTransform.TransformVectorNoScale(VelocityAtTargetLocation)
				);
				Movement.BlockGroundTracingForThisFrame();

				FQuat FinalRotation = FQuat::MakeFromZX(UpAxis, -ForwardAxis);
				Movement.InterpRotationTo(CenterTransform.TransformRotation(FinalRotation), TWO_PI);
			}
			// Remote update
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			FlyingComp.bIsDashing = bIsDashing;
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"MeltdownBossFlying");
		}
	}
};