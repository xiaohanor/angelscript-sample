class AStormKnightLightningAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	float TelegraphTime = 2.0;
	float LifeTime = 6.0;

	bool bRunAttack;

	FStormKnightLightningParams Params;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TelegraphTime += Time::GameTimeSeconds;
		LifeTime += Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Debug::DrawDebugSphere(Params.End, 300.0, LineColor = FLinearColor::LucBlue);
		
		if (Time::GameTimeSeconds > TelegraphTime && !bRunAttack)
		{
			bRunAttack = true;
			UStormKnightLightningAttackEffectHandler::Trigger_LightningStrike(this, Params);
		}

		if (bRunAttack)
		{
			Debug::DrawDebugLine(Params.Start, Params.End, FLinearColor::LucBlue, 10);
		}

		if (Time::GameTimeSeconds > LifeTime)
		{
			DestroyActor();
		}
	}
}