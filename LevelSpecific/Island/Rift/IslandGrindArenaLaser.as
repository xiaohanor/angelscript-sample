event void FIslandGrindArenaLaserSignature();

UCLASS(Abstract)
class AIslandGrindArenaLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	bool bCanHurtPlayer = true;

	UPROPERTY()
	UNiagaraSystem MuzzleEffect;

	UPROPERTY()
	FIslandGrindArenaLaserSignature OnActivated;

	UPROPERTY()
	FIslandGrindArenaLaserSignature OnDeactivated;

	FVector RootWorldPosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeactivateLaser();
		RootWorldPosition = Root.GetWorldTransform().GetLocation();
	}

	UFUNCTION()
	void DeactivateLaser()
	{
		bCanHurtPlayer = false;
		BP_DeactivateLaser();
	}

	UFUNCTION()
	void ActivateLaser()
	{
		if (MuzzleEffect != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(MuzzleEffect, RootWorldPosition);

		bCanHurtPlayer = true;
		BP_ActivateLaser();
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateLaser() {}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateLaser() {}
};
