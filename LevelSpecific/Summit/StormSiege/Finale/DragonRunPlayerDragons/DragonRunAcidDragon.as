class ADragonRunAcidDragon : ADragonRunPlayerDragon
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY()
	TSubclassOf<AAdultDragonAcidProjectile> AcidProjectileClass;

	UAdultDragonAcidProjectileSettings ProjectileSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnDragonRunActivateAttack.AddUFunction(this, n"OnDragonRunActivateAttack");
		ProjectileSettings = UAdultDragonAcidProjectileSettings::GetSettings(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
	}

	UFUNCTION()
	private void OnDragonRunActivateAttack(AActor Target)
	{
		FTransform TargetSocket = Mesh.GetSocketTransform(AdultDragonAcidBeam::ShootSocket);
		FVector Start = TargetSocket.TransformPosition(AdultDragonAcidBeam::ShootSocketOffset);

		AAdultDragonAcidProjectile Proj = SpawnActor(AcidProjectileClass, Start, bDeferredSpawn = true);
		Proj.Direction = (Target.ActorLocation - Start).GetSafeNormal();
		// Proj.Speed = ProjectileSettings.MoveSpeed;
		Proj.Speed = 12000.0;
		Proj.OwningPlayer = this;
		Proj.OtherPlayer = OtherDragon;

		FAcidHomingTargetParams HomingParams;
		HomingParams.HomingTarget = Target;
		HomingParams.HomingCorrection = 50.0;
		Proj.HomingParams = HomingParams;

		FinishSpawningActor(Proj);
	}
}