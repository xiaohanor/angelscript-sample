/**
 * Handles applying a mesh offset to smooth over discrepancies in crumb syncing relative to moving floors.
 */
class UPlayerSyncLocationMeshOffsetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"SyncLocationMeshOffset");

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UHazeCrumbSyncedActorPositionComponent CrumbSyncPosition;
	UPlayerSyncLocationMeshOffsetComponent LocationOffsetComp;
	UPlayerMovementComponent MoveComp;

	const float TELEPORT_THRESHOLD = 500.0;

	bool bHasLocation = false;
	USceneComponent LastRelativeComponent;
	FVector LastLocationError;
	float LastCrumbTrailTime = 0.0;

	bool bHasPendingLocationError = false;
	float PendingLocationErrorStartTime = 0.0;
	float PendingLocationErrorEndTime = 0.0;
	FVector PendingLocationError;
	float PendingLocationErrorAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CrumbSyncPosition = UHazeCrumbSyncedActorPositionComponent::Get(Player);
		LocationOffsetComp = UPlayerSyncLocationMeshOffsetComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (HasControl())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasPendingLocationError = false;

		bHasLocation = true;
		LastRelativeComponent = nullptr;
		LastCrumbTrailTime = CrumbSyncPosition.GetCrumbTrailReceiveTime();
		LastLocationError = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.MeshOffsetComponent.ClearOffset(this);
		Player.CameraOffsetComponent.ClearOffset(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// When the crumb trail switches which component it is relative to, accumulate the position error to lerp away
		if (MoveComp.HasMovedWithSyncedLocationThisFrame())
		{
			FHazeSyncedActorPosition SourcePosition;
			float SourceTime = 0.0;
			CrumbSyncPosition.GetCurrentSourcePositionData(SourcePosition, SourceTime);

			FHazeSyncedActorPosition TargetPosition;
			float TargetTime = 0.0;
			CrumbSyncPosition.GetCurrentTargetPositionData(TargetPosition, TargetTime);

			// If we're still lerping in an error, handle that
			if (bHasPendingLocationError)
			{
				float CurrentTime = CrumbSyncPosition.GetCrumbTrailReceiveTime();
				float NewAlpha = Math::Saturate((CurrentTime - PendingLocationErrorStartTime) / (PendingLocationErrorEndTime - PendingLocationErrorStartTime));

				LocationOffsetComp.CurrentMeshOffset -= PendingLocationError * (NewAlpha - PendingLocationErrorAlpha);
				PendingLocationErrorAlpha = NewAlpha;

				if (NewAlpha >= 1.0)
				{
					bHasPendingLocationError = false;
				}
			}

			// Detect if we have a new error that we need to start lerping in
			if (bHasLocation)
			{
				if (CrumbSyncPosition.IsValidToUseDataAtCrumbTrailReceiveTime(LastCrumbTrailTime))
				{
					if (LastRelativeComponent != TargetPosition.RelativeComponent)
					{
						// Our position is now relative to a different component,
						// if we had any error from our previous relative component, we need to
						// start lerping that away
						if (SourceTime == TargetTime || SourcePosition.RelativeComponent == TargetPosition.RelativeComponent)
						{
							LocationOffsetComp.CurrentMeshOffset -= (TargetPosition.WorldLocation - TargetPosition.ControlOriginalWorldLocation);
							LocationOffsetComp.CurrentMeshOffset += LastLocationError;
						}
						else
						{
							bHasPendingLocationError = true;

							PendingLocationError = TargetPosition.WorldLocation - TargetPosition.ControlOriginalWorldLocation;
							PendingLocationError -= LastLocationError;

							if (PendingLocationError.Size() < TELEPORT_THRESHOLD)
							{
								PendingLocationErrorAlpha = CrumbSyncPosition.GetCurrentSourceTargetAlpha();
								PendingLocationErrorStartTime = SourceTime;
								PendingLocationErrorEndTime = TargetTime;

								LocationOffsetComp.CurrentMeshOffset -= PendingLocationError * PendingLocationErrorAlpha;
							}
							else
							{
								// If it's too far away, don't do the lerp but just do a snap
								bHasPendingLocationError = false;
							}
						}
					}
				}
				else
				{
					// We transitioned the crumb trail, so we can't actually use this data
					// Likely we teleported away
				}
			}

			bHasLocation = true;
			LastRelativeComponent = TargetPosition.RelativeComponent;
			LastLocationError = TargetPosition.WorldLocation - TargetPosition.ControlOriginalWorldLocation;
			LastCrumbTrailTime = CrumbSyncPosition.GetCrumbTrailReceiveTime();
		}
		else
		{
			bHasLocation = true;
			LastRelativeComponent = nullptr;
			LastLocationError = FVector::ZeroVector;
			LastCrumbTrailTime = CrumbSyncPosition.GetCrumbTrailReceiveTime();
		}

		// If we have a position error, lerp it away
		LocationOffsetComp.CurrentMeshOffset = Math::VInterpTo(LocationOffsetComp.CurrentMeshOffset, FVector::ZeroVector, DeltaTime, 5.0);
		
		// If the mesh offset is super big, just snap it away
		if (LocationOffsetComp.CurrentMeshOffset.Size() > 500.0)
			LocationOffsetComp.CurrentMeshOffset = FVector::ZeroVector;

		// Apply the mesh offset
		if (LocationOffsetComp.CurrentMeshOffset.IsNearlyZero(0.1))
		{
			LocationOffsetComp.CurrentMeshOffset = FVector::ZeroVector;
			Player.MeshOffsetComponent.ClearOffset(this);
			Player.CameraOffsetComponent.ClearOffset(this);
		}
		else
		{
			Player.MeshOffsetComponent.SnapToLocation(this, Player.RootOffsetComponent.WorldLocation + LocationOffsetComp.CurrentMeshOffset, EInstigatePriority::Low);
			Player.CameraOffsetComponent.SnapToLocation(this, Player.RootOffsetComponent.WorldLocation + LocationOffsetComp.CurrentMeshOffset, EInstigatePriority::Low);
		}

#if !RELEASE
		TEMPORAL_LOG(this)
			.Value("CurrentMeshOffset", LocationOffsetComp.CurrentMeshOffset)
			.Value("bHasPendingLocationError", bHasPendingLocationError)
		;

		if (bHasPendingLocationError)
		{
			TEMPORAL_LOG(this)
				.Value("PendingLocationError", PendingLocationError)
				.Value("PendingLocationErrorAlpha", PendingLocationErrorAlpha)
				.Value("PendingLocationErrorStartTime", PendingLocationErrorStartTime)
				.Value("PendingLocationErrorEndTime", PendingLocationErrorEndTime)
			;
		}
#endif
	}
};

class UPlayerSyncLocationMeshOffsetComponent : UActorComponent
{
	FVector CurrentMeshOffset;

	void OffsetBackToCrumbTrail()
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		auto CrumbSyncPosition = UHazeCrumbSyncedActorPositionComponent::Get(Player);
		CurrentMeshOffset = (Player.Mesh.WorldLocation - CrumbSyncPosition.GetPosition().WorldLocation);
		Player.SetActorLocation(CrumbSyncPosition.GetPosition().WorldLocation);
	}
};