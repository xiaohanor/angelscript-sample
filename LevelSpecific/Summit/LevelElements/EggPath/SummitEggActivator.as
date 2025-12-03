event void FSummitEggActivatorSignature();

class ASummitEggActivator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger Trigger;

	UPROPERTY(EditAnywhere)
	ASummitEggActivator Sibling;

	UPROPERTY(EditAnywhere)
	bool bManager;

	bool bIsParent;
	bool bIsActivated;
	bool bIsPressured;
	bool bIsMioOn;
	bool bIsZoeOn;
	
	UPROPERTY()
	FSummitEggHolderSignature OnPressured;

	UPROPERTY()
	FSummitEggHolderSignature OnActivated;

	UPROPERTY()
	FSummitEggHolderSignature OnDeactivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");	
		Trigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");	
	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (bIsActivated)
			return;

		USummitEggBackpackComponent PlayerBackpackComp = USummitEggBackpackComponent::Get(Player);
		// Player doesn't have a backpack comp
		if(PlayerBackpackComp == nullptr)
			return;
		if(!PlayerBackpackComp.bIsHoldingEgg)
			return;

		if(Player.IsMio())
			bIsMioOn = true;
		else
			bIsZoeOn = true;
		
		if (bIsPressured)
			return;

		bIsPressured = true;
		OnPressured.Broadcast();
		BP_Pressured();

		if (Sibling.bIsPressured)
		{
			bIsActivated = true;
			Sibling.bIsActivated = true;
			BP_Activated();
			Sibling.BP_Activated();
			if (bManager)
				OnActivated.Broadcast();
			else
				Sibling.OnActivated.Broadcast();
		}

	}

	UFUNCTION()
	void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		if (bIsActivated)
			return;

		if (Player == Game::GetMio())
			bIsMioOn = false;
		if (Player == Game::GetZoe())
			bIsZoeOn = false;

		if (!bIsMioOn && !bIsZoeOn)
		{
			bIsPressured = false;
			OnDeactivated.Broadcast();
			BP_Deactivated();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activated() {}
	
	UFUNCTION(BlueprintEvent)
	void BP_Pressured() {}

	UFUNCTION(BlueprintEvent)
	void BP_Deactivated() {}
};