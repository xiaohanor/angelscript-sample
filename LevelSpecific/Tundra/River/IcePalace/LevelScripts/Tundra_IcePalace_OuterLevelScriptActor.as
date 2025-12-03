class ATundra_IcePalace_OuterLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY(EditDefaultsOnly)
	UClass ShapeShiftABP;
	UPROPERTY(EditDefaultsOnly)
	UClass DefaultABP;
	bool bIsIceCracked = false;
	UPROPERTY()
	AStaticMeshActor IntactIce;
	UPROPERTY()
	AStaticMeshActor BrokenIce;
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
	bool CrackIceAboveSphere()
	{
		if(bIsIceCracked)
			return false;

		IntactIce.SetActorHiddenInGame(true);
		IntactIce.SetActorEnableCollision(false);
		
		BrokenIce.SetActorHiddenInGame(false);
		BrokenIce.SetActorEnableCollision(true);
		return true;
	}

	UFUNCTION()
	void ApplyCustomAnimInstancesZoe(USkeletalMeshComponent SkelMesh0)
	{
		if(SkelMesh0 != nullptr)
			SkelMesh0.SetAnimClass(ShapeShiftABP);

		Game::Zoe.Mesh.SetAnimClass(ShapeShiftABP);
	}

	UFUNCTION()
	void ResetAllAnimInstancesZoe()
	{
		Game::Zoe.Mesh.SetAnimClass(DefaultABP);
	}

	UFUNCTION()
	void StartVerticalSection()
	{
		Game::Mio.ClearGameplayPerspectiveMode(this);
		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::ManualViews);

		TArray<FHazeManualView> ActiveViews;

		// Mio's view
		{
			FHazeManualView View;
			View.TopLeft.X = 0.0;
			View.TopLeft.Y = 0.5;
			View.BottomRight.X = 1.0;
			View.BottomRight.Y = 1.0;
			ActiveViews.Add(View);
		}

		// Zoe's view
		{
			FHazeManualView View;
			View.TopLeft.X = 0.0;
			View.TopLeft.Y = 0.0;
			View.BottomRight.X = 1.0;
			View.BottomRight.Y = 0.5;
			ActiveViews.Add(View);
		}

		SceneView::SetManualViews(ActiveViews);
	}
}