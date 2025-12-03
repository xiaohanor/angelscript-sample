event void FDesertOnPlayerBecameHunted();
event void FDesertOnPlayerStoppeBeingHunted();
UCLASS(Abstract)
class USandSharkPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset TargetCameraSettings;

	/**CameraShake settings used when target is chased.*/
	UPROPERTY(EditDefaultsOnly, Category = "Camera Shake")
	FSandSharkCameraShake TargetCameraShake;

	/**CameraShake settings used when target is NOT chased.*/
	UPROPERTY(EditDefaultsOnly, Category = "Camera Shake")
	FSandSharkCameraShake NonTargetCameraShake;

	/**Forcefeedback settings used when target is chased.*/
	UPROPERTY(EditDefaultsOnly, Category = "Force Feedback")
	FSandSharkForceFeedback TargetForceFeedback;

	/**Forcefeedback settings used when target is NOT chased.*/
	UPROPERTY(EditDefaultsOnly, Category = "Force Feedback")
	FSandSharkForceFeedback NonTargetForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	UPlayerFloorMotionSettings DefaultOnSandFloorMotionSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	UPlayerAirMotionSettings DefaultOnSandAirMotionSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	UPlayerStepDashSettings DashSettingsOnSand;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	UPlayerAirDashSettings AirDashSettingsOnSand;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	UPlayerSlideJumpSettings DefaultOnSandPlayerSlideJumpSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	UPlayerSlideSettings DefaultOnSandPlayerSlideSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	UPlayerSlideSettings DefaultOnSandPlayerUnwalkableSlideSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Movement")
	UPlayerJumpSettings DefaultOnSandJumpSettings;

	UPROPERTY(EditDefaultsOnly)
	UHazeLocomotionFeatureBundle FeatureBundle;

	AHazePlayerCharacter Player;

	UPROPERTY()
	FDesertOnPlayerBecameHunted OnBecameHunted;

	UPROPERTY()
	FDesertOnPlayerBecameHunted OnStoppedBeingHunted;

	// On Sand
	bool bHasTouchedSand = false;

	// Contextual Moves
	bool bIsPerformingContextualMove = false;
	bool bIsPerching = false;

	bool bIsThumping = false;

	// Safe Point
	bool bOnSafePoint = false;

	private TSet<ASandShark> SharksHuntingPlayer;

	ASandSharkSafePoint LastSafePoint;

	uint CachedHitUnderPlayerFrame = 0;
	FHitResult CachedHitUnderPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	bool IsBeingHunted() const
	{
		return SharksHuntingPlayer.Num() > 0;
	}

	void AddHuntedInstigator(ASandShark Shark)
	{
		if (SharksHuntingPlayer.Num() == 0)
		{
			FSandSharkHuntedParams Params;
			Params.Player = Player;
			USandSharkPlayerEventHandler::Trigger_OnBecameHunted(Player, Params);
			OnBecameHunted.Broadcast();
		}
		SharksHuntingPlayer.Add(Shark);
	}
	
	void RemoveHuntedInstigator(ASandShark Shark)
	{
		bool bWasHunted = SharksHuntingPlayer.Num() > 0;
		SharksHuntingPlayer.Remove(Shark);
		if (SharksHuntingPlayer.Num() == 0 && bWasHunted)
		{
			FSandSharkHuntedParams Params;
			Params.Player = Player;
			USandSharkPlayerEventHandler::Trigger_OnStoppedBeingHunted(Player, Params);
			OnStoppedBeingHunted.Broadcast();
		}
	}
	
	ASandShark GetClosestSharkHuntingPlayer()
	{
		float ClosestDistance = MAX_flt;
		ASandShark ClosestShark = nullptr;
		for (auto Shark : SharksHuntingPlayer)
		{
			float SquaredDist = Player.GetSquaredDistanceTo(Shark);
			if (SquaredDist <= ClosestDistance)
			{
				ClosestShark = Shark;
				ClosestDistance = SquaredDist;
			}
		}
		return ClosestShark;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const FString PlayerName = Player.IsMio() ? "Mio" : "Zoe";

		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Value("bHasTouchedSand", bHasTouchedSand);
		TemporalLog.Value("bIsPerformingContextualMove", bIsPerformingContextualMove);
		TemporalLog.Value("bIsPerching", bIsPerching);
		TemporalLog.Value("bOnSafePoint", bOnSafePoint);
		TemporalLog.Value("LastSafePoint", LastSafePoint);
		TemporalLog.Sphere("HitLocation", CachedHitUnderPlayer.Location, 20, FLinearColor::White, 5);
		TemporalLog.Line("HitTrace", CachedHitUnderPlayer.TraceStart, CachedHitUnderPlayer.TraceEnd, 5, FLinearColor::Blue);
	}
#endif

	/**
	 * We have multiple functions that wanted to know what was beneath the player,
	 * so we cached one trace here instead of doing multiple per frame.
	 */
	FHitResult GetHitUnderPlayer(float MaxDistance = SandShark::OnSandTraceDefaultMaxDistance)
	{
		float DistanceToTrace = Math::Max(MaxDistance, 5000);
		if (CachedHitUnderPlayerFrame != Time::FrameNumber || (CachedHitUnderPlayer.Time > 0 && DistanceToTrace > CachedHitUnderPlayer.Distance / CachedHitUnderPlayer.Time))
		{
			FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
			CachedHitUnderPlayer = TraceSettings.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - Player.MovementWorldUp * DistanceToTrace);
			CachedHitUnderPlayerFrame = Time::FrameNumber;
		}

		if (CachedHitUnderPlayer.Distance > MaxDistance)
			return FHitResult();

		return CachedHitUnderPlayer;
	}

	ASandSharkSafePoint GetLastSafePoint() const
	{
		return LastSafePoint;
	}
}