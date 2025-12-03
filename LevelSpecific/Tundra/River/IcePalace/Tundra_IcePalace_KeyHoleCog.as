event void FOnKeyHoleCogComplete();

class ATundra_IcePalace_KeyHoleCog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	USceneComponent WidgetPositionComp;

	bool bIsEnabled = false;

	FOnButtonMashCompleted OnCompleted;
	
	UPROPERTY()
	FOnKeyHoleCogComplete OnKeyHoleCogComplete;

	UPROPERTY()
	FHazeTimeLike RevealCogTimelike;
	default RevealCogTimelike.Duration = 1;
	
	float RevealCogTimelikeDuration = 0.25;

	bool bIsButtonMashing = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"InteractionStart");
		OnCompleted.BindUFunction(this, n"OnButtonMashCompleted");
		RevealCogTimelike.BindUpdate(this, n"RevealCogTimelikeUpdate");
		RevealCogTimelike.PlayRate = 1 / RevealCogTimelikeDuration;

		InteractionComp.Disable(this);
	}

	UFUNCTION()
	private void RevealCogTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector(0, 0, -90), FVector::ZeroVector, CurrentValue));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsButtonMashing)
			return;
		
		MeshRoot.AddLocalRotation(FRotator(20, 0, 0));
	}

	UFUNCTION()
	private void InteractionStart(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		FButtonMashSettings Settings;
		Settings.Duration = 4;
		Settings.bShowButtonMashWidget = true;
		Settings.WidgetAttachComponent = WidgetPositionComp;
		Game::GetZoe().StartButtonMash(Settings, this, OnCompleted);
		bIsButtonMashing = true;
	}
	
	UFUNCTION()
	private void OnButtonMashCompleted()
	{
		bIsButtonMashing = false;
		Game::GetZoe().StopButtonMash(this);
		InteractionComp.DisableForPlayer(Game::GetZoe(), this);
		InteractionComp.KickAnyPlayerOutOfInteraction();
		OnKeyHoleCogComplete.Broadcast();
	}

	void EnableKeyHoleCogInteraction(bool bEnable)
	{
		if(!bIsEnabled && bEnable)
		{
			bIsEnabled = true;
			InteractionComp.Enable(this);
			RevealCogTimelike.PlayFromStart();
		}
		else if(bIsEnabled && !bEnable)
		{
			bIsEnabled = false;
			InteractionComp.Disable(this);
		}
	}
};