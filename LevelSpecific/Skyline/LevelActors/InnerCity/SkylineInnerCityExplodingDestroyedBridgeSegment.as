class ASkylineInnerCityExplodingDestroyedBridgeSegment : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent BrokenMesh;
	default BrokenMesh.SetHiddenInGame(true);
	default BrokenMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	FHazeTimeLike BridgeDestruction;
	default BridgeDestruction.Duration = 3.5;
	default BridgeDestruction.UseLinearCurveZeroToOne();

	UMaterialInstanceDynamic BridgeDestroyMID;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BridgeDestruction.BindUpdate(this, n"DestroyingBridge");
		BridgeDestruction.BindFinished(this, n"HandleDestroyedFinished");

		BridgeDestroyMID = Material::CreateDynamicMaterialInstance(this, BrokenMesh.GetMaterial(0));
		BrokenMesh.SetMaterial(0, BridgeDestroyMID);
	}

	UFUNCTION()
	private void DestroyingBridge(float CurrentValue)
	{
		BridgeDestroyMID.SetScalarParameterValue(n"VAT_DisplayTime", Math::Lerp(0,1,CurrentValue));
	}

	UFUNCTION()
	private void HandleDestroyedFinished()
	{
		DestroyActor();
	
	}

	UFUNCTION()
	void PlayExplodeBridge()
	{
		BrokenMesh.SetHiddenInGame(false);
		BridgeDestruction.PlayFromStart();
	}
};