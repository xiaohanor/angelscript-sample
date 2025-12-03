struct FPrisonStealthDetectPlayerResult
{
	EPrisonStealthDetectPlayerResult Result;
	float DetectionTime;
};

enum EPrisonStealthDetectPlayerResult
{
	NotVisible,
	Visible,
	InstantDetection
};

UCLASS(NotBlueprintable)
class UPrisonStealthVisionComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Vision")
	FVector VisionExtent = FVector(200.0, 200.0, 200.0);

	UPROPERTY(EditAnywhere, Category = "Vision")
	float ForwardOffset = 500.0;

	UPROPERTY(EditAnywhere, Category = "Vision")
	float VerticalOffset = 200.0;

	UPROPERTY(EditAnywhere, Category = "Vision", Meta = (UIMin = "0.0", UIMax = "1.0", ClampMin = "0.0", ClampMax = "1.0"))
	float CloseVisionWidthAlpha = 0.1;

	// Time to wait until vision is enabled. This prevents spotting the player when just enabled or after leaving the stunned state.
	UPROPERTY(EditAnywhere, Category = "Vision")
	float StartVisionDelay = 0.2;

	// How long (in seconds) it takes to spot the player if it is at the CloseVisionDistance. Interpolated to FarDetectionTime over the distance from CloseVisionDistance to FarVisionDistance.
	UPROPERTY(EditAnywhere, Category = "Detection")
	float CloseDetectionTime = 0.1;

	// How long (in seconds) it takes to spot the player if it is at the FarVisionDistance. Interpolated from CloseDetectionTime over the distance from CloseVisionDistance to FarVisionDistance.
	UPROPERTY(EditAnywhere, Category = "Detection")
	float FarDetectionTime = 0.5;

	// How long it takes (in seconds) for the detection amount to reset.
	UPROPERTY(EditAnywhere, Category = "Detection")
	float DetectionReturnTime = 3.0;

	UPROPERTY(EditAnywhere, Category = "Instant Detection")
	bool bUseInstantDetection = true;

	UPROPERTY(EditAnywhere, Category = "Instant Detection", Meta = (EditCondition = "bUseInstantDetection"))
	float InstantDetectionRadius = 200.0;

#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Visualization", Meta = (MakeEditWidget))
	FVector VisualizeDetectionLocation = FVector::ZeroVector;
#endif

	FPrisonStealthDetectPlayerResult DetectPlayer(AHazePlayerCharacter Player, FPrisonStealthPlayerLastSeen& LastSeenData) const
	{
		check(Player.HasControl());

		FPrisonStealthDetectPlayerResult Result;
		Result.Result = EPrisonStealthDetectPlayerResult::NotVisible;

		if(Player.IsPlayerDead())
			return Result;

		const FVector PlayerLocation = Player.ActorLocation;

		const FVector LocationOnPlane = WorldLocation.PointPlaneProject(PlayerLocation, FVector::UpVector);
		const float DistanceToPlayerOnPlane = PlayerLocation.Distance(LocationOnPlane);
		const bool bInstantDetected = bUseInstantDetection ? DistanceToPlayerOnPlane < InstantDetectionRadius : false;

		FTransform VisionAreaTransform = GetVisionAreaTransform();
		FPrisonStealthVisionCone Trapezoid(VisionExtent, CloseVisionWidthAlpha);

#if !RELEASE
		if(DevTogglesPrisonStealth::DrawVision.IsEnabled())
			Trapezoid.DebugDrawVisionCone(VisionAreaTransform, FLinearColor::Red, 3.0);
#endif

		if(!bInstantDetected)
		{
			// Only check if within the zone if we are not within immediate detection range
			// If we are within immediate detection, we still want the trace to run to prevent being detected through walls.
			if(!Trapezoid.IsPointInside(VisionAreaTransform, PlayerLocation))
				return Result;	// Too far away
		}

		
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.IgnorePlayers();
		Trace.UseLine();

#if !RELEASE
		if(DevTogglesPrisonStealth::DrawVision.IsEnabled())
			Trace.DebugDrawOneFrame();
#endif

		const FVector Start = WorldLocation;
		const FHitResult Hit = Trace.QueryTraceSingle(Start, PlayerLocation);

		if(Hit.bBlockingHit)
			return Result;	// Something was obstructing the player

		auto CardboardBoxComp = UPrisonStealthCardboardBoxPlayerComponent::Get(Player);
		if(CardboardBoxComp != nullptr)
		{
			if(CardboardBoxComp.HasCardboardBox())
			{
				if(Player.ActorHorizontalVelocity.Size() < 10)
				{
					// Let the VO system know we evaded detection at least once.
					CardboardBoxComp.OnEvadedDetection(true);
					return Result;
				}
			}
		}
		
		if(bUseInstantDetection && bInstantDetected)
		{
			Result.Result = EPrisonStealthDetectPlayerResult::InstantDetection;
			LastSeenData.Time = Time::GetGlobalCrumbTrailTime();
			LastSeenData.Location = PlayerLocation;
			return Result;
		}

		// Calculate the detection time based on the distance to the player
		// Because the player should generally be detected faster if closer to the guard
		FVector RelativePosition = VisionAreaTransform.InverseTransformPosition(PlayerLocation);
		const float DistanceAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, Trapezoid.FullDepth), FVector2D(0, 1), RelativePosition.X);
		const float DetectionTime = Math::Lerp(CloseDetectionTime, FarDetectionTime, DistanceAlpha);

		Result.Result = EPrisonStealthDetectPlayerResult::Visible;
		Result.DetectionTime = DetectionTime;

		// Store where the player was last seen, used for searching
		LastSeenData.Time = Time::GetGlobalCrumbTrailTime();
		LastSeenData.Location = PlayerLocation;

		// The player was spotted
		return Result;
	}

	FVector GetVisionOrigin() const
	{
		FVector Up = FVector::UpVector * VerticalOffset;
		Up += FVector::UpVector * VisionExtent.Z;

		const FVector Forward = FQuat::MakeFromZX(FVector::UpVector, Owner.ActorForwardVector).RotateVector(FVector(ForwardOffset, 0, 0));

		return Owner.ActorLocation + Up + Forward;
	}

	FTransform GetVisionAreaTransform() const
	{
		FQuat Rotation = FQuat::MakeFromZX(FVector::UpVector, ForwardVector.VectorPlaneProject(Owner.ActorUpVector).GetSafeNormal());
		FVector Location = GetVisionOrigin();
		return FTransform(Rotation, Location);
	}
};

#if EDITOR
class UPrisonStealthVisionComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UPrisonStealthVisionComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        auto VisionComponent = Cast<UPrisonStealthVisionComponent>(Component);

		const FVector VisionOrigin = VisionComponent.GetVisionOrigin();
		const FTransform VisionAreaTransform = VisionComponent.GetVisionAreaTransform();

		DrawPoint(
			VisionAreaTransform.Location - FVector::UpVector * VisionComponent.VisionExtent.Z,
			FLinearColor::Red,
			30
		);

		DrawCircle(VisionOrigin, VisionComponent.InstantDetectionRadius, FLinearColor::Red, 3, FVector::UpVector);

		FPrisonStealthVisionCone Trapezoid(VisionComponent.VisionExtent, VisionComponent.CloseVisionWidthAlpha);
		Trapezoid.VisualizeVisionCone(this, VisionAreaTransform, FLinearColor::Yellow, 3.0);

		FVector TestWorldLocation = VisionAreaTransform.TransformPositionNoScale(VisionComponent.VisualizeDetectionLocation);
		if(Trapezoid.IsPointInside(VisionAreaTransform, TestWorldLocation))
			DrawPoint(TestWorldLocation, FLinearColor::Green, 30);
		else
			DrawPoint(TestWorldLocation, FLinearColor::Yellow, 30);
	}
};
#endif