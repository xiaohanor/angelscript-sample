struct FSummitCritterSwarmBatch
{
	TArray<USummitSwarmingCritterComponent> Critters;
}

class USummitSwarmingCritterComponent : UHazeSkeletalMeshComponentBase
{
	UHazeCapsuleCollisionComponent CapsuleComp;
	UHazeSkeletalMeshComponentBase Template;
	USummitCritterSwarmSettings Settings;

	FVector CritterLocation;
	FVector CritterVelocity;
	FVector Offset;

	FHazeAcceleratedRotator AccRot;
	FHazeAcceleratedFloat AccRepulsion;

	float WoundDuration = 0.0;
	FVector WoundOffset = FVector::ZeroVector;

	USceneComponent ExternalTarget;
	FVector ExternalTargetOffset;
	float ExternalTargetAcceleration;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = USummitCritterSwarmSettings::GetSettings(Cast<AHazeActor>(Owner));
		AHazeCharacter CharOwner = Cast<AHazeCharacter>(Owner);
		CapsuleComp = CharOwner.CapsuleComponent;
		Template = CharOwner.Mesh;
	}

	void Setup()
	{
		SetSkeletalMeshAsset(Template.SkeletalMeshAsset);
		for (int iMaterial = 0; iMaterial < Template.Materials.Num(); iMaterial++)
		{
			SetMaterial(iMaterial, Template.Materials[iMaterial]);
		}
		SetRelativeScale3D(Template.RelativeScale3D);
		OnRespawn();
		DetachFromParent(true);
	}

	void OnRespawn()
	{
		// Spawn tight, then disperse
		Offset = Math::GetRandomPointInSphere() * Math::RandRange(0.0, CapsuleComp.CapsuleRadius) * 0.5;
		CritterLocation = Owner.ActorTransform.TransformPosition(Offset * 0.2);
		AccRepulsion.SnapTo(0.0);
		ClearExternalTarget();
	}

	void SetExternalTarget(USceneComponent Target, FVector TargetOffset, float Acceleration)
	{
		ExternalTarget = Target;
		ExternalTargetOffset = TargetOffset;
		ExternalTargetAcceleration = Acceleration;
	}

	void ClearExternalTarget()
	{
		ExternalTarget = nullptr;	
		DetachFromParent(true); // In case we've attached to a target
	}

	bool ShouldGrabExternalTarget() const
	{
		if (ExternalTarget == nullptr)
			return false;
		if (WorldLocation.IsWithinDist(GetExternalTargetLocation(), ExternalTargetAcceleration * 0.2))
			return true;
		return false;
	}

	FVector GetExternalTargetLocation() const
	{
		return ExternalTarget.WorldLocation + ExternalTargetOffset;
	}

	void GrabExternalTarget(float DeltaTime)
	{
		if (ExternalTarget == nullptr)
			return;
		FVector ExternalTargetLoc = GetExternalTargetLocation();
		if (AttachParent != ExternalTarget)
			AttachTo(ExternalTarget, NAME_None, EAttachLocation::KeepWorldPosition);

		FHazeAcceleratedVector AccLoc;
		AccLoc.SnapTo(WorldLocation, CritterVelocity);
		AccLoc.AccelerateTo(ExternalTargetLoc, 1.0, DeltaTime);
		CritterLocation = AccLoc.Value;
		CritterVelocity = AccLoc.Velocity;

		// Land with world down towards target
		AccRot.AccelerateTo(FRotator::MakeFromZX(ExternalTargetOffset, WorldRotation.ForwardVector), 0.7, DeltaTime);

		SetWorldLocationAndRotation(CritterLocation, AccRot.Value);
	}

	void UpdateFlocking(float DeltaTime, const TMap<FIntVector, FSummitCritterSwarmBatch>& Swarm, float SlotFactor, FVector DamageOffset)
	{
		FVector OwnLoc = WorldLocation;

		// Find nearby critters
		TArray<USummitSwarmingCritterComponent> NearbyCritters;
		FIntVector Hash = GetLocationHash(SlotFactor);
		for (int i = 0; i < 27; i++)
		{
			FSummitCritterSwarmBatch Batch;
			FIntVector Key = Hash + FIntVector((i % 3) - 1, (Math::IntegerDivisionTrunc(i, 3) % 3) - 1, Math::IntegerDivisionTrunc(i, 9) -1);
			Swarm.Find(Key, Batch);
			NearbyCritters.Append(Batch.Critters);
		}
		NearbyCritters.Remove(this);

		// Accelerate towards owner predicted location
		FVector OwnerAcceleration = FVector::ZeroVector;
		if (ExternalTarget == nullptr)
		{
			OwnerAcceleration = ((Owner.ActorLocation + Owner.ActorVelocity * 1.0) + Offset - OwnLoc) * Settings.FlockingOwnerAccelerationFactor * 0.001;
			if (OwnerAcceleration.Size() > Settings.FlockingOwnerAccelerationFactor)
				OwnerAcceleration = OwnerAcceleration.GetClampedToMaxSize(Settings.FlockingOwnerAccelerationFactor);
		}

		// Accelerate away from others nearby 
		FVector Repulsion = FVector::ZeroVector;
		float RepulsionFactor = AccRepulsion.AccelerateTo(Settings.FlockingRepulsionFactor, 5.0, DeltaTime);
		for (auto Critter : NearbyCritters)
		{
			float Range = Settings.FlockingRepulseRange;
			if (Critter.ShouldGrabExternalTarget())
				Range *= 0.1;
			if (Critter.WorldLocation.IsWithinDist(OwnLoc, Range))
			{
				FVector Away = (OwnLoc - Critter.WorldLocation);
				if (Away.IsNearlyZero(1.0))
					Away = Math::GetRandomPointInSphere();
				float AwayDist = Away.Size();
				float RepulseForce = ((Settings.FlockingRepulseRange - AwayDist) / Settings.FlockingRepulseRange) * RepulsionFactor;
				Repulsion += (Away / AwayDist) * RepulseForce;
			}
		}

		// Accelerate towards center of critters nearby in front of us
		FVector Forward = AccRot.Value.Vector();
		FVector Attraction = FVector::ZeroVector;
		if (ExternalTarget == nullptr)
		{
			int NumAttractors = 0;
			for (auto Critter : NearbyCritters)
			{
				FVector ToCritter = (Critter.WorldLocation - WorldLocation).GetSafeNormal();
				if (Forward.DotProduct(ToCritter) > 0.95)
				{
					NumAttractors++;
					Attraction += ToCritter;
				}
			}
			if (NumAttractors > 0)
			{
				Attraction /= float(NumAttractors);
				Attraction *= Settings.FlockingAttractionFactor;
			}
		}

		FVector PlayerRepulsion = FVector::ZeroVector;
		if ((Settings.FlockingPlayerRepulseRange > 0.0) && (Settings.FlockingPlayerRepulseFactor > 0.0))
		{
			// Accelerate orthogonally away from players trajectory
			for (AHazePlayerCharacter Player : Game::Players)
			{
				FVector PlayerLoc = Player.ActorLocation;
				FVector PredictedLoc = PlayerLoc + Player.ActorForwardVector * 5000.0;
				if (PredictedLoc.IsWithinDist(OwnLoc, Settings.FlockingPlayerRepulseRange))
				{
					FVector PlayerTrajectoryLoc = PlayerLoc.PointPlaneProject(OwnLoc, Player.ActorForwardVector);
					FVector Away = (OwnLoc - PlayerTrajectoryLoc);
					if (Away.IsNearlyZero(1.0))
						Away = Math::GetRandomPointInSphere();
					float PlayerDist = PredictedLoc.Distance(OwnLoc);
					float RepulseForce = (Settings.FlockingPlayerRepulseRange - PlayerDist) * Settings.FlockingPlayerRepulseFactor;
					PlayerRepulsion += (Away / PlayerDist) * RepulseForce;
				}
			}
		}

		FVector DamageRepulsion = FVector::ZeroVector;
		if (!DamageOffset.IsZero() && (Settings.FlockingDamageRepulseRange > 0.0) && (Settings.FlockingDamageRepulseFactor > 0.0))
		{
			// Accelerate away from any wounds
			FVector DamageLoc = Owner.ActorLocation + DamageOffset;
			if (DamageLoc.IsWithinDist(OwnLoc, Settings.FlockingDamageRepulseRange))
			{
				FVector Away = (OwnLoc - DamageLoc);
				if (Away.IsNearlyZero(1.0))
					Away = Math::GetRandomPointInSphere();
				float AwayDist = Away.Size();
				float RepulseForce = (Settings.FlockingDamageRepulseRange - AwayDist) * Settings.FlockingDamageRepulseFactor;
				DamageRepulsion += (Away / AwayDist) * RepulseForce;
			}
		}

		FVector ExternalTargetAcc = FVector::ZeroVector;
		if (ExternalTarget != nullptr)
		{
			FVector ToTarget = (GetExternalTargetLocation() - OwnLoc);
			ExternalTargetAcc = ToTarget.GetSafeNormal() * ExternalTargetAcceleration;
		}

		CritterVelocity += (OwnerAcceleration + Repulsion + Attraction + PlayerRepulsion + DamageRepulsion + ExternalTargetAcc) * DeltaTime;
		CritterVelocity -= CritterVelocity * 0.2;
		CritterLocation += CritterVelocity * DeltaTime; 

		SetWorldLocation(CritterLocation);

		AccRot.AccelerateTo(CritterVelocity.Rotation(), 5.0, DeltaTime);
		SetWorldRotation(AccRot.Value);
	}

	FIntVector GetLocationHash(float SlotFactor) const
	{
		FIntVector Hash;
		FVector HashLoc = WorldLocation - Owner.ActorLocation; 
		Hash.X = Math::TruncToInt(HashLoc.X * SlotFactor);
		Hash.Y = Math::TruncToInt(HashLoc.Y * SlotFactor);
		Hash.Z = Math::TruncToInt(HashLoc.Z * SlotFactor);
		return Hash;
	}
}

