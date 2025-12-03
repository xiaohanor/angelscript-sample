event void FOnGrowingFlowerInteractStopped();
event void FOnGrowingFlowerInteractStarted();
event void FOnGrowingFlowerReachedEnd();

UCLASS(Abstract)
class ATundraRiver_SplineGrowingFlower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent FauxConeRotate;
	default FauxConeRotate.Friction = 15.0;
	default FauxConeRotate.ForceScalar = 0.4;
	default FauxConeRotate.SpringStrength = 0.2;
	default FauxConeRotate.ConeAngle = 50.0;

	UPROPERTY(DefaultComponent, Attach = FauxConeRotate)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UStaticMeshComponent PetalCollision;
	default PetalCollision.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UStaticMeshComponent FlowerElevatorCollision;
	default FlowerElevatorCollision.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UTundraGroundedLifeReceivingTargetableComponent LifeReceivingTargetable;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	UNiagaraComponent StemNiagara;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent FauxPhysicsPlayerWeightComp;

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeReceivingComp;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent GroundSlamResponseComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;
	default MovementImpactCallbackComp.bUseSpecifiedComponentsForImpacts = true;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedDistance;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 12000.0;

	UPROPERTY()
	FOnGrowingFlowerInteractStopped OnInteractStopped;

	UPROPERTY()
	FOnGrowingFlowerInteractStopped OnInteractStarted;

	UPROPERTY()
	FOnGrowingFlowerReachedEnd OnReachedEnd;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedAudioTargetDistance;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTundraRiver_SplineGrowingFlowerVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(EditInstanceOnly)
	ASplineActor Spline;

	UPROPERTY(EditAnywhere)
	float LowestSplineDistance = 500.0;

	UPROPERTY(EditAnywhere)
	float BaseSplineDistance = 800.0;

	UPROPERTY(EditAnywhere)
	float MaxRotateAngleDegrees = 15.0;

	/* The rotation of the flower will slerp between zero rotation and the rotation of the spline using this value. */
	UPROPERTY(EditAnywhere, Meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float RotationAlphaScalar = 0.3;

	UPROPERTY(EditAnywhere)
	float TreeGuardianGrowSpeedMultiplier = 0.05;

	UPROPERTY(EditAnywhere)
	float ResetToBaseHeightSpeedMultiplier = 0.15;

	UPROPERTY(EditAnywhere, Category = "Height Offset")
	float MonkeySmashHeightOffset = -600.0;

	UPROPERTY(EditAnywhere, Category = "Height Offset")
	float LandingHeightOffset = -150.0;

	UPROPERTY(EditAnywhere, Category = "Height Offset")
	float GroundSlamPauseDuration = 1.5;

	UPROPERTY(EditAnywhere, Category = "Height Offset")
	float LandingPauseDuration = 1.5;

	UPROPERTY(EditAnywhere, Category = "Height Offset")
	float MonkeySmashHeightOffsetWhenLifeGiving = -600.0;

	UPROPERTY(EditAnywhere, Category = "Height Offset")
	float LandingHeightOffsetWhenLifeGiving = -150.0;

	UPROPERTY(EditAnywhere, Category = "Height Offset")
	float GroundSlamPauseDurationWhenLifeGiving = 1.5;

	UPROPERTY(EditAnywhere, Category = "Height Offset")
	float LandingPauseDurationWhenLifeGiving = 1.5;

	UPROPERTY(EditAnywhere)
	float EndInteractPauseDuration = 2.5;

	UPROPERTY(EditAnywhere)
	UForceFeedbackEffect ForceFeedbackWhenReachingEnd;

	float TargetLandingOffset = 0.0;
	float LandingOffset = 0.0;
	float TimeOfLanding = -100.0;

	float TargetSmashOffset = 0.0;
	float SmashOffset = 0.0;
	float TimeOfSmash = -100.0;

	float TimeOfStopInteract = -100.0;
	float TargetDistance;

	FHazeAcceleratedRotator AcceleratedRotator;
	FHazeAcceleratedFloat AcceleratedForceFeedbackMultiplier;
	FTundraRiver_GrowingFlowerAnimData AnimData;
	bool bPetalCollisionEnabled;
	
	UPROPERTY()
	float CurrentAlpha;
	bool bMoving = false;
	bool bHasReachedEnd = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedForceFeedbackMultiplier.SnapTo(1.0);
		SetPetalCollisionActive(false);
		SetActorControlSide(Game::Zoe);
		TargetDistance = BaseSplineDistance;
		SyncedDistance.Value = TargetDistance;
		SyncedAudioTargetDistance.Value = TargetDistance;
		ActorRotation = FRotator::MakeFromZX(FVector::UpVector, FVector::ForwardVector);
		AcceleratedRotator.SnapTo(ActorRotation);

		MovementImpactCallbackComp.AddComponentUsedForImpacts(FlowerElevatorCollision);
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpact");
		GroundSlamResponseComp.OnGroundSlam.AddUFunction(this, n"OnGroundSlam");
		LifeReceivingComp.OnInteractStart.AddUFunction(this, n"OnInteractStart");
		LifeReceivingComp.OnInteractStop.AddUFunction(this, n"OnInteractStop");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!IsPausedBecauseOfLanding())
			TargetLandingOffset = Math::FInterpConstantTo(TargetLandingOffset, 0.0, DeltaTime, SplineLength * 0.15);

		if(!IsPausedBecauseOfGroundSlam())
			TargetSmashOffset = Math::FInterpConstantTo(TargetSmashOffset, 0.0, DeltaTime, SplineLength * 0.15);

		SmashOffset = Math::FInterpTo(SmashOffset, TargetSmashOffset, DeltaTime, 2.0);
		LandingOffset = Math::FInterpTo(LandingOffset, TargetLandingOffset, DeltaTime, 2.0);

		LifeReceivingComp.VerticalAlphaSettings.bEnableForceFeedback = true;
		if(LifeReceivingComp.IsCurrentlyLifeGiving())
		{
			float RawInput = LifeReceivingComp.RawVerticalInput;
			TargetDistance = Math::Clamp(TargetDistance + (RawInput * DeltaTime * SplineLength * TreeGuardianGrowSpeedMultiplier), LowestSplineDistance, SplineLength);

			if(RawInput < -KINDA_SMALL_NUMBER && Math::IsNearlyEqual(TargetDistance, LowestSplineDistance))
				LifeReceivingComp.VerticalAlphaSettings.bEnableForceFeedback = false;
		}
		else if(!IsPausedBecauseOfEndInteract() && !bHasReachedEnd)
		{
			TargetDistance = Math::FInterpConstantTo(TargetDistance, BaseSplineDistance, DeltaTime, SplineLength * ResetToBaseHeightSpeedMultiplier);

			AnimData.bTreeGuardianInteracting = false;
		}

		if(HasControl())
		{
			SyncedDistance.Value = Math::FInterpTo(SyncedDistance.Value, TargetDistance, DeltaTime, 2.0);

			SyncedAudioTargetDistance.Value = TargetDistance + TargetLandingOffset + TargetSmashOffset;
			SyncedAudioTargetDistance.Value = Math::Clamp(SyncedAudioTargetDistance.Value, LowestSplineDistance, SplineLength);
		}

		FixupOffsets();

		float CurrentDistance = SyncedDistance.Value + LandingOffset + SmashOffset;
		CurrentDistance = Math::Clamp(CurrentDistance, LowestSplineDistance, SplineLength);
		float NewAlpha = CurrentDistance / SplineLength;
		if(!bMoving && CurrentAlpha != NewAlpha)
		{
			OnStartMoving();
		}
		else if(bMoving && CurrentAlpha == NewAlpha)
		{
			OnStopMoving();
		}

		CurrentAlpha = NewAlpha;
		AnimData.HeightAlpha = CurrentAlpha;
		if(!bPetalCollisionEnabled && LifeReceivingComp.IsCurrentlyLifeGiving() && CurrentAlpha > 0.9)
		{
			SetPetalCollisionActive(true);
		}
		else if(bPetalCollisionEnabled && CurrentAlpha < 0.9)
		{
			SetPetalCollisionActive(false);
		}

		float Multiplier = AcceleratedForceFeedbackMultiplier.AccelerateTo(bHasReachedEnd ? 0.0 : 1.0, 1.0, DeltaTime);
		LifeReceivingComp.VerticalAlphaSettings.ForceFeedbackMultiplier = Multiplier;

		UpdateActorTransform(CurrentDistance, DeltaTime);
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void SnapActorToBaseDistance()
	{
		if(Spline == nullptr)
			return;

		UpdateActorTransform(BaseSplineDistance, 0.0, true);
	}
#endif

	void FixupOffsets()
	{
		if(SyncedDistance.Value + SmashOffset < LowestSplineDistance)
		{
			SmashOffset = LowestSplineDistance - SyncedDistance.Value;
			TargetSmashOffset = SmashOffset;
			LandingOffset = 0.0;
			TargetLandingOffset = 0.0;
		}

		if(SyncedDistance.Value + LandingOffset < LowestSplineDistance)
		{
			LandingOffset = LowestSplineDistance - SyncedDistance.Value;
			TargetLandingOffset = LandingOffset;
		}
	}

	void SetPetalCollisionActive(bool bState)
	{
		PetalCollision.SetCollisionEnabled(bState ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
		bPetalCollisionEnabled = bState;
	}

	void UpdateActorTransform(float SplineDistance, float DeltaTime, bool bCalledInEditor = false)
	{
		FTransform SplineTransform = Spline.Spline.GetWorldTransformAtSplineDistance(SplineDistance);

		FVector UpVector = SplineTransform.Rotation.ForwardVector;
		UpVector = FQuat::Slerp(FQuat::Identity, FQuat::MakeFromZX(UpVector, FVector::ForwardVector), RotationAlphaScalar).UpVector;
		UpVector = UpVector.ConstrainToCone(FVector::UpVector, Math::DegreesToRadians(MaxRotateAngleDegrees));
		FRotator Rotation = FRotator::MakeFromZX(UpVector, FVector::ForwardVector);

		ActorLocation = SplineTransform.Location;

		if(SplineDistance >= SplineLength - 100 && !bHasReachedEnd)
		{
			bHasReachedEnd = true;
			OnReachedEnd.Broadcast();
			Game::Zoe.PlayForceFeedback(ForceFeedbackWhenReachingEnd, this);
		}
		
		if(!bCalledInEditor)
		{
			AcceleratedRotator.AccelerateTo(Rotation, 1.0, DeltaTime);
			ActorRotation = AcceleratedRotator.Value;
		}
		else
		{
			ActorRotation = Rotation;
		}
	}

	UFUNCTION()
	private void OnGroundImpact(AHazePlayerCharacter Player)
	{
		auto MoveComp = UPlayerMovementComponent::Get(Player);
		if(!MoveComp.WasInAir())
			return;

		float Offset = LifeReceivingComp.IsCurrentlyLifeGiving() ? LandingHeightOffsetWhenLifeGiving : LandingHeightOffset;
		TargetLandingOffset += Offset;

		if(SyncedDistance.Value + TargetLandingOffset + TargetSmashOffset < LowestSplineDistance)
			TargetLandingOffset = LowestSplineDistance - (SyncedDistance.Value + TargetSmashOffset);

		TimeOfLanding = Time::GetGameTimeSeconds();
		AnimData.LandFrame.Set(Time::FrameNumber);
	}

	UFUNCTION()
	private void OnGroundSlam(ETundraPlayerSnowMonkeyGroundSlamType GroundSlamType, FVector PlayerLocation)
	{
		float Offset = LifeReceivingComp.IsCurrentlyLifeGiving() ? MonkeySmashHeightOffsetWhenLifeGiving : MonkeySmashHeightOffset;
		TargetSmashOffset += Offset;

		if(SyncedDistance.Value + TargetLandingOffset + TargetSmashOffset < 0.0)
			TargetSmashOffset = LowestSplineDistance - (SyncedDistance.Value + TargetLandingOffset);
		
		TimeOfSmash = Time::GetGameTimeSeconds();
		AnimData.SmashFrame.Set(Time::FrameNumber);
	}

	UFUNCTION()
	private void OnInteractStart(bool bForced)
	{
		AnimData.bTreeGuardianInteracting = true;
	}

	UFUNCTION()
	private void OnInteractStop(bool bForced)
	{
		TimeOfStopInteract = Time::GetGameTimeSeconds();
	}

	void OnStartMoving()
	{
		UTundraRiver_SplineGrowingFlower_EffectHandler::Trigger_OnStartMoving(this);
		bMoving = true;
	}

	void OnStopMoving()
	{
		UTundraRiver_SplineGrowingFlower_EffectHandler::Trigger_OnStopMoving(this);
		bMoving = false;
	}

	float GetSplineLength() const property
	{
		return Spline.Spline.SplineLength;
	}

	UFUNCTION(BlueprintPure)
	float AudioGetCurrentAlpha()
	{
		return Math::NormalizeToRange(SyncedAudioTargetDistance.Value, LowestSplineDistance, SplineLength);
	}

	bool IsPausedBecauseOfLanding()
	{
		return Time::GetGameTimeSince(TimeOfLanding) < RelevantLandingPauseDuration;
	}

	bool IsPausedBecauseOfGroundSlam()
	{
		return Time::GetGameTimeSince(TimeOfSmash) < RelevantLandingPauseDuration;
	}

	bool IsPausedBecauseOfEndInteract()
	{
		return Time::GetGameTimeSince(TimeOfStopInteract) < EndInteractPauseDuration;
	}

	float GetRelevantLandingPauseDuration() const property
	{
		if(LifeReceivingComp.IsCurrentlyLifeGiving())
			return LandingPauseDurationWhenLifeGiving;
		
		return LandingPauseDuration;
	}

	float GetRelevantGroundSlamPauseDuration() const property
	{
		if(LifeReceivingComp.IsCurrentlyLifeGiving())
			return GroundSlamPauseDurationWhenLifeGiving;
		
		return GroundSlamPauseDuration;
	}
}

#if EDITOR
class UTundraRiver_SplineGrowingFlowerVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundraRiver_SplineGrowingFlowerVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraRiver_SplineGrowingFlowerVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto GrowingFlower = Cast<ATundraRiver_SplineGrowingFlower>(Component.Owner);

		UHazeSplineComponent Spline = GrowingFlower.Spline.Spline;

		FVector LowestPoint = Spline.GetWorldLocationAtSplineDistance(GrowingFlower.LowestSplineDistance);
		FVector BasePoint = Spline.GetWorldLocationAtSplineDistance(GrowingFlower.BaseSplineDistance);

		DrawPoint(LowestPoint, FLinearColor::Red, 20.0);
		DrawPoint(BasePoint, FLinearColor::Yellow, 20.0);
	}
}
#endif