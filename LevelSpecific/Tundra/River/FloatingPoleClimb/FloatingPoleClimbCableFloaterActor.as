class ATundraFloatingPoleClimbCableFloaterActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	USphereComponent Collision;
	default Collision.SphereRadius = 75.0;

	UPROPERTY(DefaultComponent, Attach=Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbSyncedActorPos;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	FVector Velocity;
	ATundraIceSwimmingVolume SwimmingVolume;
	float SurfaceHeight;
	USimpleMovementData Movement;

	const float AirFriction = 1.0;
	const float WaterFriction = 1.4;
	const float GravityAcceleration = 2000.0;
	const float BuoyancyMaxAcceleration = 4000.0;
	const float CablePullForceMultiplier = 1000.0;

	float RandomTimeOffset;
	ATundraFloatingPoleClimbActor AttachedFloatingPole;
	bool bAttached = false;
	float TimeOfAttach;
	UHazeCharacterSkeletalMeshComponent OtterMesh;
	FVector RelativeStartLocation;

	const float LerpToPlayerDuration = 0.3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CrumbSetRandomTimeOffset(Math::RandRange(0.0, 10.0));
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetRandomTimeOffset(float TimeOffset)
	{
		RandomTimeOffset = TimeOffset;
	}

	void Attach(UHazeCharacterSkeletalMeshComponent In_OtterMesh)
	{
		OtterMesh = In_OtterMesh;
		AttachToComponent(OtterMesh, NAME_None, EAttachmentRule::KeepWorld);
		RelativeStartLocation = ActorRelativeLocation;
		bAttached = true;
		TimeOfAttach = Time::GetGameTimeSeconds();
	}

	void Detach()
	{
		DetachFromActor();
		Velocity = Game::Mio.ActorVelocity;
		SetActorTickEnabled(true);
		bAttached = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bAttached)
		{
			float Alpha = Time::GetGameTimeSince(TimeOfAttach) / LerpToPlayerDuration;
			Alpha = Math::Saturate(Alpha);
			if(Alpha == 1.0)
			{
				SetActorTickEnabled(false);
			}
			Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
			ActorRelativeLocation = Math::Lerp(RelativeStartLocation, FVector::ZeroVector, Alpha);
			return;
		}

		if(SwimmingVolume == nullptr)
			OverlapCheckForTundraSwimmingVolumes();

		if(!MoveComp.PrepareMove(Movement))
			return;

		if(HasControl())
		{
			HandleCablePullForce(DeltaTime);
			ApplyFriction(DeltaTime);
			HandleGravity(DeltaTime);
			HandleBuoyancy(DeltaTime);
			HandleMeshBobbing();
			Movement.AddVelocity(Velocity);
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(Movement);
	}

	void HandleCablePullForce(float DeltaTime)
	{
		FVector Vector = (AttachedFloatingPole.Collision.WorldLocation - ActorLocation);
		float Size = Vector.Size();

		float Alpha = Math::NormalizeToRange(Size, AttachedFloatingPole.Cable.CableLength, AttachedFloatingPole.CableMaxLengthUntilReleasing);
		Alpha = Math::Saturate(Alpha);

		Vector = Vector.GetSafeNormal() * Alpha * CablePullForceMultiplier;
		Vector.Z = 0.0;
		Velocity += Vector * DeltaTime;
	}

	void ApplyFriction(float DeltaTime)
	{
		float CurrentFriction = Math::Lerp(AirFriction, WaterFriction, CurrentSubmergedAlpha);
		FVector FrictionDeltaVelocity = GetFrameRateIndependentDrag(CurrentFriction, DeltaTime);
		Velocity += FrictionDeltaVelocity;
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	void HandleGravity(float DeltaTime)
	{
		Velocity += FVector::DownVector * (GravityAcceleration * DeltaTime);
	}

	void HandleBuoyancy(float DeltaTime)
	{
		Velocity += FVector::UpVector * (CurrentSubmergedAlpha * BuoyancyMaxAcceleration * DeltaTime);
	}

	float GetCurrentSubmergedAlpha() property
	{
		float Alpha = 0.0;

		if(SwimmingVolume != nullptr)
		{
			float CollisionHeightExtent = (GetActorLocalBoundingBox(false).Extent * ActorRelativeScale3D).Z;
			float CurrentHeight = Mesh.WorldLocation.Z;
			Alpha = Math::NormalizeToRange(CurrentHeight, SurfaceHeight - CollisionHeightExtent, SurfaceHeight + CollisionHeightExtent);
			Alpha = 1.0 - Alpha;
			Alpha = Math::Clamp(Alpha, 0.0, 1.0);
		}

		return Alpha;
	}

	void OverlapCheckForTundraSwimmingVolumes()
	{
		FHazeTraceSettings Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.UseComponentShape(Mesh);
		FOverlapResultArray Overlaps = Trace.QueryOverlaps(Mesh.WorldLocation);

		TArray<FOverlapResult> OverlapArray = Overlaps.GetOverlapHits();
		for(FOverlapResult Overlap : OverlapArray)
		{
			auto Current = Cast<ATundraIceSwimmingVolume>(Overlap.Actor);
			if(Current == nullptr)
				continue;

			SwimmingVolume = Current;
			FVector Point;
			SwimmingVolume.BrushComponent.GetClosestPointOnCollision(Mesh.WorldLocation + FVector::UpVector * 1000.0, Point);
			SurfaceHeight = Point.Z;
			return;
		}
	}

	void HandleMeshBobbing()
	{
		float Time = Time::GameTimeSeconds + RandomTimeOffset;

		FRotator VehicleRotation;
		VehicleRotation.Roll = Math::Sin(Time * 1.17) * 2.0;
		VehicleRotation.Pitch = Math::Sin(Time * 1.5) * 2.0;

		FVector VehicleLocation;
		VehicleLocation.Z += Math::Sin(Time * 3.15) * 5.0;
		Mesh.SetRelativeLocationAndRotation(VehicleLocation, VehicleRotation);
	}
}