class AIslandStormdrainShootableSupportBeam : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent ShootMesh;

	UPROPERTY(DefaultComponent, Attach = "ShootMesh")
	UIslandRedBlueTargetableComponent TargetComp;

	UPROPERTY(DefaultComponent, Attach ="ShootMesh")
	UIslandRedBlueImpactCounterResponseComponent ImpactComp;
	default ImpactComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach ="Root")
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = "RotationRoot")
	UStaticMeshComponent Beam;

	UPROPERTY(DefaultComponent, Attach = "Beam")
	UStaticMeshComponent GrappleMesh;

	UPROPERTY(DefaultComponent, Attach = "GrappleMesh")
	USwingPointComponent SwingPoint;

	UPROPERTY()
	UIslandRedBlueImpactCounterResponseComponentSettings MioSettings;

	UPROPERTY()
	UIslandRedBlueImpactCounterResponseComponentSettings ZoeSettings;

	UPROPERTY()
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer;// = EHazePlayer::Mio;
	default UsableByPlayer = EHazePlayer::Mio;
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			ShootMesh.SetMaterial(0, MioMaterial);
			ImpactComp.Settings = MioSettings;
		}

		else
		{
			ShootMesh.SetMaterial(0, ZoeMaterial);
			ImpactComp.Settings = ZoeSettings;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnFullAlpha.AddUFunction(this, n"OnFullAlpha");
		ImpactComp.OnImpactEvent.AddUFunction(this,n"OnImpact");
		MoveAnimation.BindUpdate(this, n"TL_Update");

		ImpactComp.BlockImpactForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);
		TargetComp.DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer), this);

		SwingPoint.Disable(this);
	}

	UFUNCTION()
	void TL_Update(float Alpha)
	{
		RotationRoot.SetRelativeRotation(FRotator(-90*(1-Alpha),0,0));
	}

	UFUNCTION()
	void OnFullAlpha(AHazePlayerCharacter Player)
	{
		ImpactComp.BlockImpactForPlayer(Game::GetPlayer(UsableByPlayer), this);
		TargetComp.DisableForPlayer(Game::GetPlayer(UsableByPlayer), this);
		MoveDown();
		ShootMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		ShootMesh.SetHiddenInGame(true, false);
	}

	UFUNCTION()
	void OnImpact(FIslandRedBlueImpactResponseParams Data)
	{

	}

	UFUNCTION()
	void MoveDown()
	{
		SwingPoint.Enable(this);
		MoveAnimation.Play();
	}
}