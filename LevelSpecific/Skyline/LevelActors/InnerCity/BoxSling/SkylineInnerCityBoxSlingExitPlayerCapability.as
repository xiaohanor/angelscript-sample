asset SkylineInnerCityBoxSlingExitPlayerSheet of UHazeCapabilitySheet
{
	//Capabilities.Add(USkylineInnerCityBoxSlingExitPlayerCapability);
};

class USkylineInnerCityBoxSlingExitPlayerCapability : UHazePlayerCapability
{
	USkylineInnerCityBoxSlingPlayerComponent BoxedComp;
	float AllowExitDelay = 0.3;
	bool bPromptActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BoxedComp = USkylineInnerCityBoxSlingPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BoxedComp.bIsBoxed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BoxedComp.bIsBoxed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bPromptActive)
			return;

		if (!BoxedComp.bCanExit && bPromptActive)
		{
			bPromptActive = false;
			Player.RemoveCancelPromptByInstigator(this);
		}

		if (BoxedComp.bCanExit && IsActioning(BoxedComp.PromptExit.Action) && HasControl())
		{
			if (BoxedComp.bIsBoxed && BoxedComp.Boxy != nullptr && BoxedComp.bCanExit)
				CrumbExitBox();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbExitBox()
	{
		Player.ApplyBlendToCurrentView(2.0);
		AActor BoxActor = BoxedComp.Boxy;
		BoxedComp.Boxy.UnboxPlayer();
		Player.TeleportActor(BoxActor.ActorLocation - BoxActor.ActorForwardVector * 200.0, BoxActor.ActorRotation, this, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bPromptActive = false;
		Timer::SetTimer(this, n"DelayedTutorial", AllowExitDelay);
	}

	UFUNCTION()
	void DelayedTutorial()
	{
		
		Player.ShowCancelPromptWithText(this, BoxedComp.Boxy.CustomCancelText);
		//Player.ShowTutorialPrompt(BoxedComp.PromptExit, this);
		bPromptActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (bPromptActive)
			Player.RemoveCancelPromptByInstigator(this);
	}
};