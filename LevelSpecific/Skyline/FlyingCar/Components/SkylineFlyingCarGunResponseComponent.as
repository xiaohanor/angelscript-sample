event void FSkylineFlyingCarGunHitEvent(FSkylineFlyingCarGunHit HitInfo);

class USkylineFlyingCarGunResponseComponent : UActorComponent
{
	UPROPERTY()
	FSkylineFlyingCarGunHitEvent OnHitEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnHitEvent.AddUFunction(this, n"OnHit");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHit(FSkylineFlyingCarGunHit HitInfo)
	{
		// Do some auto magic
		USkylineFlyingCarDestructibleComponent DestructibleComponent = USkylineFlyingCarDestructibleComponent::Get(Owner);
		if (DestructibleComponent != nullptr)
		{
			DestructibleComponent.TakeDamage(HitInfo);
		}
	}
}