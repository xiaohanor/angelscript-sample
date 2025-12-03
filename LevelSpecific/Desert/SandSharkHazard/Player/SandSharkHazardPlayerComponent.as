UCLASS(Abstract)
class USandSharkHazardPlayerComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	uint CachedHitUnderPlayerFrame = 0;
	FHitResult CachedHitUnderPlayer;

	bool bHasTouchedSand = false;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASandSharkHazard> HazardClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value(f"bHasTouchedSand", bHasTouchedSand);
	}
	#endif

	FHitResult GetHitUnderPlayer(float MaxDistance = SandShark::OnSandTraceDefaultMaxDistance)
	{
		float DistanceToTrace = Math::Max(MaxDistance, 5000);
		if(CachedHitUnderPlayerFrame != Time::FrameNumber || (CachedHitUnderPlayer.Time > 0 && DistanceToTrace > CachedHitUnderPlayer.Distance / CachedHitUnderPlayer.Time))
		{
			FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
			CachedHitUnderPlayer = TraceSettings.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - Player.MovementWorldUp * DistanceToTrace);
			CachedHitUnderPlayerFrame = Time::FrameNumber;
		}

		if(CachedHitUnderPlayer.Distance > MaxDistance)
			return FHitResult();

		return CachedHitUnderPlayer;
	}
};