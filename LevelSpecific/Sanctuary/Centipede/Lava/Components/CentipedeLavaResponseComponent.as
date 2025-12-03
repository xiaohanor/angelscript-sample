USTRUCT()
struct FCentipedeLavaHitParams
{
	TSubclassOf<AHazeActor> SourceDamager;
	float DamagePerSecond = 0.0;
	float DamageDuration = 0.0;
	bool bInstakill = false;
	bool bTriggerForceFeedback = false;
	TArray<int> SegmentIndexes;
	bool bDeathEvenIfInfiniteHealth = false;
}

event void FOnLavaHit(FCentipedeLavaHitParams HitParams);
class UCentipedeLavaResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnLavaHit OnLavaHitEvent;

	ACentipede Centipede;
	UCentipedeLavaIntoleranceComponent LavaIntoleranceComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnLavaHitEvent.AddUFunction(this, n"OnLavaHit");
		Centipede = Cast<ACentipede>(Owner);
		LavaIntoleranceComponent = UCentipedeLavaIntoleranceComponent::Get(Owner);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnLavaHit(FCentipedeLavaHitParams HitParams)
	{
		if (LavaIntoleranceComponent.bIsRespawning)
			return;

		if (HitParams.bInstakill)
			InstaKill();
		else if (LavaIntoleranceComponent != nullptr)
		{
			FCentipedeLavaDamageOverTime DamageOverTime;
			DamageOverTime.DamagePerSecond = HitParams.DamagePerSecond;
			DamageOverTime.DamageDuration = HitParams.DamageDuration;
			DamageOverTime.bTriggerForceFeedback = HitParams.bTriggerForceFeedback;
			DamageOverTime.SegmentIndexes = HitParams.SegmentIndexes;
			DamageOverTime.SourceDamager = HitParams.SourceDamager;
			DamageOverTime.bDeathEvenIfInfiniteHealth = HitParams.bDeathEvenIfInfiniteHealth;
			LavaIntoleranceComponent.AddDamageSource(DamageOverTime);
		}
	}

	private void InstaKill()
	{
		LavaIntoleranceComponent.Health.SetValue(0.0);
	}
}