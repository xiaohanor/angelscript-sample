class UStoneBeastTailSegmentImitationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 120;
	//default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AStoneBeastTailSegment TailSegment;

	AStoneBeastTailSegment SegmentToImitate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TailSegment = Cast<AStoneBeastTailSegment>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Game::Mio.bIsParticipatingInCutscene)
			return false;

		if (!TailSegment.TailSegmentToImitate.IsValid())
			return false;

		auto ImitationSegment = TailSegment.TailSegmentToImitate.Get();

		if (!ImitationSegment.bIsActive && !ImitationSegment.bIsReturning)
			return false;

		return true;
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SegmentToImitate.bIsActive && !SegmentToImitate.bIsReturning)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SegmentToImitate = TailSegment.TailSegmentToImitate.Get();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TailSegment.SetSegmentTransform(TailSegment.TailSegmentToImitate.Get().SegmentTransform);
	}

	// UFUNCTION(BlueprintOverride)
	// void OnLogState(FTemporalLog TemporalLog)
	// {
	// 	TemporalLog.Value("OwnerName", Owner.ActorNameOrLabel);
	// 	TEMPORAL_LOG(f"{Owner.ActorNameOrLabel}")
	// 		.Value("ImitationCapability", IsActive() ? "Active" : (IsBlocked() ? "Blocked" : "Inactive"));
	// }


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TailSegment.SetSegmentTransform(TailSegment.TailSegmentToImitate.Get().SegmentTransform);
	}
};