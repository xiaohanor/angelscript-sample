class AMeltdownScreenWalkRaderSmashBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Platform01;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Platform02;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Platform03;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Platform04;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Platform05;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void SmashBridge()
	{
		UMeltdownScreenWalkRaderSmashBridgeEventHandler::Trigger_SmashBridge(this);
	}
};