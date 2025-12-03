event void FOnSummitDebrisFallingGrappleComplete();

class ASummitDebrisFallingQTEManager : AHazeActor
{
	UPROPERTY()
	FOnSummitDebrisFallingGrappleComplete OnSummitDebrisFallingGrappleComplete;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(15));
#endif

	UPROPERTY(EditAnywhere)
	AActor StoneBeast;

	UPROPERTY(EditAnywhere)
	TArray<FName> BlockCapabilitiesTags;
	default BlockCapabilitiesTags.Add(CapabilityTags::GameplayAction);
	default BlockCapabilitiesTags.Add(CapabilityTags::MovementInput);
	default BlockCapabilitiesTags.Add(CapabilityTags::Movement);
	default BlockCapabilitiesTags.Add(CapabilityTags::Input);

	UPROPERTY()
	UHazeCapabilitySheet PlayerCapabilitySheet;

	FTimeDilationEffect TimeDilation;
	default TimeDilation.TimeDilation = 0.1;
	default TimeDilation.BlendInDurationInRealTime = 0.3;

	TPerPlayer<UDebrisFallingPlayerComponent> DebrisFallingComp;

	float Gravity = 500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		StoneBeast.ActorLocation += FVector(0,0,-Gravity) * DeltaSeconds;
		Gravity = Math::FInterpConstantTo(Gravity, 0.0, DeltaSeconds, 0.2);

		if (!HasControl())
			return;

		if (DebrisFallingComp[0].bPlayersHaveGrappled && DebrisFallingComp[1].bPlayersHaveGrappled)
		{
			CrumbFinishQTE();
		}
	}

	UFUNCTION()
	void StartQTE()
	{
		if (!HasControl())
			return;

		CrumbStartQTE();		
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbStartQTE()
	{
		ActivateSlowMo();
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbFinishQTE()
	{
		SetActorTickEnabled(false);
		DeactivateSlowMo();
		OnSummitDebrisFallingGrappleComplete.Broadcast();
	}

	void ActivateSlowMo()
	{
		TimeDilation::StartWorldTimeDilationEffect(TimeDilation, this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			for (FName CurrentName : BlockCapabilitiesTags)
			{
				Player.BlockCapabilities(CurrentName, this);
			}

			Player.StartCapabilitySheet(PlayerCapabilitySheet, this);

			DebrisFallingComp[Player] = UDebrisFallingPlayerComponent::Get(Player);
		}
	
		SetActorTickEnabled(true);
	}

	void DeactivateSlowMo()
	{
		TimeDilation::StopWorldTimeDilationEffect(this);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			for (FName CurrentName : BlockCapabilitiesTags)
			{
				Player.UnblockCapabilities(CurrentName, this);
			}

			Player.StopCapabilitySheet(PlayerCapabilitySheet, this);
		}	
	}
};