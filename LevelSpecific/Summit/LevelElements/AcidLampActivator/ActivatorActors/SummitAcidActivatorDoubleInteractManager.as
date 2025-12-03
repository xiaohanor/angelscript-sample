event void FOnSummitAcidActivatorDoubleInteractCompleted(); 

class ASummitAcidActivatorDoubleInteractManager : AHazeActor
{
	UPROPERTY()
	FOnSummitAcidActivatorDoubleInteractCompleted OnSummitAcidActivatorDoubleInteractCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(8.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<ASummitAcidActivatorActor> AcidActivators;

	bool InteractionCompleted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ASummitAcidActivatorActor Activator : AcidActivators)
		{
			Activator.OnAcidActorActivated.AddUFunction(this, n"OnAcidActorActivated");
			Activator.OnAcidActorDeactivated.AddUFunction(this, n"OnAcidActorDeactivated");
		}

		SetActorControlSide(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())
			return;
		
		if (InteractionCompleted)
			return;

		int AmountActive = 0;

		for (ASummitAcidActivatorActor Activator : AcidActivators)
		{
			if (Activator.IsActivatorActive())
				AmountActive++;
		}

		if (AmountActive == 2)
		{
			CrumbDoubleInteractCompleted();
		}
	}

	UFUNCTION()
	private void OnAcidActorActivated()
	{
	}

	UFUNCTION()
	private void OnAcidActorDeactivated()
	{
	}

	UFUNCTION(CrumbFunction)
	void CrumbDoubleInteractCompleted()
	{
		if (InteractionCompleted)
			return;
		
		InteractionCompleted = true;
		OnSummitAcidActivatorDoubleInteractCompleted.Broadcast();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		for (ASummitAcidActivatorActor Activator : AcidActivators)
		{
			Debug::DrawDebugLine(ActorLocation, Activator.ActorLocation, FLinearColor::Green, 10.0);
		}	
	}
	#endif
};