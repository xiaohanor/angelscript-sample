class AMeltdownScreenWalkMineCart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.SpringStrength = 10.0;
	default TranslateComp.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromZoeControl;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsWeightComponent Weight;

	UPROPERTY(DefaultComponent, Attach = Weight)
	UStaticMeshComponent MineCart;

	UPROPERTY(EditAnywhere)
	FVector Impulse;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		ResponseComp.OnJumpTrigger.AddUFunction(this, n"OnActivated");
	}

	UFUNCTION()
	private void OnActivated()
	{
		OnJumped();
		TranslateComp.ApplyImpulse(
		ActorLocation, FVector(Impulse)
		);
	}

	UFUNCTION(BlueprintEvent)
	void OnJumped()
	{

	}

};