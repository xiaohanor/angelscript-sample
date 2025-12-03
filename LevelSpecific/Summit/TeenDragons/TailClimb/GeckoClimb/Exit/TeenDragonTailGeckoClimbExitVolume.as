event void FTeenDragonTriggerEvent(AHazePlayerCharacter DragonRider);

UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class ATeenDragonTailGeckoClimbExitVolume : AVolume
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default Shape::SetVolumeBrushColor(this, FLinearColor(1.00, 0.00, 0.00));
	default BrushComponent.SetCollisionProfileName(n"Trigger");

	// Whether the trigger should ignore networking and only trigger locally
    UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Exit Trigger", AdvancedDisplay)
	bool bTriggerLocally = false;

	UPROPERTY(DefaultComponent, BlueprintReadOnly, ShowOnActor)
	UHazeCameraSettingsComponent CameraSettings;
	default CameraSettings.Player = EHazeSelectPlayer::Zoe;

    UPROPERTY(Category = "Exit Trigger")
    FTeenDragonTriggerEvent OnDragonEnter;

    UPROPERTY(Category = "Exit Trigger")
    FTeenDragonTriggerEvent OnDragonLeave;

	private TArray<FInstigator> DisableInstigators;
	private bool bDragonInsideTrigger;
	private UHazeCameraUserComponent CurrentUserComponent;

    UFUNCTION(Category = "Exit Trigger")
    void EnableExitTrigger(FInstigator Instigator)
    {
		DisableInstigators.Remove(Instigator);
        UpdateAlreadyInsideActors();
    }

    UFUNCTION(Category = "Exit Trigger")
    void DisableExitTrigger(FInstigator Instigator)
    {
		DisableInstigators.AddUnique(Instigator);
        UpdateAlreadyInsideActors();
    }

	// bool IsTailDragon(ATeenDragon Dragon) const
	// {
	// 	return !Dragon.PlayerDragonComp.IsAcidDragon();
	// }

	UFUNCTION(BlueprintOverride)
	private void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CameraSettings.Update(CurrentUserComponent);
	}

	UFUNCTION()
	private void OnClimbStartedOrStoppedInsideVolume(FTeenDragonTailClimbParams Params)
	{
		UpdateAlreadyInsideActors();
	}

	UFUNCTION()
	private void EnableCancelPrompt(FTeenDragonTailClimbParams Params)
	{
		Game::Zoe.ShowCancelPrompt(this);
	}

	UFUNCTION()
	private void DisableCancelPrompt(FTeenDragonTailClimbParams Params)
	{
		Game::Zoe.RemoveCancelPromptByInstigator(this);
	}


	// Manually update which actors are inside, we may have missed overlap events due to disable or streaming
	private void UpdateAlreadyInsideActors()
	{
		TArray<AActor> Overlaps;
		GetOverlappingActors(Overlaps, AHazeActor);

		for (auto Actor : Overlaps)
		{
			if (DisableInstigators.Num() == 0)
				ReceiveBeginOverlap(Actor);
			else
				ReceiveEndOverlap(Actor);
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {
		ReceiveBeginOverlap(OtherActor);
	}

    private void ReceiveBeginOverlap(AActor OtherActor)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		auto DragonComp = UPlayerTeenDragonComponent::Get(Player);
		if (DragonComp == nullptr)
			return;
		if (DisableInstigators.Num() != 0)
			return;
		if (DragonComp.IsAcidDragon())
			return;
		if (!Player.HasControl() && !bTriggerLocally)
			return;
		
		auto ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		auto TailDragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		if(!TailDragonComp.IsClimbing())
		{
			ClimbComp.OnClimbStarted.UnbindObject(this);
			ClimbComp.OnClimbStarted.AddUFunction(this, n"OnClimbStartedOrStoppedInsideVolume");
			ClimbComp.OnClimbStarted.AddUFunction(this, n"EnableCancelPrompt");
			ClimbComp.OnClimbStopped.AddUFunction(this, n"DisableCancelPrompt");
			return;
		}
		else
		{
			ClimbComp.OnClimbStopped.UnbindObject(this);
			ClimbComp.OnClimbStopped.AddUFunction(this, n"OnClimbStartedOrStoppedInsideVolume");
			ClimbComp.OnClimbStopped.AddUFunction(this, n"DisableCancelPrompt");
			ClimbComp.OnClimbStarted.AddUFunction(this, n"EnableCancelPrompt");
		}

		if (!bDragonInsideTrigger)
		{
			bDragonInsideTrigger = true;
			if (bTriggerLocally)
				Internal_OnDragonEnter(Player);
			else
				CrumbDragonEnter(Player);
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorEndOverlap(AActor OtherActor)
    {
		ReceiveEndOverlap(OtherActor);
	}

    private void ReceiveEndOverlap(AActor OtherActor)
    {
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		auto DragonComp = UPlayerTeenDragonComponent::Get(Player);
		if (DragonComp == nullptr)
			return;
		if (DisableInstigators.Num() != 0)
			return;
		if (DragonComp.IsAcidDragon())
			return;
		if (!Player.HasControl() && !bTriggerLocally)
			return;

		auto ClimbComp = UTeenDragonTailGeckoClimbComponent::Get(Player);
		ClimbComp.OnClimbStarted.UnbindObject(this);
		ClimbComp.OnClimbStopped.UnbindObject(this);

		if (bDragonInsideTrigger)
		{
			bDragonInsideTrigger = false;
			if (bTriggerLocally)
				Internal_OnDragonLeave(Player);
			else
				CrumbDragonLeave(Player);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDragonEnter(AHazePlayerCharacter Player)
	{
		Internal_OnDragonEnter(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbDragonLeave(AHazePlayerCharacter Player)
	{
		Internal_OnDragonLeave(Player);
	}

	private void Internal_OnDragonEnter(AHazePlayerCharacter Player)
	{
		OnDragonEnter.Broadcast(Player);
		CurrentUserComponent = UHazeCameraUserComponent::Get(Player);

		CameraSettings.Apply(CurrentUserComponent);
		if(CameraSettings.ShouldUpdate())
			SetActorTickEnabled(true);

		UTeenDragonTailGeckoClimbComponent::Get(Player).ExitVolumesInside.AddUnique(this);
		Game::Zoe.ShowCancelPrompt(this);
	}

	private void Internal_OnDragonLeave(AHazePlayerCharacter Dragon)
	{
		OnDragonLeave.Broadcast(Dragon);

		CameraSettings.Clear(CurrentUserComponent);
		SetActorTickEnabled(false);
		CurrentUserComponent = nullptr;

		UTeenDragonTailGeckoClimbComponent::Get(Dragon).ExitVolumesInside.Remove(this);
		Game::Zoe.RemoveCancelPromptByInstigator(this);
	}
}