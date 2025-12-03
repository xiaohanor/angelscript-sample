class ASanctuaryCutableDrawBridgeChain : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent UpperChainRootComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LowerChainRootComp;

	UPROPERTY(EditInstanceOnly)
	bool bLeftChain;

	UPROPERTY()
	FHazeTimeLike ChainFallTimeLike;
	default ChainFallTimeLike.UseSmoothCurveZeroToOne();
	default ChainFallTimeLike.Duration = 1.0;
	
	ASanctuaryCutableDrawBridge DrawBridgeActor;

	bool bCut = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		if (AttachParentActor != nullptr)
		{
			DrawBridgeActor = Cast<ASanctuaryCutableDrawBridge>(AttachParentActor);
		}

		ChainFallTimeLike.BindUpdate(this, n"ChainFallTimeLikeUpdate");
	}

	UFUNCTION()
	private void ChainFallTimeLikeUpdate(float CurrentValue)
	{
		LowerChainRootComp.SetRelativeScale3D(FVector(CurrentValue));
	}

	UFUNCTION()
	void Cut()
	{
		if(HasControl())
			CrumbCut();
	}

	UFUNCTION(CrumbFunction)
	void CrumbCut()
	{
		if (!bCut)
		{
			bCut = true;
			ChainFallTimeLike.Play();

			BP_SpawnCutChainVFX();
			
			if (DrawBridgeActor != nullptr)
			{
				DrawBridgeActor.ChainCut(bLeftChain);
				
				FSanctuaryCutableDrawBridgeChainSide Params;
				Params.bLeftChain = bLeftChain;
				USanctuaryCutableDrawBridgeEventHandler::Trigger_OnCutChain(this, Params);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_SpawnCutChainVFX(){}

	UFUNCTION()
	void MissCut()
	{
		if(HasControl())
			CrumbMissCut();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMissCut()
	{
		if (DrawBridgeActor != nullptr)
			DrawBridgeActor.MissCut();
	}

};