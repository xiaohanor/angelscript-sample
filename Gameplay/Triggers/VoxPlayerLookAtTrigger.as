class AVoxPlayerLookAtTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "VoxSpeaker";
#endif

	UPROPERTY(DefaultComponent, ShowOnActor)
	UVoxTriggerComponent VoxTriggerComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UPlayerLookAtTriggerComponent LookAtTrigger;
	default LookAtTrigger.ReplicationType = EPlayerLookAtTriggerReplication::Local;

	// Whether the trigger should ignore networking and only trigger locally
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "HazeVox", AdvancedDisplay)
	bool bTriggerLocally = false;

	// If true, this will only trigger if both players are looking at the LookAtTrigger
	UPROPERTY(EditAnywhere, Category = "HazeVox")
	bool bBothPlayerTrigger = false;

	UPROPERTY(Category = "HazeVox")
	FPlayerLookAtEvent OnBeginLookAt;

	UPROPERTY(Category = "HazeVox")
	FPlayerLookAtEvent OnEndLookAt;

	UPROPERTY(Category = "HazeVox")
	FVoxTriggerEvent OnTriggered;

	private TArray<AHazePlayerCharacter> LookingActors;
	private bool bIsControlSideOnly = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Force network type to local since we network in this actor
		LookAtTrigger.ReplicationType = EPlayerLookAtTriggerReplication::Local;

		LookAtTrigger.OnBeginLookAt.AddUFunction(this, n"BeginLookAt");
		LookAtTrigger.OnEndLookAt.AddUFunction(this, n"EndLookAt");

		VoxTriggerComponent.OnVoxAssetTriggered.AddUFunction(this, n"OnComponentTriggered");
	}

	UFUNCTION()
	void OnComponentTriggered(AHazeActor Player)
	{
		OnTriggered.Broadcast(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void BeginLookAt(AHazePlayerCharacter Player)
	{
		UpdateIsControlSide();
		if (bIsControlSideOnly)
		{
			if (!HasControl())
				return;
		}
		else
		{
			if (!Player.HasControl() && !bTriggerLocally)
				return;
		}

		if (bTriggerLocally || bIsControlSideOnly)
			LocalBeginLookAt(Player);
		else
			CrumbBeginLookAt(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void EndLookAt(AHazePlayerCharacter Player)
	{
		UpdateIsControlSide();
		if (bIsControlSideOnly)
		{
			if (!HasControl())
				return;
		}
		else
		{
			if (!Player.HasControl() && !bTriggerLocally)
				return;
		}

		if (bTriggerLocally || bIsControlSideOnly)
			LocalEndLookAt(Player);
		else
			CrumbEndLookAt(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbBeginLookAt(AHazePlayerCharacter Player)
	{
		LocalBeginLookAt(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbEndLookAt(AHazePlayerCharacter Player)
	{
		LocalEndLookAt(Player);
	}

	private void LocalBeginLookAt(AHazePlayerCharacter Player)
	{
		OnBeginLookAt.Broadcast(Player);
		LookingActors.AddUnique(Player);

		if (bBothPlayerTrigger)
		{
			if (LookingActors.Num() > 1)
				VoxTriggerComponent.OnStarted(LookingActors[0], bIsControlSideOnly);
		}
		else
		{
			VoxTriggerComponent.OnStarted(Player, bIsControlSideOnly);
		}
	}

	private void LocalEndLookAt(AHazePlayerCharacter Player)
	{
		OnEndLookAt.Broadcast(Player);
		LookingActors.Remove(Player);

		if (bBothPlayerTrigger)
		{
			VoxTriggerComponent.OnEnded();
		}
		else // !bBothPlayerTrigger
		{
			if (LookingActors.Num() == 0)
				VoxTriggerComponent.OnEnded();
		}
	}

	private void UpdateIsControlSide()
	{
		bIsControlSideOnly = EvaluateIsControlSideOnly();
	}

	private bool EvaluateIsControlSideOnly() const
	{
		if (bTriggerLocally)
			return false;

		if (VoxTriggerComponent.TimeInTrigger > 0.0)
			return true;

		const bool bTriggerForMio = LookAtTrigger.Players == EHazeSelectPlayer::Both || LookAtTrigger.Players == EHazeSelectPlayer::Mio;
		if (VoxTriggerComponent.MioVoxAsset != nullptr && bTriggerForMio)
			return true;

		const bool bTriggerForZoe = LookAtTrigger.Players == EHazeSelectPlayer::Both || LookAtTrigger.Players == EHazeSelectPlayer::Zoe;
		if (VoxTriggerComponent.ZoeVoxAsset != nullptr && bTriggerForZoe)
			return true;

		return false;
	}
}

class UVoxPlayerLookAtTriggerDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = AVoxPlayerLookAtTrigger;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		// Hide network settings since LookAtTrigger ReplicationType can't be changed
		HideCategory(n"Network");
	}
}
