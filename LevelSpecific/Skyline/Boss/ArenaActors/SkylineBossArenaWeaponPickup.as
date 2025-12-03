class ASkylineBossArenaWeaponPickup : AGravityBikeWeaponPickup
{
	UPROPERTY(EditAnywhere)
	bool bStartDisabled = true;

	UPROPERTY(EditAnywhere)
	FName Group = n"Default";

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if (bStartDisabled)
			DisablePickup();
	}

	UFUNCTION()
	void DisablePickup()
	{
		AddActorDisable(this);
	}

	UFUNCTION()
	void EnablePickup()
	{
		RemoveActorDisable(this);

		// Re-activate the niagara components, since they might have been deactivated by the disable
		for (auto Data : PlayerDatas)
		{
			if (IsValid(Data.NiagaraComp) && Data.IsEnabled())
				Data.NiagaraComp.Activate(true);
		}
	}
};

UFUNCTION()
void EnableSkylineBossArenaPickups(FName Group = n"Default")
{
	TListedActors<ASkylineBossArenaWeaponPickup> Pickups;

	for (auto Pickup : Pickups)
	{
		if (Group != Pickup.Group)
			continue;

		Pickup.EnablePickup();
	}
}

UFUNCTION()
void DisableSkylineBossArenaPickups(FName Group = n"Default")
{
	TListedActors<ASkylineBossArenaWeaponPickup> Pickups;
	for (auto Pickup : Pickups)
	{
		if (Group != Pickup.Group)
			continue;

		Pickup.DisablePickup();
	}
}