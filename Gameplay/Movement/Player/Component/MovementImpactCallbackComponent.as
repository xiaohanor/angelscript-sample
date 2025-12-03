
event void FOnPlayerImpact(AHazePlayerCharacter Player);

struct FMovementImpactCallbackPlayerState
{
	bool bGroundImpact;
	bool bWallImpact;
	bool bCeilingImpact;

	TArray<FInstigator> WallAttachInstigators;

	bool HasAnyImpact() const
	{
		return bGroundImpact || bWallImpact || bCeilingImpact;
	}

#if EDITOR
	uint DebugStartGroundFrame;
	uint DebugStartWallFrame;
	uint DebugStartCeilingFrame;

	uint DebugEndGroundFrame;
	uint DebugEndWallFrame;
	uint DebugEndCeilingFrame;

	uint GetDebugStartAnyImpactFrame() const
	{
		return Math::Min(DebugStartGroundFrame, Math::Min(DebugStartWallFrame, DebugStartCeilingFrame));
	}

	uint GetDebugEndAnyImpactFrame() const
	{
		return Math::Max(DebugEndGroundFrame, Math::Max(DebugEndWallFrame, DebugEndCeilingFrame));
	}
#endif
}

UCLASS(NotBlueprintable, HideCategories = "ComponentTick Activation Cooking Disable Tags Navigation")
class UMovementImpactCallbackComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	access EditDefaults = protected, UFauxPhysicsPlayerWeightComponent, * (editdefaults, readonly);
	access MoveComp = protected, UHazeMovementComponent (inherited);

	/**
	 * If false, we will send all impacts from the player control to the remote side.
	 * If true, local impacts will be used for the remote player. This means 2 things:
	 * 1. The impacts won't be as reliable, as remote player movement is very approximate.
	 * 2. At the time of writing, only Any and Ground callbacks will work, since no removte resolver sweeps the moved delta, only finding ground.
	 */
	UPROPERTY(Category = Settings, EditAnywhere, BlueprintReadOnly)
	access:EditDefaults bool bTriggerLocally = false;

	// Specify components use for impacts using AddComponentUsedForImpacts
	UPROPERTY(Category = Settings, EditAnywhere)
	access:EditDefaults bool bUseSpecifiedComponentsForImpacts = false;

	// Specify components use for impacts using AddComponentUsedForImpacts
	UPROPERTY(Category = Settings, EditAnywhere, meta = (EditCondition = "bUseSpecifiedComponentsForImpacts", EditConditionHides))
	access:EditDefaults TArray<FComponentReference> ComponentsUsedForImpacts;

	UPROPERTY(Category = "Events | Started")
	FOnPlayerImpact OnAnyImpactByPlayer;
	UPROPERTY(Category = "Events | Started")
	FOnPlayerImpact OnGroundImpactedByPlayer;
	UPROPERTY(Category = "Events | Started")
	FOnPlayerImpact OnWallImpactedByPlayer;
	UPROPERTY(Category = "Events | Started")
	FOnPlayerImpact OnCeilingImpactedByPlayer;

	UPROPERTY(Category = "Events | Ended")
	FOnPlayerImpact OnAnyImpactByPlayerEnded;
	UPROPERTY(Category = "Events | Ended")
	FOnPlayerImpact OnGroundImpactedByPlayerEnded;
	UPROPERTY(Category = "Events | Ended")
	FOnPlayerImpact OnWallImpactedByPlayerEnded;
	UPROPERTY(Category = "Events | Ended")
	FOnPlayerImpact OnCeilingImpactedByPlayerEnded;

	// Triggered when the player attaches to the wall, for example through a wall run, scramble or mantle
	UPROPERTY(Category = "Events | Wall Attach")
	FOnPlayerImpact OnAttachedToWallByPlayer;
	UPROPERTY(Category = "Events | Wall Attach")
	FOnPlayerImpact OnWallAttachByPlayerEnded;

#if EDITOR
	/**
	 * If true, we will log all impacts.
	 * Can only be set before BeginPlay.
	 */
	UPROPERTY(EditAnywhere, BlueprintHidden, Category = "Debug")
	access:EditDefaults bool bTemporalLog = false;
#endif

	private TPerPlayer<FMovementImpactCallbackPlayerState> PlayerStates;
	private TArray<UPrimitiveComponent> ComponentsUsedForImpacts_Internal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Component : ComponentsUsedForImpacts)
		{
			auto Primitive = Cast<UPrimitiveComponent>(Component.GetComponent(Owner));
			if(Primitive == nullptr)
				continue;

			ComponentsUsedForImpacts_Internal.Add(Primitive);
		}

#if EDITOR
		SetComponentTickEnabled(bTemporalLog);
#endif
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const FTemporalLog TemporalLog = GetTemporalLog();

		for(auto Player : Game::Players)
		{
			const FTemporalLog PlayerLog = TemporalLog.Section(Player.IsMio() ? "Mio" : "Zoe", int(Player.Player));

			const FMovementImpactCallbackPlayerState& PlayerState = PlayerStates[Player];

			PlayerLog.Section("Any", 0)
				.Value("Has Any Impact", PlayerState.HasAnyImpact())
				.Value("Start Any Impact", PlayerState.GetDebugStartAnyImpactFrame() == Time::FrameNumber)
				.Value("End Any Impact", PlayerState.GetDebugEndAnyImpactFrame() == Time::FrameNumber)
			;

			PlayerLog.Section("Ground", 1)
				.Value("Has Ground Impact", PlayerState.bGroundImpact)
				.Value("Start Ground Impact", PlayerState.DebugStartGroundFrame == Time::FrameNumber)
				.Value("End Ground Impact", PlayerState.DebugEndGroundFrame == Time::FrameNumber)
			;

			PlayerLog.Section("Wall", 2)
				.Value("Has Wall Impact", PlayerState.bWallImpact)
				.Value("Start Wall Impact", PlayerState.DebugStartWallFrame == Time::FrameNumber)
				.Value("End Wall Impact", PlayerState.DebugEndWallFrame == Time::FrameNumber)
			;

			PlayerLog.Section("Ceiling", 3)
				.Value("Has Ceiling Impact", PlayerState.bCeilingImpact)
				.Value("Start Ceiling Impact", PlayerState.DebugStartCeilingFrame == Time::FrameNumber)
				.Value("End Ceiling Impact", PlayerState.DebugEndCeilingFrame == Time::FrameNumber)
			;

			auto WallAttachSection = PlayerLog.Section("Wall Attach", 4);
			WallAttachSection.Value("Instigator Count", PlayerState.WallAttachInstigators.Num());
			for(int i = 0; i < PlayerState.WallAttachInstigators.Num(); i++)
			{
				WallAttachSection.Value(f"Instigator {i}", PlayerState.WallAttachInstigators[i]);
			}
		}
	}
#endif

	// Adds a primitive component to be checked for impacts
	UFUNCTION(BlueprintCallable)
	void AddComponentUsedForImpacts(UPrimitiveComponent Component)
	{
		bUseSpecifiedComponentsForImpacts = true;
		ComponentsUsedForImpacts_Internal.Add(Component);
	}
	// Adds an array of primitive components to be checked for impacts
	UFUNCTION(BlueprintCallable)
	void AddComponentsUsedForImpacts(TArray<UPrimitiveComponent> Components)
	{
		bUseSpecifiedComponentsForImpacts = true;
		ComponentsUsedForImpacts_Internal.Append(Components);
	}

	UFUNCTION(BlueprintCallable)
	void RemoveComponentUsedForImpact(UPrimitiveComponent Component)
	{
		ComponentsUsedForImpacts_Internal.Remove(Component);
	}

	bool HasAnyPlayerImpact() const
	{
		for(auto PlayerState : PlayerStates)
		{
			if(PlayerState.HasAnyImpact())
				return true;
		}

		return false;
	}

	bool HasPlayerImpact(AHazePlayerCharacter Player) const
	{
		return PlayerStates[Player].HasAnyImpact();
	}

	TArray<AHazePlayerCharacter> GetImpactingPlayers() const
	{
		TArray<AHazePlayerCharacter> Players;
		for(auto Player : Game::Players)
		{
			if(HasPlayerImpact(Player))
				Players.Add(Player);
		}
		return Players;
	}

	access:MoveComp
	bool ImpactFromPlayer(AHazePlayerCharacter Player, EMovementImpactType ImpactType, FHitResult Hit)
	{
		check(IsValidImpact(Hit), "Always check IsValidImpact() before calling ImpactFromPlayer()");

		ImpactedByPlayerActor(Player, ImpactType);

		return true;
	}

	access:MoveComp
	void ClearImpactFromPlayer(AHazePlayerCharacter Player, EMovementImpactType ImpactType)
	{
		ImpactedByPlayerEndedActor(Player, ImpactType);
	}

	protected void ImpactedByPlayerActor(AHazePlayerCharacter Player, EMovementImpactType ImpactType)
	{
		// Only the control player can decide when we start impacting
		if(!bTriggerLocally && !Player.HasControl())
			return;

		// No need to dispatch the event or send crumb functions if we haven't changed anything
		if(!ensure(!IsAlreadyImpacted(Player, ImpactType)))
			return;

		if (bTriggerLocally)
			LocalImpactedByPlayer(Player, ImpactType);
		else
			CrumbImpactedByPlayer(Player, ImpactType);
	}

	protected void ImpactedByPlayerEndedActor(AHazePlayerCharacter Player, EMovementImpactType ImpactType)
	{
		// Only the control player can decide when we stop impacting
		if(!bTriggerLocally && !Player.HasControl())
			return;

		// No need to dispatch the event or send crumb functions if we haven't changed anything
		if(!ensure(IsAlreadyImpacted(Player, ImpactType)))
			return;

		if (bTriggerLocally)
			LocalImpactedByPlayerEnded(Player, ImpactType);
		else
			CrumbImpactedByPlayerEnded(Player, ImpactType);
	}

	protected bool IsAlreadyImpacted(const AHazePlayerCharacter Player, EMovementImpactType ImpactType) const
	{
		switch(ImpactType)
		{
			case EMovementImpactType::Ground:
				return PlayerStates[Player].bGroundImpact;

			case EMovementImpactType::Wall:
				return PlayerStates[Player].bWallImpact;

			case EMovementImpactType::Ceiling:
				return PlayerStates[Player].bCeilingImpact;

			default:
				check(false, "Invalid impact type!");
				return false;
		}
	}

	UFUNCTION(CrumbFunction)
	protected void CrumbImpactedByPlayer(AHazePlayerCharacter Player, EMovementImpactType ImpactType)
	{
		LocalImpactedByPlayer(Player, ImpactType);
	}

	protected void LocalImpactedByPlayer(AHazePlayerCharacter Player, EMovementImpactType ImpactType)
	{
		check(!IsAlreadyImpacted(Player, ImpactType));

		const bool bHadAnyImpact = PlayerStates[Player].HasAnyImpact();

		switch(ImpactType)
		{
			case EMovementImpactType::Ground:
			{
				PlayerStates[Player].bGroundImpact = true;
				OnGroundImpactedByPlayer.Broadcast(Player);

#if EDITOR
				if(bTemporalLog)
				{
					PlayerStates[Player].DebugStartGroundFrame = Time::FrameNumber;
					GetTemporalLog().Event(f"Broadcast Ground Impact for {Player}");
				}
#endif
				break;
			}

			case EMovementImpactType::Wall:
			{
				PlayerStates[Player].bWallImpact = true;
				OnWallImpactedByPlayer.Broadcast(Player);

#if EDITOR
				if(bTemporalLog)
				{
					PlayerStates[Player].DebugStartWallFrame = Time::FrameNumber;
					GetTemporalLog().Event(f"Broadcast Wall Impact for {Player}");
				}
#endif
				break;
			}

			case EMovementImpactType::Ceiling:
			{
				PlayerStates[Player].bCeilingImpact = true;
				OnCeilingImpactedByPlayer.Broadcast(Player);

#if EDITOR
				if(bTemporalLog)
				{
					PlayerStates[Player].DebugStartCeilingFrame = Time::FrameNumber;
					GetTemporalLog().Event(f"Broadcast Ceiling Impact for {Player}");
				}
#endif
				break;
			}

			default:
				check(false, "Invalid impact type!");
				break;
		}

		const bool bHasAnyImpact = PlayerStates[Player].HasAnyImpact();
		if(!bHadAnyImpact && bHasAnyImpact)
		{
			OnAnyImpactByPlayer.Broadcast(Player);

#if EDITOR
			if(bTemporalLog)
				GetTemporalLog().Event(f"Broadcast Any Impact for {Player}");
#endif
		}
	}

	UFUNCTION(CrumbFunction)
	protected void CrumbImpactedByPlayerEnded(AHazePlayerCharacter Player, EMovementImpactType ImpactType)
	{
		LocalImpactedByPlayerEnded(Player, ImpactType);
	}

	protected void LocalImpactedByPlayerEnded(AHazePlayerCharacter Player, EMovementImpactType ImpactType)
	{
		check(IsAlreadyImpacted(Player, ImpactType));

		const bool bHadAnyImpact = PlayerStates[Player].HasAnyImpact();

		switch(ImpactType)
		{
			case EMovementImpactType::Ground:
			{
				OnGroundImpactedByPlayerEnded.Broadcast(Player);
				PlayerStates[Player].bGroundImpact = false;

#if EDITOR
				if(bTemporalLog)
				{
					PlayerStates[Player].DebugEndGroundFrame = Time::FrameNumber;
					GetTemporalLog().Event(f"Broadcast End Ground Impact for {Player}");
				}
#endif
				break;
			}

			case EMovementImpactType::Wall:
			{
				OnWallImpactedByPlayerEnded.Broadcast(Player);
				PlayerStates[Player].bWallImpact = false;

#if EDITOR
				if(bTemporalLog)
				{
					PlayerStates[Player].DebugEndWallFrame = Time::FrameNumber;
					GetTemporalLog().Event(f"Broadcast End Wall Impact for {Player}");
				}
#endif
				break;
			}

			case EMovementImpactType::Ceiling:
			{
				OnCeilingImpactedByPlayerEnded.Broadcast(Player);
				PlayerStates[Player].bCeilingImpact = false;

#if EDITOR
				if(bTemporalLog)
				{
					PlayerStates[Player].DebugEndCeilingFrame = Time::FrameNumber;
						GetTemporalLog().Event(f"Broadcast End Ceiling Impact for {Player}");
				}
#endif
				break;
			}

			default:
				check(false, "Invalid impact type!");
				break;
		}

		const bool bHasAnyImpact = PlayerStates[Player].HasAnyImpact();
		if(bHadAnyImpact && !bHasAnyImpact)
		{
			OnAnyImpactByPlayerEnded.Broadcast(Player);

#if EDITOR
			if(bTemporalLog)
				GetTemporalLog().Event(f"Broadcast End Any Impact for {Player}");
#endif
		}
	}
	
	access:MoveComp
	bool IsValidImpact(FHitResult Impact) const
	{
		check(Impact.Actor == Owner);
		
		if(bUseSpecifiedComponentsForImpacts)
		{
			if(!ComponentsUsedForImpacts_Internal.Contains(Impact.Component))
				return false;
		}

		return true;
	}

	void AddWallAttachInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		FMovementImpactCallbackPlayerState& State = PlayerStates[Player];
		bool bWasAttached = State.WallAttachInstigators.Num() != 0;
		State.WallAttachInstigators.AddUnique(Instigator);

		if (!bWasAttached)
		{
			OnAttachedToWallByPlayer.Broadcast(Player);

#if EDITOR
			if(bTemporalLog)
				GetTemporalLog().Event(f"Broadcast Wall Attach for {Player}");
#endif
		}
	}

	void RemoveWallAttachInstigator(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		FMovementImpactCallbackPlayerState& State = PlayerStates[Player];
		bool bWasAttached = State.WallAttachInstigators.Num() != 0;
		State.WallAttachInstigators.RemoveSingleSwap(Instigator);

		if (bWasAttached && State.WallAttachInstigators.Num() == 0)
		{
			OnWallAttachByPlayerEnded.Broadcast(Player);

#if EDITOR
			if(bTemporalLog)
				GetTemporalLog().Event(f"Broadcast End Wall Attach for {Player}");
#endif
		}
	}

#if EDITOR
	FTemporalLog GetTemporalLog() const
	{
		return TEMPORAL_LOG(Owner, "Impact Callbacks");
	}
#endif
}