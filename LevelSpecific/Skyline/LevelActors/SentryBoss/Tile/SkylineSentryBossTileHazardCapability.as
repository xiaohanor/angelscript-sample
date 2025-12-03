class USkylineSentryBossHazardTileHazardCapability : UHazeCapability
{

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineSentryBossTile Tile;

	float TimeToHazard;

	bool bIsChargingUp;
	bool bIsFullyCharged;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Tile = Cast<ASkylineSentryBossTile>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		if(Tile.bIsHazardActivated)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Tile.bIsHazardActivated)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

		TimeToHazard = Time::GameTimeSeconds + Tile.Boss.TileManager.HazardTelegraphTime;
		Tile.MeshComp.SetMaterial(0, Tile.ChargeUpMaterial);
		bIsChargingUp = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Tile.MeshComp.SetMaterial(0, Tile.NormalMaterial);

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		if(bIsChargingUp)
		{

			if(TimeToHazard > Time::GameTimeSeconds)
				return;

			bIsChargingUp = false;

		}
		
		Niagara::SpawnOneShotNiagaraSystemAtLocation(Tile.HazardNiagaraSystem,Tile.SpawnPoint.WorldLocation, Tile.ActorRotation);

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseSphereShape(Tile.HazardZone);
		TraceSettings.IgnoreActor(Tile);

		FHitResultArray HitArray = TraceSettings.QueryTraceMulti(Tile.HazardZone.WorldLocation, Tile.HazardZone.WorldLocation + Tile.ActorForwardVector);

		for(FHitResult Hit : HitArray)
		{
			if(Hit.bBlockingHit)
			{
				if(Hit.Actor == Game::Mio)
					Print("Hit Mio");
			}
		}
		
		Tile.bIsHazardActivated = false;
	}

}