class USkylineRappellerCuttableRopeCapability : UHazeCapability
{
	AHazePlayerCharacter BladeWielder;
	USkylineRappellerRopeCollisionComponent BladeCollision;
	UGravityBladeCombatTargetComponent BladeTarget;
	UCableComponent CableComp;
	UGravityBladeCombatResponseComponent BladeResponse;
	UHazeActorRespawnableComponent RespawnComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeWielder = Game::Mio;
		BladeCollision = USkylineRappellerRopeCollisionComponent::Get(Owner);
		BladeCollision.AddComponentCollisionBlocker(this);
		CableComp = UCableComponent::Get(Owner);
		BladeTarget = UGravityBladeCombatTargetComponent::Get(Owner);
		BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		// If blade hit rope, then we fall to our doom!
		if (HitData.Component == BladeCollision)
			BladeCollision.bIsCut = true;
	}

	UFUNCTION()
	private void OnReset()
	{
		BladeCollision.bIsCut = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BladeCollision.bIsCut)
			return false;
		if (!BladeWielder.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, 500.0))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BladeCollision.bIsCut)
			return true;
		if (!BladeWielder.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, 500.0))
			return true;
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BladeCollision.RemoveComponentCollisionBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BladeCollision.AddComponentCollisionBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Blade collsion capsule should keep level with blade wielder, 
		// so she has something to hit at all times
		FVector BladeLoc = BladeWielder.FocusLocation;
		TArray<FVector> CableLocs;
		CableComp.GetCableParticleLocations(CableLocs);
		FVector BestLoc = CableLocs[0];
		float ClosestDistSqr = BIG_NUMBER;
		for (int i = 1; i < CableLocs.Num(); i++) // Inefficient since rope will almost always be taut, TODO
		{
			FVector Loc;
			float Dummy;
			Math::ProjectPositionOnLineSegment(CableLocs[i-1], CableLocs[i], BladeLoc, Loc, Dummy);
			float DistSqr = BladeLoc.DistSquared(Loc);
			if (DistSqr < ClosestDistSqr)
			{
				BestLoc = Loc;
				ClosestDistSqr = DistSqr;
			}
		}		
		BladeCollision.SetWorldLocation(BestLoc);	
		BladeTarget.SetWorldLocation(BestLoc);			
	}
}
