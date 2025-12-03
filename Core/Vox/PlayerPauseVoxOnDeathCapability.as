

struct FPlayerPauseVoxOnDeathParams
{
	bool bWaitingOnGameOver = false;
}

class UPlayerPauseVoxOnDeathCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Vox");

	UPlayerPauseVoxOnDeathComponent PauseOnDeathComp;
	UPlayerHealthComponent HealthComp;

	bool bWaitingForRespawn = false;
	bool bWaitingOnGameOver = false;

	const float PauseDelayTime = 0.2;
	float PauseDelayTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PauseOnDeathComp = UPlayerPauseVoxOnDeathComponent::GetOrCreate(Player);
		HealthComp = UPlayerHealthComponent::Get(Owner);
		HealthComp.OnReviveTriggered.AddUFunction(this, n"OnPlayerRespawn");
	}

	UFUNCTION()
	void OnPlayerRespawn()
	{
		if (bWaitingForRespawn)
		{
			bWaitingForRespawn = false;
			bWaitingOnGameOver = false;
			PlayerRespawned();
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPlayerPauseVoxOnDeathParams& Params) const
	{
		if (HealthComp.bIsDead)
			return true;

		if (HealthComp.bIsGameOver)
		{
			Params.bWaitingOnGameOver = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!bWaitingForRespawn)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PauseDelayTimer > 0.0)
		{
			PauseDelayTimer -= DeltaTime;
			if (PauseDelayTimer <= 0.0)
			{
				UHazeVoxController::Get().PauseActor(Player, this);
				HandleOnDeathDelegates();
			}
		}

		if (bWaitingOnGameOver)
		{
			if (!HealthComp.bIsGameOver)
			{
				bWaitingForRespawn = false;
				bWaitingOnGameOver = false;
				PlayerRespawned();
			}
		}

		TEMPORAL_LOG(this)
			.Value("IsDead", HealthComp.bIsDead)
			.Value("IsRespawning", HealthComp.bIsRespawning)
			.Value("PauseDelayTimer", PauseDelayTimer)
			.Value("NumRespawnDeleages", PauseOnDeathComp.RespawnDelegates.Num())
			.Value("NumDeathDelegates", PauseOnDeathComp.DeathDelegates.Num())
			.Value("WaitingForRespawn", bWaitingForRespawn)
			.Value("WaitingOnGameOver", bWaitingOnGameOver);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPlayerPauseVoxOnDeathParams Params)
	{
		bWaitingOnGameOver = Params.bWaitingOnGameOver;
		bWaitingForRespawn = true;
		PauseDelayTimer = PauseDelayTime;
	}

	private void PlayerRespawned()
	{
		TEMPORAL_LOG(this).Event("PlayerRespawned");

		UHazeVoxController::Get().ResumeActor(Player, this);

		// Move delegates to new list since list might be modified during callbacks
		TArray<FOnVoxPlayerPauseOnDeadRespawn> RespawnDelegates = PauseOnDeathComp.RespawnDelegates;
		PauseOnDeathComp.RespawnDelegates.Reset();

		for (auto Delegate : RespawnDelegates)
		{
			Delegate.ExecuteIfBound(Player);
		}
	}

	private void HandleOnDeathDelegates()
	{
		TEMPORAL_LOG(this).Event("HandleOnDeathDelegates");

		for (int i = PauseOnDeathComp.DeathDelegates.Num() - 1; i >= 0; --i)
		{
			if (!PauseOnDeathComp.DeathDelegates[i].IsBound())
			{
				PauseOnDeathComp.DeathDelegates.RemoveAtSwap(i);
			}
		}

		for (auto Delegate : PauseOnDeathComp.DeathDelegates)
		{
			Delegate.ExecuteIfBound(Player);
		}
	}
}
