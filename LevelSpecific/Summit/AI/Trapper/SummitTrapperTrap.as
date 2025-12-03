event void FOnSummitTrapDestroyed();

class ASummitTrapperTrap : AHazeActor
{
	FOnSummitTrapDestroyed OnTrapDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	float TrapHealth = 1.0;
	float AcidDamage = 0.01;
	float TailDamage = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		DestroyTrap();
	}

	UFUNCTION()
	void OnAcidHit(FAcidHit Hit)
	{
		DamageTrap(AcidDamage);
	}

	private void DamageTrap(float Value)
	{
		TrapHealth -= Value;

		if (TrapHealth <= 0.0)
		{
			DestroyTrap();
		}
	}

	private void DestroyTrap()
	{
		OnTrapDestroyed.Broadcast();
	}
}