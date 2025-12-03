class AStormChaseFallingRockObstacle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UStormChaseFallingObstacleComponent FallingComp;

	UPROPERTY(DefaultComponent, Attach = FallingComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UAdultDragonTakeDamageDestructibleRocksComponent DragonTakeDamageComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;
	default DisableComp.AutoDisableRange = 120000;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DragonTakeDamageComp.OnDestructibleRockHit.AddUFunction(this, n"OnDestructibleRockHit");
	}

	UFUNCTION()
	private void OnDestructibleRockHit(USceneComponent HitComponent, AHazePlayerCharacter Player)
	{
		UStormChaseFallingRockObstacleEffectHandler::Trigger_OnImpact(this, FOnStormChaseFallingRockParams(ActorLocation));
		AddActorDisable(this);
	}
};