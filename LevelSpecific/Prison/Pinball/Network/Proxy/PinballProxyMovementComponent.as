struct FPinballMagnetDroneProxyMovementIterationResult
{
	uint Subframe;
	float OtherSideTime;
	FPinballBallLaunchData LaunchData;
};

/**
 * A movement component that allows resolving multiple times per frame.
 * Make sure to call ProxyPrepareMove and ProxyHasMovedThisFrame instead of the regular functions!
 */
UCLASS(Abstract)
class UPinballProxyMovementComponent : UHazeMovementComponent
{
	default FollowEnablement.DefaultValue = EMovementFollowEnabledStatus::FollowEnabled;

	APinballProxy Proxy;
	uint ProxyLastMoveFrame = 0;
	FInstigator ProxyLastMoveInstigator;

	TArray<FPinballMagnetDroneProxyMovementIterationResult> IterationResults;

#if EDITOR
	TArray<FMovementHitResult> DebugMovementSweeps;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Proxy = Cast<APinballProxy>(Owner);

		UMovementStandardSettings::SetAutoFollowGround(Proxy, EMovementAutoFollowGroundType::FollowWalkable, this, EHazeSettingsPriority::Defaults);
	}

#if !RELEASE
	void LogInitial(FTemporalLog InitialLog) const
	{
		InitialLog.Page("Movement")
			.HitResults("Ground Contact", GroundContact.ConvertToHitResult(), CollisionShape)
			.Value("Followed Component", GetCurrentMovementFollowAttachment().Component)
		;
	}

	void LogPostTick(FTemporalLog SubframeLog) const
	{
		SubframeLog.Page("Movement")
			.HitResults("Ground Contact", GroundContact.ConvertToHitResult(), CollisionShape)
			.Value("ProxyLastMoveFrame", ProxyLastMoveFrame)
			.Value("ProxyLastMoveInstigator", ProxyLastMoveInstigator)
			.Value("Followed Component", GetCurrentMovementFollowAttachment().Component)
		;

		for(int i = 0; i < AllImpacts.Num(); i++)
		{
			SubframeLog.Section("Impacts").HitResults(f"Impact {i}:", AllImpacts[i].ConvertToHitResult(), CollisionShape);
		}
	}
#endif

	bool PrepareMove(UBaseMovementData DataType, FVector CustomWorldUp) override
	{
		devError("Use ProxyPrepareMove()!");
		return false;
	}

	bool ProxyPrepareMove(UBaseMovementData DataType, float DeltaTime, FVector CustomWorldUp = FVector::ZeroVector)
	{
#if !RELEASE
		devCheck(DataType.DebugPreparedFrame == 0, f"Movedata {GetName()} was prepared by {DataType.DebugMoveInstigator} but never applied to the movement component.");
		devCheck(CustomWorldUp.IsNearlyZero() || CustomWorldUp.IsUnit(), f"Movedata {GetName()} was prepared by {DataType.DebugMoveInstigator} with an invalid world up.");
		devCheck(Owner.AttachParentActor == nullptr, f"{Owner} has performed a move while attached to {Owner.AttachParentActor}. This is not allowed. Attach the player by using the 'FollowComponentMovement' functions instead");
#endif

		auto PinballSweepingData = Cast<UPinballMagnetDroneMovementData>(DataType);
		if(PinballSweepingData != nullptr)
			return PrepareMagnetDroneMovementData(PinballSweepingData, DeltaTime, CustomWorldUp);

		auto ProxyTeleportingData = Cast<UPinballProxyTeleportingMovementData>(DataType);
		if(ProxyTeleportingData != nullptr)
			return PrepareProxyTeleportingMovementData(ProxyTeleportingData, DeltaTime, CustomWorldUp);

		auto ProxyAttractionMoveData = Cast<UPinballMagnetAttractionMovementData>(DataType);
		if(ProxyAttractionMoveData != nullptr)
			return PrepareMagnetAttractionMovementData(ProxyAttractionMoveData, DeltaTime, CustomWorldUp);

		auto ProxyAttachedMoveData = Cast<UPinballMagnetAttachedMovementData>(DataType);
		if(ProxyAttachedMoveData != nullptr)
			return PrepareMagnetAttachedMovementData(ProxyAttachedMoveData, DeltaTime, CustomWorldUp);

		devError("Invalid movement data type?");
		return false;
	}

	private bool PrepareMagnetDroneMovementData(UPinballMagnetDroneMovementData PinballSweepingData, float DeltaTime, FVector CustomWorldUp = FVector::ZeroVector)
	{
		if(PinballSweepingData.PrepareProxyMove(this, CustomWorldUp, DeltaTime))
		{
#if !RELEASE
			if(!ensure(PinballSweepingData.DebugPreparedFrame == Time::FrameNumber, f"PrepareMove was called on {PinballSweepingData.Name}, but it seems that UBaseMovementData::PrepareMove() was never called. Did you forget to call Super?"))
				return false;
#endif

			SetPreparingStatus(PinballSweepingData.StatusInstigator);

			if(CustomWorldUp.IsUnit())
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-CustomWorldUp));
			else
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-FVector::UpVector));

			return true;
		}
		else
		{
			return false;
		}
	}

	private bool PrepareProxyTeleportingMovementData(UPinballProxyTeleportingMovementData ProxyTeleportingData, float DeltaTime, FVector CustomWorldUp = FVector::ZeroVector)
	{
		if(ProxyTeleportingData.PrepareProxyMove(this, CustomWorldUp, DeltaTime))
		{
#if !RELEASE
			if(!ensure(ProxyTeleportingData.DebugPreparedFrame == Time::FrameNumber, f"PrepareMove was called on {ProxyTeleportingData.Name}, but it seems that UBaseMovementData::PrepareMove() was never called. Did you forget to call Super?"))
				return false;
#endif
			SetPreparingStatus(ProxyTeleportingData.StatusInstigator);

			if(CustomWorldUp.IsUnit())
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-CustomWorldUp));
			else
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-FVector::UpVector));

			return true;
		}
		else
		{
			return false;
		}
	}

	private bool PrepareMagnetAttractionMovementData(UPinballMagnetAttractionMovementData ProxyAttractionMoveData, float DeltaTime, FVector CustomWorldUp = FVector::ZeroVector)
	{
		if(ProxyAttractionMoveData.PrepareProxyMove(this, CustomWorldUp, DeltaTime))
		{
#if !RELEASE
			if(!ensure(ProxyAttractionMoveData.DebugPreparedFrame == Time::FrameNumber, f"PrepareMove was called on {ProxyAttractionMoveData.Name}, but it seems that UBaseMovementData::PrepareMove() was never called. Did you forget to call Super?"))
				return false;
#endif
			SetPreparingStatus(ProxyAttractionMoveData.StatusInstigator);

			if(CustomWorldUp.IsUnit())
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-CustomWorldUp));
			else
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-FVector::UpVector));

			return true;
		}
		else
		{
			return false;
		}
	}

	private bool PrepareMagnetAttachedMovementData(UPinballMagnetAttachedMovementData ProxyAttachedMoveData, float DeltaTime, FVector CustomWorldUp = FVector::ZeroVector)
	{
		if(ProxyAttachedMoveData.PrepareProxyMove(this, CustomWorldUp, DeltaTime))
		{
#if !RELEASE
			if(!ensure(ProxyAttachedMoveData.DebugPreparedFrame == Time::FrameNumber, f"PrepareMove was called on {ProxyAttachedMoveData.Name}, but it seems that UBaseMovementData::PrepareMove() was never called. Did you forget to call Super?"))
				return false;
#endif
			SetPreparingStatus(ProxyAttachedMoveData.StatusInstigator);

			if(CustomWorldUp.IsUnit())
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-CustomWorldUp));
			else
				InternalGravityDirection.SetDefaultValue(FMovementGravityDirection::TowardsDirection(-FVector::UpVector));

			return true;
		}
		else
		{
			return false;
		}
	}

	void ApplyMove(UBaseMovementData DataType) override
	{
		Super::ApplyMove(DataType);
		ProxyLastMoveFrame = Proxy.SubframeNumber;
		ProxyLastMoveInstigator = DataType.MovementInstigator;
	}

	bool ProxyHasMovedThisFrame() const
	{
		if(Proxy.SubframeNumber == 0)
			return false;
		
		if(Proxy.SubframeNumber == ProxyLastMoveFrame)
			return true;

		return false;
	}

	void PostPrediction()
	{
		// if(ProxyLastMoveFrame == 0)
		// 	PrintWarning("Prediction proxy didn't move this frame!");

		// Clear all follow attachments
		FollowComponentAttachments.Empty();
		UpdateMovementFollowAttachment();
	}

	UFUNCTION(BlueprintOverride)
	void ApplyMovementAttachmentTransform(USceneComponent ChangedComponent)
	{
		FVector PreviousLocation = Owner.ActorLocation;
		Super::ApplyMovementAttachmentTransform(ChangedComponent);

#if !RELEASE
		Proxy.GetSubframeLog().Page("Movement")
			.Sphere("Location before Follow", PreviousLocation, GetRadius())
			.Sphere("Location after Follow", Owner.ActorLocation, GetRadius(), FLinearColor::Green)
			.Arrow("Follow Delta", PreviousLocation, Owner.ActorLocation, 2, 20, FLinearColor::Yellow)
		;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnReset(FVector NewWorldUp, bool bValidateGround, float OverrideTraceDistance)
	{
		Super::OnReset(NewWorldUp, bValidateGround, OverrideTraceDistance);

		ProxyLastMoveFrame = 0;
		ProxyLastMoveInstigator = FInstigator();
		IterationResults.Reset();
	}

	void SnapRemoteCrumbSyncedPosition() override
	{
		devError("Don't use replication on this component!");
	}

	void TransitionCrumbSyncedPosition(FInstigator Instigator) override
	{
		devError("Don't use replication on this component!");
	}

	FHazeSyncedActorPosition GetCrumbSyncedPosition() const override
	{
		devError("Don't use replication on this component!");
		return FHazeSyncedActorPosition();
	}

	FHazeSyncedActorPosition GetLatestAvailableSyncedPosition(float&out OutCrumbTrailTime) const override
	{
		devError("Don't use replication on this component!");
		return FHazeSyncedActorPosition();
	}

	bool CanApplyCrumbSyncedRelativePosition(FHazeMovementComponentAttachment Attachment) const override
	{
		return false;
	}

	void ApplyCrumbSyncedRelativePosition(
		FInstigator Instigator,
		USceneComponent RelativeToComponent,
		FName Socket,
		EInstigatePriority Priority,
		bool bRelativeRotation) override
	{
		devError("Don't use replication on this component!");
	}

	void ClearCrumbSyncedRelativePosition(FInstigator Instigator) override
	{
		devError("Don't use replication on this component!");
	}

	float GetRadius() const
	{
		return ShapeComponent.GetCollisionShape().SphereRadius;
	}

#if EDITOR
	void ValidateTickGroup(FString FunctionName) override
	{
		// The guy that added this warning is a dum dum
		return;
	}
#endif
};