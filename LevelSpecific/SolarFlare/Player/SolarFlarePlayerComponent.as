event void FOnSolarFlarePlayerRecievedHit();

class USolarFlarePlayerComponent : UActorComponent
{
	access ReadOnly = private, * (readonly);

	FOnSolarFlarePlayerRecievedHit OnSolarFlarePlayerRecievedHit;

	TArray<USolarFlareCoverOverlapComponent> OuterOverlapComps;
	TArray<USolarFlareCoverOverlapComponent> OverlapCoverComps;
	TArray<USolarFlarePlayerCoverComponent> PlayerCoverComps;

	UPROPERTY()
	AHazePlayerCharacter OwningPlayer;

	UPROPERTY()
	UPlayerHealthSettings HealthSettings;

	float InvincibilityDuration;

	access:ReadOnly TPerPlayer<bool> bTriggerShieldProtecting;
	access:ReadOnly bool bTriggerShieldActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
		ApplyHealthSettings();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// for (USolarFlareCoverOverlapComponent Cover : OverlapCoverComps)
		// {
		// 	PrintToScreen(f"{Cover.IsCoverEnabled()=}");
		// }

		// PrintToScreen(f"{PlayerCoverComps.Num()=}");
		// PrintToScreen("" + OwningPlayer.Name + "Protected by self: " + bTriggerShieldProtecting[OwningPlayer]);
		// PrintToScreen("" + OwningPlayer.Name + "Protected by Other: " + bTriggerShieldProtecting[OwningPlayer.OtherPlayer]);
	}

	void ApplyHealthSettings()
	{
		OwningPlayer.ApplySettings(HealthSettings, this, EHazeSettingsPriority::Sheet);
	}

	void ClearHealthSettings()
	{
		OwningPlayer.ClearSettingsByInstigator(this);
	}

	void AddCover(USolarFlareCoverOverlapComponent Comp)
	{
		OverlapCoverComps.AddUnique(Comp);
	}

	void RemoveCover(USolarFlareCoverOverlapComponent Comp)
	{
		if (OverlapCoverComps.Contains(Comp))
			OverlapCoverComps.Remove(Comp);
	}

	void SetPlayerCovers(TArray<USolarFlarePlayerCoverComponent> Covers)
	{
		PlayerCoverComps = Covers;
	}
	
	void AlterTriggerShieldProtected(bool bIsProtected, AHazePlayerCharacter Player)
	{
		bTriggerShieldProtecting[Player] = bIsProtected;
	}

	void SetTriggerShieldActive(bool bIsActive)
	{
		bTriggerShieldActive = bIsActive;
	}

	bool CanKillPlayer()
	{
		if (Time::GameTimeSeconds < InvincibilityDuration)
			return false;

		return HasNoCover();
	}

	bool HasNoCover()
	{
		if (PlayerCoverComps.Num() > 0)
			return false;

		if (bTriggerShieldProtecting[OwningPlayer] || bTriggerShieldProtecting[OwningPlayer.OtherPlayer])
			return false;

		int ActiveOverlapCoverComps = 0;

		for (USolarFlareCoverOverlapComponent Cover : OverlapCoverComps)
		{
			if (Cover.IsCoverEnabled())
				ActiveOverlapCoverComps++;
		}

		if (ActiveOverlapCoverComps == 0)
			return true;

		return OverlapCoverComps.Num() == 0;		
	}

	bool IsThisCoverInUse(USolarFlarePlayerCoverComponent CurrentComp)
	{
		return PlayerCoverComps.Contains(CurrentComp);
	}

	void SetInvincibleForDuration(float Duration)
	{
		InvincibilityDuration = Time::GameTimeSeconds + Duration;
	}
}