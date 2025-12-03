class AIslandStormdrainPillarPadel : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = "MovingRoot")
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = "Mesh")
	UIslandRedBlueImpactShieldResponseComponent ImpactComp;

	UPROPERTY(DefaultComponent, Attach = "ImpactComp")
	UIslandRedBlueTargetableComponent TargetComp;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings MioSettings;

	UPROPERTY()
	UIslandRedBlueImpactShieldResponseComponentSettings ZoeSettings;

	UPROPERTY()
	UMaterialInterface DeactivatedMaterial;

	UPROPERTY()
	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 1.0;
	default MoveAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnimation.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditInstanceOnly)
	float ResetTimer = 8;
	float Timer = 0;
	bool bActive = true;

	UPROPERTY()
	int MaterialIndex;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			Mesh.SetMaterial(MaterialIndex, MioMaterial);
			ImpactComp.Settings = MioSettings;
		}

		else
		{
			Mesh.SetMaterial(MaterialIndex, ZoeMaterial);
			ImpactComp.Settings = ZoeSettings;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisableForPlayer(Game::GetOtherPlayer(UsableByPlayer));
		ImpactComp.OnImpactWhenShieldDestroyed.AddUFunction(this, n"HandleFullAlpha");
		MoveAnimation.BindUpdate(this, n"HandleTimeLikeUpdate");
	}

	UFUNCTION()
	void HandleTimeLikeUpdate(float CurveValue)
	{
		MovingRoot.SetRelativeRotation(FRotator(CurveValue*-90, 0,0));
	}

	UFUNCTION()
	void HandleFullAlpha(FIslandRedBlueImpactShieldResponseParams ImpactData)
	{
		DisableForPlayer(Game::GetPlayer(UsableByPlayer));
		Mesh.SetMaterial(MaterialIndex, DeactivatedMaterial);
		SetActorTickEnabled(true);
		Timer = ResetTimer;
		MoveAnimation.Play();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer -= DeltaSeconds;
		if(Timer <= 0)
		{
			Reset();
			//SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void Reset()
	{
		ImpactComp.ResetShieldAlpha();
		if(UsableByPlayer == EHazePlayer::Mio)
		{
			Mesh.SetMaterial(MaterialIndex, MioMaterial);
		}

		else
		{
			Mesh.SetMaterial(MaterialIndex, ZoeMaterial);
		}
		EnableForPlayer(Game::GetPlayer(UsableByPlayer));
		MoveAnimation.Reverse();
	}

	UFUNCTION()
	void DisableForPlayer(AHazePlayerCharacter Player)
	{
		TargetComp.DisableForPlayer(Player, this);
		ImpactComp.BlockImpactForPlayer(Player, this);
	}

	UFUNCTION()
	void EnableForPlayer(AHazePlayerCharacter Player)
	{
		TargetComp.EnableForPlayer(Player, this);
		ImpactComp.UnblockImpactForPlayer(Player, this);
	}
}