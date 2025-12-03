class ASoftSplitSciFiBridgeDestruction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BridgePart01;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BridgePart02;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BridgePart03;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BridgePart04;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintCallable)
	void DestroyBridge()
	{
		USoftSplitBridgeSciFiDestructionEventHandler::Trigger_BridgeDestroyed(this);
	}
};