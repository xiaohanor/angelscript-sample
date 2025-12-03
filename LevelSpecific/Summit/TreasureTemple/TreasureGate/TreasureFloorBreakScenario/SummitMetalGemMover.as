class ASummitMetalGemMover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DustParticles;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = EndComp)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AttachComp.RelativeLocation = Math::VInterpConstantTo(AttachComp.RelativeLocation, EndComp.RelativeLocation, DeltaSeconds, 2800.0);
		if ((AttachComp.RelativeLocation - EndComp.RelativeLocation).Size() < 1.0)
		{
			SetActorTickEnabled(false);
			FSummitMetalGemMoveParams Params;
			Params.Location = ActorLocation;
			USummitMetalGemMoverEffectHandler::Trigger_MetalGemMoveStopped(this, Params);
		}
	}

	UFUNCTION()
	void ActivateBarrierMove()
	{
		//Effects
		FSummitMetalGemMoveParams Params;
		Params.Location = ActorLocation;
		USummitMetalGemMoverEffectHandler::Trigger_MetalGemMoveActivated(this, Params);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void SetEndState()
	{
		AttachComp.RelativeLocation = EndComp.RelativeLocation;
	}
}