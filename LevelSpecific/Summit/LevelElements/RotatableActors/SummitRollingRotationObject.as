class ASummitRollingRotationObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent RotationComponent;

	UPROPERTY(DefaultComponent, Attach = RotationComponent)
	UStaticMeshComponent RollingHitMesh;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float RollHitImpulse = 100.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		TailResponseComp.OnHitByRoll.AddUFunction(this, n"RollHit");
	}

	UFUNCTION(NotBlueprintCallable)
	private void RollHit(FRollParams Params)
	{
		FauxPhysics::ApplyFauxForceToParentsAt(RotationComponent, Params.HitLocation, Params.RollDirection * RollHitImpulse);

		Game::Mio.PlayCameraShake(ImpactCameraShake, this, 1.0, ECameraShakePlaySpace::CameraLocal);
		Game::Zoe.PlayCameraShake(ImpactCameraShake, this, 1.0, ECameraShakePlaySpace::CameraLocal);
	}
}
