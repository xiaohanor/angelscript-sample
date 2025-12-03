class UTundraBossFurBallUnlimitedCapability : UTundraBossChildCapability
{
	bool bShouldTickSpawnTimer = false;
	float PreSpawnTimer = 0;
	float PreSpawnTimerDuration = 1.5;
	float SpawnTimer = 0;
	float SpawnTimerDuration = 6;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::FurballUnlimited)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::FurballUnlimited)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(bShouldTickSpawnTimer)
		{
			SpawnTimer += DeltaTime;
			if(SpawnTimer >= SpawnTimerDuration)
			{
				bShouldTickSpawnTimer = false;
			}
			else
			{
				return;
			}
		}

		if(Boss.CrackingIce.bIceHasExploded)
			return;
		
		if(Boss.MioIceChunk.bIceChunkHidden && Boss.ZoeIceChunk.bIceChunkHidden && !Boss.bStopFurballFromSpawning)
		{
			PreSpawnTimer += DeltaTime;
			if(PreSpawnTimer < PreSpawnTimerDuration)
				return;

			Boss.StartProgressAfterFirstFurballTimer(SpawnTimerDuration);
			CrumbPlayFurBallAnimation();
			bShouldTickSpawnTimer = true;
			PreSpawnTimer = 0;
			SpawnTimer = 0;
		}
	}

	//The FurBalls are spawned from an AnimNotify
	UFUNCTION(CrumbFunction)
	void CrumbPlayFurBallAnimation()
	{
		Boss.RequestAnimation(ETundraBossAttackAnim::FurBall);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bShouldTickSpawnTimer = false;
		SpawnTimer = 0;
		Boss.OnAttackEventHandler(-1);
		Boss.bStopFurballFromSpawning = false;

		//Don't delay the spawn the first time we spawn furballs.
		PreSpawnTimer = PreSpawnTimerDuration;

		if(!HasControl())
			return;		
	}
};