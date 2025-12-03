struct FStoneBeastCameraData
{
	AFocusCameraActor Cam;
	FHazeCameraWeightedFocusTargetInfo FocusTargetInfo;
}

class AStoneBeastTargetActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(4.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBeastTargetActorLocationCapability");

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	bool bDebugOn = false;

	TArray<AHazePlayerCharacter> AlivePlayers;
	AStoneBeastTargetActor Leader;
	bool bHasInitialized;

	// TArray<AFocusCameraActor> Cameras;

	// TArray<FStoneBeastCameraData> SavedTargetInfo;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// TArray<AActor> Actors;
		// GetAttachedActors(Actors);
		// for (AActor Actor : Actors)
		// {
		// 	auto Cam = Cast<AFocusCameraActor>(Actor);
		// 	if (Cam != nullptr)
		// 		Cameras.Add(Cam);
		// }

		auto MioHealthComp = UPlayerHealthComponent::Get(Game::Mio);
		auto ZoeHealthComp = UPlayerHealthComponent::Get(Game::Zoe);

		MioHealthComp.OnDeathTriggered.AddUFunction(this, n"MioDeath");
		MioHealthComp.OnReviveTriggered.AddUFunction(this, n"MioRevive");
		
		ZoeHealthComp.OnDeathTriggered.AddUFunction(this, n"ZoeDeath");
		ZoeHealthComp.OnReviveTriggered.AddUFunction(this, n"ZoeRevive");

		AlivePlayers.Add(Game::Mio);
		AlivePlayers.Add(Game::Zoe);

		for (auto Other : TListedActors<AStoneBeastTargetActor>())
		{
			if (Other == this)
				Leader = nullptr;
			else
				Leader = Other;

			break;
		}
		
		// Delay activation of capability until initial beginplay teleports have been done
		Timer::SetTimer(this, n"OnTimerTimeout", 0.1);
	}

	UFUNCTION()
	private void MioDeath()
	{
		AlivePlayers.Remove(Game::Mio);
	}

	UFUNCTION()
	private void MioRevive()
	{
		AlivePlayers.Add(Game::Mio);
	}

	UFUNCTION()
	private void ZoeDeath()
	{
		AlivePlayers.Remove(Game::Zoe);
	}

	UFUNCTION()
	private void ZoeRevive()
	{
		AlivePlayers.Add(Game::Zoe);
	}

	UFUNCTION()
	private void OnTimerTimeout()
	{
		SetActorLocation((Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5);
		bHasInitialized = true;
	}
};