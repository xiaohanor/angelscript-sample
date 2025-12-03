class USkylineDroneBossLeftAttachCapability : USkylineDroneBossChildCapability
{
	default CapabilityTags.Add(SkylineDroneBossTags::SkylineDroneBossAttach);

	FVector SpawnLocation;
	FRotator SpawnRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		auto Phase = Boss.CurrentPhase;
		if (Phase == nullptr)
			return false;
		
		if (Phase.LeftAttachmentSpawnAmount > 0 &&
			Boss.PhaseLeftAttachmentsSpawned > Phase.LeftAttachmentSpawnAmount)
			return false;

		if (Phase.LeftAttachmentClass == nullptr)
			return false;

		auto& Attachment = Boss.LeftAttachment;
		if (Attachment.IsValid())
			return false;

		float TimeSinceDestroyed = Time::GetGameTimeSince(Attachment.DestroyTimestamp);
		if (TimeSinceDestroyed < Phase.LeftAttachmentSpawnDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		auto Phase = Boss.CurrentPhase;
		if (ActiveDuration > Phase.LeftAttachmentSpawnDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		const auto Phase = Boss.CurrentPhase;
		auto& Attachment = Boss.LeftAttachment;

		SpawnLocation = Boss.LeftPivot.WorldLocation + Boss.LeftPivot.UpVector * 1500.0;
		SpawnRotation = Boss.LeftPivot.WorldRotation;

		auto AttachmentActor = Cast<ASkylineDroneBossAttachment>(
			SpawnActor(Phase.LeftAttachmentClass, SpawnLocation, SpawnRotation, bDeferredSpawn = true)
		);
		AttachmentActor.AttachToComponent(Boss.LeftPivot);
		AttachmentActor.Boss = Boss;
		FinishSpawningActor(AttachmentActor);

		Attachment.Actor = AttachmentActor;
		Attachment.SpawnTimestamp = Time::GameTimeSeconds;

		FSkylineDroneBossAttachmentSpawnedData SpawnedData;
		SpawnedData.Attachment = Attachment.Actor;
		USkylineDroneBossEventHandler::Trigger_AttachmentSpawned(Boss, SpawnedData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto& Attachment = Boss.LeftAttachment;
		if (Attachment.IsValid())
		{
			Attachment.Actor.ActorRelativeLocation = FVector::ZeroVector;
			Attachment.Actor.Activate(Boss);

			FSkylineDroneBossAttachmentConnectedData ConnectedData;
			ConnectedData.Attachment = Attachment.Actor;
			USkylineDroneBossEventHandler::Trigger_AttachmentConnected(Boss, ConnectedData);
		}

		Attachment.AttachTimestamp = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const auto Phase = Boss.CurrentPhase;
		float Alpha = Math::Clamp(ActiveDuration / Phase.LeftAttachmentSpawnDuration, 0.0, 1.0);
		
		float LocationFraction = Alpha;
		if (Phase.LeftSpawnCurve != nullptr)
			LocationFraction = Phase.LeftSpawnCurve.GetFloatValue(Alpha);

		auto& Attachment = Boss.LeftAttachment;
		if (Attachment.IsValid())
		{
			FVector Location = Math::Lerp(SpawnLocation, Boss.LeftPivot.WorldLocation, LocationFraction);
			Attachment.Actor.SetActorLocation(Location);
		}
	}
}