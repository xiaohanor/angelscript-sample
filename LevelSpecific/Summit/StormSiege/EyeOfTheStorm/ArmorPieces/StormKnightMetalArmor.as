class AStormKnightMetalArmor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
	#endif

	UPROPERTY(DefaultComponent)
	UAttachOwnerToParentComponent AttachComp;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	TArray<UStaticMeshComponent> MeshComps;

	bool bWasHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this ,n"OnAcidHit");
		GetComponentsByClass(MeshComps);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		if (bWasHit)
			return;

		bWasHit = true;

		for (UStaticMeshComponent Comp : MeshComps)
		{
			Comp.SetSimulatePhysics(true);
			Comp.AddImpulse((Comp.WorldLocation - ActorLocation).GetSafeNormal() * 15000.0);
		}

		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000.0, 20000.0);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 5000.0, 20000.0);
	}
}