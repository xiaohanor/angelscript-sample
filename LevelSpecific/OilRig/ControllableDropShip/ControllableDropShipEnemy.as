class AControllableDropShipEnemy : AHazeSkeletalMeshActor
{
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY(EditDefaultsOnly)
	UBlendSpace BlendSpace;

	UPROPERTY(EditInstanceOnly)
	AControllableDropShipTurret Turret;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayBlendSpace(BlendSpace, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetBlendSpaceValues(0.0, Turret.GetCurrentPitch());
	}
}