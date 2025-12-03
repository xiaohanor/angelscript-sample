class ASkylineDroneBossBeamAttachment : ASkylineDroneBossAttachment
{
	UPROPERTY(DefaultComponent)
	UGravityWhipImpactResponseComponent WhipImpactResponse;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComponent.OnTakeDamage.AddUFunction(this, n"HandleTakeDamage");
		WhipImpactResponse.OnImpact.AddUFunction(this, n"HandleImpact");
	}

	UFUNCTION()
	private void HandleTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		if (HealthComponent.CurrentHealth < SMALL_NUMBER)
			DestroyActor();
	}

	UFUNCTION()
	private void HandleImpact(FGravityWhipImpactData ImpactData)
	{
		HealthComponent.TakeDamage(0.3, EDamageType::Default, this);
	}
}