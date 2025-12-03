USTRUCT()
struct FSanctuaryCentipedeBurningEventEventData
{
	UPROPERTY()
	float BurningAmount;
}

USTRUCT()
struct FSanctuaryCentipedeGateChainGrabbedData
{
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	bool bOtherPlayerIsHoldingChain = false;
}

USTRUCT()
struct FSanctuaryCentipedeGateChainReleasedData
{
	UPROPERTY()
	float ProgressWhenReleased = 0.0;
	UPROPERTY()
	AHazePlayerCharacter Player;
	UPROPERTY()
	bool bOtherPlayerIsHoldingChain = false;
}

USTRUCT()
struct FSanctuaryCentipedeBiteEventData
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	UCentipedeBiteResponseComponent BiteResponse;

	FSanctuaryCentipedeBiteEventData(AHazePlayerCharacter InPlayer, UCentipedeBiteResponseComponent InBiteResponse)
	{
		Player = InPlayer;
		BiteResponse = InBiteResponse;
	}
}

USTRUCT()
struct FSanctuaryCentipedeSwingpointEventData
{
	UPROPERTY()
	UCentipedeSwingPointComponent SwingPointComponent;

	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	float DistanceToOtherPlayer;

	FSanctuaryCentipedeSwingpointEventData(AHazePlayerCharacter InPlayer, float Distance)
	{
		Player = InPlayer;
		DistanceToOtherPlayer = Distance;
	}
}

class UCentipedeEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	UNiagaraSystem BiteVFX;

	UPROPERTY()
	UNiagaraSystem BiteWithTargetVFX;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> BurningWidgetClass;
	UHazeUserWidget BurningWidgetInstance = nullptr;

	AHazePlayerCharacter PlayerOwner;
	UPlayerCentipedeComponent CentipedeComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBiteAnticipationStarted(FCentipedeBiteEventParams Params) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBiteAnticipationStopped(FCentipedeBiteEventParams Params) {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBiteStarted(FSanctuaryCentipedeBiteEventData Data)
	{
		FName AttachBone = CentipedeComponent.GetMeshHeadBoneName();
		auto NiagaraComponent = Niagara::SpawnOneShotNiagaraSystemAttached(BiteVFX, CentipedeComponent.Centipede.Mesh, AttachBone);
		if (NiagaraComponent != nullptr)
		{
			float DirectionMultiplier = CentipedeComponent.IsHeadPlayer() ? 1.0 : -1.0;
			NiagaraComponent.SetRelativeLocation(FVector::ForwardVector * 200.0 * DirectionMultiplier);
		}
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBiteStopped(FSanctuaryCentipedeBiteEventData Data)
	{		
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBiteResponseComponentBitten()
	{
		FName AttachBone = CentipedeComponent.GetMeshHeadBoneName();
		auto NiagaraComponent = Niagara::SpawnOneShotNiagaraSystemAttached(BiteWithTargetVFX, CentipedeComponent.Centipede.Mesh, AttachBone);
		if (NiagaraComponent != nullptr)
		{
			float DirectionMultiplier = CentipedeComponent.IsHeadPlayer() ? 1.0 : -1.0;
			NiagaraComponent.SetRelativeLocation(FVector::ForwardVector * 200.0 * DirectionMultiplier);
		}
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGateChainGrabbed(FSanctuaryCentipedeGateChainGrabbedData Params) 
	{
		DevPrintStringEvent("Centipede", "OnGateChainGrabbed: " + Params.bOtherPlayerIsHoldingChain);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGateChainReleased(FSanctuaryCentipedeGateChainReleasedData Params) 
	{
		DevPrintStringEvent("Centipede", "OnGateChainReleased: " + Params.ProgressWhenReleased + " , " + Params.bOtherPlayerIsHoldingChain);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttachWaterOutlet(FCentipedeWaterOutletEventParams Params) 
	{
		DevPrintStringEvent("Centipede", "OnAttachWaterOutlet");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDetachWaterOutlet(FCentipedeWaterOutletEventParams Params) 
	{
		DevPrintStringEvent("Centipede", "OnDetachWaterOutlet");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingPointAttached(FSanctuaryCentipedeSwingpointEventData Params) 
	{
		DevPrintStringEvent("Centipede", "OnSwingPointAttached");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingPointIdling(FSanctuaryCentipedeBiteEventData Params) 
	{
		DevPrintStringEvent("Centipede", "OnSwingPointIdling");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingPointReleased(FSanctuaryCentipedeSwingpointEventData Params) 
	{
		DevPrintStringEvent("Centipede", "OnDetachSwingpoint");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCentipedeStretchStart() 
	{
		DevPrintStringEvent("Centipede", "OnCentipedeStretchStart");
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCentipedeStretchStop() 
	{
		DevPrintStringEvent("Centipede", "OnCentipedeStretchStop");
	}

	// Centipede.LavaIntoleranceComponent.BurningAlpha -> to fetch how much we're burning
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBurningStarted() 
	{
		DevPrintStringEvent("Centipede", "OnBurningStarted");
	}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBurningStopped() 
	{
		DevPrintStringEvent("Centipede", "OnBurningStopped");
	}
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBurningDeath() 
	{

	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode)) // DEPRECATED, not called
	void OnUpdateBurning(FSanctuaryCentipedeBurningEventEventData BurningData) {}
}