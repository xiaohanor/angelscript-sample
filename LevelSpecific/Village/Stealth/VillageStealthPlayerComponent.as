class UVillageStealthPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AVillageStealthThrowable> ThrowableClass;
	AVillageStealthThrowable Throwable;

	bool bBoulderThrownAtPlayer = false;
	AVillageStealthOgreThrownBoulder CurrentBoulder;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Throwable = SpawnActor(ThrowableClass, bDeferredSpawn = true);
		Throwable.MakeNetworked(this);
		FinishSpawningActor(Throwable);
		Throwable.AddActorDisable(Throwable);
	}

	void ThrowBoulder(AVillageStealthOgreThrownBoulder Boulder)
	{
		CurrentBoulder = Boulder;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentBoulder != nullptr)
		{
			if (CurrentBoulder.bReachedTarget)
			{
				bBoulderThrownAtPlayer = false;
				CurrentBoulder = nullptr;
			}
		}
	}
}