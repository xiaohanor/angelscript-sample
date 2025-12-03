event void FStealthGuardHitEvent(APrisonStealthGuard Guard);
event void FStealthCameraHitEvent(APrisonStealthCamera Camera);

event void FStealthPlayerDetectedEvent(APrisonStealthEnemy DetectedBy, AHazePlayerCharacter DetectedPlayer);
event void FStealthPlayerEnterVisionEvent(AHazePlayerCharacter Player);
event void FStealthPlayerExitVisionEvent(AHazePlayerCharacter Player);

event void FStealthAnyPlayerDetectedEvent();
event void FStealthFirstPlayerEnterVisionEvent();
event void FStealthAllPlayersExitVisionEvent();

struct FPrisonStealthPlayerVisibility
{
	TPerPlayer<bool> bVisible;

	bool IsAnyPlayerVisible() const
	{
		return bVisible[EHazePlayer::Mio] && bVisible[EHazePlayer::Zoe];
	}
}

#if !RELEASE
namespace DevTogglesPrisonStealth
{
	const FHazeDevToggleBool PrintEvents;
	const FHazeDevToggleBool DrawVision;
};
#endif

struct FPrisonPendingPlayerKillData
{
	AHazePlayerCharacter Player;
	float TimeOfStartKill;
	APrisonStealthEnemy DetectedBy;
}

/**
 * Manages the stealth guards.
 * Broadcasts events to be handled in level blueprint during the stealth section.
 */
class UPrisonStealthManager : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	FStealthGuardHitEvent OnStealthGuardHit;

	UPROPERTY()
	FStealthCameraHitEvent OnStealthCameraHit;

	UPROPERTY()
	FStealthPlayerDetectedEvent OnStealthPlayerDetected;

	UPROPERTY()
	FStealthPlayerEnterVisionEvent OnStealthPlayerEnterVision;

	UPROPERTY()
	FStealthPlayerExitVisionEvent OnStealthPlayerExitVision;

	UPROPERTY()
	FStealthAnyPlayerDetectedEvent OnStealthAnyPlayerDetected;

	UPROPERTY()
	FStealthFirstPlayerEnterVisionEvent OnStealthFirstPlayerEnterVision;

	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY()
	FStealthAllPlayersExitVisionEvent OnStealthAllPlayersExitVision;

	private TMap<APrisonStealthEnemy, FPrisonStealthPlayerVisibility> EnemiesAndPlayerVisibility;
	private TArray<FPrisonPendingPlayerKillData> PendingKillData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if !RELEASE
		DevTogglesPrisonStealth::PrintEvents.MakeVisible();
		DevTogglesPrisonStealth::DrawVision.MakeVisible();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		devCheck(IsAnyPlayerPendingKill(), "Ran tick even though no player is pending kill");
		for(int i = PendingKillData.Num() - 1; i >= 0; i--)
		{
			FPrisonPendingPlayerKillData Data = PendingKillData[i];
			if(Time::GetGameTimeSince(Data.TimeOfStartKill) > 0.35)
			{
				FVector Direction = Data.DetectedBy.ActorLocation - Data.Player.GetActorLocation();

				Data.Player.KillPlayer(FPlayerDeathDamageParams(Direction,2.5,false),Data.DetectedBy.DeathEffect);
				PendingKillData.RemoveAt(i);
				SetComponentTickEnabled(IsAnyPlayerPendingKill());
			}
		}
	}

	void OnGuardHit(APrisonStealthGuard Guard)
	{
		OnStealthGuardHit.Broadcast(Guard);

#if !RELEASE
		if(DevTogglesPrisonStealth::PrintEvents.IsEnabled())
			Print(f"OnGuardHit: {Guard=}");
#endif
	}

	void OnCameraHit(APrisonStealthCamera Camera)
	{
		OnStealthCameraHit.Broadcast(Camera);

#if !RELEASE
		if(DevTogglesPrisonStealth::PrintEvents.IsEnabled())
			Print(f"OnCameraHit: {Camera=}");
#endif
	}

	void OnPlayerDetected(APrisonStealthEnemy DetectedBy, AHazePlayerCharacter Player)
	{
		check(Player.HasControl());
		CrumbOnPlayerDetected(DetectedBy, Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnPlayerDetected(APrisonStealthEnemy DetectedBy, AHazePlayerCharacter Player)
	{
		DeathEffect = DetectedBy.DeathEffect;
		SetPlayerPendingKill(Player, DetectedBy);
		OnStealthPlayerDetected.Broadcast(DetectedBy, Player);
		RemovePlayerFromAllEnemyVisions(Player);

#if !RELEASE
		if(DevTogglesPrisonStealth::PrintEvents.IsEnabled())
			Print(f"OnStealthPlayerDetected: {DetectedBy=}, {Player=}");
#endif
	}

	bool IsAnyPlayerPendingKill() const
	{
		return PendingKillData.Num() > 0;
	}

	void SetPlayerPendingKill(AHazePlayerCharacter Player, APrisonStealthEnemy DetectedBy)
	{
		FPrisonPendingPlayerKillData KillData;
		KillData.DetectedBy = DetectedBy;
		KillData.Player = Player;
		KillData.TimeOfStartKill = Time::GetGameTimeSeconds();
		PendingKillData.Add(KillData);
		SetComponentTickEnabled(true);
	}

	void OnPlayerEnterVision(APrisonStealthEnemy DetectedBy, AHazePlayerCharacter Player)
	{
		check(Player.HasControl());
		CrumbOnPlayerEnterVision(DetectedBy, Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnPlayerEnterVision(APrisonStealthEnemy DetectedBy, AHazePlayerCharacter Player)
	{
		const bool bWasFirst = EnemiesAndPlayerVisibility.Num() == 0;
		const bool bWasNew = !EnemiesAndPlayerVisibility.Contains(DetectedBy);

		FPrisonStealthPlayerVisibility& Visibility = EnemiesAndPlayerVisibility.FindOrAdd(DetectedBy);
		check(!Visibility.bVisible[Player]);
		Visibility.bVisible[Player] = true;

		if(bWasNew)
		{
			OnStealthPlayerEnterVision.Broadcast(Player);

#if !RELEASE
		if(DevTogglesPrisonStealth::PrintEvents.IsEnabled())
			Print(f"OnStealthPlayerEnterVision: {Player=}");
#endif
		}

		if(bWasFirst)
		{
			OnStealthFirstPlayerEnterVision.Broadcast();

#if !RELEASE
		if(DevTogglesPrisonStealth::PrintEvents.IsEnabled())
			Print(f"OnStealthFirstPlayerEnterVision");
#endif
		}
	}

	void OnPlayerExitVision(APrisonStealthEnemy DetectedBy, AHazePlayerCharacter Player)
	{
		check(Player.HasControl());
		CrumbOnPlayerExitVision(DetectedBy, Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnPlayerExitVision(APrisonStealthEnemy DetectedBy, AHazePlayerCharacter Player)
	{
		if(!EnemiesAndPlayerVisibility.Contains(DetectedBy))
			return;

		if(!IsPlayerInVision(Player))
			return;

		check(EnemiesAndPlayerVisibility.Num() > 0);
		check(EnemiesAndPlayerVisibility.Contains(DetectedBy));

		FPrisonStealthPlayerVisibility& Visibility = EnemiesAndPlayerVisibility.FindOrAdd(DetectedBy, FPrisonStealthPlayerVisibility());

		check(Visibility.bVisible[Player]);
		Visibility.bVisible[Player] = false;

		bool bRemoved = false;
		if(!Visibility.IsAnyPlayerVisible())
		{
			// If this player is no longer seen by anything, broadcast PlayerExitVision
			bRemoved = EnemiesAndPlayerVisibility.Remove(DetectedBy);
			OnStealthPlayerExitVision.Broadcast(Player);

#if !RELEASE
			if(DevTogglesPrisonStealth::PrintEvents.IsEnabled())
				Print(f"OnStealthPlayerExitVision: {Player=}");
#endif
		}

		// If we no longer have any player within visibility, broadcast AllPlayersExitVision
		if(EnemiesAndPlayerVisibility.Num() == 0)
		{
			OnStealthAllPlayersExitVision.Broadcast();

#if !RELEASE
			if(DevTogglesPrisonStealth::PrintEvents.IsEnabled())
				Print("OnStealthAllPlayersExitVision");
#endif
		}
	}

	private bool IsPlayerInVision(AHazePlayerCharacter Player)
	{
		for(auto It : EnemiesAndPlayerVisibility)
		{
			if(It.Value.bVisible[Player])
				return true;
		}

		return false;
	}

	private void RemovePlayerFromAllEnemyVisions(AHazePlayerCharacter Player)
	{
		TArray<APrisonStealthEnemy> EnemiesToRemove;
		for(auto& It : EnemiesAndPlayerVisibility)
		{
			bool bRemoved = false;
			if(It.Value.bVisible[Player])
			{
				It.Value.bVisible[Player] = false;
				bRemoved = true;
			}

			if(!It.Value.IsAnyPlayerVisible())
				EnemiesToRemove.Add(It.Key);
		}

		for(auto EnemyToRemove : EnemiesToRemove)
		{
			EnemiesAndPlayerVisibility.Remove(EnemyToRemove);
		}
	}
}