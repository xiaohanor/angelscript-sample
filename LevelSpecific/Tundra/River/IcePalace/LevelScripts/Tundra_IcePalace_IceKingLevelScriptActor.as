class ATundra_IcePalace_IceKingLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY(EditDefaultsOnly)
	UClass ShapeShiftABP;
	UPROPERTY(EditDefaultsOnly)
	UClass DefaultABP;
	UPROPERTY()
	ATundraTreeGuardianRangedShootProjectileSpawner ShootProjectileSpawner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ShootProjectileSpawner.OnShootProjectileLaunched.AddUFunction(this, n"OnShootProjectileLaunched");
	}

	UFUNCTION()
	private void OnShootProjectileLaunched(ATundraTreeGuardianRangedShootProjectile Projectile)
	{
		BP_RangedShootProjectileLaunched(Projectile);
	}

	UFUNCTION(BlueprintEvent)
	void BP_RangedShootProjectileLaunched(ATundraTreeGuardianRangedShootProjectile Projectile)
	{}

	UFUNCTION()
	void SequenceShapeshift(AHazeSkeletalMeshActor SkelMesh, AHazePlayerCharacter Player, bool bShapeshiftToNormalCharacter, UAnimSequence ScalePosePlayer, UAnimSequence ScalePoseShape, float ScalePlayer = 1, float ScaleShape = 1)
	{
		SkelMesh.Mesh.SetHiddenInGame(false);
		Player.Mesh.SetHiddenInGame(false);

		FTundraCutsceneShapeshiftData OtherShapeData;
		OtherShapeData.bShapeshiftingTo = !bShapeshiftToNormalCharacter;
		OtherShapeData.BlendTime = 0.22;
		OtherShapeData.Scale = ScaleShape;
		OtherShapeData.SourceSkelMesh = Player.Mesh;
		OtherShapeData.ScalePose = ScalePoseShape;
		// OtherShapeData.Tint = FLinearColor(0.06, 0.67, 0.75);
		OtherShapeData.bHideMeshOnComplete = !OtherShapeData.bShapeshiftingTo;
		UTundraCutsceneShapeshiftComponent ShapeshiftComp = UTundraCutsceneShapeshiftComponent::Get(SkelMesh);

		if(ShapeshiftComp != nullptr)
			ShapeshiftComp.Shapeshift(OtherShapeData);

		FTundraCutsceneShapeshiftData CharacterData;
		CharacterData.bShapeshiftingTo = bShapeshiftToNormalCharacter;
		CharacterData.BlendTime = 0.22;
		CharacterData.Scale = ScalePlayer;
		CharacterData.SourceSkelMesh = SkelMesh.Mesh;
		CharacterData.ScalePose = ScalePosePlayer;
		// CharacterData.Tint = FLinearColor(0.58, 0.10, 0.81);
		CharacterData.bHideMeshOnComplete = !CharacterData.bShapeshiftingTo;
		UTundraCutsceneShapeshiftComponent PlayerCharacterShapeshiftComp = UTundraCutsceneShapeshiftComponent::Get(Player);
		
		if(PlayerCharacterShapeshiftComp != nullptr)
			PlayerCharacterShapeshiftComp.Shapeshift(CharacterData);
	}

	UFUNCTION()
	void ApplyCustomAnimInstances(USkeletalMeshComponent SkelMesh01, USkeletalMeshComponent SkelMesh02)
	{
		if(SkelMesh01 != nullptr)
			SkelMesh01.SetAnimClass(ShapeShiftABP);

		if(SkelMesh02 != nullptr)
			SkelMesh02.SetAnimClass(ShapeShiftABP);

		Game::Mio.Mesh.SetAnimClass(ShapeShiftABP);
		Game::Zoe.Mesh.SetAnimClass(ShapeShiftABP);
	}

	UFUNCTION()
	void ResetAllAnimInstances()
	{
		Game::Mio.Mesh.SetAnimClass(DefaultABP);
		Game::Zoe.Mesh.SetAnimClass(DefaultABP);
	}

	UFUNCTION()
	void SetPlayerVelocityDuringSlide(AHazePlayerCharacter Player, UArrowComponent Direction)
	{
		Player.SetActorVelocity(Direction.ForwardVector * 1125.0);
	}
};