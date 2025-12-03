class USummitCritterSwarmFlockingCapability : UHazeCapability
{
	USummitCritterSwarmComponent SwarmComp;
	USummitCritterSwarmSettings Settings;
	UHazeCapsuleCollisionComponent CapsuleComp;
	USummitCritterSwarmAcidHittableComponent AcidHittableComp;
	float DamageTime;
	FVector DamageOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmComp = USummitCritterSwarmComponent::GetOrCreate(Owner);
		Settings = USummitCritterSwarmSettings::GetSettings(Owner);
		AHazeCharacter CharOwner = Cast<AHazeCharacter>(Owner);
		CapsuleComp = CharOwner.CapsuleComponent;
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
		AcidHittableComp = USummitCritterSwarmAcidHittableComponent::GetOrCreate(Owner);
		UAcidResponseComponent AcidResponseComp = UAcidResponseComponent::GetOrCreate(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		SwarmComp.BoundsRadius = CharOwner.CapsuleComponent.ScaledCapsuleRadius;
		CharOwner.Mesh.AddComponentVisualsBlocker(this);
		for (int iCritter = 0; iCritter < Settings.NumCritters; iCritter++)
		{
			USummitSwarmingCritterComponent Critter = USummitSwarmingCritterComponent::Create(Owner);
			Critter.Setup();
			SwarmComp.Critters.Add(Critter);
		}
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		DamageTime = Time::GameTimeSeconds;
		if (Hit.ImpactLocation.IsZero())
		{
			// No impact info, assume we hit where line from attacker to far ahead in view intersects bounds, with some random penetration
			FVector AttackLoc = Hit.PlayerInstigator.ActorCenterLocation;
			AHazePlayerCharacter PlayerAttacker = Cast<AHazePlayerCharacter>(Hit.PlayerInstigator);
			FVector ViewDir = PlayerAttacker.ViewRotation.Vector();
			FVector ViewDest = PlayerAttacker.ViewLocation + ViewDir * 10000.0;
			FVector ImpactLoc = Math::LinePlaneIntersection(AttackLoc, ViewDest, Owner.ActorCenterLocation, ViewDir);
			//ImpactLoc += ViewDir * SwarmComp.BoundsRadius * Math::RandRange(-1.0, -0.5); 
			DamageOffset = ImpactLoc - Owner.ActorLocation;;
		}
		else
		{
			// We have proper impact info
			DamageOffset = Hit.ImpactLocation - Owner.ActorLocation;
		}
	}

	UFUNCTION()
	private void OnRespawn()
	{
		for (USummitSwarmingCritterComponent Critter : SwarmComp.Critters)
		{
			Critter.OnRespawn();
		}
		for (USummitSwarmingCritterComponent Critter : SwarmComp.UnspawnedCritters)
		{
			Critter.OnRespawn();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Always active
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GetGameTimeSince(DamageTime) > Settings.FlockingDamageRepulseDuration)
			DamageOffset = FVector::ZeroVector;

		// Hash critters on location for better performance
		float SlotFactor = 1.0 / Settings.FlockingRepulseRange;
		TMap<FIntVector, FSummitCritterSwarmBatch> Swarm;
		for (USummitSwarmingCritterComponent Critter : SwarmComp.Critters)
		{
			FIntVector Hash = Critter.GetLocationHash(SlotFactor);
			FSummitCritterSwarmBatch& Batch = Swarm.FindOrAdd(Hash);
			Batch.Critters.Add(Critter);
		}
		for (USummitSwarmingCritterComponent Critter : SwarmComp.Critters)
		{
			if (Critter.ShouldGrabExternalTarget())
				Critter.GrabExternalTarget(DeltaTime);
			else
				Critter.UpdateFlocking(DeltaTime, Swarm, SlotFactor, DamageOffset);
		}

		AdjustAcidHittableBounds(Swarm);
	}

	void AdjustAcidHittableBounds(TMap<FIntVector, FSummitCritterSwarmBatch> Swarm)
	{
		// Ignore all single critter batches, assuming they're outliers.
		TArray<USummitSwarmingCritterComponent> Critters;
		for (auto Batch : Swarm)
		{
			if (Batch.Value.Critters.Num() > 1)
				Critters.Append(Batch.Value.Critters);
		}  

		// Adjust acid hittable comp to encapsulate most critters
		if (Critters.Num() == 0)
		{
			AcidHittableComp.SphereRadius = 0.0;
			return;
		}

		FVector OwnLoc = Owner.ActorLocation;	
		FVector Offset = FVector::ZeroVector;
		for (USummitSwarmingCritterComponent Critter : Critters)
		{
			Offset += (Critter.WorldLocation - OwnLoc);
		}
		FVector Center = OwnLoc + (Offset / float(Critters.Num()));
		float HighestDistSqr = 0.0;
		for (USummitSwarmingCritterComponent Critter : Critters)
		{
			float DistSqr = Critter.WorldLocation.DistSquared(Center);
			if (DistSqr > HighestDistSqr)
				HighestDistSqr = DistSqr;
		}
		AcidHittableComp.WorldLocation = Center;
		AcidHittableComp.SphereRadius = Math::Sqrt(HighestDistSqr);
	}
}

