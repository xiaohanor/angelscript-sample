class USkylineDroneBossRightAttachCapability : USkylineDroneBossChildCapability
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
		
		if (Phase.RightAttachmentSpawnAmount > 0 &&
			Boss.PhaseRightAttachmentsSpawned > Phase.RightAttachmentSpawnAmount)
			return false;

		if (Phase.RightAttachmentClass == nullptr)
			return false;

		auto& Attachment = Boss.RightAttachment;
		if (Attachment.IsValid())
			return false;

		float TimeSinceDestroyed = Time::GetGameTimeSince(Attachment.DestroyTimestamp);
		if (TimeSinceDestroyed < Phase.RightAttachmentSpawnDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		auto Phase = Boss.CurrentPhase;
		if (ActiveDuration > Phase.RightAttachmentSpawnDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		const auto Phase = Boss.CurrentPhase;
		auto& Attachment = Boss.RightAttachment;

		SpawnLocation = Boss.RightPivot.WorldLocation + Boss.RightPivot.UpVector * 1500.0;
		SpawnRotation = Boss.RightPivot.WorldRotation;

		auto AttachmentActor = Cast<ASkylineDroneBossAttachment>(
			SpawnActor(Phase.RightAttachmentClass, SpawnLocation, SpawnRotation, bDeferredSpawn = true)
		);
		AttachmentActor.AttachToComponent(Boss.RightPivot);
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
		auto& Attachment = Boss.RightAttachment;
		
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
		float Alpha = Math::Clamp(ActiveDuration / Phase.RightAttachmentSpawnDuration, 0.0, 1.0);
		
		float LocationFraction = Alpha;
		if (Phase.RightSpawnCurve != nullptr)
			LocationFraction = Phase.RightSpawnCurve.GetFloatValue(Alpha);

		auto& Attachment = Boss.RightAttachment;
		if (Attachment.IsValid())
		{
			FVector Location = Math::Lerp(SpawnLocation, Boss.RightPivot.WorldLocation, LocationFraction);
			Attachment.Actor.SetActorLocation(Location);
		}
	}
}