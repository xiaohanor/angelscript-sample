event void FAIslandGrenadeLockListenerSignature();

struct FIslandGrenadeLockActiveLaserNiagaraData
{
	UNiagaraComponent NiagaraComp;
	AHazePlayerCharacter Player;
	AIslandGrenadeLock LockA;
	AIslandGrenadeLock LockB;

	bool ShouldDeactivate() const
	{
		if(!LockA.bActivatedByGrenade)
			return true;

		if(!LockB.bActivatedByGrenade)
			return true;

		if(LockA.ActivatedByGrenadeExplosionIndex != LockB.ActivatedByGrenadeExplosionIndex)
			return true;

		return false;
	}
}

struct FIslandGrenadeLockLaserPooledNiagaraData
{
	TArray<UNiagaraComponent> SpawnedLasers;
}

class AIslandGrenadeLockListener : AHazeActor
{
	// Change tick group so niagara beam start/end locations are set when all grenade locks have moved.
	default TickGroup = ETickingGroup::TG_HazeGameplay;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnCompleted;
	
	UPROPERTY()
	FAIslandGrenadeLockListenerSignature OnReset;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<AIslandGrenadeLock> Children;

	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bResettable;

	UPROPERTY(EditAnywhere, Category = "Setup")
	float ResetTimer = 5;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem LaserNiagara;

	UPROPERTY(EditAnywhere)
	bool bSeparateLaserNiagaraForZoe = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bSeparateLaserNiagaraForZoe", EditConditionHides))
	UNiagaraSystem LaserNiagaraZoe;

	UPROPERTY(EditAnywhere)
	float BeamWidth = 100.0;

	UPROPERTY()
	bool bCompleted;

	UPROPERTY(EditInstanceOnly)
	TArray<AIslandGrenadeLockIndicator> OptionalIndicators;

	private TArray<AIslandGrenadeLock> ActiveChildren;
	int ActiveRedLocks = 0;
	int ActiveBlueLocks = 0;
	private float TimeUntilResetTimer;
	
	private TArray<FIslandGrenadeLockActiveLaserNiagaraData> ActiveLasers;
	private TPerPlayer<bool> CompletedPerPlayer;

	UPROPERTY(EditAnywhere, Category = Audio)
	FSoundDefReference LocksSoundDef;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bool bHasAttachedAudioForRed = false;
		bool bHasAttachedAudioForBlue = false;

		for (auto Child : Children)
		{
			Child.GrenadeListener = this;
			Child.OnActivated.AddUFunction(this, n"OnLockActivated");
			Child.OnDeactivated.AddUFunction(this, n"OnLockDeactivated");	

			if(!bHasAttachedAudioForRed
			&& Child.UsableByPlayer  == EHazePlayer::Mio
			&& LocksSoundDef.SoundDef.IsValid())
			{
				LocksSoundDef.SpawnSoundDefAttached(Child, this);
				bHasAttachedAudioForRed = true;
			}
			else if(!bHasAttachedAudioForBlue
			&& Child.UsableByPlayer  == EHazePlayer::Zoe
			&& LocksSoundDef.SoundDef.IsValid())
			{
				LocksSoundDef.SpawnSoundDefAttached(Child, this);
				bHasAttachedAudioForBlue = true;
			}
		}

		TimeUntilResetTimer = ResetTimer;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		HandleDrawLasers();

		if (!bCompleted)
			return;

		if(!bResettable)
			return;

		TimeUntilResetTimer = TimeUntilResetTimer - DeltaSeconds;
		if (TimeUntilResetTimer <= 0)
		{
			ResetLocks();
		}
	}

	UFUNCTION()
	private void OnLockActivated(AIslandGrenadeLock Lock)
	{
		bool bWasAdded = ActiveChildren.AddUnique(Lock);

		if(!bWasAdded)
			return;

		HandleOnePlayerEffectEvents();
		HandleAddActiveLasers(Lock);
		CheckCompleted();

		int& RelevantAmount = Lock.UsableByPlayer == EHazePlayer::Mio ? ActiveRedLocks : ActiveBlueLocks;
		RelevantAmount++;

		for(auto OptionalIndicator : OptionalIndicators)
			OptionalIndicator.SetGrenadeLockCompletionAmount(Lock.UsableByPlayer, RelevantAmount);
	}

	UFUNCTION()
	private void OnLockDeactivated(AIslandGrenadeLock Lock)
	{
		bool bWasRemoved = ActiveChildren.RemoveSingleSwap(Lock) == 1;

		if(!bWasRemoved)
			return;

		HandleOnePlayerEffectEvents();

		int& RelevantAmount = Lock.UsableByPlayer == EHazePlayer::Mio ? ActiveRedLocks : ActiveBlueLocks;
		RelevantAmount--;

		for(auto OptionalIndicator : OptionalIndicators)
			OptionalIndicator.SetGrenadeLockCompletionAmount(Lock.UsableByPlayer, RelevantAmount);
	}

	private void CheckCompleted()
	{
		if(bCompleted)
			return;

		bool bShouldComplete = HasPlayerCompleted(Game::Mio) && HasPlayerCompleted(Game::Zoe);

		// Call this on both sides so that if one side has completed the puzzle it is also completed on the other side.
		if(bShouldComplete)
			CrumbSetCompleted();
	}

	private void HandleOnePlayerEffectEvents()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			bool bHasCompleted = HasPlayerCompleted(Player);
			if(CompletedPerPlayer[Player] != bHasCompleted)
			{
				FIslandGrenadeLockListenerOnePlayerEffectParams Params;
				Params.Listener = this;
				Params.Player = Player;
				CompletedPerPlayer[Player] = bHasCompleted;
				if(bHasCompleted)
					UIslandGrenadeLockListenerEffectHandler::Trigger_OnOnePlayerSucceeded(this, Params);
				else
					UIslandGrenadeLockListenerEffectHandler::Trigger_OnOnePlayerFailed(this, Params);
			}
		}
	}

	private bool HasPlayerCompleted(AHazePlayerCharacter Player)
	{
		for(AIslandGrenadeLock Lock : Children)
		{
			if(Lock.UsableByPlayer != Player.Player)
				continue;

			if(!ActiveChildren.Contains(Lock))
				return false;
		}

		if(!HasSameGrenadeCompletedLocksForPlayer(Player))
			return false;

		return true;
	}

	private bool HasSameGrenadeCompletedLocksForPlayer(AHazePlayerCharacter Player)
	{
		int PlayerExplosionIndex = -1;

		for(int i = 0; i < ActiveChildren.Num(); i++)
		{
			if(ActiveChildren[i].UsableByPlayer != Player.Player)
				continue;

			if(!ActiveChildren[i].bActivatedByGrenade)
				continue;

			if(PlayerExplosionIndex == -1)
				PlayerExplosionIndex = ActiveChildren[i].ActivatedByGrenadeExplosionIndex;

			// If a grenade lock is activated by another explosion, don't complete the puzzle.
			if(PlayerExplosionIndex != ActiveChildren[i].ActivatedByGrenadeExplosionIndex)
				return false;
		}

		return true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetCompleted()
	{
		// Since this might get called twice if both the remote side and control side thinks it is completed so return in that case
		if(bCompleted)
			return;

		bCompleted = true;
		for (auto Child : Children)
		{
			Child.SetCompleted();
		}
		OnCompleted.Broadcast();
		for(auto OptionalIndicator : OptionalIndicators)
			OptionalIndicator.OnGrenadeLockPuzzleComplete();

		FIslandGrenadeLockListenerGenericEffectParams Params(this);
		UIslandGrenadeLockListenerEffectHandler::Trigger_OnListenerCompleted(this, Params);

		if (bResettable)
			TimeUntilResetTimer = ResetTimer;
	}

	UFUNCTION()
	void ResetLocks()
	{
		bCompleted = false;
		for (auto Child : Children)
		{
			CompletedPerPlayer[Game::GetPlayer(Child.UsableByPlayer)] = false;
			Child.DeactivateLock();
		}
		OnReset.Broadcast();
		FIslandGrenadeLockListenerGenericEffectParams Params(this);
		UIslandGrenadeLockListenerEffectHandler::Trigger_OnListenerReset(this, Params);
	}

	UFUNCTION()
	void ForceFinishPuzzle()
	{
		for (auto Child : Children)
		{
			Child.ActivateLock();
		}
	}

	TArray<AIslandGrenadeLock> GetActiveChildren()
	{
		return ActiveChildren;
	}

	void GetLocksUsableByPlayer(EHazePlayer Player, TArray<AIslandGrenadeLock>&out Locks)
	{
		for(auto Lock : Children)
		{
			if(Lock.UsableByPlayer == Player)
				Locks.Add(Lock);
		}
	}

	void HandleDrawLasers()
	{
		for(int i = ActiveLasers.Num() - 1; i >= 0; i--)
		{
			FIslandGrenadeLockActiveLaserNiagaraData Data = ActiveLasers[i];
			if(Data.ShouldDeactivate())
			{
				Data.NiagaraComp.DeactivateImmediately();
				ActiveLasers.RemoveAt(i);
				continue;
			}

			SetLaserStartEndPositions(Data);
		}
	}

	void HandleAddActiveLasers(AIslandGrenadeLock NewLock)
	{
		if(!NewLock.bActivatedByGrenade)
			return;

		TSet<AIslandGrenadeLock> AlreadyConnectedLocks;
		for(int i = 0; i < ActiveLasers.Num(); i++)
		{
			FIslandGrenadeLockActiveLaserNiagaraData Data = ActiveLasers[i];
			if(Data.LockA == NewLock)
				AlreadyConnectedLocks.Add(Data.LockB);
			else if(Data.LockB == NewLock)
				AlreadyConnectedLocks.Add(Data.LockA);
		}

		for(int i = 0; i < ActiveChildren.Num(); i++)
		{
			AIslandGrenadeLock Lock = ActiveChildren[i];
			if(Lock == NewLock)
				continue;

			if(Lock.UsableByPlayer != NewLock.UsableByPlayer)
				continue;

			if(NewLock.ActivatedByGrenadeExplosionIndex != Lock.ActivatedByGrenadeExplosionIndex)
				continue;

			if(AlreadyConnectedLocks.Contains(Lock))
				continue;

			FIslandGrenadeLockActiveLaserNiagaraData Data;
			Data.LockA = NewLock;
			Data.LockB = Lock;
			Data.Player = Game::GetPlayer(NewLock.UsableByPlayer);
			Data.NiagaraComp = SpawnNiagaraComponent(Data.Player);
			SetLaserStartEndPositions(Data);
			ActiveLasers.Add(Data);
		}
	}

	UNiagaraComponent SpawnNiagaraComponent(AHazePlayerCharacter Player)
	{
		UNiagaraSystem NiagaraSystem = LaserNiagara;
		if(Player.IsZoe() && bSeparateLaserNiagaraForZoe)
			NiagaraSystem = LaserNiagaraZoe;

		UNiagaraComponent Niagara = Niagara::SpawnLoopingNiagaraSystemAttached(NiagaraSystem, RootComponent);
		Niagara.SetNiagaraVariableFloat("BeamWidth", BeamWidth);
		return Niagara;
	}
	
	void SetLaserStartEndPositions(FIslandGrenadeLockActiveLaserNiagaraData Data)
	{
		Data.NiagaraComp.SetNiagaraVariablePosition("BeamStart", Data.NiagaraComp.WorldTransform.InverseTransformPosition(Data.LockA.GetConnectedLineWorldLocation()));
		Data.NiagaraComp.SetNiagaraVariablePosition("BeamEnd", Data.NiagaraComp.WorldTransform.InverseTransformPosition(Data.LockB.GetConnectedLineWorldLocation()));
	}
}