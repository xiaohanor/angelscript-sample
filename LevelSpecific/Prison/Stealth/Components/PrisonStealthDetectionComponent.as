struct FPrisonStealthEnemyPlayerDetectionData
{
	// The player has entered an enemies visibility, and is being searched for
	bool bPlayerIsInSight = false;

	// Where the player was last seen
	FPrisonStealthPlayerLastSeen LastSeenData;

	// An alpha of how detected this player is
	UHazeCrumbSyncedFloatComponent SyncedDetectionAlpha = nullptr;

	// The player was fully detected by an enemy, and was killed
	bool bHasDetectedPlayer = false;
}

struct FPrisonStealthPlayerLastSeen
{
	float Time = -1;
	FVector Location = FVector::ZeroVector;

	bool IsValid() const
	{
		return Time >= 0;
	}

	bool opEquals(FPrisonStealthPlayerLastSeen Other) const
	{
		if(!Math::IsNearlyEqual(Time, Other.Time, KINDA_SMALL_NUMBER))
			return false;

		if(!Location.Equals(Other.Location))
			return false;

		return true;
	}
}

UCLASS(NotBlueprintable)
class UPrisonStealthDetectionComponent : UActorComponent
{
	access EnemyInternal = private, APrisonStealthEnemy;

	UPROPERTY(EditDefaultsOnly)
	EHazePlayer PlayerToDetect = EHazePlayer::Mio;

	UPROPERTY(EditAnywhere)
	bool bIsEnabled = true;

	private FPrisonStealthEnemyPlayerDetectionData DetectionData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Player = Game::GetPlayer(PlayerToDetect);

		if(!bIsEnabled)
			return;

		FString ComponentName = "SyncedDetectionAlpha_";
		if(Player.IsMio())
			ComponentName += "Mio";
		else
			ComponentName += "Zoe";

		UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");

		DetectionData.SyncedDetectionAlpha = UHazeCrumbSyncedFloatComponent::GetOrCreate(Owner, FName(ComponentName));
		DetectionData.SyncedDetectionAlpha.OverrideSyncRate(EHazeCrumbSyncRate::Standard);
		DetectionData.SyncedDetectionAlpha.OverrideControlSide(Player);
	}

	UFUNCTION()
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		// When the player respawns, reset everything
		DetectionData.bPlayerIsInSight = false;

		DetectionData.LastSeenData = FPrisonStealthPlayerLastSeen();
		
		DetectionData.SyncedDetectionAlpha.SetValue(0);
		DetectionData.SyncedDetectionAlpha.TransitionSync(this);

		DetectionData.bHasDetectedPlayer = false;
	}

	bool IsPlayerInSight() const
	{
		check(bIsEnabled);
		return DetectionData.bPlayerIsInSight;
	}

	access:EnemyInternal
	void SetIsPlayerInSight(bool bIsPlayerInSight)
	{
		check(bIsEnabled);
		check(PlayerHasControl());

		if(IsPlayerInSight() == bIsPlayerInSight)
			return;

		CrumbSetIsPlayerInSight(bIsPlayerInSight);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetIsPlayerInSight(bool bIsPlayerInSight)
	{
		DetectionData.bPlayerIsInSight = bIsPlayerInSight;
	}

	bool HasDetectedPlayer() const
	{
		check(bIsEnabled);
		return DetectionData.bHasDetectedPlayer;
	}

	access:EnemyInternal
	void SetHasDetectedPlayer(bool bHasDetectedPlayer)
	{
		check(bIsEnabled);
		check(PlayerHasControl());

		if(HasDetectedPlayer() == bHasDetectedPlayer)
			return;

		CrumbSetHasDetectedPlayer(bHasDetectedPlayer);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetHasDetectedPlayer(bool bHasDetectedPlayer)
	{
		DetectionData.bHasDetectedPlayer = bHasDetectedPlayer;
	}

	FPrisonStealthPlayerLastSeen GetLastSeenData() const
	{
		check(bIsEnabled);
		return DetectionData.LastSeenData;
	}

	void SetLastSeenData(FPrisonStealthPlayerLastSeen LastSeenData)
	{
		check(bIsEnabled);
		check(PlayerHasControl());

		if(DetectionData.LastSeenData == LastSeenData)
			return;

		CrumbSetLastSeenData(LastSeenData);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetLastSeenData(FPrisonStealthPlayerLastSeen LastSeenData)
	{
		DetectionData.LastSeenData = LastSeenData;
	}

	float GetDetectionAlpha() const
	{
		check(bIsEnabled);
		return DetectionData.SyncedDetectionAlpha.Value;
	}

	void SetDetectionAlpha(float Value, bool bSnap)
	{
		check(bIsEnabled);
		check(PlayerHasControl());

		float PreviousValue = DetectionData.SyncedDetectionAlpha.Value;
		DetectionData.SyncedDetectionAlpha.SetValue(Value);

		if(Owner.IsActorBeingDestroyed() || !Owner.HasActorBegunPlay())
			return;

		if(bSnap && !Math::IsNearlyEqual(Value, PreviousValue))
			DetectionData.SyncedDetectionAlpha.SnapRemote();
	}	

	bool HasSpottedPlayer() const
	{
		return GetDetectionAlpha() > 0.0;
	}

	bool PlayerHasControl() const
	{
		return Game::GetPlayer(PlayerToDetect).HasControl();
	}
};