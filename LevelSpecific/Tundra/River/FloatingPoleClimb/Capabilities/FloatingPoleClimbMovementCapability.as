class UTundraFloatingPoleClimbMovementCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraFloatingPoleClimbMovementComponent MoveComp;
	USweepingMovementData Movement;
	ATundraFloatingPoleClimbActor FloatingPole;

	ATundraIceSwimmingVolume SwimmingVolume;
	float SurfaceHeight;
	float RandomTimeOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{	
		FloatingPole = Cast<ATundraFloatingPoleClimbActor>(Owner);
		MoveComp = UTundraFloatingPoleClimbMovementComponent::Get(FloatingPole);
		Movement = MoveComp.SetupSweepingMovementData();
		CrumbSetRandomTimeOffset(Math::RandRange(0.0, 10.0));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				// If floating pole was placed in air, it wont have found a swimming volume until it falls down into it.
				if(SwimmingVolume == nullptr)
					OverlapCheckForTundraSwimmingVolumes();

				HandleControlMovement(DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}

		HandleMeshBobbing();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetRandomTimeOffset(float TimeOffset)
	{
		RandomTimeOffset = TimeOffset;
	}

	void HandleMeshBobbing()
	{
		float Time = ActiveDuration + RandomTimeOffset;

		FRotator Rotation;
		Rotation.Roll = Math::Sin(Time * 1.17) * 2.0;
		Rotation.Pitch = Math::Sin(Time * 1.5) * 2.0;

		FVector VehicleLocation;
		VehicleLocation.Z += Math::Sin(Time * 3.15) * 5.0;
		FloatingPole.Mesh.SetRelativeLocationAndRotation(VehicleLocation, Rotation);
	}

	void HandleControlMovement(float DeltaTime)
	{
		// How forces are applied
		//
		//
		//
		//				 ║🧍  Additional player gravity
		//				 ║ 	  	   		↓
		//      ↑		 ║
		//	Buoyancy	 ║	 	(Air friction)
		// ~~~~~~~~~~~~~┌╨┐~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		//   Gravity	└┬┘  	(Water friction)
		//		↓		 |
		//				 | Cable pull force
		//				 🐟  	 ↓
		
		Movement.AddOwnerVelocity();
		ApplyFriction(DeltaTime);

		// These should cancel each other out when about half 
		HandleGravity();
		HandleBuoyancy();

		HandleCablePullForce();
		HandleRotation(DeltaTime);
	}

	void ApplyFriction(float DeltaTime)
	{
		float CurrentFriction = Math::Lerp(FloatingPole.AirFriction, FloatingPole.WaterFriction, CurrentSubmergedAlpha);
		FVector FrictionDeltaVelocity = GetFrameRateIndependentDrag(MoveComp.Velocity, CurrentFriction, DeltaTime);
		Movement.AddVelocity(FrictionDeltaVelocity);
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	void HandleGravity()
	{
		float Gravity = FloatingPole.BaseGravityAcceleration;
		for(auto Player : Game::Players)
		{
			auto PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
			if(PoleClimbComp == nullptr)
				continue;

			if(PoleClimbComp.Data.ActivePole != FloatingPole.PoleActor)
				continue;

			Gravity += FloatingPole.PolePlayerAdditionalGravityAcceleration;
		}

		Movement.AddAcceleration(FVector::DownVector * Gravity);
	}

	void HandleBuoyancy()
	{
		Movement.AddAcceleration(FVector::UpVector * (CurrentSubmergedAlpha * FloatingPole.BuoyancyMaxAcceleration));
	}

	void HandleCablePullForce()
	{
		if(FloatingPole.CablePlayer == nullptr && FloatingPole.OptionalCableFloater == nullptr)
			return;

		AHazeActor TargetActor = FloatingPole.CablePlayer;
		if(TargetActor == nullptr)
			TargetActor = FloatingPole.OptionalCableFloater;

		FVector Vector = (TargetActor.ActorLocation - FloatingPole.Collision.WorldLocation);
		float Size = Vector.Size();

		if(Size < FloatingPole.Cable.CableLength)
			return;

		Size -= FloatingPole.Cable.CableLength;

		Size = Math::Min(Size, FloatingPole.MaxCableAdditionalLength);
		Vector = Vector.GetSafeNormal() * Size;
		Movement.AddAcceleration(Vector * FloatingPole.CablePullForceMultiplier);
	}

	void HandleRotation(float DeltaTime)
	{
		FQuat FinalRotation;
		for(AHazePlayerCharacter Player : FloatingPole.ClimbingPlayers)
		{
			auto PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
			if(PoleClimbComp == nullptr)
				continue;

			float HeightAlpha = PoleClimbComp.Data.CurrentHeight / FloatingPole.PoleActor.Height;
			FinalRotation *= Math::RotatorFromAxisAndAngle(Player.ActorRightVector, -FloatingPole.PolePlayerMaxRotationAngle * HeightAlpha).Quaternion();
		}

		FloatingPole.AcceleratedQuat.SpringTo(FinalRotation, FloatingPole.SwaySpringStiffness, FloatingPole.SwaySpringDamping, DeltaTime);
		Movement.SetRotation(FloatingPole.AcceleratedQuat.Value);
	}

	void OverlapCheckForTundraSwimmingVolumes()
	{
		FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(FloatingPole.Collision);
		Trace.TraceWithProfile(n"PlayerCharacter");
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(FloatingPole.Collision.WorldLocation);

		TArray<FOverlapResult> OverlapArray = Overlaps.GetOverlapHits();
		for(FOverlapResult Overlap : OverlapArray)
		{
			auto Current = Cast<ATundraIceSwimmingVolume>(Overlap.Actor);
			if(Current == nullptr)
				continue;

			SwimmingVolume = Current;
			FVector Point;
			SwimmingVolume.BrushComponent.GetClosestPointOnCollision(FloatingPole.Collision.WorldLocation + FVector::UpVector * 1000.0, Point);
			SurfaceHeight = Point.Z;
			return;
		}
	}

	float GetCurrentSubmergedAlpha() property
	{
		float Alpha = 0.0;

		if(SwimmingVolume != nullptr)
		{
			float CollisionHeightExtent = FloatingPole.Collision.SphereRadius;
			float CurrentHeight = FloatingPole.Collision.WorldLocation.Z;
			Alpha = Math::NormalizeToRange(CurrentHeight, SurfaceHeight - CollisionHeightExtent, SurfaceHeight + CollisionHeightExtent);
			Alpha = 1.0 - Alpha;
			Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		}

		return Alpha;
	}
}