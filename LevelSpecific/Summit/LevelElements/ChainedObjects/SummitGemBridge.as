class ASummitGemBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp )
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ASummitNightQueenGem Gem;

	UPROPERTY(DefaultComponent)
	UBoxComponent HitCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsWeightComponent WeightComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	bool bKnocked;

	UPROPERTY(EditAnywhere)
	float ChainDropRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeightComp.AddDisabler(this);
		if(Gem != nullptr)
			Gem.OnSummitGemDestroyed.AddUFunction(this, n"OnGemDestroyed");		
					 
	}

	UFUNCTION()
	private void OnGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
	//		RotateComp.ConstrainAngleMax = ChainDropRotation;
			WeightComp.RemoveDisabler(this); 
		//	ForceKnock();
	}

	UFUNCTION()
	void ForceKnock()
	{
		if (bKnocked)
			return;

		bKnocked = true;
		WeightComp.RemoveDisabler(this); 
		Game::Zoe.PlayCameraShake(CamShake,this,10.0);
		if(Gem == nullptr)
			RotateComp.ConstrainAngleMax = ChainDropRotation;
		
	}

}