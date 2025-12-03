class UIslandOverseerTakeDamageCapability : UHazeCapability
{		
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	AAIIslandOverseer Overseer;
	UIslandOverseerTakeDamageComponent TakeDamageComp;
	UBasicAIHealthComponent HealthComp;

	float ImpactTime;
	float FlashTime;
	float Duration = 0.1;
	float FlashDuration = 0.1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Overseer = Cast<AAIIslandOverseer>(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner);
		TakeDamageComp = UIslandOverseerTakeDamageComponent::GetOrCreate(Owner);
		TakeDamageComp.OnImpact.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(bool bAddTint)
	{
		if(bAddTint && Time::GetGameTimeSince(FlashTime) > FlashDuration + 0.1)
		{
			DamageFlash::DamageFlashActor(Owner, FlashDuration, FLinearColor(0.33, 0.00, 0.00));
			FlashTime = Time::GameTimeSeconds;
			FlashDuration = Math::RandRange(0.1, 0.2);
		}
		ImpactTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ImpactTime < SMALL_NUMBER)
			return false;
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::Dead)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Time::GetGameTimeSince(ImpactTime) > Duration)
			return true;
		if(Overseer.PhaseComp.Phase == EIslandOverseerPhase::Dead)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TakeDamageComp.bHitReactionTakeDamageLeft = false;
		TakeDamageComp.bHitReactionTakeDamageRight = false;
		TakeDamageComp.bHitReactionTakeDamageProfile = false;
		TakeDamageComp.bHitReactionTakeDamageCutHead = false;
		TakeDamageComp.bHitReactionTakeDamageCutHeadDead = false;
		ImpactTime = 0;
	}
}