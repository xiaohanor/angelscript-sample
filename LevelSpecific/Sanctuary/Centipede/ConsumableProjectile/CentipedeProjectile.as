event void FOnCentipedeProjectileDespawnSignature();

class ACentipedeProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float Speed = 1000.0;

	UPROPERTY()
	float TargetRadius = 50.0;

	UPROPERTY()
	float LifeTime = 10.0;

	FVector Direction;

	UCentipedeProjectileTargetableComponent TargetableComponent;

	UPROPERTY()
	FOnCentipedeProjectileDespawnSignature OnProjectileDespawn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	private void OnDespawn()
	{
		OnProjectileDespawn.Broadcast();
		DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//Set direction if projectile has a target
		if (TargetableComponent != nullptr)
		{
			Direction = (TargetableComponent.WorldLocation - ActorLocation).GetSafeNormal();

			if (TargetableComponent.WorldLocation.Distance(ActorLocation) < TargetRadius)
			{
				auto ResponseComp = UCentipedeProjectileResponseComponent::Get(TargetableComponent.Owner);

				if (ResponseComp != nullptr)
				{
					ResponseComp.ProjectileImpact(Direction, 10.0);
				}
				else
					PrintToScreen("PROJECTILE HIT ACTOR WITH TARGETABLE COMP BUT NO PROJECTILE RESPONSE COMP", 10.0, FLinearColor::Red);

				OnDespawn();
			}
		}

		//Despawn projectile after a duration since spawn
		if (GameTimeSinceCreation > LifeTime)
			OnDespawn();

		//Set location and rotation
		SetActorRotation(FRotator::MakeFromZ(Direction));
		AddActorWorldOffset(Direction * Speed * DeltaSeconds);
	}
};