
class AToggleCameraParticles : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_LastDemotable;

	UPROPERTY(EditAnywhere, Category = "ToggleCameraParticles")
	bool bDisableToggle = false;

	UPROPERTY(EditAnywhere, Category = "ToggleCameraParticles")
	UNiagaraSystem CameraParticles_Zoe;

	UPROPERTY(EditAnywhere, Category = "ToggleCameraParticles")
	UNiagaraSystem CameraParticles_Mio;

	UPROPERTY(EditAnywhere, Category = "ToggleCameraParticles")
	bool bRegisterWithKillParticleManager = false;

	// should we apply or clear when we enter the volume
	UPROPERTY(EditAnywhere, Category = "ToggleCameraParticles")
	bool bInvertLogic = false;

	UPROPERTY(EditAnywhere, Category = "ToggleCameraParticles")
	AActorTrigger TriggerVolume;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(TriggerVolume == nullptr)
			return;

		if(bDisableToggle)
			return;

		TriggerVolume.OnActorEnter.AddUFunction(this, n"OnActorEnterTrigger");
		TriggerVolume.OnActorLeave.AddUFunction(this, n"OnActorExitTrigger");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorEnterTrigger(AHazeActor Actor)
	{
		AHazePlayerCharacter Player = FindPlayerOnActor(Actor);

		if(Player == nullptr)
			return;

		OnPlayerEnterTrigger(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorExitTrigger(AHazeActor Actor)
	{
		AHazePlayerCharacter Player = FindPlayerOnActor(Actor);

		if(Player == nullptr)
			return;

		OnPlayerLeaveTrigger(Player);
	}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Meta = (AutoCreateBPNode))
	void OnPlayerEnterTrigger(AHazePlayerCharacter Player) 
	{
		if(bInvertLogic)
			EnableVFX(Player);
		else
			DisableVFX(Player);
	}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Meta = (AutoCreateBPNode))
	void OnPlayerLeaveTrigger(AHazePlayerCharacter Player) 
	{
		if(bInvertLogic)
			DisableVFX(Player);
		else
			EnableVFX(Player);
	}

	void EnableVFX(AHazePlayerCharacter Player)
	{
		auto Asset = Player.IsMio() ? CameraParticles_Mio : CameraParticles_Zoe;
		PostProcessing::ApplyCameraParticles(
			Player,
			Asset,
			this,
			EInstigatePriority::Level,
			FVector::ZeroVector,
			bRegisterWithKillParticleManager
		);
		PrintToScreenScaled("Enabling Camera Particles via Volume", 3.0, FLinearColor::Yellow);
	}

	void DisableVFX(AHazePlayerCharacter Player)
	{
		PostProcessing::ClearCameraParticles(Player, this);
		PrintToScreenScaled("DISABLING Camera Particles via Volume", 3.0, FLinearColor::Yellow);
	}

	AHazePlayerCharacter FindPlayerOnActor(AHazeActor Actor)
	{
		if(Actor == nullptr)
			return nullptr;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if(Player != nullptr)
			return Player;

		if(Player == nullptr)
		{
			TArray<AActor> OutActors;
			Actor.GetAttachedActors(OutActors, true, true);
			for(AActor ActorIter : OutActors)
			{
				AHazePlayerCharacter PotentialPlayer = Cast<AHazePlayerCharacter>(ActorIter);
				if(PotentialPlayer != nullptr)
				{
					return PotentialPlayer;
				}
			}
		}

		return nullptr;
	}

}