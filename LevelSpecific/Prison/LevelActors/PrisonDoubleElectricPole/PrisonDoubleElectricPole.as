event void FPrisonDoubleElectricPoleOnActivated();

UCLASS(Abstract)
class APrisonDoubleElectricPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LightMeshComp;

	UPROPERTY(EditInstanceOnly, Category = "Buttons")
	TArray<APrisonDoubleElectricPoleButton> Buttons;

	UPROPERTY(EditInstanceOnly, Category = "Hazards")
	TArray<APrisonDoubleElectricPoleHazard> Hazards;

	UPROPERTY(EditAnywhere, Category = "Hazards")
	bool bResetOnExitButton = false;

	UPROPERTY()
	FPrisonDoubleElectricPoleOnActivated OnActivated;

	int ActivatedButtons = 0;
	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Button : Buttons)
		{
			Button.OnEnter.AddUFunction(this, n"OnEnterButton");
			Button.OnExit.AddUFunction(this, n"OnExitButton");
		}
	}

	UFUNCTION(BlueprintCallable)
	void Activate()
	{
		if(bActivated)
			return;

		bActivated = true;

		for(auto Hazard : Hazards)
		{
			Hazard.Deactivate();
		}

		BP_OnActivated();
		OnActivated.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void Deactivate()
	{
		if(!bActivated)
			return;
		
		bActivated = false;

		BP_OnDeactivated();

		for(auto Hazard : Hazards)
		{
			Hazard.Activate();
		}
	}

	UFUNCTION()
	private void OnEnterButton(APrisonDoubleElectricPoleButton Button, AHazePlayerCharacter Player, bool bFirst)
	{
		if(!bFirst)
			return;

		if(!HasControl())
			return;

		CrumbOnEnter();
	}

	UFUNCTION()
	private void OnExitButton(APrisonDoubleElectricPoleButton Button, AHazePlayerCharacter Player, bool bLast)
	{
		if(!bLast)
			return;

		if(!HasControl())
			return;

		CrumbOnExit();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnEnter()
	{
		ActivatedButtons++;

		if(ActivatedButtons == Buttons.Num())
		{
			Activate();
		}
		else if(ActivatedButtons == 1)
		{
			BP_OnSemiActivated();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnExit()
	{
		ActivatedButtons--;

		if(bResetOnExitButton && ActivatedButtons == 0)
			Deactivate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnActivated()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnSemiActivated()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDeactivated()
	{
	}
};