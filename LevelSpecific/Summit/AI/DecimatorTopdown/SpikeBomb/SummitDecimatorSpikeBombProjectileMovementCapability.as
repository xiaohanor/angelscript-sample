class USummitDecimatorSpikeBombProjectileMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);
	default BlockExclusionTags.Add(n"ProjectileMovement");	

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	USummitDecimatorSpikeBombSettings Settings;
	UBasicAICharacterMovementComponent MoveComp;
	USimpleMovementData Movement;
	UTeenDragonTailAttackResponseComponent TailAttackResponseComp;
	USummitMeltComponent MeltComp;
	UHazeActorRespawnableComponent RespawnComp;
	USummitDecimatorSpikeBombAutoAimComponent AutoAimComp;
    USummitDecimatorSpikeBombComponent SpikeBombComp;

	FVector CurrentVelocity;
	float Gravity = 982;
	bool bIsLaunched = false;
	FRollParams RollHitParams; // If we want always auto aim, we should clean this up

	AAISummitDecimatorTopdown Decimator;
	AAISummitDecimatorSpikeBomb SpikeBombOwner;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorSpikeBombSettings::GetSettings(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSimpleMovementData();
		TailAttackResponseComp = UTeenDragonTailAttackResponseComponent::Get(Owner);
		TailAttackResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		MeltComp = USummitMeltComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"Reset");
		AutoAimComp = USummitDecimatorSpikeBombAutoAimComponent::GetOrCreate(Owner);
		SpikeBombComp = USummitDecimatorSpikeBombComponent::Get(Owner);
		SpikeBombOwner = Cast<AAISummitDecimatorSpikeBomb>(Owner);
	}

	UFUNCTION()
	private void Reset()
	{
		bIsLaunched = false;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
        if (!Owner.HasControl())
            return;

		if (bIsLaunched)
			return;

		if(!MeltComp.bMelted)
			return;

		//if (!SpikeBombComp.bIsLaunchable) // removed for having Decimator controlled by Zoe side all the time.
		//	return;

		bIsLaunched = true;	
	}
	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FRollParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!bIsLaunched)
			return false;
		
        //if (!SpikeBombComp.bIsLaunchable) // removed for having Decimator controlled by Zoe side all the time.
        //    return false;
        
        Params = RollHitParams;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;
		
		if (!bIsLaunched)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FRollParams Params)
	{
		if (Decimator == nullptr)
			Decimator = SpikeBombOwner.DecimatorOwner;

		// If within auto-aim angle, set Dir towards Decimator
		FVector ToDecimator;
		FVector TargetLocation; 

		ToDecimator = Decimator.ActorCenterLocation - Owner.ActorCenterLocation;
		ToDecimator.Z = 0;
		TargetLocation = Decimator.ActorCenterLocation;
				
		// Height controlled trajectory
		float Height = Decimator.PhaseComp.CurrentPhase == 3 ? Settings.SpikeBombHitByRollAutoAimArcHeightPhaseThree : Settings.SpikeBombHitByRollAutoAimArcHeight; // Lower height in phase 3.
		// Set velocity without any movement prediction.
		CurrentVelocity = Trajectory::CalculateVelocityForPathWithHeight(Owner.ActorLocation, TargetLocation, Gravity * Settings.SpikeBombGravityScale, Height);

		// If the Decimator is spinning around the boundaries of the arena, we'll want to roughly predict its future location and set the trajectory velocity to match.
		FVector PredictedLocation;
		if (Decimator.PhaseComp.CurrentPhase == 2)
		 	PredictedLocation = CalculatePredictedTrajectoryVelocity(); // Phase 2 only
		else
			PredictedLocation = Decimator.ActorCenterLocation;

		FVector ToPredictedLocation;
		ToPredictedLocation = (PredictedLocation - Owner.ActorLocation);
		ToPredictedLocation.Z = 0;
		// If outside of auto-aim angle range, set velocity in actual roll direction
		FVector RollDir = Params.RollDirection;
		if (ToPredictedLocation.GetSafeNormal().DotProduct(RollDir) < Math::Cos(Settings.SpikeBombHitByRollAutoAimAngle))
		{
			CurrentVelocity = RollDir.RotateTowards(FVector::UpVector,Settings.SpikeBombHitByRollFlightAngle) * CurrentVelocity.Size();
			AutoAimComp.OnManualAimHit.Broadcast();
		}
		else
		{
			AutoAimComp.OnAutoAimAssistedHit.Broadcast();
		}		

		USummitDecimatorSpikeBombEffectsHandler::Trigger_OnLaunched(Owner, FSummitDecimatorSpikeBombLaunchParams(Params.HitLocation, CurrentVelocity.GetSafeNormal()));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Reset();
	}

	// Movement is locally simulated. This also gives the benefit that the predicted Decimator location will be independent of Decimator's control side.
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			// Apply gravity with gravity scale manually
			CurrentVelocity -= FVector(0, 0, Gravity) * Settings.SpikeBombGravityScale * DeltaTime;

			// Set movement velocity
			Movement.AddVelocity(CurrentVelocity);

			MoveComp.ApplyMove(Movement);
		}
	}

	// Used in phase 2 for calculating trajectory.
	FVector CalculatePredictedTrajectoryVelocity()
	{		
		AActor ArenaCenterScenePoint = Decimator.AttachmentRootActor;
		USummitDecimatorTopdownSettings DecimatorSettings = USummitDecimatorTopdownSettings::GetSettings(Decimator);
		float SpinningDir = Decimator.SpinningDir;
		if (Decimator.PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::TurningInwards) // temp hack, spinning dir is toggled too early in spin balcony capability.
			SpinningDir = -SpinningDir;
		FRotator RotationRate(0, DecimatorSettings.SpinBalconyRotationRate * SpinningDir, 0);
		
		FVector PredictedLocation = Decimator.ActorCenterLocation;
		FVector ToPredictedLocation;		
		const float PredictionTimeLeastDeltaStep = 0.01;  
		float PredictionTimeDelta = 1000.0; // Big number
		float LastPredictionTime = 1000.0;
		
		ToPredictedLocation = Decimator.ActorCenterLocation - Owner.ActorCenterLocation;
		ToPredictedLocation.Z = 0; // constrain to plane
			
		// Refine prediction. Should be enough with two iterations.
		for (int i = 0; PredictionTimeDelta > PredictionTimeLeastDeltaStep && i < 10; i++)
		{
			float HorizontalSpeed = FVector(CurrentVelocity.X, CurrentVelocity.Y, 0).Size();
			float TimeToPredictedLoc = ToPredictedLocation.Size() / HorizontalSpeed;
			float PredictionTime = GetAdjustedPredictedDuration(TimeToPredictedLoc); // Trims prediction time for suspended movement.

			if (PredictionTime <= 0.0) // Early out, need no prediction.
				break;

			// Simulate future location
			ArenaCenterScenePoint.AddActorLocalRotation(RotationRate * PredictionTime); // temporary rotation for calculating predicted location
			PredictedLocation = Decimator.ActorCenterLocation; // Decimator is now in predicted location until next line.			
			ArenaCenterScenePoint.AddActorLocalRotation(RotationRate * -PredictionTime); // undo rotation

			// Update velocity needed to get to predicted location
			CurrentVelocity = Trajectory::CalculateVelocityForPathWithHeight(Owner.ActorLocation, PredictedLocation, Gravity * Settings.SpikeBombGravityScale, Settings.SpikeBombHitByRollAutoAimArcHeight);

			// Update diff between predicted times for each iteration
			PredictionTimeDelta = Math::Abs(LastPredictionTime - PredictionTime);
			LastPredictionTime = PredictionTime;

			ToPredictedLocation = PredictedLocation - Owner.ActorCenterLocation;
			ToPredictedLocation.Z = 0;
		}
		
		return PredictedLocation;
	}

	// Calculates the remaining spin duration to be used as the spikebomb auto-aim prediction time
	float GetAdjustedPredictedDuration(float PredictedDuration)
	{
		if (Decimator.PhaseComp.CurrentPhase < 2)
			return 0.0;

		if (Decimator.PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::Idle)
			return 0.0;

		// If currently moving, just use the predicted duration and respect any turn delay.
		if (Decimator.PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::Pause)
		{
			float TurnDelay = Decimator.bIsTurningOutward ? Decimator.PhaseComp.RemainingTurnDuration : 0.0;
			float SpinDuration = Math::Min(PredictedDuration - TurnDelay, PredictedDuration);
//PrintScaled("PredictDuration=" + PredictedDuration + "Pause prediction=" + SpinDuration + "RemainingPause=" +Decimator.PhaseComp.RemainingPauseDuration);
			return SpinDuration;
		}

		// If currently standing still, remove some prediction time
		if (Decimator.PhaseComp.RemainingActionDuration > 0.0)
		{
			float TurnDelay = Decimator.bIsTurningOutward ? Decimator.PhaseComp.RemainingTurnDuration : 90.0 / Decimator.PhaseComp.Settings.DecimatorTurnRate; // When action is running, the turn duration is guaranteed to be full amount.
			float SpinDuration = Math::Max(PredictedDuration - Decimator.PhaseComp.RemainingActionDuration - TurnDelay, 0);
//PrintScaled("TurnDelay=" + TurnDelay, Color = FLinearColor::Red);
//PrintScaled("PredictDuration=" + PredictedDuration + "Action prediction=" + SpinDuration, Color = FLinearColor::Blue);
			return SpinDuration;
		}

		return 0.0;
	}
	
};