class ASkylineHighwayFlipWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationComp;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent ResponseComp;

	bool bHit;
	FHazeAcceleratedRotator AccRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHit.AddUFunction(this, n"OnHit");
	}

	UFUNCTION()
	private void OnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		AccRotation.SnapTo(ActorRotation);
		TargetRotation = ActorRotation + FRotator(-90, 0, 0);
		bHit = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bHit)
			return;

		AccRotation.SpringTo(TargetRotation, 100, 0.25, DeltaSeconds);
		ActorRotation = AccRotation.Value;
	}
}