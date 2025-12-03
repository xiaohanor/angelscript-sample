class UPlayerKnockBackComponent : UMovementImpactCallbackComponent
{
	default bTriggerLocally = true;

	/* Whether the knockback should be triggerable by Mio. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Knockback Trigger", AdvancedDisplay)
    bool bKnocksMio = true;

	/* Whether the knockbackshould be triggerable by Zoe. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Knockback Trigger", AdvancedDisplay)
    bool bKnocksZoe = true;

	/* Whether the knockback should be triggerable by ground impact. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Knockback Trigger")
    bool bGroundImpact = true;

	/* Whether the knockback should be triggerable by wall impact. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Knockback Trigger")
    bool bWallImpact = true;

	/* Whether the knockback should be triggerable by ceiling impact. */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Knockback Trigger")
    bool bCeilingImpact = true;

	/* How long the knockback should be */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Knockback Trigger")
    float KnockbackDuration = 3.0;

	/* How long the knockback CoolDown should be */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Knockback Trigger")
    float CoolDownDuration = 0.0;

	UPROPERTY(EditAnywhere, Category = "Should DamagePlayer", Meta = (InlineEditConditionToggle))
	bool bShouldDamagePlayer = false;
	UPROPERTY(EditAnywhere, Category = "Should DamagePlayer", Meta = (EditCondition = "bShouldDamagePlayer"))
	float PlayerDamage = 0.1;

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

		if ((Player.IsMio() && bKnocksMio) || (Player.IsZoe() && bKnocksZoe))
		{
			Player.ApplyKnockdown((-Player.ActorForwardVector * 1700) + FVector::UpVector * 800, KnockbackDuration, n"Knockdown", CoolDownDuration);

			 if(bShouldDamagePlayer)
			 	Player.DamagePlayerHealth(PlayerDamage);
		}
			
	}
};