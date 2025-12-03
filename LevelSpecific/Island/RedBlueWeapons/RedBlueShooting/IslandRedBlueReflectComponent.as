struct FIslandRedBlueReflectComponentBlocker
{
	TArray<FInstigator> Blockers;

	bool IsActive() const
	{
		return Blockers.Num() > 0;
	}
}

event void FIslandRedBlueReflectEvent(AIslandRedBlueWeaponBullet Bullet, AActor HitActor, FVector ReflectImpactPoint);

/* Slap this component on a actor you want bullets to reflect on, by default it applies to the whole actor but can also apply to a specific scene component with a setting */
class UIslandRedBlueReflectComponent : USceneComponent
{
	// If true, this will only reflect bullets if the parent component is hit
	UPROPERTY(EditAnywhere, Category = "Red Blue Settings")
	bool bIsPrimitiveParentExclusive = false;

	UPROPERTY()
	FIslandRedBlueReflectEvent OnBulletReflect;

	private TPerPlayer<FIslandRedBlueReflectComponentBlocker> ReflectBlockers;

	bool ShouldReflectFor(AHazePlayerCharacter Player, UPrimitiveComponent Component)
	{
		if(IsReflectBlockedFor(Player))
			return false;

		if(!bIsPrimitiveParentExclusive)
			return true;

		if(AttachParent == Component)
			return true;

		return false;
	}

	UFUNCTION(BlueprintCallable, Category = "Reflect Blockers")
	bool IsReflectBlockedFor(AHazePlayerCharacter Player) const
	{
		return ReflectBlockers[Player].IsActive();
	}

	UFUNCTION(BlueprintCallable, Category = "Reflect Blockers")
	void AddReflectBlockerForBothPlayers(FInstigator Instigator)
	{
		ReflectBlockers[0].Blockers.AddUnique(Instigator);
		ReflectBlockers[1].Blockers.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Reflect Blockers")
	void RemoveReflectBlockerForBothPlayers(FInstigator Instigator)
	{
		ReflectBlockers[0].Blockers.RemoveSingleSwap(Instigator);
		ReflectBlockers[1].Blockers.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Reflect Blockers")
	void AddReflectBlockerForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		ReflectBlockers[Player].Blockers.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Reflect Blockers")
	void AddReflectBlockerForColor(EIslandRedBlueWeaponType Color, FInstigator Instigator)
	{
		ReflectBlockers[IslandRedBlueWeapon::GetPlayerForColor(Color)].Blockers.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Reflect Blockers")
	void RemoveReflectBlockerForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		ReflectBlockers[Player].Blockers.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "Reflect Blockers")
	void RemoveReflectBlockerForColor(EIslandRedBlueWeaponType Color, FInstigator Instigator)
	{
		ReflectBlockers[IslandRedBlueWeapon::GetPlayerForColor(Color)].Blockers.RemoveSingleSwap(Instigator);
	}
}