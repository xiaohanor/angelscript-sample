class AMoonMarketBouncyBallBlaster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshScaler;

	UPROPERTY(DefaultComponent, Attach = MeshScaler)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	USceneComponent BallSpawnPoint;

	UPROPERTY(DefaultComponent, Attach = BallSpawnPoint)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UMoonMarketBouncyBallResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketPolymorphShapeComponent ShapeComp;
	default ShapeComp.ShapeData.ShapeTag = "Pumpkin";
	default ShapeComp.ShapeData.bIsBubbleBlockingShape = true;
	default ShapeComp.ShapeData.bCanDash = false;
	default ShapeComp.ShapeData.bUseCustomMovement = true;
	default ShapeComp.ShapeData.bCancelByThunder = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitByBallEvent.AddUFunction(this, n"OnHitByBall");
	}

	UFUNCTION()
	private void OnHitByBall(FMoonMarketBouncyBallHitData Data)
	{
		
	}
};