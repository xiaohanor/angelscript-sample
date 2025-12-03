class UAnimGiantsLookAtComponent : UActorComponent
{
	float PickNewTargetTimer = 0;

	AHazeActor LookAtTarget;

	UHazeSkeletalMeshComponentBase Mesh;

	AHazeActor ForceLookAtActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
	}

	AHazeActor GetTarget(bool bClosest, float Radius)
	{
		if (Mesh == nullptr)
			return nullptr;

		const float RadiusSquared = Radius * Radius;

		const FVector HeadLocation = Mesh.GetSocketLocation(n"Head");

		const float MioDistanceSquared = (Game::Mio.ActorLocation - HeadLocation).SizeSquared();
		const float ZoeDistanceSquared = (Game::Zoe.ActorLocation - HeadLocation).SizeSquared();

		if (Radius > SMALL_NUMBER)
		{
			if (MioDistanceSquared > RadiusSquared)
			{
				if (ZoeDistanceSquared > RadiusSquared)
					return nullptr;
				return Game::Zoe;
			}
			else if (ZoeDistanceSquared > RadiusSquared)
				return Game::Mio;
		}

		if (bClosest)
			return MioDistanceSquared < ZoeDistanceSquared ? Game::Mio : Game::Zoe;
		else
			return LookAtTarget == Game::Mio ? Game::Zoe : Game::Mio;
	}

	bool GetLookAtLocation(bool bClosest,
						   FHazeAcceleratedVector& OutHeadLookAtLoc,
						   FVector& OutEyesLookAtLoc, float DeltaTime,
						   float HeadBlendTime = 4,
						   float Radius = 0,
						   float ClampPitchMin = -15,
						   float ClampPitchMax = 20)
	{
		if (Game::Mio == nullptr)
			return false;

		// if (Radius > 0)
		// {
		// 	const FVector HeadLocation = Mesh.GetSocketLocation(n"Head");
		// 	Debug::DrawDebugSphere(HeadLocation, Radius, 50, Thickness = 50);
		// }

		if (ForceLookAtActor != nullptr)
			LookAtTarget = ForceLookAtActor;
		else
		{
			PickNewTargetTimer -= DeltaTime;
			if (PickNewTargetTimer <= 0)
			{
				AHazeActor NewLookAtTarget = GetTarget(bClosest, Radius);
				PickNewTargetTimer = Math::RandRange(2.0, 10.0);
				if (NewLookAtTarget == nullptr)
				{
					PickNewTargetTimer /= 2;
				}
				else if (LookAtTarget == nullptr)
				{
					OutHeadLookAtLoc.SnapTo(NewLookAtTarget.ActorLocation);
					OutEyesLookAtLoc = NewLookAtTarget.ActorLocation;
				}

				LookAtTarget = NewLookAtTarget;
			}
		}

		if (LookAtTarget == nullptr)
			return false;

		FVector LookAtTargetLoc = LookAtTarget.ActorLocation + FVector(0, 0, 150);
		OutHeadLookAtLoc.AccelerateTo(LookAtTargetLoc, HeadBlendTime, DeltaTime);

		ClampEyeTargetLoc(LookAtTargetLoc, ClampPitchMin, ClampPitchMax);
		OutEyesLookAtLoc = Math::VInterpConstantTo(OutEyesLookAtLoc, LookAtTargetLoc, DeltaTime, 10000);

		return true;
	}

	void ClampEyeTargetLoc(FVector& TargetLocation, float ClampPitchMin = -15, float ClampPitchMax = 20)
	{
		const FTransform EyesTransformGS = FTransform(FVector(700, 0, 600)) * Mesh.GetSocketTransform(n"Head");

		FVector LocalTargetLocation = EyesTransformGS.InverseTransformPositionNoScale(TargetLocation);
		FVector DirectionToTargetLS = LocalTargetLocation.GetSafeNormal();

		auto LookAtRotation = FRotator::MakeFromXZ(DirectionToTargetLS, FVector::UpVector);
		auto PitchAngleDegrees = LookAtRotation.Pitch;

		if (PitchAngleDegrees < ClampPitchMin || PitchAngleDegrees > ClampPitchMax)
		{
			const float Clamp = PitchAngleDegrees < 0 ? ClampPitchMin : ClampPitchMax;
			const auto ClampedNormal = EyesTransformGS.Rotation * FRotator(Clamp, 0, 0).Quaternion();

			TargetLocation = Math::LinePlaneIntersection(
				LookAtTarget.ActorLocation,
				LookAtTarget.ActorLocation - FVector::DownVector,
				EyesTransformGS.Location,
				ClampedNormal.AxisZ);
		}
	}
};