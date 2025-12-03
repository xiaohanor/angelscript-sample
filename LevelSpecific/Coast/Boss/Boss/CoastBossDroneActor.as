class ACoastBossDroneActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UCoastBossDroneComponent DroneMesh;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInstance WeakMaterial;

	FHazeAcceleratedVector2D AccManualRelativeLocation;
	FVector2D TargetManualRelativeLocation;
	FVector2D ActualRelativeLocation;

	FHazeAcceleratedVector2D AccBossOffset;
	bool bAddBossLocation = true;

	bool bDead = false;

	float Health = 1.0;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	void BecomeWeakpoint()
	{
		DroneMesh.bIsWeakpoint = true;
		BP_BecomeWeakpoint();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BecomeWeakpoint() {}
};