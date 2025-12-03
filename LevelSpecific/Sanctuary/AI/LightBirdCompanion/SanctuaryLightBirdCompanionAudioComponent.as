class USanctuaryLightBirdCompanionAudioComponent : UActorComponent
{
	// Launch alpha is only properly calculated on control side
	UHazeCrumbSyncedFloatComponent SyncedLaunchAlpha;

	// Recall can be calculated locally
	float RecallAlpha = 0.0;
	bool bWasLaunched = false;
	FVector RecallStartLocation;
	const float RecallDoneThreshold = 200.0;

	USanctuaryLightBirdCompanionComponent CompanionComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CompanionComp = USanctuaryLightBirdCompanionComponent::Get(Owner);

		SyncedLaunchAlpha = UHazeCrumbSyncedFloatComponent::Create(Owner, n"AudioSyncedLaunchAlpha");		
		SyncedLaunchAlpha.OverrideSyncRate(EHazeCrumbSyncRate::Standard);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CompanionComp == nullptr)
			return;

		// Keep track of how far companion has come to reaching player from wherever it was last launched
		if ((CompanionComp.State == ELightBirdCompanionState::LaunchStart) || 
			(CompanionComp.State == ELightBirdCompanionState::Launched) ||
			(CompanionComp.State == ELightBirdCompanionState::LaunchAttached))
		{
			bWasLaunched = true;
			RecallStartLocation = Owner.ActorLocation;	
			RecallAlpha = 0.0;
		}
		else if (bWasLaunched)
		{
			FVector RecallDestination = CompanionComp.Player.FocusLocation;
			if (Owner.ActorLocation.IsWithinDist(RecallDestination, RecallDoneThreshold))
			{
				bWasLaunched = false;
				RecallAlpha = 1.0;
			}
			else
			{
				float RecallDistance = Math::Max(1.0, RecallStartLocation.Distance(RecallDestination) - RecallDoneThreshold);	
				float CurrentDistance = Math::Max(1.0, Owner.ActorLocation.Distance(RecallDestination) - RecallDoneThreshold);
				RecallAlpha = Math::Min(1.0, 1.0 - CurrentDistance / RecallDistance);
			}
		}

		// Debug::DrawDebugString(Owner.ActorLocation + FVector(0,0,80), "LaunchAlpha: " + LaunchDistanceAlpha, Scale = 1.4);		
		// Debug::DrawDebugString(Owner.ActorLocation + FVector(0,0,20), "RecallAlpha: " + RecallDistanceAlpha, FLinearColor::Gray, Scale = 1.4);		
	}

	float GetLaunchDistanceAlpha() const property
	{
		return SyncedLaunchAlpha.Value;
	}

	float GetRecallDistanceAlpha() const property
	{
		return RecallAlpha;
	}

	void SetLaunchDistanceAlpha(float Alpha) property	
	{
		if (HasControl())
			SyncedLaunchAlpha.Value = Alpha;
	}
};
