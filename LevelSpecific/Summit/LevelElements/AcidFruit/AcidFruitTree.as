class AAcidFruitTree : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TeenDragonTailAttackResponseComp;

	UPROPERTY()
	TSubclassOf<AAcidFruit> AcidFruit;

	UPROPERTY(EditAnywhere)
	AActor SpawnPoint;

	float LastHitTime;
	float SpawnFruitCooldown = 1.0;
	float MinRadius = 400.0;
	float MaxRadius = 1000.0;
	float SpawnHeight = 1000.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TeenDragonTailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	void OnHitByRoll(FRollParams Param)
	{
		if(Time::GameTimeSeconds < LastHitTime)
			return;
		
		if(SpawnPoint == nullptr)
		{
			float X = GetAxisPosition();
			float Y = GetAxisPosition();

			SpawnActor(AcidFruit, ActorLocation + FVector(X, Y, SpawnHeight));
		}
		else
		{
			SpawnActor(AcidFruit, SpawnPoint.ActorLocation, SpawnPoint.ActorRotation);
		}
		
		LastHitTime = SpawnFruitCooldown + Time::GameTimeSeconds;
	}


	float GetAxisPosition()
	{
		bool bDecider = Math::RandBool();

		if(bDecider)
			return Math::RandRange(MinRadius, MaxRadius);
		else
			return Math::RandRange(-MaxRadius, -MinRadius);
	}
}