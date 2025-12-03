class ASummitchainedAndRollableBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp )
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	ANightQueenChain Chain;

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
	bool bUseRoll = true;

	UPROPERTY(EditAnywhere)
	float ChainDropRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeightComp.AddDisabler(this);
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"HitByRoll");
		if(Chain != nullptr)
			Chain.OnNightQueenMetalMelted.AddUFunction(this, n"OnMetalMelted");	
					 
	}

	UFUNCTION()
	private void HitByRoll(FRollParams Params)
	{
		if (!bUseRoll)
			return;
		
		ForceKnock();
	}

	UFUNCTION()
	private void OnMetalMelted()
	{
		RotateComp.ConstrainAngleMax = ChainDropRotation;
	}

	UFUNCTION()
	void ForceKnock()
	{
		if (bKnocked)
			return;

		bKnocked = true;
		WeightComp.RemoveDisabler(this); 
		Game::Zoe.PlayCameraShake(CamShake,this,10.0);
		if(Chain == nullptr)
			RotateComp.ConstrainAngleMax = ChainDropRotation;
	}
}