
UCLASS(Abstract)
class UWorld_Tundra_Shared_Interactable_LifeReceiveingControlledPuzzle_Object_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UFauxPhysicsTranslateComponent FauxTranslateComp;
	UHazeCrumbSyncedFloatComponent SyncedFloatComp;

	UFUNCTION(BlueprintEvent)
	void OnStartMoving(bool bIsForward) {};

	UFUNCTION(BlueprintEvent)
	void OnStopMoving() {};

	UFUNCTION(BlueprintEvent)
	void OnHitConstraintLow(float Strength) {};

	UFUNCTION(BlueprintEvent)
	void OnHitConstraintHigh(float Strength) {};

	UFUNCTION(BlueprintEvent)
	void TickMoving(float DeltaSeconds) {};

	UFUNCTION(BlueprintEvent)
	void StartTrackingSyncedFloatAlpha() {};

	UPROPERTY(Category = "Movement")
	float MaxMovementSpeed = 700;

	UPROPERTY(Category = "Movement")
	bool bMovementControlledByAlpha = false;


	UFUNCTION(BlueprintPure)
	void GetMovementSpeedNormalized(float&out Speed, float&out Direction)
	{
		Speed = Math::Min(1.0, CachedMovementSpeed / MaxMovementSpeed);
		Direction = DirectionValue;
	}

	UFUNCTION(BlueprintPure)
	float GetAlphaValue()
	{
		return Alpha;
	}

	private float Alpha = 0.0;
	private float PreviousAlpha = 0.0;
	private float DirectionValue = 0.0;

	private bool bIsMoving = false;
	private bool bWasMoving = false;
	
	private float CachedMovementSpeed = 0.0;
	private FVector LastLocation;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		FauxTranslateComp = UFauxPhysicsTranslateComponent::Get(HazeOwner);
		SyncedFloatComp = UHazeCrumbSyncedFloatComponent::Get(HazeOwner);

		if(FauxTranslateComp != nullptr)
		{
			FauxTranslateComp.OnConstraintHit.AddUFunction(this, n"OnHitConstraintInternal");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(FauxTranslateComp == nullptr && SyncedFloatComp != nullptr)
		{
			StartTrackingSyncedFloatAlpha();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(FauxTranslateComp != nullptr)
			Alpha = FauxTranslateComp.GetCurrentAlphaBetweenConstraints().Size();
		else if(SyncedFloatComp != nullptr)
			Alpha = SyncedFloatComp.GetValue();

		bIsMoving = (Alpha != PreviousAlpha);
		if(!bIsMoving)
		{
			DirectionValue = 0.0;

			if(bWasMoving)
				OnStopMoving();
		}
		else
		{
			DirectionValue = Math::Sign(Alpha - PreviousAlpha);

			if(!bWasMoving)
			{
				bool bIsForward = DirectionValue > 0;
				OnStartMoving(bIsForward);	
			}

			TickMoving(DeltaSeconds);
		}

		if (!bMovementControlledByAlpha)
		{
			const FVector CurrentLocation = FauxTranslateComp != nullptr ? FauxTranslateComp.GetWorldLocation() : DefaultEmitter.AudioComponent.GetWorldLocation();
			const FVector Velo = CurrentLocation - LastLocation;
			CachedMovementSpeed = Velo.Size() / DeltaSeconds;

			LastLocation = CurrentLocation;
		}
		else
		{
			CachedMovementSpeed = Math::Abs((Alpha - PreviousAlpha) / DeltaSeconds);
		}

		PreviousAlpha = Alpha;
		bWasMoving = bIsMoving;
	}

	UFUNCTION()
	void OnHitConstraintInternal(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(Alpha > 0.5)
			OnHitConstraintHigh(HitStrength);
		else
			OnHitConstraintLow(HitStrength);
	}

	UFUNCTION(BlueprintCallable)
	void TrackDistanceToCameraOnAllEmitters()
	{
		for (auto AudioComponent : AudioComponents)
		{
			AudioComponent.GetDistanceToTarget(EHazeAudioDistanceTrackingTarget::Camera, true);
		}
	}
}