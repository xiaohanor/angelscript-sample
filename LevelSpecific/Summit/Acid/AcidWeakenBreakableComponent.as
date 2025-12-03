
event void FOnWeakenedByAcid();
event void FOnAcidWeakenRestored();
event void FOnWeakenPercentageChanged(float NewWeakenPct);
event void FOnBrokenByTail(FOnBrokenByTailParams Params);

struct FOnBrokenByTailParams
{
	UPROPERTY()
	FVector BreakLocation;
	UPROPERTY()
	FVector BreakDirection;
};

class UAcidTailBreakableComponent : UActorComponent
{
	// How many hits of acid does it take for the object to weaken enough to be breakable
	UPROPERTY(EditAnywhere, Category = "Acid Weaken Breakable")
	int AcidHitsNeededToWeaken = 10;

	// How many tail hits does it take for the object to break once weakened
	UPROPERTY(EditAnywhere, Category = "Acid Weaken Breakable")
	int TailHitsNeededToBreak = 3;

	// How long until the object restores after being weakened after the last time it is hit by acid
	UPROPERTY(EditAnywhere, Category = "Acid Weaken Breakable")
	float TimeUntilRestore = 4.0;

	// How long does it take for the restore to fully restore the object down to 0 weakening
	UPROPERTY(EditAnywhere, Category = "Acid Weaken Breakable")
	float RestoreDuration = 1.0;

	// Whether to use a weaken duration that happens after the threshold is reached
	UPROPERTY(EditAnywhere, Category = "Acid Weaken Breakable")
	bool bUseWeakenDuration = true;

	// How long it takes after the needed hits for the object to fully weaken
	UPROPERTY(EditAnywhere, Category = "Acid Weaken Breakable", Meta = (EditCondition = "bUseWeakenDuration", EditConditionHides))
	float WeakenDuration = 1.0;
	
	// What weaken pct we reach before the weaken duration
	UPROPERTY(EditAnywhere, Category = "Acid Weaken Breakable", Meta = (EditCondition = "bUseWeakenDuration", EditConditionHides))
	float WeakenPctBeforeThreshold = 0.0;

	// Called when the object is weakened enough to be breakable
	UPROPERTY()
	FOnWeakenedByAcid OnWeakenedByAcid;

	// Called when the object is broken by being hit by the tail after being weakened
	UPROPERTY()
	FOnBrokenByTail OnBrokenByTail;

	// Called when the object has restored from its weakened state and can no longer be broken
	UPROPERTY()
	FOnAcidWeakenRestored OnWeakenRestored;

	// Called when the percentage of how much it is weakened changes. 0 is not weakened at all, 1 is weakened enough to be broken
	UPROPERTY()
	FOnWeakenPercentageChanged OnWeakenPercentageChanged;

	private TArray<FInstigator> Disablers;

	private float DamagePct = 0;
	private float WeakenPct = 0.0;
	private float BreakPct = 0.0;
	private float RestoreTimer = 0.0;
	private bool bWeakened = false;
	private bool bBroken = false;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto AcidResponseComp = UAcidResponseComponent::GetOrCreate(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		auto TailAttackResponseComp = UTeenDragonTailAttackResponseComponent::GetOrCreate(Owner);
		TailAttackResponseComp.OnHitByTailAttack.AddUFunction(this, n"OnTailHit");

		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		DamagePct = 0;
		WeakenPct = 0.0;
		BreakPct = 0.0;
		RestoreTimer = 0.0;
		bWeakened = false;
		bBroken = false;
	}

	UFUNCTION()
	void DisableAcidWeaken(FInstigator Instigator)
	{
		Disablers.AddUnique(Instigator);
	}

	UFUNCTION()
	void EnableAcidWeaken(FInstigator Instigator)
	{
		Disablers.Remove(Instigator);
	}

	UFUNCTION(BlueprintPure)
	float GetWeakenPercentage() const
	{
		return WeakenPct;
	}

	UFUNCTION(BlueprintPure)
	float GetBrokenPercentage() const
	{
		return BreakPct;
	}

	bool IsWeakened()
	{
		return bWeakened;
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit AcidHit)
	{
		if (Disablers.Num() > 0)
			return;

		if (bBroken)
			return;

		DamagePct += 1.0 / float(AcidHitsNeededToWeaken);
		DamagePct = Math::Min(1.0, DamagePct);

		if (bUseWeakenDuration)
		{
			if (WeakenPct < WeakenPctBeforeThreshold)
			{
				WeakenPct += 1.0 / float(AcidHitsNeededToWeaken) * WeakenPctBeforeThreshold;
				WeakenPct = Math::Min(WeakenPct, WeakenPctBeforeThreshold);
			}
		}
		else
		{
			WeakenPct = DamagePct;
		}

		RestoreTimer = 0.0;
		SetComponentTickEnabled(true);

		OnWeakenPercentageChanged.Broadcast(WeakenPct);

		if (!bWeakened && DamagePct >= 1.0) // TODO: Network
		{
			OnWeakenedByAcid.Broadcast();
			bWeakened = true;
		}
	}

	UFUNCTION()
	private void OnTailHit(FTailAttackParams Params)
	{
		if (Disablers.Num() > 0)
			return;

		if (bBroken)
			return;

		BreakPct += 1.0 / float(TailHitsNeededToBreak);
		BreakPct = Math::Min(1.0, BreakPct);

		if (bWeakened && BreakPct >= 1.0 && HasControl())
		{
			FOnBrokenByTailParams BreakParams;
			BreakParams.BreakLocation = Params.WorldAttackLocation;
			BreakParams.BreakDirection = Params.AttackDirection;
			CrumbOnBroken(BreakParams);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnBroken(FOnBrokenByTailParams Params)
	{
		bBroken = true;
		OnBrokenByTail.Broadcast(Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{		
		if (bBroken)
		{
			SetComponentTickEnabled(false);
			return;
		}

		if (Disablers.Num() > 0)
			return;

		if (bWeakened)
		{
			if (bUseWeakenDuration && WeakenPct < 1.0)
			{
				if (WeakenDuration > 0.0)
					WeakenPct += DeltaSeconds * (1.0 - WeakenPctBeforeThreshold) / WeakenDuration;
				else
					WeakenPct = 1.0;

				WeakenPct = Math::Min(1.0, WeakenPct);
				OnWeakenPercentageChanged.Broadcast(WeakenPct);
			}

			RestoreTimer += DeltaSeconds;
			if (RestoreTimer >= TimeUntilRestore)
			{
				bWeakened = false;
				OnWeakenRestored.Broadcast();
			}
		}
		else
		{
			RestoreTimer += DeltaSeconds;
			if (RestoreTimer >= TimeUntilRestore)
			{
				if (RestoreDuration > 0.0)
				{
					WeakenPct -= DeltaSeconds / RestoreDuration;
					WeakenPct = Math::Max(0.0, WeakenPct);

					DamagePct -= DeltaSeconds / RestoreDuration;
					DamagePct = Math::Max(0.0, DamagePct);

					//Maybe breakpct is permanent
					BreakPct -= DeltaSeconds / RestoreDuration;
					BreakPct = Math::Max(0.0, DamagePct);
					
					OnWeakenPercentageChanged.Broadcast(WeakenPct);
				}
				else
				{
					WeakenPct = 0.0;
					DamagePct = 0.0;
				}
			}
		}

		if (WeakenPct <= 0.0 && DamagePct <= 0.0)
			SetComponentTickEnabled(false);
	}
};