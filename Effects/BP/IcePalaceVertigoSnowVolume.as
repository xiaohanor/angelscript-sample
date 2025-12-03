
/**
 * Enable VFX for this area when Players enter the trigger volume
 */

class AIcePalaceVertigoSnowVolume : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_LastDemotable;

    UPROPERTY(DefaultComponent, RootComponent, Category = "Vertigo VFX Volume")
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Movable;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Vertigo VFX Volume";
#endif

    UPROPERTY(EditAnywhere, Category = "Vertigo VFX Volume")
	AActorTrigger TriggerVolume;

    private TPerPlayer<FPerPlayerVertigoVFXData> PerPlayerData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(TriggerVolume == nullptr)
		{
			//Removing for now, as some waterfalls won't have references for a while
			// devError("the Waterfall Events need a TriggerVolume assigned to work");
			return;
		}

		TriggerVolume.OnActorEnter.AddUFunction(this, n"OnActorEnterTrigger");
		TriggerVolume.OnActorLeave.AddUFunction(this, n"OnActorExitTrigger");

		// don't tick until player enters the volume
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Meta = (AutoCreateBPNode))
	void OnActorEnterVertigoVolume(AHazePlayerCharacter Player) { }

	UFUNCTION(BlueprintEvent, NotBlueprintCallable, Meta = (AutoCreateBPNode))
	void OnActorLeaveVertigoVolume(AHazePlayerCharacter Player) { }

	UFUNCTION(NotBlueprintCallable)
	private void OnActorEnterTrigger(AHazeActor Actor)
	{
		AHazePlayerCharacter Player = FindPlayerOnActor(Actor);

		if(Player != nullptr)
		{
			// flag that we allow the camera VFX to be spawned
			PerPlayerData[Player].bPlayerHasEnteredVolume = true;

			PerPlayerData[Player].PrevCameralocation = Player.ViewLocation;

			// start ticking once the players enter
			SetActorTickEnabled(true);

			// Event handler entered volume
		}

		OnActorEnterVertigoVolume(Player);
		
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorExitTrigger(AHazeActor Actor)
	{
		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player != nullptr)
		{
			OnActorLeaveVertigoVolume(Player);

			// Event handler left volume
		}
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

struct FPerPlayerVertigoVFXData
{
	UNiagaraComponent CameraVFX = nullptr;
	bool bCameraEffectTriggered = false;
	bool bPlayerHasEnteredVolume = false;
	FVector PrevCameralocation = FVector::ZeroVector;
};