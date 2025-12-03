event void FOnCrystalPillarKnocked();

class USummitPathCrystalComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	FHazeShapeSettings PathCrystalZoneShapeSetting;
}

class ASummitPathCrystalPillar : AHazeActor
{
	UPROPERTY()
	FOnCrystalPillarKnocked OnCrystalPillarKnocked;

    UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	USummitPathCrystalComponent PathCrystalControlZone;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MuralRoot;

	UPROPERTY(DefaultComponent, Attach = MuralRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

    UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitPathCrystal> PathCrystalPieces; // For editor visualisation only!
    bool bBeingEdited = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	void Activate()
	{
		OnCrystalPillarKnocked.Broadcast();
		Game::Mio.PlayCameraShake(CameraShake, this, 1.0);
		Game::Zoe.PlayCameraShake(CameraShake, this, 1.0);

        for (auto CrystalPiece : PathCrystalPieces)
		{
            CrystalPiece.Activate();
		}
	}
	

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		Activate();
		BP_Activate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {
		
	}

    UFUNCTION(CallInEditor, Category = "Setup")
	void AddCrystalInZone()
	{
		TArray<ASummitPathCrystal> CrystalActors = Editor::GetAllEditorWorldActorsOfClass(ASummitPathCrystal);

		for(auto CrystalActor : CrystalActors)
		{
			if(PathCrystalControlZone.PathCrystalZoneShapeSetting.IsPointInside(PathCrystalControlZone.WorldTransform, CrystalActor.ActorLocation))
			{
				auto Crystal = Cast<ASummitPathCrystal>(CrystalActor);
				PathCrystalPieces.AddUnique(Crystal);
			}
		}
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void SetCrystalInZone()
	{
		TArray<ASummitPathCrystal> CrystalActors = Editor::GetAllEditorWorldActorsOfClass(ASummitPathCrystal);

		PathCrystalPieces.Empty();
		for(auto CrystalActor : CrystalActors)
		{
			if(PathCrystalControlZone.PathCrystalZoneShapeSetting.IsPointInside(PathCrystalControlZone.WorldTransform, CrystalActor.ActorLocation))
			{
				auto Crystal = Cast<ASummitPathCrystal>(CrystalActor);
				PathCrystalPieces.AddUnique(Crystal);
			}
		}
	}

    UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// For syncing lists in crystal in editor

		if(bBeingEdited)
			return;
		
		// Remove duplicates of crystal pieces when changing the reference
		for(int i = PathCrystalPieces.Num() - 1; i >= 0; i--)
		{
			auto Crystal = PathCrystalPieces[i];

			if(Crystal == nullptr)
				continue;

			for(int j = i - 1; j >= 0; j--)
			{
				auto OtherCrystal = PathCrystalPieces[j];

				if(OtherCrystal == nullptr)
					continue;

				if(Crystal == OtherCrystal)
				{
					PathCrystalPieces.RemoveSingleSwap(OtherCrystal);
				}
			}
		}
	}

}