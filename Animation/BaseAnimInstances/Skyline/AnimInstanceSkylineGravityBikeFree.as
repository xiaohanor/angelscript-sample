UCLASS(Abstract)
class UAnimInstanceSkylineGravityBikeFree : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator WheelRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SuspensionOffset;

	FHazeAcceleratedFloat Suspension;
	FHazeAcceleratedVector AccLocation;

	bool bIsInAir;

	bool bLandingSpring;
	float PreventCentrifugalSuspensionTimer = 0;

	float WheelRotationSpeedInAir;
	const float WHEEL_ROTATION_SPEED = .3;

	const float GROUND_NOISE_FREQUENCY = 1;
	const float GROUND_NOISE_AMPLITUDE = 4;

	const float INERTIA_LAG_DURATION = 0.3;
	const float INERTIA_AMPLITUDE = 1;

	const float MinLimit = -8;
	const float MaxLimit = 10;

	int ForceNoSuspensionFrames;

	AGravityBikeFree BikeFree;
	AGravityBikeSpline BikeSpline;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		BikeFree = Cast<AGravityBikeFree>(HazeOwningActor);
		BikeSpline = Cast<AGravityBikeSpline>(HazeOwningActor);
		AccLocation.SnapTo(HazeOwningActor.ActorLocation);
		Suspension.SnapTo(0);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (BikeFree == nullptr && BikeSpline == nullptr)
			return;

		const FVector LocalVelocity = HazeOwningActor.GetActorLocalVelocity();
		if (HazeOwningActor.bIsControlledByCutscene)
		{
			Suspension.SnapTo(0);
			AccLocation.SnapTo(HazeOwningActor.ActorLocation);

			SuspensionOffset = FVector::ZeroVector;
			bLandingSpring = false;
			bIsInAir = false;
			PreventCentrifugalSuspensionTimer = 0;

			WheelRotation.Pitch -= LocalVelocity.X * DeltaTime * WHEEL_ROTATION_SPEED;

			ForceNoSuspensionFrames = 15;
			return;
		}

		AccLocation.AccelerateTo(HazeOwningActor.ActorLocation, INERTIA_LAG_DURATION, DeltaSeconds);

		//Debug::DrawDebugPoint(AccLocation.Value, 10, FLinearColor::Red);
		//Debug::DrawDebugDirectionArrow(HazeOwningActor.ActorLocation, GetBikeUp(), 200, 100, FLinearColor::Red, 10);
		// PrintToScreen(f"{AccLocation.Value=}");

		if (CheckValueChangedAndSetBool(bIsInAir, IsAirBorne()))
		{
			if (bIsInAir)
			{
				WheelRotationSpeedInAir = LocalVelocity.X * WHEEL_ROTATION_SPEED; // Set the initial wheel rotation
			}
			else
			{
				// Prevent centrifugal suspension for a while so we first get the landing spring
				PreventCentrifugalSuspensionTimer = 0.8;
				bLandingSpring = true;
			}
		}

		if (bIsInAir)
		{
			// De-accelerate while in air (or maybe accelerate more if bWantsToMove?)
			WheelRotationSpeedInAir = Math::FInterpTo(WheelRotationSpeedInAir, 20, DeltaTime, 2);
			WheelRotation.Pitch -= WheelRotationSpeedInAir * DeltaTime;
		}
		else
		{
			WheelRotation.Pitch -= LocalVelocity.X * DeltaTime * WHEEL_ROTATION_SPEED;
		}

		WheelRotation.Pitch = Math::Wrap(WheelRotation.Pitch, 0, 360);

		// ---- Suspension ----
		if (bIsInAir)
		{
			Suspension.Value = Math::FInterpTo(Suspension.Value, 35, DeltaTime, 1);
		}
		else
		{
			float SpringTarget = 0;

			if(LocalVelocity.Size() > 100)
			{
				// Generate some noise to emulate the ground being bumpy
				float GroundNoise = Math::PerlinNoise2D(FVector2D(HazeOwningActor.ActorLocation.X, HazeOwningActor.ActorLocation.Y) * GROUND_NOISE_FREQUENCY);
				GroundNoise *= GROUND_NOISE_AMPLITUDE;
				SpringTarget += GroundNoise;
			}

			{
				// Add some inertia from our world location changing
				float OffsetFromInertia = (HazeOwningActor.ActorLocation - AccLocation.Value).DotProduct(GetBikeUp());
				OffsetFromInertia *= INERTIA_AMPLITUDE;

				SpringTarget += OffsetFromInertia;
			}

			bool bSpring = false;
			if (PreventCentrifugalSuspensionTimer > 0)
			{
				PreventCentrifugalSuspensionTimer -= DeltaTime;
				bSpring = true;
			}
			else
			{
				// If player is turning fast enough, lower the bike
				if (Math::Abs(LocalVelocity.Y) > 500)
				{
					bLandingSpring = false;
					Suspension.AccelerateTo(MinLimit, 1.5, DeltaTime);
				}
				else
					bSpring = true;
			}

			if (bSpring)
			{
				SpringTarget = Math::Clamp(SpringTarget, MinLimit, MaxLimit);
				float PreviousValue = Suspension.Value;

				if (bLandingSpring)
					Suspension.SpringTo(SpringTarget, 500, 0.05, DeltaTime);
				else
					Suspension.SpringTo(SpringTarget, 200, 0.1, DeltaTime);

				bool bHitLimit = false;
				float SubstepDeltaTime = DeltaTime;
				if(Suspension.Value < MinLimit && Suspension.Velocity < 0)
				{
					// Hit min limit
					float Time = Math::NormalizeToRange(MinLimit, PreviousValue, Suspension.Value);
					Suspension.Value = MinLimit;
					Suspension.Velocity *= -0.7;
					SubstepDeltaTime *= Time;
					bHitLimit = true;
				}
				else if(Suspension.Value > MaxLimit && Suspension.Velocity > 0)
				{
					// Hit max limit
					float Time = Math::NormalizeToRange(MaxLimit, PreviousValue, Suspension.Value);
					Suspension.Value = MaxLimit;
					Suspension.Velocity *= -0.7;
					SubstepDeltaTime *= Time;
					bHitLimit = true;
				}

				if(bHitLimit)
				{
					// Substep another spring if we hit a limit
					if (bLandingSpring)
						Suspension.SpringTo(SpringTarget, 500, 0.05, SubstepDeltaTime);
					else
						Suspension.SpringTo(SpringTarget, 200, 0.1, SubstepDeltaTime);
				}
			}
		}

		if (ForceNoSuspensionFrames > 0)
		{
			Suspension.SnapTo(0);
			--ForceNoSuspensionFrames;
		}

		SuspensionOffset.Z = Math::Clamp(Suspension.Value, MinLimit, MaxLimit);
	}

	bool IsAirBorne()
	{
		if (BikeSpline != nullptr )
			return BikeSpline.IsAirborne.Get();

		return BikeFree.IsAirborne.Get();
	}

	FVector GetBikeUp() const
	{
		if (BikeSpline != nullptr )
			return BikeSpline.MeshPivot.UpVector;

		return BikeFree.MeshPivot.UpVector;
	}
}