class AWaterSplashManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(25));
#endif

	UPROPERTY(EditAnywhere)
	AActor WaterSplashLocationActor;

	UPROPERTY(EditAnywhere)
	AActor WaterSplashLocationEnterActor;

	UFUNCTION()
	void ActivatePlayerSplash()
	{
		UWaterSplashEffectHandler::Trigger_OnPlayersExitWater(this, FStoneBeastChaseWaterSplashParams(Game::Mio.ActorLocation));
		UWaterSplashEffectHandler::Trigger_OnPlayersExitWater(this, FStoneBeastChaseWaterSplashParams(Game::Zoe.ActorLocation));
	}

	UFUNCTION()
	void ActivateStoneBeastSplash(AActor StoneBeastActor)
	{
		UWaterSplashEffectHandler::Trigger_OnStoneBeastExitWater(this, FStoneBeastChaseWaterSplashParams(WaterSplashLocationActor.ActorLocation));
	}

	UFUNCTION()
	void ActivateStoneBeastSplashEnter(AActor StoneBeastActor)
	{
		UWaterSplashEffectHandler::Trigger_OnStoneBeastEnterWater(this, FStoneBeastChaseWaterSplashParams(WaterSplashLocationActor.ActorLocation));
	}
};