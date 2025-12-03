event void FSummitClimbTutorialShow();

class ASummitFreeFormClimbTutorial : AHazeActor
{
	UPROPERTY()
	FSummitClimbTutorialShow OnActivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitFreeFormClimbTutorialCapability");

	UPROPERTY()
	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}

	UFUNCTION()
	void Activate()
	{
		if (bIsActive)
			return;

		bIsActive = true;
		OnActivated.Broadcast();
		BP_Activate();
	}

	UFUNCTION()
	void Reverse()
	{
		bIsActive = false;
		BP_Reverse();
	}
	
	UFUNCTION(BlueprintEvent)
	void BP_Activate() 
    {
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_Reverse() 
    {
		
	}

}

class USummitFreeFormClimbTutorialCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UPlayerTailBabyDragonComponent DragonComp;
	UPlayerMovementComponent MioMovementComp;

	ASummitFreeFormClimbTutorial BackpackInteractActor;

	bool bIsHanging;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BackpackInteractActor = Cast<ASummitFreeFormClimbTutorial>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (DragonComp == nullptr)
			DragonComp = UPlayerTailBabyDragonComponent::Get(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DragonComp == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (DragonComp == nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		if (DragonComp.ClimbState == ETailBabyDragonClimbState::Hang
			&& DragonComp.AttachmentComponent != nullptr)
		{
			bIsHanging = true;
			BackpackInteractActor.Activate();
		} else {
			bIsHanging = false;
			BackpackInteractActor.Reverse();
		}

		// if (BackpackInteractActor.bIsActive && !bIsHanging)
		// {
		// 	// BackpackInteractActor.Reverse();
		// }

	}
};