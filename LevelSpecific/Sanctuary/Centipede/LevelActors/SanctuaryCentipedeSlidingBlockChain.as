event void FSanctuaryCentipedeSlidingBlockChainSignature(ASanctuaryCentipedeSlidingBlockChain BrokenChain);

class ASanctuaryCentipedeSlidingBlockChain : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ChainHoleRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCentipedeBiteResponseComponent BiteComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent ChainTranslateComp;

	UPROPERTY(DefaultComponent, Attach = ChainTranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY()
	FSanctuaryCentipedeSlidingBlockChainSignature OnBreak;

	bool bBroken = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BiteComp.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBiteStart");
		ChainHoleRoot.DetachFromParent(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bBroken)
		{
			FRotator Rotation = (ChainHoleRoot.WorldLocation - ChainTranslateComp.WorldLocation).GetSafeNormal().Rotation();
			ChainTranslateComp.SetWorldRotation(Rotation);
		}
	}

	UFUNCTION()
	private void HandleBiteStart(FCentipedeBiteEventParams BiteParams)
	{
		BiteComp.Disable(this);
		Break();
	}

	private void Break()
	{
		bBroken = true;
		ForceComp.Force = FVector::ForwardVector * 6000.0;
		BP_Break();
		DetachFromActor(EDetachmentRule::KeepWorld);
		OnBreak.Broadcast(this);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Break(){}
};	