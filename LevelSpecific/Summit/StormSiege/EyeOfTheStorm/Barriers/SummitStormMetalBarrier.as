class ASummitStormMetalBarrier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshCompBody;
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshCompTower;

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY(EditAnywhere)
	TArray<ASummitStormMetalBarrier> SmallerBarriers;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	TArray<UStaticMeshComponent> MeshComps;

	int MaxHits = 1;
	int CurrentHits;

	bool bWasHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this ,n"OnAcidHit");
		GetComponentsByClass(MeshComps);

		if (SmallerBarriers.Num() > 0)
			MaxHits = SmallerBarriers.Num();
		else
			CurrentHits = 1;
	}

	UFUNCTION()
	void OnAcidHit(FAcidHit Hit)
	{
		if (CurrentHits < MaxHits - 1)
		{
			CurrentHits++;
			SmallerBarriers[CurrentHits].OnAcidHit(Hit);
			return;
		}

		if (bWasHit)
			return;

		bWasHit = true;

		for (UStaticMeshComponent Comp : MeshComps)
		{
			if (Comp == MeshCompBody || Comp == MeshCompTower)
				continue;
			
			Comp.SetSimulatePhysics(true);
			Comp.AddImpulse((Comp.WorldLocation - ActorLocation).GetSafeNormal() * 15000.0);
		}

		MeshCompBody.SetHiddenInGame(true);
		MeshCompTower.SetHiddenInGame(true);

		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000.0, 20000.0);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000.0, 20000.0);
	}
}