enum EStoneBeastTailSegmentChainID
{
	Unassigned UMETA(Hidden),
	Chain1,
	Chain2,
	Chain1LowerPart,
	Chain1UpperPart,
	MAX UMETA(Hidden)
}

asset UStoneBeastTailSegmentSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UStoneBeastTailSegmentFollowCapability);
	Capabilities.Add(UStoneBeastTailSegmentLeadCapability);
	Capabilities.Add(UStoneBeastTailSegmentReturnCapability);
	Capabilities.Add(UStoneBeastTailSegmentImitationCapability);
	Capabilities.Add(UStoneBeastTailSegmentSpeedTrackerCapability);
}

class AStoneBeastTailSegment : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;
	default BillboardComp.WorldScale3D = FVector(5);
	default BillboardComp.RelativeLocation = FVector(0, 0, 0);

	UPROPERTY(DefaultComponent, Attach = BillboardComp)
	UEditorBillboardComponent SelectBillboardComp;
	default SelectBillboardComp.RelativeLocation = FVector(0, 0, 500);
	default SelectBillboardComp.WorldScale3D = FVector(5);
	default SelectBillboardComp.SpriteName = "S_Solver";
#endif

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "bIsControllingActor", EditConditionHides))
	AStoneBeastTailSegment TargetTailSegment;

	/**
	 * If true, this actor's values will be used to control movement of this segment.
	 * If false, this actor will use the values of the segment with same index.
	 */
	UPROPERTY(EditInstanceOnly)
	bool bIsControllingActor = false;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsControllingActor", EditConditionHides))
	float FollowTransformDelay = 0.5;

	/**
	 * Chain Identifier. Used for activation/deactivation.
	 */
	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsControllingActor", EditConditionHides))
	TSet<EStoneBeastTailSegmentChainID> ChainIDs;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsControllingActor", EditConditionHides))
	float PitchRotationAmplitude = 35;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsControllingActor", EditConditionHides))
	float PitchRotationFrequency = 1;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsControllingActor", EditConditionHides))
	float YawRotationAmplitude = 35;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsControllingActor", EditConditionHides))
	float YawRotationFrequency = 1.5;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsControllingActor", EditConditionHides))
	float RollRotationAmplitude = 35;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsControllingActor", EditConditionHides))
	float RollRotationFrequency = 0.5;

	UPROPERTY(EditInstanceOnly, meta = (EditCondition = "!bIsControllingActor", EditConditionHides))
	TSoftObjectPtr<AStoneBeastTailSegment> TailSegmentToImitate;

	UPROPERTY(EditAnywhere)
	float SegmentCullDistance = 4000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(UStoneBeastTailSegmentSheet);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.ListedTag = NAME_None;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;
	default DisableComp.AutoDisableRange = 50000;

	FTransform OriginalTransform;

	bool bIsActive = false;
	bool bIsReturning = false;

	bool bIsMovingUp = false;

	float CurrentVerticalSpeed = 0;
	FHazeAcceleratedFloat AccSpeed;

	TArray<float> SpeedEntries;
	int SpeedEntryIndex;

	float PreviousAverageSpeed;

	float CurrentStopDuration = -1;
	FTransform SegmentTransform;

	// NB: This is used for audio, make sure to update if big changes are made to the speeds of the segments;
	const float MaxVerticalSpeed = 700;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ListedActorComp.ListedTag = NAME_None;

#if EDITOR
		if (bIsControllingActor)
		{
			SelectBillboardComp.RelativeLocation = FVector(0, 0, 500);
			SelectBillboardComp.WorldScale3D = FVector(5);
			SelectBillboardComp.SpriteName = "S_Solver";
		}
		else
		{
			SelectBillboardComp.RelativeLocation = FVector(0, 0, 400);
			SelectBillboardComp.WorldScale3D = FVector(3);
			SelectBillboardComp.SpriteName = "S_Pawn";
		}
#endif
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void ForceUpdate()
	{
		Editor::RerunConstructionScript(this);
	}
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		if (bIsControllingActor)
		{
			if (TargetTailSegment != nullptr)
			{
				if (HasCommonChainID(TargetTailSegment))
				{
					Debug::DrawDebugArrow(SelectBillboardComp.WorldLocation, TargetTailSegment.SelectBillboardComp.WorldLocation, 10000, FLinearColor::Yellow, 20, 0, true);
					Debug::DrawDebugString(SelectBillboardComp.WorldLocation, f"Will follow {TargetTailSegment.Name}", FLinearColor::Yellow);
				}
				else
				{
					Debug::DrawDebugArrow(SelectBillboardComp.WorldLocation, TargetTailSegment.SelectBillboardComp.WorldLocation, 10000, FLinearColor::Red, 20, 0, true);
					Debug::DrawDebugString(SelectBillboardComp.WorldLocation, f"ChainID MISSMATCH", FLinearColor::Red);
				}
			}
		}
		if (TailSegmentToImitate.IsValid())
		{
			Debug::DrawDebugArrow(SelectBillboardComp.WorldLocation, TailSegmentToImitate.Get().SelectBillboardComp.WorldLocation, 10000, FLinearColor::White, 20, 0, true);
			Debug::DrawDebugString(SelectBillboardComp.WorldLocation, f"Will imitate {TailSegmentToImitate.Get().Name}", FLinearColor::White);
		}

		Debug::DrawDebugCircle(ActorLocation, SegmentCullDistance, Thickness = 50, LineColor = FLinearColor::Green);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		if (TailSegmentToImitate != nullptr)
			TEMPORAL_LOG(f"{ActorNameOrLabel}").Status("Is Imitation Actor", FLinearColor::LucBlue);
		else if (TargetTailSegment == nullptr)
			TEMPORAL_LOG(f"{ActorNameOrLabel}").Status("Is Lead Actor", FLinearColor::Green);
		else
			TEMPORAL_LOG(f"{ActorNameOrLabel}").Status("Is Follow Actor", FLinearColor::Purple);

		float AverageSpeed = GetAverageSpeed();
		TEMPORAL_LOG(f"{ActorNameOrLabel}")
			.Value("TargetTailSegment", TargetTailSegment)
			.Value("bIsControllingActor", bIsControllingActor)
			.Value("CurrentStopDuration", CurrentStopDuration)
			.Value("bIsActive", bIsActive)
			.Value("bIsReturning", bIsReturning)
			.Value("VerticalSpeed", CurrentVerticalSpeed)
			.Value("AccSpeed", AccSpeed.Value)
			.Value("AverageSpeed", AverageSpeed)
			.Value("PreviousAverageSpeed", PreviousAverageSpeed)
			.Value("bIsMovingUp", bIsMovingUp)
			.Value("SegmentTransform", SegmentTransform)
		;
#endif
	}

	bool HasCommonChainID(AStoneBeastTailSegment OtherSegment) const
	{
		for (auto ChainID : ChainIDs)
		{
			if (OtherSegment.ChainIDs.Contains(ChainID))
				return true;
		}
		return false;
	}

	bool HasChainID(EStoneBeastTailSegmentChainID ChainID) const
	{
		return ChainIDs.Contains(ChainID);
	}

	float GetAverageSpeed()
	{
		float Sum = 0;
		for (auto Value : SpeedEntries)
			Sum += Value;

		return Sum / SpeedEntries.Num();
	}

	void TrackSpeed(float Speed)
	{
		SpeedEntries[SpeedEntryIndex] = Speed;
		SpeedEntryIndex = (SpeedEntryIndex + 1) % SpeedEntries.Num();
	}

	// UFUNCTION(DevFunction)
	// void StopSegmentsWithSameIDs(float Duration)
	// {
	// 	StoneBeastTail::StopAllTailSegments(Duration, ChainID);
	// }

	// UFUNCTION(DevFunction)
	// void StartAllTailSegments()
	// {
	// 	StoneBeastTail::StartAllTailSegments(ChainID);
	// }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalTransform = ActorTransform;
		SegmentTransform = ActorTransform;

		SpeedEntries.SetNumZeroed(10);
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void StartMoving()
	{
		bIsActive = true;
		bIsReturning = false;
	}

	void StopMoving(float Duration)
	{
		bIsActive = false;
		bIsReturning = true;
		CurrentStopDuration = Duration;
	}

	void SetSegmentLocationAndRotation(FVector Location, FRotator Rotation)
	{
		SegmentTransform.SetLocation(Location);
		SegmentTransform.SetRotation(Rotation);
		SetSegmentTransform(SegmentTransform);
	}

	bool bSegmentWasDisabled = false;
	bool bIsLerpingBack = false;
	FTransform DisabledTransform;
	float LastEnabledTime = 0.0;
	float LastDisabledTime = 0.0;

	void SetSegmentTransform(FTransform NewSegmentTransform)
	{
		SegmentTransform = NewSegmentTransform;

		float DistanceToClosestPlayer = Game::GetDistanceFromLocationToClosestPlayer(OriginalTransform.Location);
		if (DistanceToClosestPlayer < SegmentCullDistance)
		{
			if (bSegmentWasDisabled)
			{
				bSegmentWasDisabled = false;
				DisabledTransform = ActorTransform;
				LastDisabledTime = Time::GameTimeSeconds;
				if (Time::GetGameTimeSince(LastEnabledTime) > 0.5)
					bIsLerpingBack = true;
			}

			if (bIsLerpingBack && false)
			{
				float LerpIn = Time::GetGameTimeSince(LastDisabledTime) / 2.0;
				float LerpAlpha = Math::Saturate(Math::EaseInOut(0, 1, LerpIn, 2));
				if (LerpAlpha < 1.0)
				{
					FTransform BlendedTransform;
					BlendedTransform.Blend(DisabledTransform, SegmentTransform, LerpAlpha);

					SetActorTransform(BlendedTransform);
				}
				else
				{
					SetActorTransform(SegmentTransform);
					bIsLerpingBack = false;
				}
			}
			else
			{
				SetActorTransform(SegmentTransform);
			}

			// Debug::DrawDebugSphere(SegmentTransform.Location, SegmentCullDistance, LineColor = FLinearColor::Green);
		}
		else
		{
			if (!bSegmentWasDisabled)
			{
				bSegmentWasDisabled = true;
				LastEnabledTime = Time::GameTimeSeconds;
			}
			// Debug::DrawDebugSphere(SegmentTransform.Location, SegmentCullDistance, LineColor = FLinearColor::Red);
		}
	}

};
