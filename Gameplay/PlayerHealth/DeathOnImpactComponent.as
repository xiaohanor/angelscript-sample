class UDeathOnImpactComponent : UMovementImpactCallbackComponent
{
	default bTriggerLocally = true;

	/* Whether the death trigger should be triggerable by Mio. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Trigger", AdvancedDisplay)
    bool bKillsMio = true;

	/* Whether the death trigger should be triggerable by Zoe. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Trigger", AdvancedDisplay)
    bool bKillsZoe = true;

	/* Whether the death trigger should be triggerable by ground impact. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Trigger")
    bool bGroundImpact = true;

	/* Whether the death trigger should be triggerable by wall impact. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Trigger")
    bool bWallImpact = true;

	/* Whether the death trigger should be triggerable by ceiling impact. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Death Trigger")
    bool bCeilingImpact = true;

	/* Death effect to play when this kills a player */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Death Trigger")
	TSubclassOf<UDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (bGroundImpact)
			OnGroundImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpact");

		if (bWallImpact)
			OnWallImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpact");

		if (bCeilingImpact)
			OnCeilingImpactedByPlayer.AddUFunction(this, n"HandlePlayerImpact");
	}

	UFUNCTION()
	private void HandlePlayerImpact(AHazePlayerCharacter Player)
	{
		if ((Player.IsMio() && bKillsMio) || (Player.IsZoe() && bKillsZoe))
		{
			Player.KillPlayer(FPlayerDeathDamageParams(FVector::ZeroVector, 4.0), DeathEffect);
		}
	}
};