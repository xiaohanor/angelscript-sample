
delegate void FNetworkLockDelegate(AHazePlayerCharacter Player, FInstigator LockInstigator);

struct FNetworkLockDelegateData
{
	FNetworkLockDelegate Delegate;
	FInstigator Instigator;
};

struct FNetworkLockHint
{
	FInstigator Instigator;
	float HintWeight = 0.0;
};

struct FNetworkLockPerPlayerData
{
	TArray<FInstigator> LockInstigators;
	TArray<FNetworkLockDelegateData> LockDelegates;
	TArray<FNetworkLockHint> Hints;
	bool bIsLocked = false;
};

/** 
 * Represents a network lock that can only be acquired by one player at a time.
 * There are methods available for hinting which player is likely to use it, to 
 * make it more responsive.
 */
class UNetworkLockComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default bBlockTickOnDisable = false;

	TPerPlayer<FNetworkLockPerPlayerData> LockData;

	AHazePlayerCharacter CurrentLockedBy = nullptr;
	AHazePlayerCharacter CurrentOwner = nullptr;

	bool bOtherSideWantsLock = false;
	bool bSentWantLock = false;
	float LastHintOwnerSwitch = -1.0;
	int DisallowLockingCounter = 0;

	/**
	 * Acquire the lock for a specific player.
	 * OBS! The delegate will only be executed on that player's control side!
	 */
	void Acquire(AHazePlayerCharacter AcquirePlayer, FInstigator LockInstigator, FNetworkLockDelegate AcquireControlSideDelegate = FNetworkLockDelegate())
	{
		auto& PlayerData = LockData[AcquirePlayer];
		PlayerData.LockInstigators.Add(LockInstigator);

		// Handle the lock delegate
		if (AcquirePlayer.HasControl())
		{
			if (PlayerData.bIsLocked)
			{
				AcquireControlSideDelegate.ExecuteIfBound(AcquirePlayer, LockInstigator);
			}
			else if (CurrentOwner.HasControl() && CurrentLockedBy == nullptr && DisallowLockingCounter == 0)
			{
				NetAcquiredLock(AcquirePlayer);
				AcquireControlSideDelegate.ExecuteIfBound(AcquirePlayer, LockInstigator);
			}
			else
			{
				FNetworkLockDelegateData DelegateData;
				DelegateData.Delegate = AcquireControlSideDelegate;
				DelegateData.Instigator = LockInstigator;
				PlayerData.LockDelegates.Add(DelegateData);
			}
		}

		// Start ticking so we can acquire the lock
		if (!PlayerData.bIsLocked)
			SetComponentTickEnabled(true);
	}

	/**
	 * Release the lock for this player and instigator combination.
	 */
	void Release(AHazePlayerCharacter ReleasePlayer, FInstigator LockInstigator)
	{
		auto& PlayerData = LockData[ReleasePlayer];
		PlayerData.LockInstigators.Remove(LockInstigator);

		// Remove any delegates for this instigator as well
		for (int i = PlayerData.LockDelegates.Num() - 1; i >= 0; --i)
		{
			if (PlayerData.LockDelegates[i].Instigator == LockInstigator)
				PlayerData.LockDelegates.RemoveAt(i);
		}

		// Release the lock if needed
		if (PlayerData.bIsLocked && PlayerData.LockInstigators.Num() == 0)
		{
			if (CurrentOwner.HasControl())
			{
				NetReleasedLock(ReleasePlayer);
			}
			else
			{
				SetComponentTickEnabled(true);
			}
		}
	}

	/**
	 * Whether this lock has been acquired for this player.
	 */
	bool IsAcquired(AHazePlayerCharacter Player) const
	{
		auto& PlayerData = LockData[Player];
		return PlayerData.bIsLocked;
	}

	/**
	 * Whether this lock has been acquired for this player, and active for this instigator.
	 */
	bool IsAcquiredByInstigator(AHazePlayerCharacter Player, FInstigator LockInstigator) const
	{
		auto& PlayerData = LockData[Player];
		return PlayerData.bIsLocked && PlayerData.LockInstigators.Contains(LockInstigator);
	}

	/**
	 * Whether either side is currently trying to acquire this lock.
	 * Should be treated as fuzzy, only use in heuristics, since lag can make this temporarily wrong.
	 */
	bool IsBeingAcquiredByEitherSide() const
	{
		return LockData[0].LockInstigators.Num() != 0 || LockData[1].LockInstigators.Num() != 0;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Take the server player if we don't already have an owner
		if (CurrentOwner == nullptr)
		{
			if (Network::HasWorldControl())
				CurrentOwner = Game::FirstLocalPlayer;
			else
				CurrentOwner = Game::FirstLocalPlayer.OtherPlayer;
		}
	}

	/**
	 * Force the owner of the lock. This is not network safe, and should not
	 * be called outside of a first BeginPlay initialization.
	 */
	void ForceCurrentOwner_BeginPlayOnly(AHazePlayerCharacter Player)
	{
		CurrentOwner = Player;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Network::IsGameNetworked())
			UpdateLockNetworked();
		else
			UpdateLockLocal();
	}

	void UpdateLockLocal()
	{
		bool bKeepTicking = false;
		for (auto Player : Game::Players)
		{
			auto& PlayerData = LockData[Player];
			if (PlayerData.bIsLocked && PlayerData.LockInstigators.Num() == 0)
			{
				// We no longer need this lock, release it 
				NetReleasedLock(Player);
			}
			else if (!PlayerData.bIsLocked && PlayerData.LockInstigators.Num() != 0 && DisallowLockingCounter == 0 && CurrentLockedBy == nullptr)
			{
				// We want a lock on this side, lock it
				NetAcquiredLock(Player);
			}

			// Keep ticking while we have lock requests
			if (PlayerData.LockInstigators.Num() != 0)
				bKeepTicking = true;
		}

		// Stop ticking when no longer needed
		if (!bKeepTicking)
			SetComponentTickEnabled(false);
	}

	void UpdateLockNetworked()
	{
		bool bWantLockOnThisSide = false;
		bool bWantSendLockToOtherSide = false;
		bool bKeepTicking = false;

		for (auto Player : Game::Players)
		{
			auto& PlayerData = LockData[Player];

			if (Player.HasControl() && CurrentOwner.HasControl())
			{
				if (PlayerData.bIsLocked && PlayerData.LockInstigators.Num() == 0)
				{
					// We no longer need this lock, release it 
					NetReleasedLock(Player);
				}
				else if (!PlayerData.bIsLocked && PlayerData.LockInstigators.Num() != 0 && DisallowLockingCounter == 0)
				{
					// We want a lock on this side, lock it
					NetAcquiredLock(Player);
				}
			}

			// Determine if this side wants to own the lock
			if (PlayerData.LockInstigators.Num() != 0)
			{
				if (Player.HasControl())
					bWantLockOnThisSide = true;
				else
					bWantSendLockToOtherSide = true;
			}

			// Keep ticking while we have lock requests
			if (PlayerData.LockInstigators.Num() != 0)
				bKeepTicking = true;
		}

		// Request the lock from the other side
		if (bWantLockOnThisSide != bSentWantLock)
		{
			bSentWantLock = bWantLockOnThisSide;
			NetWantLock(Network::HasWorldControl(), bWantLockOnThisSide);
		}

		// If we have the lock but don't want it, and the other side wants it, transfer ownership
		if (CurrentOwner.HasControl() && !bWantLockOnThisSide && (bOtherSideWantsLock || bWantSendLockToOtherSide) && CanTransferOwner())
			NetTransferOwner(CurrentOwner.OtherPlayer);

		// If nobody wants the lock, check any hints we might have
		if (CurrentOwner.HasControl() && !bWantLockOnThisSide && !bOtherSideWantsLock && !bWantSendLockToOtherSide)
			UpdateOwnerFromHints();

		// Keep ticking while the other side has lock requests
		if (bOtherSideWantsLock || bWantSendLockToOtherSide)
			bKeepTicking = true;

		// Stop ticking when no longer needed
		if (!bKeepTicking)
			SetComponentTickEnabled(false);
	}
	
	void ApplyOwnerHint(AHazePlayerCharacter Player, FInstigator Instigator, float HintWeight, bool bComputeHintUpdate = true)
	{
		auto& PlayerData = LockData[Player];
		bool bExistingHint = false;
		for (auto& Hint : PlayerData.Hints)
		{
			if (Hint.Instigator == Instigator)
			{
				Hint.HintWeight = HintWeight;
				bExistingHint = true;
				break;
			}
		}

		if (!bExistingHint)
		{
			FNetworkLockHint NewHint;
			NewHint.HintWeight = HintWeight;
			NewHint.Instigator = Instigator;
			PlayerData.Hints.Add(NewHint);
		}

		if (bComputeHintUpdate)
			UpdateHintValues();
	}

	void UpdateHintValues()
	{
		if (CurrentOwner != GetMostHintedOwner())
			SetComponentTickEnabled(true);
	}

	void ClearOwnerHint(AHazePlayerCharacter Player, FInstigator Instigator, bool bComputeHintUpdate = true)
	{
		auto& PlayerData = LockData[Player];
		for (int i = 0, Count = PlayerData.Hints.Num(); i < Count; ++i)
		{
			if (PlayerData.Hints[i].Instigator == Instigator)
			{
				PlayerData.Hints.RemoveAt(i);
				break;
			}
		}

		if (bComputeHintUpdate)
			UpdateHintValues();
	}

	private void UpdateOwnerFromHints()
	{
		check(CurrentOwner.HasControl());

		if (!CanTransferOwner())
			return;

		// Only allow switching based on hints once per second
		if (LastHintOwnerSwitch >= 0.0 && Time::GetGameTimeSince(LastHintOwnerSwitch) < 1.0)
			return;

		// Switch to new owner based on hint
		AHazePlayerCharacter HintedOwner = GetMostHintedOwner();
		if (HintedOwner != CurrentOwner)
		{
			NetTransferOwner(HintedOwner);
			LastHintOwnerSwitch = Time::GetGameTimeSeconds();
		}
	}

	private AHazePlayerCharacter GetMostHintedOwner()
	{
		float BiggestHint = -MAX_flt;
		AHazePlayerCharacter BestPlayer = CurrentOwner;

		for (auto Player : Game::Players)
		{
			auto& PlayerData = LockData[Player];
			for (auto& Hint : PlayerData.Hints)
			{
				if (Hint.HintWeight > BiggestHint)
				{
					BiggestHint = Hint.HintWeight;
					BestPlayer = Player;
				}
			}
		}

		return BestPlayer;
	}

	UFUNCTION(NetFunction)
	private void NetReleasedLock(AHazePlayerCharacter Player)
	{
		auto& PlayerData = LockData[Player];
		PlayerData.bIsLocked = false;
		CurrentLockedBy = nullptr;

		TEMPORAL_LOG(this).Event(f"Release lock for {Player.Name}");

		// After we release a lock, the other side isn't allowed to lock it until
		// they have received all pending crumbs we sent while the lock was active by our side.
		// This provides a stronger guarantee that operations done while locked are applied on both sides,
		// otherwise doing Acquire->Crumb->Release could let the other side lock _before_ they execute Crumb.
		DisallowLockingCounter += 1;
		if (CurrentOwner.HasControl())
			CrumbAllowLocking();
	}

	UFUNCTION(NetFunction)
	private void NetAcquiredLock(AHazePlayerCharacter Player)
	{
		auto& PlayerData = LockData[Player];
		PlayerData.bIsLocked = true;
		CurrentLockedBy = Player;

		TEMPORAL_LOG(this).Event(f"Acquire lock for {Player.Name}");

		if (Player.HasControl())
		{
			auto TriggerDelegates = PlayerData.LockDelegates;
			PlayerData.LockDelegates.Empty();

			for (auto DelegateData : TriggerDelegates)
				DelegateData.Delegate.ExecuteIfBound(Player, DelegateData.Instigator);
		}
	}

	UFUNCTION(NetFunction)
	private void NetWantLock(bool bWorldControl, bool bWantLock)
	{
		if (bWorldControl == Network::HasWorldControl())
			return;
		
		bOtherSideWantsLock = bWantLock;
		SetComponentTickEnabled(true);
	}

	UFUNCTION(NetFunction)
	private void NetTransferOwner(AHazePlayerCharacter NewOwner)
	{
		TEMPORAL_LOG(this).Event(f"Transfer lock owner to {NewOwner.Name}");

		CurrentOwner = NewOwner;
		SetComponentTickEnabled(true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbAllowLocking()
	{
		DisallowLockingCounter -= 1;
	}

	private bool CanTransferOwner()
	{
		return true;
	}
};