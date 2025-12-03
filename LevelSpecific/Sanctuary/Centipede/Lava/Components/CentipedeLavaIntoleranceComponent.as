
struct FCentipedeLavaDamageOverTime
{
	TSubclassOf<AHazeActor> SourceDamager;
	float DamagePerSecond = 0.0;
	float DamageDuration = 0.0;
	float DamageTimer = 0.0;
	bool bTriggerForceFeedback = false;
	TArray<int> SegmentIndexes;
	bool bDeathEvenIfInfiniteHealth = false;
}

event void CentipedeBurnAdded();

class UCentipedeLavaIntoleranceComponent : UActorComponent
{
	access ReadOnly = private, * (readonly);
	access:ReadOnly UHazeCrumbSyncedFloatComponent Health;

	access DeathAccess = private, * (readonly), UCentipedeBurningDeathCapability;
	access:DeathAccess bool bForceDeathMio = false;
	access:DeathAccess bool bForceDeathZoe = false;
	
	TArray<FCentipedeLavaDamageOverTime> Burns;

	UPROPERTY(Category = "Health Regen")
	float DurationBeforeHealthRegenStarts = 0.0;
	float HealthRegenStartsTimer = 0.0;

	UPROPERTY(Category = "Health Regen")
	float HealthRegenPerSecond = 0.25;

	FHazeAcceleratedFloat VignetteAlpha;
	UPROPERTY(BlueprintReadOnly)
	float BurningAlpha = 0.0;
	ACentipede Centipede;

	bool bIsRespawning = false;

	CentipedeBurnAdded OnCentipedeBurnAdded;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Health = UHazeCrumbSyncedFloatComponent::Create(Owner, n"SyncedHealth");
		Health.SetValue(1.0);
		Centipede = Cast<ACentipede>(Owner);
	}

	void AddDamageSource(const FCentipedeLavaDamageOverTime& Burn)
	{
		if (bIsRespawning)
			return;
		HealthRegenStartsTimer = 0.0;
		Burns.Add(Burn);
		OnCentipedeBurnAdded.Broadcast();
	}

	UFUNCTION(NetFunction)
	void NetSetForceDeath(bool bMio)
	{
		if (bMio)
			bForceDeathMio = true;
		else
			bForceDeathZoe = true;
	}

	void SetHealth(float NewValue, bool bSnapRemote = false)
	{
		Health.SetValue(NewValue);
		if (bSnapRemote)
			Health.SnapRemote();
	}

	bool IsDying()
	{
		if (bForceDeathMio || bForceDeathZoe)
			return true;
		return Health.Value < KINDA_SMALL_NUMBER;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(Owner, "Lava Intolerance").Value("Health", Health.Value);
		TEMPORAL_LOG(Owner, "Lava Intolerance").Value("Num Burns: ", Burns.Num());
		for (int iBurn = 0; iBurn < Burns.Num(); ++iBurn) 
		{
			auto& Burn = Burns[iBurn];
			FString BurnCategory = "Burn " + iBurn;
			TEMPORAL_LOG(Owner, "Lava Intolerance").Value(BurnCategory + " dps", Burn.DamagePerSecond);
			TEMPORAL_LOG(Owner, "Lava Intolerance").Value(BurnCategory + " dur", Burn.DamageDuration);
			TEMPORAL_LOG(Owner, "Lava Intolerance").Value(BurnCategory + " timer", Burn.DamageTimer);
			TEMPORAL_LOG(Owner, "Lava Intolerance").Value(BurnCategory + " ff", Burn.bTriggerForceFeedback);
			for (int iIdx = 0; iIdx < Burn.SegmentIndexes.Num(); ++iIdx) 
				TEMPORAL_LOG(Owner, "Lava Intolerance").Value(BurnCategory + " segment index " + iIdx, Burn.SegmentIndexes[iIdx]);
		}
	}	
#endif

	bool DeathEvenIfInfiniteHealth() const
	{
		if (bForceDeathMio || bForceDeathZoe)
			return true;
		for (int iBurn = 0; iBurn < Burns.Num(); ++iBurn) 
		{
			if (Burns[iBurn].bDeathEvenIfInfiniteHealth)
				return true;
		}
		return false;
	}
};