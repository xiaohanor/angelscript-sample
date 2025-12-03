struct FEvergreenBarrelAnimData
{
	bool bPlayerInRange;
	bool bPlayerInBarrel;
}

asset EvergreenBarrelPlayerSheet of UHazeCapabilitySheet
{
	AddCapability(n"EvergreenBarrelCapability");
	AddCapability(n"EvergreenBarrelEnterCapability");
	AddCapability(n"EvergreenBarrelKillCapability");
	AddCapability(n"EvergreenBarrelLaunchCapability");
	AddCapability(n"EvergreenBarrelLaunchBlockBarrelCapability");
}

UCLASS(Abstract)
class AEvergreenBarrel : AHazeActor
{
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_HazeInput;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent FX_Loc;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedBarrelRotation;
	default SyncedBarrelRotation.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestOnPlayerComp;
	default RequestOnPlayerComp.PlayerSheets_Mio.Add(EvergreenBarrelPlayerSheet);

	UPROPERTY()
	UForceFeedbackEffect FFEnterBarrel;

	UPROPERTY()
	UForceFeedbackEffect FFExitBarrel;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEvergreenBarrelVisualizerDummyComponent VisualizerDummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(EditInstanceOnly)
	AEvergreenLifeManager LifeManager;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditAnywhere)
	float RotationSpeedInDegrees = 150.0;

	UPROPERTY(EditAnywhere)
	float MioShootOutImpulse = 4000.0;

	UPROPERTY(EditAnywhere)
	float MioGravityUntilHittingGroundOrPoleClimb = 5750;

	/* If the line created by the monkey's previous location and its current location intersects the circle segment that represents the enter angle the
	monkey will enter the barrel */
	UPROPERTY(EditAnywhere)
	float EnterConeAngleDegrees = 90.0;

	/* If the line created by the monkey's previous location and its current location intersects the circle segment that represents the kill angle the
	monkey will get killed */
	UPROPERTY(EditAnywhere)
	float KillConeAngleDegrees = 80.0 * 1.8;

	UPROPERTY(EditAnywhere)
	float EnterCircleRadius = 500.0;

	UPROPERTY(EditAnywhere)
	FVector EnterCircleLocalOffset = FVector(0.0, 0.0, -100.0);

	/* If true will use horizontal raw input instead of horizontal alpha, will use interp speed in that case */
	UPROPERTY(EditAnywhere)
	bool bUseRawInput = false;

	UPROPERTY(EditAnywhere)
	FVector ExtentsMargins = FVector(100.0, 100.0, 0.0);

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseRawInput"))
	float RawInputInterpSpeed = 10.0;

	UPROPERTY(EditAnywhere)
	float EnterDuration = 0.2;

	UPROPERTY(EditAnywhere, Category = "Auto Aim")
	float AutoAimMaxRange = 2500.0;

	UPROPERTY(EditAnywhere, Category = "Auto Aim")
	float AutoAimMaxAngle = 20.0;
	
	UPROPERTY(EditAnywhere, Category = "Auto Aim")
	bool bDrawDebugSphereOnCurrentAutoAimTarget = false;

	UPROPERTY(EditAnywhere, Category = "Visualizer")
	bool bVisualizeAutoAimMaxRange = true;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	bool bMonkeyInBarrel = false;

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraLifeReceivingComponent LifeComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerMovementComponent MoveComp;
	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;
	FEvergreenBarrelAnimData AnimData;

	float InterpedAlpha;
	bool bGravityOverridden = false;
	TOptional<FVector> PreviousPlayerLocation;
	FTransform OriginalTransform;
	TArray<AEvergreenBarrel> AutoAimBarrels;
	FBox Bounds;
	float PreviousAlpha;
	bool bLaunchMonkey = false;
	FRotator InitialRotation;

	private TOptional<uint> FrameOfLastEnterQuery;
	private bool bEnteredBarrelThisFrame = false;
	private bool bShouldGetKilledThisFrame = false;

	const float PlayerInRangeAnimationDistance = 2400.0;
	const bool bDebugAnimationDistance = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRotation = ActorRotation;
		SetActorControlSide(Game::Zoe);
		GetInRangeAutoAimTargets(AutoAimBarrels);

		LifeComp = LifeManager.LifeComp;
		LifeComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"OnShootOutMonkey");
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Game::Mio);
		MoveComp = UPlayerMovementComponent::Get(Game::Mio);
		HealthComp = UPlayerHealthComponent::Get(Game::Mio);
		RespawnComp = UPlayerRespawnComponent::Get(Game::Mio);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnRespawn");

		Bounds = SkeletalMesh.GetBoundingBoxRelativeToOwner();
		Bounds = FBox::BuildAABB(Bounds.Center, Bounds.Extent + ExtentsMargins);
	}

	UFUNCTION()
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		PreviousPlayerLocation.Reset();
		SyncedBarrelRotation.Value = InitialRotation;
		ActorRotation = SyncedBarrelRotation.Value;
	}

	void OnStartEnteringBarrel(AHazePlayerCharacter Player)
	{
		UEvergreenBarrelEffectHandler::Trigger_OnReceiveMonkey(this);
		Player.PlayForceFeedback(FFEnterBarrel, this);
	}

	FVector GetBarrelEnterCircleOrigin() const property
	{
		FVector Offset = ActorTransform.TransformVector(EnterCircleLocalOffset);
		return ActorLocation + Offset;
	}

	UFUNCTION()
	private void OnShootOutMonkey()
	{
		if(!bMonkeyInBarrel)
			return;

		bLaunchMonkey = true;
		Game::Mio.PlayCameraShake(CameraShake, this);
		Game::GetMio().PlayForceFeedback(FFExitBarrel, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bool bInRange = Game::Mio.ActorCenterLocation.DistSquared(SkeletalMesh.WorldLocation) <= Math::Square(PlayerInRangeAnimationDistance);
		AnimData.bPlayerInRange = bInRange && !Game::Mio.IsPlayerDead();

#if EDITOR
		HandleDebugDrawing();
#endif

		float RelevantAlpha;
		if(bUseRawInput)
		{
			InterpedAlpha = Math::FInterpTo(InterpedAlpha, LifeComp.RawHorizontalInput, DeltaTime, RawInputInterpSpeed);
			RelevantAlpha = InterpedAlpha;
		}
		else
		{
			RelevantAlpha = LifeComp.HorizontalAlpha;
		}

		bool bPreviousWasZero = Math::IsNearlyZero(PreviousAlpha);
		bool bCurrentIsZero = Math::IsNearlyZero(RelevantAlpha);
		if(bPreviousWasZero != bCurrentIsZero)
		{
			if(bCurrentIsZero)
			{
				UEvergreenBarrelEffectHandler::Trigger_OnStopTurning(this);
			}
			else
			{
				UEvergreenBarrelEffectHandler::Trigger_OnStartTurning(this);
			}
		}

		PreviousAlpha = RelevantAlpha;

		if(HasControl())
		{
			float DeltaPitch = RelevantAlpha * RotationSpeedInDegrees * DeltaTime;
			FQuat DeltaQuat = FRotator(-DeltaPitch, 0.0, 0.0).Quaternion();
			SyncedBarrelRotation.Value = FRotator(ActorQuat * DeltaQuat);
		}

		ActorRotation = SyncedBarrelRotation.Value;
	}

#if EDITOR
	void HandleDebugDrawing()
	{
		if(bDebugAnimationDistance)
		{
			Debug::DrawDebugSphere(ActorLocation, PlayerInRangeAnimationDistance, 12, AnimData.bPlayerInRange ? FLinearColor::Green : FLinearColor::Red, 3.0);
		}

		if(bDrawDebugSphereOnCurrentAutoAimTarget)
		{
			AEvergreenBarrel Barrel;
			if(bMonkeyInBarrel && IsWithinAutoAimRange(Barrel))
			{
				Debug::DrawDebugSphere(Barrel.ActorLocation, 500.0, 12, FLinearColor::Green, 3.0);
			}
		}
	}
#endif

	bool ShouldPlayerEnterBarrel()
	{
		QueryShouldPlayerEnterBarrelOrBeKilled();
		return bEnteredBarrelThisFrame;
	}

	bool ShouldPlayerGetKilled()
	{
		QueryShouldPlayerEnterBarrelOrBeKilled();
		return bShouldGetKilledThisFrame;
	}

	void QueryShouldPlayerEnterBarrelOrBeKilled()
	{
		if(FrameOfLastEnterQuery.IsSet() && FrameOfLastEnterQuery.Value == Time::FrameNumber)
			return;

		if(!PreviousPlayerLocation.IsSet())
		{
			PreviousPlayerLocation.Set(Game::Mio.ActorCenterLocation);
			return;
		}

		bEnteredBarrelThisFrame = PlayerIntersectedArc(ActorUpVector, EnterConeAngleDegrees);
		bShouldGetKilledThisFrame = PlayerIntersectedArc(-ActorUpVector, KillConeAngleDegrees);
		
		FrameOfLastEnterQuery.Set(Time::FrameNumber);
		PreviousPlayerLocation.Set(Game::Mio.ActorCenterLocation);
	}

	bool PlayerIntersectedArc(FVector ArcDirection, float FullArcDegrees)
	{
		FVector Origin = BarrelEnterCircleOrigin;
		FVector Normal = FVector::ForwardVector;
		
		FVector Previous = PreviousPlayerLocation.Value;
		FVector Current = Game::Mio.ActorCenterLocation;

		bool bStartedWithinRadius = Previous.Distance(Origin) <= EnterCircleRadius;
		
		// If we started within the radius we don't care about sphere intersections, only intersections with the sides of the arc.
		if(!bStartedWithinRadius)
		{
			FLineSphereIntersection Intersections = Math::GetLineSegmentSphereIntersectionPoints(Previous, Current, Origin, EnterCircleRadius);
			if(Intersections.bHasIntersection)
			{
				float Angle = (Intersections.MinIntersection - Origin).GetSafeNormal().GetAngleDegreesTo(ArcDirection);
				if(Angle < FullArcDegrees * 0.5)
					return true;
			}
		}

		FVector LeftArcSideNormal = ArcDirection.RotateAngleAxis(-FullArcDegrees * 0.5 + 90.0, Normal);
		FVector RightArcSideNormal = ArcDirection.RotateAngleAxis(FullArcDegrees * 0.5 - 90.0 , Normal);
		
		FVector LeftArcSideIntersection;
		bool bIntersectingLeftArcSide = Math::IsLineSegmentIntersectingPlane(Previous, Current, LeftArcSideNormal, Origin, LeftArcSideIntersection);
		FVector OriginToLeftIntersect = LeftArcSideIntersection - Origin;
		if(bIntersectingLeftArcSide && ArcDirection.DotProduct(OriginToLeftIntersect) > 0.0 && OriginToLeftIntersect.Size() <= EnterCircleRadius)
			return true;

		FVector RightArcSideIntersection;
		bool bIntersectingRightArcSide = Math::IsLineSegmentIntersectingPlane(Previous, Current, RightArcSideNormal, Origin, RightArcSideIntersection);
		FVector OriginToRightIntersect = RightArcSideIntersection - Origin;
		if(bIntersectingRightArcSide && ArcDirection.DotProduct(OriginToRightIntersect) > 0.0 && OriginToRightIntersect.Size() <= EnterCircleRadius)
			return true;

		return false;
	}

	bool IsPlayerWithinBounds()
	{
		return Game::Mio.ActorCenterLocation.Distance(BarrelEnterCircleOrigin) <= EnterCircleRadius;
	}

	void GetInRangeAutoAimTargets(TArray<AEvergreenBarrel>& InAutoAimBarrels)
	{
		TListedActors<AEvergreenBarrel> ListedBarrels;
		InAutoAimBarrels = ListedBarrels.Array;
		for(int i = InAutoAimBarrels.Num() - 1; i >= 0; i--)
		{
			float DistSquared = ActorLocation.DistSquared(InAutoAimBarrels[i].ActorLocation);

			if(this == InAutoAimBarrels[i] || DistSquared > Math::Square(AutoAimMaxRange))
			{
				InAutoAimBarrels.RemoveAt(i);
			}
		}
	}

	bool IsWithinAutoAimRange(AEvergreenBarrel&out TargetBarrel)
	{
		for(AEvergreenBarrel Barrel : AutoAimBarrels)
		{
			FVector ThisBarrelToOtherDir = (Barrel.ActorLocation - ActorLocation).GetSafeNormal();
			float AngleDegrees = ThisBarrelToOtherDir.GetAngleDegreesTo(SkeletalMesh.UpVector);

			if(AngleDegrees <= Barrel.AutoAimMaxAngle)
			{
				TargetBarrel = Barrel;
				return true;
			}
		}

		return false;
	}

	FVector GetPlaneOriginWorldLocation() const property
	{
		FVector PlaneRelativeOrigin = Bounds.Center + FVector::UpVector * Bounds.Extent.Z;
		return ActorTransform.TransformPosition(PlaneRelativeOrigin);
	}

	UFUNCTION(BlueprintPure)
	float AudioGetCurrentTurnRate() const
	{
		float RelevantAlpha = bUseRawInput ? InterpedAlpha : LifeComp.HorizontalAlpha;
		return Math::Abs(RelevantAlpha);
	}
}

#if EDITOR
UCLASS(NotPlaceable, NotBlueprintable)
class UEvergreenBarrelVisualizerDummyComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UEvergreenBarrelVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UEvergreenBarrelVisualizerDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		AEvergreenBarrel Barrel = Cast<AEvergreenBarrel>(Component.Owner);

		DrawEnterAngles(Barrel);
		DrawVelocityArc(Barrel);

		if(Barrel.bVisualizeAutoAimMaxRange)
			DrawWireSphere(Barrel.ActorLocation, Barrel.AutoAimMaxRange, FLinearColor::Red, 1.0);

		TArray<AEvergreenBarrel> InRangeBarrels;
		Barrel.GetInRangeAutoAimTargets(InRangeBarrels);
		DrawMaxAnglesOnBarrels(Barrel, InRangeBarrels);
	}

	void DrawEnterAngles(AEvergreenBarrel Barrel)
	{
		DrawArc(Barrel.BarrelEnterCircleOrigin, Barrel.EnterConeAngleDegrees, Barrel.EnterCircleRadius, Barrel.ActorUpVector, FLinearColor::Green, 5.0, Barrel.ActorRightVector);
		DrawArc(Barrel.BarrelEnterCircleOrigin, Barrel.KillConeAngleDegrees, Barrel.EnterCircleRadius, -Barrel.ActorUpVector, FLinearColor::Red, 5.0, Barrel.ActorRightVector);
	}

	void DrawMaxAnglesOnBarrels(AEvergreenBarrel ThisBarrel, const TArray<AEvergreenBarrel>& Barrels)
	{
		for(AEvergreenBarrel Barrel : Barrels)
		{
			FVector Dir = (ThisBarrel.ActorLocation - Barrel.ActorLocation).GetSafeNormal();
			DrawArc(Barrel.ActorLocation, Barrel.AutoAimMaxAngle, 800.0, Dir, FLinearColor::Red, 3.0);
			DrawArrow(Barrel.ActorLocation, Barrel.ActorLocation + Dir * 800.0, FLinearColor::Red, 50.0, 3.0);
		}
	}

	void DrawVelocityArc(AEvergreenBarrel Barrel)
	{
		const float FullArcMaxDuration = 2.0;
		const float StepDuration = 0.02;
		FVector CurrentPlayerLocation = Barrel.SkeletalMesh.WorldLocation - Barrel.SkeletalMesh.UpVector * (TundraShapeshiftingStatics::SnowMonkeyCollisionSize.Y * 0.5);
		float CurrentDuration = 0.0;
		FVector PreviousLocation = CurrentPlayerLocation;
		FVector CurrentMioVelocity = Barrel.SkeletalMesh.UpVector * Barrel.MioShootOutImpulse;

		while(CurrentDuration < FullArcMaxDuration)
		{
			CurrentDuration += StepDuration;
			float CurrentStepDuration = Math::Min(StepDuration, FullArcMaxDuration - CurrentDuration);
			CurrentPlayerLocation = PreviousLocation + (CurrentMioVelocity * CurrentStepDuration);
			DrawLine(PreviousLocation, CurrentPlayerLocation, FLinearColor::Red, 5);
			CurrentMioVelocity = TickAirMotionVelocity(Barrel, CurrentMioVelocity, CurrentStepDuration);
			PreviousLocation = CurrentPlayerLocation;
		}
	}

	FVector TickAirMotionVelocity(AEvergreenBarrel Barrel, FVector PreviousVelocity, float DeltaTime)
	{
		FVector Horizontal = PreviousVelocity.VectorPlaneProject(FVector::UpVector);
		FVector Vertical = PreviousVelocity - Horizontal;

		Horizontal = CalculateUnconstrainedAirControlVelocity(Horizontal, DeltaTime);
		Vertical -= FVector::UpVector * (Barrel.MioGravityUntilHittingGroundOrPoleClimb * DeltaTime);

		return Horizontal + Vertical;
	}

	// Copy of function in UPlayerAirMotionComponent (with a lot of the unnecessary stuff stripped away)
	FVector CalculateUnconstrainedAirControlVelocity(
		FVector PreviousVelocity,
		float DeltaTime
	)
	{
		float TargetMaximumSpeedBeforeDrag = 600.0;
		float DragSpeed = 250.0;

		// Zero input always gives the velocity
		float VelocitySize = PreviousVelocity.Size();
		if (VelocitySize > TargetMaximumSpeedBeforeDrag)
			VelocitySize = Math::Max(TargetMaximumSpeedBeforeDrag, VelocitySize - (DragSpeed * DeltaTime));

		return PreviousVelocity.GetSafeNormal() * VelocitySize;
	}
}
#endif