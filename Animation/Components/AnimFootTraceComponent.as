struct FAnimHazeFeetTraceInfo
{
	FVector PreviousFootLocation = FVector::ZeroVector;
	FVector CapsuleLocation = FVector::ZeroVector;
	float LastTraceTime = 0;
	bool bIsOnDynamicPlatform = false;
}

// delegate void FGetAnimFootTraceData(FHazeAnimIKFeetPlacementTraceDataInput& TraceInputData);

delegate void FGetAnimFootTraceData(FHazeAnimIKFeetPlacementTraceDataInput& TraceInputData, AHazeCharacter Character);

delegate void FGetAnimSlopeWrapData(FHazeSlopeWarpingData& Data, AHazeCharacter Character);

// This is WIP and will replace the PlayerFootstepTraceComponent
class UAnimFootTraceComponent : UActorComponent
{
	UHazeSkeletalMeshComponentBase Mesh;
	UHazeMovementComponent MoveComp;

	private TMap<FName, FAnimHazeFeetTraceInfo> CachedTraceInfos;

	private bool bNeedsToInitialize;
	private float MaxDotProductWhileWalking;

	private int FootTraceIndex = 0;

	private AHazeCharacter OwningCharacter;

	UPROPERTY()
	TArray<FName> FeetSocketNames;

	UPROPERTY()
	float TraceVerticalStartPos = 30;

	UPROPERTY()
	float TraceVerticalEndPos = -50;

	UPROPERTY()
	float SpehereTraceSize = 7;

	// Only do a new trace if a foot has moved more than x units from it's previous location
	UPROPERTY()
	float NewTraceDistanceThreshold = 3;

	UPROPERTY()
	float TraceAheadMultiplier = 1;

	/** The max speed before `AreRequirementsMet()` will return False. */
	UPROPERTY(Category = "Enable Rules")
	float MaxSpeed = 160;

	/** Max angles that character can walk in before `AreRequirementsMet()` will return False. */
	UPROPERTY(Category = "Enable Rules")
	float MaxAngleWhileWalking = 40;

	FGetAnimFootTraceData OverrideTraceDelegate;
	
	TArray<UObject> BlockIKSlopeWarp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (MoveComp == nullptr)
			MoveComp = UHazeMovementComponent::Get(Owner);

		OwningCharacter = Cast<AHazeCharacter>(Owner);
		if (OwningCharacter != nullptr && Mesh == nullptr)
			Mesh = OwningCharacter.Mesh;

		// Fill the arrays with required items
		for (const FName SocketName : FeetSocketNames)
		{
			CachedTraceInfos.Add(SocketName, FAnimHazeFeetTraceInfo());
			// CachedTraceInfos.Add(FAnimHazeFeetTraceInfo());
		}

		MaxDotProductWhileWalking = Math::Cos(Math::DegreesToRadians(MaxAngleWhileWalking));
	}

	/**
	 * Should be called on `BeginPlay` in the Actor, to set the mesh, if this component is used on something that's not a AHazeCharacter
	 */
	UFUNCTION()
	void SetMesh(UHazeSkeletalMeshComponentBase InMesh)
	{
		Mesh = InMesh;
	}

	UFUNCTION()
	void SetMovementComp(UHazeMovementComponent InMoveComp)
	{
		MoveComp = InMoveComp;
	}

	private FHazeTraceSettings GetTraceSettings()
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		TraceSettings.UseSphereShape(SpehereTraceSize);

		return TraceSettings;
	}

	private FHitResult PerformTrace(FVector Start, FVector End, FHazeTraceSettings& TraceSettings, bool bComplex = false)
	{
		TraceSettings.SetTraceComplex(bComplex);
		return TraceSettings.QueryTraceSingle(Start, End);
	}

	/**
	 * Check if complex trace is required
	 */
	private bool GetComplexTraceRequired() const
	{
		const USceneComponent SceneComponent = MoveComp.GetGroundContact().Component;
		if (SceneComponent == nullptr)
			return false;
		return SceneComponent.HasTag(ComponentTags::ComplexFootTrace);
	}

	/**
	 * Update the trace data for a given foot
	 * __Args__:
	 * 	- Index: The index of the HitResults to update
	 * 	- DeltaTime: deltatime
	 * 	- bForceTrace: should it be forced to do a new trace?
	 *
	 * __Returns__:
	 * 	`true` if a new trace was made and HitResults were updated
	 */
	private bool TraceFoot(FHazeAnimIKFeetPlacementTraceData& TraceData, int Index, bool bIsStandingOnAMovingPlatform, FHazeTraceSettings& TraceSettings, bool bComplexTrace)
	{
		// FHazeAnimIKFeetPlacementTraceData& TraceData = TraceInputData.TraceData[Index];
		FAnimHazeFeetTraceInfo& CachedTraceInfo = CachedTraceInfos[TraceData.BoneName];

		const FVector FootSocketLocation = Mesh.GetSocketLocation(TraceData.BoneName);

		const bool bForceTrace = CachedTraceInfo.bIsOnDynamicPlatform;
		if (!bForceTrace && TraceData.GroundData.bBlockingHit && Owner.ActorRotation.UnrotateVector(FootSocketLocation - CachedTraceInfo.PreviousFootLocation).Size2D() < NewTraceDistanceThreshold)
			return false;

		// DeltaTime
		const float DeltaTime = Time::GameTimeSeconds - CachedTraceInfo.LastTraceTime;
		if (DeltaTime <= 0)
			return false;

		// Get the start & end position of wanted trace
		// Remove Up vector from the location & set it to be capsule loc
		FVector Location = Math::LinePlaneIntersection(FootSocketLocation,
													   FootSocketLocation - Owner.ActorUpVector,
													   Owner.ActorLocation,
													   Owner.ActorUpVector);

		if (!bIsStandingOnAMovingPlatform)
		{
			FVector FootVelocity = Owner.ActorRotation.UnrotateVector(FootSocketLocation - CachedTraceInfo.PreviousFootLocation) / DeltaTime;
			FootVelocity.Z = 0;

			const float SlopeAngle = MoveComp.GetSlopeRotationForAnimation().Pitch;
			const float SlopeFootMultiplier = 1 - Math::Clamp(Math::Abs(SlopeAngle) / 40, 0, 1);

			const float ClampValue = 700;
			FootVelocity.X = Math::Clamp(FootVelocity.X, -ClampValue, ClampValue);
			FootVelocity.Y = Math::Clamp(FootVelocity.Y, -ClampValue, ClampValue);

			Location += Owner.ActorRotation.RotateVector(FootVelocity * 0.075 * TraceAheadMultiplier * SlopeFootMultiplier);
		}

		const FVector StartPos = Location + (Owner.ActorUpVector * TraceVerticalStartPos);
		const FVector EndPos = Location + (Owner.ActorUpVector * TraceVerticalEndPos);

		// Do a trace
		const FHitResult HitResult = PerformTrace(StartPos, EndPos, TraceSettings, bComplexTrace);

		TraceData.ComponentTransformAtTrace = Owner.ActorTransform;
		TraceData.GroundData.bBlockingHit = HitResult.bBlockingHit;
		TraceData.GroundData.ImpactNormal = HitResult.ImpactNormal;
		TraceData.GroundData.ImpactPoint = HitResult.ImpactPoint;
		TraceData.GroundData.TraceStart = HitResult.TraceStart;
		TraceData.GroundData.TraceEnd = HitResult.TraceEnd;

		// TODO: Remove `CachedTraceInfo.bIsOnDynamicPlatform`, it's no longer used
		// This means all of this could be moved into the AnimGraph node, this comp doesn't need to do this check
		if (HitResult.Component != nullptr)
			CachedTraceInfo.bIsOnDynamicPlatform = HitResult.Component.Mobility == EComponentMobility::Movable;
		else
			CachedTraceInfo.bIsOnDynamicPlatform = true;
		TraceData.bInterpolatePositionInWS = !CachedTraceInfo.bIsOnDynamicPlatform;

		// Cache values used in the next frame evaluation
		CachedTraceInfo.PreviousFootLocation = FootSocketLocation;
		CachedTraceInfo.CapsuleLocation = Owner.ActorLocation;
		CachedTraceInfo.LastTraceTime = Time::GameTimeSeconds;

		return true;
	}

	UFUNCTION()
	void TraceFeet(FHazeAnimIKFeetPlacementTraceDataInput& TraceInputData, bool bForceTraceAllFeet = false)
	{
		if (OverrideTraceDelegate.IsBound())
		{
			OverrideTraceDelegate.Execute(TraceInputData, OwningCharacter);
			return;
		}

		// Trace the feet
		auto TraceSettings = GetTraceSettings();

		if (MoveComp == nullptr)
			return;

		const auto SceneComponent = MoveComp.GetGroundContact().Component;
		const bool bIsStandingOnAMovingPlatform = SceneComponent == nullptr ? false : SceneComponent.Mobility == EComponentMobility::Movable;
		const bool bComplexTrace = GetComplexTraceRequired();

		for (int i = 0; i < FeetSocketNames.Num(); i++)
		{
			FootTraceIndex = Math::WrapIndex(FootTraceIndex + 1, 0, FeetSocketNames.Num());

			if (TraceFoot(TraceInputData.TraceData[FootTraceIndex], FootTraceIndex, bIsStandingOnAMovingPlatform, TraceSettings, bComplexTrace))
			{
				if (!bIsStandingOnAMovingPlatform && !bForceTraceAllFeet && !bNeedsToInitialize)
				{
					break; // Optimization, only allow a maximum of 1 trace per tick (might want to allow 2 for e.g. dragons).
				}
			}
		}

		bNeedsToInitialize = false;
	}

	UFUNCTION()
	void InitializeTraceDataVariable(FHazeAnimIKFeetPlacementTraceDataInput& TraceInputData)
	{
		TraceInputData.TraceData.Reset();
		for (const FName SocketName : FeetSocketNames)
		{
			auto FootTraceData = FHazeAnimIKFeetPlacementTraceData();
			FootTraceData.BoneName = SocketName;
			TraceInputData.TraceData.Add(FootTraceData);
		}

		TraceInputData.TraceStartEndHeight.X = TraceVerticalEndPos;
		TraceInputData.TraceStartEndHeight.Y = TraceVerticalStartPos;

		bNeedsToInitialize = true;
	}

	UFUNCTION(BlueprintPure)
	bool AreRequirementsMet() const
	{
		if (!BlockIKSlopeWarp.IsEmpty())
			return false;

		const bool bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		if (bWantsToMove && MoveComp.GetGroundContact().ImpactNormal.DotProduct(Owner.ActorUpVector) < MaxDotProductWhileWalking && !GetComplexTraceRequired())
			return false;

		return MoveComp.Velocity.Size() < MaxSpeed || !bWantsToMove;
	}

	void UpdateSlopeWarpData(FHazeSlopeWarpingData& Data)
	{
		if (!BlockIKSlopeWarp.IsEmpty())
		{
			Data = FHazeSlopeWarpingData();
			return;
		}

		const auto GroundImpact = MoveComp.GetGroundContact();
		Data.ImpactNormal = GroundImpact.ImpactNormal;
		Data.ImpactPoint = (GroundImpact.ImpactPoint - GroundImpact.Location) + Owner.ActorLocation;
		Data.bBlockingHit = GroundImpact.bBlockingHit;
		Data.ActorVelocity = MoveComp.Velocity;
		Data.OverrideMaxStepHeight = -1;
		
	}

	void Block(UObject Instigator)
	{
		BlockIKSlopeWarp.AddUnique(Instigator);
	}

	void UnBlock(UObject Instigator)
	{
		if (BlockIKSlopeWarp.Contains(Instigator))
			BlockIKSlopeWarp.Remove(Instigator);
	}
}
