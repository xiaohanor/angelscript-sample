event void FGameShowArenaBombPickedUpEvent();

class AGameShowArenaBombHolder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh03;

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaBomb ConnectedBomb;

	UPROPERTY()
	FGameShowArenaBombPickedUpEvent OnBombPickedUp;

	UPROPERTY()
	FHazeTimeLike BombHolderTimelike;
	default BombHolderTimelike.Duration = 3;

	UPROPERTY(EditAnywhere)
	EHazePlayer HolderSpawnAtPlayer;

	FVector StartLoc = FVector(0, 0, 2000);
	FVector EndLoc = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ConnectedBomb.OnBombStartExploding.AddUFunction(this, n"OnBombExploded");
		ConnectedBomb.OnBombUnfrozen.AddUFunction(this, n"HandleBombUnfrozen");
		MeshRoot.SetRelativeLocation(StartLoc);
		SetActorHiddenInGame(true);

		BombHolderTimelike.BindUpdate(this, n"BombHolderTimelikeUpdate");
		BombHolderTimelike.BindFinished(this, n"BombHolderTimelikeFinished");
	}

	UFUNCTION()
	void OverrideHolderSpawnAtPlayer(EHazePlayer NewPlayer)
	{
		HolderSpawnAtPlayer = NewPlayer;
	}

	UFUNCTION()
	private void BombHolderTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(StartLoc, EndLoc, CurrentValue));
	}

	UFUNCTION()
	private void BombHolderTimelikeFinished()
	{
		if (BombHolderTimelike.IsReversed())
			SetActorHiddenInGame(true);
	}

	UFUNCTION()
	private void OnBombExploded(AGameShowArenaBomb Bomb)
	{
		Timer::SetTimer(this, n"EnableInteraction", 2.5, false);
	}

	UFUNCTION()
	void EnableInteraction()
	{
		if (HasControl())
			ConnectedBomb.CrumbRespawn();

		ConnectedBomb.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::SnapToTarget);
		ConnectedBomb.ActorRelativeLocation = FVector::ZeroVector;
		ConnectedBomb.ActorRelativeRotation = FRotator(0, 0, 0);
		ConnectedBomb.ShowTutorial(Game::Players[HolderSpawnAtPlayer]);
	}

	UFUNCTION()
	private void HandleBombUnfrozen()
	{
		OnBombPickedUp.Broadcast();
	}

	UFUNCTION()
	void ActivateBombHolder()
	{
		SetActorHiddenInGame(false);
		ConnectedBomb.ClearAllDisables();

		TArray<FString> DebugInfo;
		ConnectedBomb.GetDisableInstigatorsDebugInformation(DebugInfo);

		if (ConnectedBomb.State.Get() == EGameShowArenaBombState::Frozen)
		{
			ConnectedBomb.AttachToComponent(MeshRoot, NAME_None, EAttachmentRule::SnapToTarget);
			ConnectedBomb.ActorRelativeLocation = FVector::ZeroVector;
			ConnectedBomb.ActorRelativeRotation = FRotator(0, 0, 0);
		}

		ConnectedBomb.ShowTutorial(Game::Players[HolderSpawnAtPlayer]);
		BombHolderTimelike.PlayFromStart();
		FGameShowArenaBombHolderLoweringParams Params;
		Params.BombHolder = this;
		UGameShowArenaBombHolderEventHandler::Trigger_OnStartLowering(this, Params);
	}

	UFUNCTION()
	void DeactivateBombHolder()
	{
		BombHolderTimelike.ReverseFromEnd();
	}
}