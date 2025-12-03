const FStatID STAT_PlayerMovementComponent_HandlePlayerMoveInto(n"PlayerMovementComponent_HandlePlayerMoveInto");
const FStatID STAT_PlayerMovementComponent_HandlePlayerMoveIntoRotating(n"PlayerMovementComponent_HandlePlayerMoveIntoRotating");

UCLASS(NotBlueprintable, NotPlaceable)
class UPlayerMovementComponent : UHazeMovementComponent
{
	// The current movement input capability type that should be used.
	// The capabilities are added to the available movement sheet
	TInstigated<EPlayerMovementInputCapabilityType> MovementCapabilityType(EPlayerMovementInputCapabilityType::Square);
	default DefaultFollowMovementResolver = UFollowComponentMovementResolver;
	default bConstrainRotationToHorizontalPlane = true;
	default bAllowSnappingPostSequence = true;

	// Makes it possible to rerun the movement on this component
	default bCanRerunMovement = true;

	default FindInheritVelocityComponentMethod = EMovementFindInheritVelocityComponentMethod::FindOnFollowedActorAndParents;

	AHazePlayerCharacter Player;

#if EDITOR
	bool bDebugIsInNotifyBlock = false;
#endif

	protected FQuat PreviousFrameMovementRotation;
	protected float RelativeMovementYawVelocity = 0.0;
	protected float WorldMovementYawVelocity = 0.0;
	private bool bPreviousMoveHadSyncedLocation = false;

	TInstigated<FInputPlaneLock> InputPlaneLock;

	UCameraFollowMovementFollowDataComponent FollowMovementData;

	protected UMoveIntoPlayerMovementData MoveIntoPlayerMovementData;
	protected UMoveIntoPlayerRotatingMovementData MoveIntoPlayerRotatingMovementData;
	protected FMoveIntoPlayerRelativeInstigator CurrentMoveIntoPlayerRelativeInstigator;

	protected EMovementImpactType IsBroadcastingImpactCallbacks = EMovementImpactType::Unset;
	protected TArray<UMovementImpactCallbackComponent> CurrentGroundImpactCallbackComponents;
	protected TArray<UMovementImpactCallbackComponent> CurrentWallImpactCallbackComponents;
	protected TArray<UMovementImpactCallbackComponent> CurrentCeilingImpactCallbackComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	
		Player = Cast<AHazePlayerCharacter>(Owner);
		SetupShapeComponent(Player.CapsuleComponent);

		FollowMovementData = UCameraFollowMovementFollowDataComponent::Get(Player);

		MoveIntoPlayerMovementData = Cast<UMoveIntoPlayerMovementData>(SetupMovementData(UMoveIntoPlayerMovementData));
		MoveIntoPlayerRotatingMovementData = Cast<UMoveIntoPlayerRotatingMovementData>(SetupMovementData(UMoveIntoPlayerRotatingMovementData));

		Player.ApplyDefaultSettings(PlayerDefaultMovementSettings);
		Player.ApplyDefaultSettings(PlayerDefaultMovementResolverSettings);
		Player.ApplyDefaultSettings(PlayerDefaultMovementGravitySettings);
		Player.ApplyDefaultSettings(PlayerDefaultMovementSteppingSettings);
		Player.ApplyDefaultSettings(PlayerDefaultMovementSweepingSettings);

		// After teleports and begin play,
		// We make sure that the current ground under the player
		// is the current ground we are starting with so we don't
		// begin one frame with doing a stepdown.
		FindGround();

		auto HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.OnStartDying.AddUFunction(this, n"OnStartDying");

#if !RELEASE
		DevTogglesMovement::Move::AutoRunInCircles.MakeVisible();
#endif
	}

	UFUNCTION()
	private void OnStartDying()
	{
		// Reset all accumulated events and broadcast impacts
		// This will make sure that we don't keep any movement impact callbacks active while dead
		AccumulatedImpacts.Reset();
		BroadcastAllImpactCallbacks();

		// These should be cleared now
		check(CurrentGroundImpactCallbackComponents.IsEmpty() && CurrentWallImpactCallbackComponents.IsEmpty() && CurrentCeilingImpactCallbackComponents.IsEmpty());
	}
	
	UFUNCTION(BlueprintOverride)
	void OnReset(FVector NewWorldUp, bool bValidateGround, float OverrideTraceDistance)
	{
		// Don't validate ground here, we do that after broadcasting impacts
		Super::OnReset(NewWorldUp, false, -1);

		// If we are not already broadcasting impact callbacks, do so here
		// We need this check since we can be reset from impact callbacks (example, from death),
		// which would make us broadcast again, while we never finished the first one
		if(IsBroadcastingImpactCallbacks == EMovementImpactType::Unset)
		{
			// OnReset will reset AccumulatedImpacts, we must broadcast callbacks now
			check(!AccumulatedImpacts.HasImpactedAnything());

			BroadcastAllImpactCallbacks();

			// These should be cleared now
			check(CurrentGroundImpactCallbackComponents.IsEmpty() && CurrentWallImpactCallbackComponents.IsEmpty() && CurrentCeilingImpactCallbackComponents.IsEmpty());
		}
	
		RelativeMovementYawVelocity = 0.0;
		WorldMovementYawVelocity = 0.0;
		PreviousFrameMovementRotation = HazeOwner.ActorQuat;
		FollowMovementData.OnReset();
	
		if(bValidateGround)
		{
			if(IsBroadcastingImpactCallbacks != EMovementImpactType::Unset)
			{
				// It is not allowed to check for starting ground while broadcasting impact callbacks!
				return;
			}

			FindGround(OverrideTraceDistance);
		}
	}

	protected void BroadcastAllImpactCallbacks() override
	{
		UpdateMovementImpactCallbacks(AccumulatedImpacts.GetGroundImpacts(), CurrentGroundImpactCallbackComponents, EMovementImpactType::Ground);
		UpdateMovementImpactCallbacks(AccumulatedImpacts.GetWallImpacts(), CurrentWallImpactCallbackComponents, EMovementImpactType::Wall);
		UpdateMovementImpactCallbacks(AccumulatedImpacts.GetCeilingImpacts(), CurrentCeilingImpactCallbackComponents, EMovementImpactType::Ceiling);
	}

	void FindGround(float OverrideTraceDistance = -1) override
	{
		// Default to no ground, since if we fail to find ground, we don't want to be grounded
		CurrentContacts.GroundContact = FMovementHitResult();

		const float WalkableSlopeAngleSetting = GetWalkableSlopeAngle();
		if(WalkableSlopeAngleSetting < 0)
		{
			// Can't find ground if nothing is walkable :c
			return;
		}

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(this);
		if(!TraceSettings.IsValid())
			return;
		
		FVector TraceStart = Player.ActorLocation;
		float TraceDistance = OverrideTraceDistance;
		TraceDistance = Math::Max(TraceDistance, GetGroundedSafetyMargin());
		TraceDistance += GetGroundedSafetyMargin();

		// First, try tracing with the current capsule location down
		FVector TraceEnd = TraceStart - (WorldUp * TraceDistance);
		FHitResult GroundHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

#if !RELEASE
		const FTemporalLog TemporalLog = GetGroundPage().Section("Find Ground");
		TemporalLog.Value("Trace Distance", TraceDistance);
		TemporalLog.HitResults("GroundHit [1 of 2]", GroundHit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif

		if(GroundHit.bBlockingHit && GroundHit.bStartPenetrating)
		{
			// We were penetrating something, try tracing from higher up
			TraceStart += WorldUp * GetShapeSizeForMovement(); 
			GroundHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

#if !RELEASE
			TemporalLog.HitResults("GroundHit [2 of 2]", GroundHit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif
		}

		if(GroundHit.IsValidBlockingHit())
		{
			// Apply safety distance
			GroundHit.Location += WorldUp * GetGroundedSafetyMargin();

			const FVector ImpactNormal = GroundHit.ImpactNormal;
			const float ImpactAngle = WorldUp.GetAngleDegreesTo(ImpactNormal);
			const float HitResultWalkableSlopeAngle = GroundHit.Component.GetWalkableSlopeAngle(WalkableSlopeAngleSetting);

			if(HitResultWalkableSlopeAngle >= 0 && ImpactAngle < HitResultWalkableSlopeAngle)
			{
				CurrentContacts.GroundContact = FMovementHitResult(GroundHit, 0);
				CurrentContacts.GroundContact.Type = EMovementImpactType::Ground;
				CurrentContacts.GroundContact.bIsWalkable = GroundHit.Component.HasTag(ComponentTags::Walkable);

				TArray<FHitResult> Hits;
				Hits.Add(GroundContact.ConvertToHitResult());
				UpdateMovementImpactCallbacks(Hits, CurrentGroundImpactCallbackComponents, EMovementImpactType::Ground);

				// Make sure that the previous ground is the current ground
				// so we don't perform stepdowns when starting
				OverridePreviousGroundContactWithCurrent();
				return;
			}
		}

		// No ground found, we are airborne
		CurrentContacts.GroundContact = FMovementHitResult(GroundHit, 0);
	}

	/**
	 * FB TODO: Make this a more core part of the movement component (maybe even a static function?)
	 * This is currently the same as FindGround, but returns the result.
	 */
	bool GroundTrace(FMovementHitResult&out OutGroundHit, float OverrideTraceDistance) const
	{
		const float WalkableSlopeAngleSetting = GetWalkableSlopeAngle();
		if(WalkableSlopeAngleSetting < 0)
		{
			// Can't find ground if nothing is walkable :c
			return false;
		}

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(this);
		if(!TraceSettings.IsValid())
			return false;
		
		FVector TraceStart = Player.ActorLocation;
		float TraceDistance = OverrideTraceDistance;
		TraceDistance = Math::Max(TraceDistance, GetGroundedSafetyMargin());
		TraceDistance += GetGroundedSafetyMargin();

		// First, try tracing with the current capsule location down
		FVector TraceEnd = TraceStart - (WorldUp * TraceDistance);
		FHitResult GroundHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

#if !RELEASE
		const FTemporalLog TemporalLog = GetGroundPage().Section("Find Ground");
		TemporalLog.Value("Trace Distance", TraceDistance);
		TemporalLog.HitResults("GroundHit [1 of 2]", GroundHit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif

		if(GroundHit.bBlockingHit && GroundHit.bStartPenetrating)
		{
			// We were penetrating something, try tracing from higher up
			TraceStart += WorldUp * GetShapeSizeForMovement(); 
			GroundHit = TraceSettings.QueryTraceSingle(TraceStart, TraceEnd);

#if !RELEASE
			TemporalLog.HitResults("GroundHit [2 of 2]", GroundHit, TraceSettings.Shape, TraceSettings.ShapeWorldOffset);
#endif
		}

		if(GroundHit.IsValidBlockingHit())
		{
			// Apply safety distance
			GroundHit.Location += WorldUp * GetGroundedSafetyMargin();

			const FVector ImpactNormal = GroundHit.ImpactNormal;
			const float ImpactAngle = WorldUp.GetAngleDegreesTo(ImpactNormal);
			const float HitResultWalkableSlopeAngle = GroundHit.Component.GetWalkableSlopeAngle(WalkableSlopeAngleSetting);

			if(HitResultWalkableSlopeAngle >= 0 && ImpactAngle < HitResultWalkableSlopeAngle)
			{
				OutGroundHit = FMovementHitResult(GroundHit, 0);
				OutGroundHit.Type = EMovementImpactType::Ground;
				OutGroundHit.bIsWalkable = GroundHit.Component.HasTag(ComponentTags::Walkable);
				return true;
			}
		}

		// No ground found, we are airborne
		OutGroundHit = FMovementHitResult(GroundHit, 0);
		return false;
	}

	void PostSequencerControl(FHazePostSequencerControlParams Params) override
	{
		Super::PostSequencerControl(Params);
		
		if(!HasControl())
		{
			if(Params.bSmoothSnapToGround && bAllowSnappingPostSequence)
			{
				// If we are the remote, we will wait for a crumb before we snap to the ground
				// But we still want to stop the animation IK from moving us down
				Player.SetAnimTrigger(n"MovementVerticalSnap");
			}
		}
	}

	void SnapToLocationWithVerticalLerp(FVector Location, float LerpSpeed = 0.2) override
	{
		Super::SnapToLocationWithVerticalLerp(Location, LerpSpeed);
		
		Player.SetAnimTrigger(n"MovementVerticalSnap");
	}

#if !RELEASE
	protected void AddComponentSpecificDebugInfo(FTemporalLog& TemporalLog) const override
	{
		if(!InputPlaneLock.IsDefaultValue())
		{
			FInputPlaneLock PlaneLock = InputPlaneLock.Get();
			float Size = 500;
			TemporalLog.Value(f"{MovementDebug::CategoryInfo};Plane Lock Input", true);
			TemporalLog.DirectionalArrow(f"{MovementDebug::CategoryInfo};Plane Lock Stick Up Down", Player.ActorCenterLocation, PlaneLock.UpDown * Size, 50, Color = FLinearColor::Red);
			TemporalLog.DirectionalArrow(f"{MovementDebug::CategoryInfo};Plane Lock Stick Left Right", Player.ActorCenterLocation, PlaneLock.LeftRight * Size, 50, Color = FLinearColor::Blue);
		
		}
		else
		{
			TemporalLog.Value(f"{MovementDebug::CategoryInfo};Plane Lock Input", false);
		}
	}
#endif

	/**
	 * Get the angular velocity (degrees) of yaw that the player is exhibiting.
	 * Used for banking in animation, for example.
	 */
	const float& GetMovementYawVelocity(bool bRelativeToFloor) const
	{
		if (bRelativeToFloor)
			return RelativeMovementYawVelocity;
		else
			return WorldMovementYawVelocity;
	}

	FVector GetNonLockedMovementInput() const property override
	{
		return UHazeMovementComponent::GetMovementInput();
	}

	FVector GetMovementInput() const property override
	{
		const FVector WantedInput = Super::GetMovementInput();
		
		// If spline locked, we need to modify the input
		if(SplineLockComponent != nullptr && SplineLockComponent.HasActiveSplineLock())
		{
			const FVector SplineLockedInput = SplineLockComponent.GetLockedMovementInput(WantedInput);
			return SplineLockedInput;
		}

#if !RELEASE
		if (DevTogglesMovement::Move::AutoRunInCircles.IsEnabled(Player) && WantedInput.Size() < KINDA_SMALL_NUMBER)
			return (Owner.ActorForwardVector + Owner.ActorRightVector * 0.2).GetSafeNormal();
#endif

		return WantedInput;
	}

	void PostResolve(UBaseMovementData DataType) override
	{
		if(CurrentMoveIntoPlayerRelativeInstigator.IsSet() && CurrentMoveIntoPlayerRelativeInstigator.IsOld())
		{
			CurrentMoveIntoPlayerRelativeInstigator.Clear(this);
		}

		Super::PostResolve(DataType);
		
		// Calculate how much we're yawing relative to our reference frame 
		RelativeMovementYawVelocity = DataType.GetYawVelocityPostMovement(PreviousFrameMovementRotation, bRelativeToFollow = true);
		WorldMovementYawVelocity = DataType.GetYawVelocityPostMovement(PreviousFrameMovementRotation, bRelativeToFollow = false);
		PreviousFrameMovementRotation = HazeOwner.ActorQuat;
		bPreviousMoveHadSyncedLocation = DataType.bHasSyncedLocationInfo;

		// For players, we make sure the players update overlaps every frame, even if they stood still this frame.
		// We have this to make an optimization work where volumes/triggers that only overlap with the player
		// don't update their own overlaps when they move, assuming that the player updates overlaps every frame to compensate.
		Player.CapsuleComponent.QueueComponentForUpdateOverlaps();
	}

	/**
	 * Whether we moved this frame, and that move was following a synced position instead of doing a local move.
	 */
	bool HasMovedWithSyncedLocationThisFrame() const
	{
		if (HasMovementControl())
			return false;
		if (!HasMovedThisFrame())
			return false;
		return bPreviousMoveHadSyncedLocation;
	}

	UFUNCTION(Category = "Movement")
	void ApplyMoveAndRequestLocomotion(UBaseMovementData Movement, FName AnimationTag)    
	{
		ApplyMove(Movement);		
		if(Player.Mesh.CanRequestLocomotion())
		{
			// FLinearColor DebugColor = Owner == Game::Mio ? FLinearColor::Yellow : FLinearColor::Green;
			// PrintToScreen("Requesting Tag: " + AnimationTag, Color = DebugColor);
			Player.Mesh.RequestLocomotion(AnimationTag, Movement.GetMovementInstigator());
		}	
	}

	UFUNCTION(Category = "Movement")
	void ApplyMoveAndRequestOverrideFeature(UBaseMovementData Movement, FName AnimationTag)
	{
		ApplyMove(Movement);
		if (Player.Mesh.CanRequestOverrideFeature())
		{
			Player.Mesh.RequestOverrideFeature(AnimationTag, Movement.GetMovementInstigator());
		}
	}

	protected void ApplyImpacts() override
	{
		Super::ApplyImpacts();

		UpdateMovementImpactCallbacks(AccumulatedImpacts.GetGroundImpacts(), CurrentGroundImpactCallbackComponents, EMovementImpactType::Ground);
		UpdateMovementImpactCallbacks(AccumulatedImpacts.GetWallImpacts(), CurrentWallImpactCallbackComponents, EMovementImpactType::Wall);
		UpdateMovementImpactCallbacks(AccumulatedImpacts.GetCeilingImpacts(), CurrentCeilingImpactCallbackComponents, EMovementImpactType::Ceiling);
	}

	private void UpdateMovementImpactCallbacks(const TArray<FHitResult>& Impacts, TArray<UMovementImpactCallbackComponent>& CurrentImpactCallbackComponents, EMovementImpactType ImpactType)
	{
		// We only update callbacks of one type at a time, and don't allow getting here from a callback
		if(!ensure(IsBroadcastingImpactCallbacks == EMovementImpactType::Unset))
			return;

		IsBroadcastingImpactCallbacks = ImpactType;
		BroadcastImpactStartCallbacks(Impacts, CurrentImpactCallbackComponents, ImpactType);
		BroadcastImpactEndCallbacks(Impacts, CurrentImpactCallbackComponents, ImpactType);
		IsBroadcastingImpactCallbacks = EMovementImpactType::Unset;
	}

	private void BroadcastImpactStartCallbacks(const TArray<FHitResult>& Impacts, TArray<UMovementImpactCallbackComponent>& CurrentImpactCallbackComponents, EMovementImpactType ImpactType) const
	{
		/**
		 * If we had an impact with a component, call ImpactFromPlayer on it
		 * We only want to broadcast the first valid hit, not all of the hits
		 * NOTE: The callbacks can cause the player to get killed, which will cause the impacts array to be
		 * reset, which prevents us from using an iterator here.
		 */

		for(int i = 0; i < Impacts.Num(); i++)
		{
			const FHitResult Impact = Impacts[i];

			if(!IsValid(Impact.Actor))
				continue;

			auto ImpactCallbackComp = UMovementImpactCallbackComponent::Get(Impact.Actor);
			if(ImpactCallbackComp == nullptr)
				continue;

			if(CurrentImpactCallbackComponents.Contains(ImpactCallbackComp))
				continue;	// This is a current impact, we can't call ImpactStart on it again
			
			// Try broadcasting the impact to the callback component
			const bool bImpactWasValid = ImpactCallbackComp.IsValidImpact(Impact);

			// Impacts can fail if internal validation fails
			if(!bImpactWasValid)
				continue;

			// Store this callback so that we can end the impact later
			CurrentImpactCallbackComponents.Add(ImpactCallbackComp);

			// Call ImpactFromPlayer after storing the callback component, since some responses may call OnReset on the movement component, such as killing the player
			ImpactCallbackComp.ImpactFromPlayer(Player, ImpactType, Impact);
		}
	}

	private void BroadcastImpactEndCallbacks(const TArray<FHitResult>& Impacts, TArray<UMovementImpactCallbackComponent>& CurrentImpactCallbackComponents, EMovementImpactType ImpactType) const
	{
		if(Impacts.IsEmpty())
		{
			if(!CurrentImpactCallbackComponents.IsEmpty())
			{

				// No valid impacts at all, meaning that all current impact callbacks are invalid
				for(auto CallbackComp : CurrentImpactCallbackComponents)
				{
					if (CallbackComp != nullptr)
						CallbackComp.ClearImpactFromPlayer(Player, ImpactType);
				}

				CurrentImpactCallbackComponents.Reset();
			}
			return;
		}

		bool bFinalIsValidImpact = false;
		if(!Impacts.IsEmpty())
		{
			const FHitResult FinalImpact = CurrentContacts.GetContact(ImpactType).ConvertToHitResult();
			if(FinalImpact.IsValidBlockingHit())
			{
				const auto FinalCallbackComp = UMovementImpactCallbackComponent::Get(FinalImpact.Actor);
				if(FinalCallbackComp != nullptr)
					bFinalIsValidImpact = FinalCallbackComp.IsValidImpact(FinalImpact);
			}
		}

		if(!bFinalIsValidImpact)
		{
			if(!CurrentImpactCallbackComponents.IsEmpty())
			{
				// If the final impact was no impact, then all current callbacks are invalid
				for(auto CallbackComp : CurrentImpactCallbackComponents)
					CallbackComp.ClearImpactFromPlayer(Player, ImpactType);

				CurrentImpactCallbackComponents.Reset();
			}
		}
		else
		{
			/**
			* The last impact was valid, which means that some impacts might still be valid
			* We then need to go through and find exactly which callback components are still impacted
			* 
			* NOTE: This could be optimized by combining with the results from BroadcastImpactStartCallbacks to only
			* iterate through the impacts once. However, I prioritized readable code here and felt that splitting
			* the function in two was more readable and less coupled. And in reality, there are quite few impacts (mostly 1-3)
			* so the performance cost should be very negligible.
			*/

			// Find the impact callback components we impacted last move
			TSet<UMovementImpactCallbackComponent> NewImpactCallbackComponents;
			for(const FHitResult& Impact : Impacts)
			{
				UMovementImpactCallbackComponent ImpactCallbackComp = UMovementImpactCallbackComponent::Get(Impact.Actor);
				if(ImpactCallbackComp == nullptr)
					continue;

				NewImpactCallbackComponents.Add(ImpactCallbackComp);
			}
			
			// Remove any callbacks that we are no longer impacting
			for(int i = CurrentImpactCallbackComponents.Num() - 1; i >= 0; i--)
			{
				UMovementImpactCallbackComponent CurrentCallbackComp = CurrentImpactCallbackComponents[i];

				const bool bWasImpactedThisFrame = NewImpactCallbackComponents.Contains(CurrentCallbackComp);

				// If we were hit this frame, we are still impacting
				if(bWasImpactedThisFrame)
					continue;

				// Clear the callback if it was not impacted this frame
				CurrentCallbackComp.ClearImpactFromPlayer(Player, ImpactType);
				CurrentImpactCallbackComponents.RemoveAtSwap(i);
			}
		}
	}

	/**
	 * Zero input: returns the 'InHorizontalVelocity'
	 * Input aligned with the 'InHorizontalVelocity': returns Input * the biggest value between 'InHorizontalVelocity' and 'TargetSpeed'
	 * Input opposite 'InHorizontalVelocity': returns Input * 'TargetSpeed'
	 * InterpSpeed: controls how fast the redirected velocity is changing
	 */
    FVector GetInputAdjustedHorizontalVelocity(FVector InHorizontalVelocity, 
		float TargetSpeed, 
		float InterpConstantSpeed, 
		float DeltaTime, 
		FVector MoveInputOverride = FVector::ZeroVector,
		float OverspeedDrag = 0.0
	) const
    {    
		FVector MoveInput = MoveInputOverride.IsNearlyZero() ? MovementInput : MoveInputOverride;

		// Zero input always gives the velocity
	    if (MoveInput.IsNearlyZero())
		{
			float VelocitySize = InHorizontalVelocity.Size();
			if (VelocitySize > TargetSpeed)
				VelocitySize = Math::Max(TargetSpeed, VelocitySize - (OverspeedDrag * DeltaTime));

			return InHorizontalVelocity.GetSafeNormal() * VelocitySize;
		}

		// Zero velocity returns the the input
		if (InHorizontalVelocity.IsNearlyZero())
		{
			return Math::VInterpConstantTo(
				InHorizontalVelocity,
				MoveInput.GetSafeNormal() * TargetSpeed,
				DeltaTime, InterpConstantSpeed);
		}

		const float Alignment = MoveInput.VectorPlaneProject(WorldUp).GetSafeNormal().DotProductNormalized(InHorizontalVelocity.VectorPlaneProject(WorldUp).GetSafeNormal());
		const FVector WorstInputVelocity = MoveInput * TargetSpeed;
		const FVector BestInputVelocity = MoveInput * Math::Max(TargetSpeed, InHorizontalVelocity.Size() - (OverspeedDrag * DeltaTime));

		FVector TargetVelocity = Math::Lerp(WorstInputVelocity, BestInputVelocity, Alignment);
		FVector NewForward = Math::VInterpConstantTo(InHorizontalVelocity, TargetVelocity, DeltaTime, InterpConstantSpeed); 

		return NewForward;
    }

	FVector GetTotalHorizontalVelocity(FVector InHorizontalVelocity, FVector InVerticalVelocity) const
	{
		FVector OutHorizontalVelocity = InHorizontalVelocity;
		OutHorizontalVelocity += InVerticalVelocity.VectorPlaneProject(WorldUp);

		return OutHorizontalVelocity;
	}

	// Returns the current input type that should be used by the input capabilities
	EPlayerMovementInputCapabilityType GetWantedMovementInputCapabilityType() const property
	{
		return MovementCapabilityType.Get();
	}

	// returns a rotation based on the current horizontal velocity.
	// if we don't have a velocity, the actors current rotation is returned
	UFUNCTION()
	FRotator GetRotationBasedOnVelocity(FVector InVel = FVector::ZeroVector)
	{
		// If no argument was passed, use horizontal velocity on the component. Otherwise use whatever Velocity was passed
		FVector HorVel = HorizontalVelocity.VectorPlaneProject(GetWorldUp()).GetSafeNormal();
		if(InVel != FVector::ZeroVector)
			HorVel = InVel;
			
		if(HorVel.IsNearlyZero())
			return Owner.GetActorRotation();
		else 
			return HorVel.Rotation();
	}

	float GetCollisionCapsuleRadius() const
	{
		return GetCollisionShape().Shape.CapsuleRadius;
	}

	float GetCollisionCapsuleHalfHeight() const
	{
		return GetCollisionShape().Shape.CapsuleHalfHeight;
	}

	protected void UpdateActorTransformFromFollowMovement(FTransform NewActorTransform, bool bFromRefFrame) override
	{
		FollowMovementData.UpdateActorTransformFromFollowMovement(NewActorTransform, bFromRefFrame);
		Super::UpdateActorTransformFromFollowMovement(NewActorTransform, bFromRefFrame);
	}

	void HandlePlayerMoveInto(FVector Delta, USceneComponent MovedByComponent, bool bImpartVelocityOnPushedPlayer, FString DebugMoveCategory, bool bCrumbSyncRelativeToShape = true)
	{
		FScopeCycleCounter CycleCounter(STAT_PlayerMovementComponent_HandlePlayerMoveInto);

		// Store the state within a GuardValue-esque struct
		// This ensures that the state is reset when we leave this scope, stopping us from interfering with other movement
		FHazeMovementComponentStatusGuardValue GuardValue;
		GuardValue.StoreMovementComponentState(this);

        if(Delta.IsNearlyZero())
			return;

		if (!MoveIntoPlayerMovementData.PrepareMoveIntoPlayer(this, MovedByComponent, DebugMoveCategory))
			return;

        MoveIntoPlayerMovementData.AddDelta(Delta);

		SetResolvingStatus(MovedByComponent, false);

		auto Resolver = Cast<UMoveIntoPlayerMovementResolver>(GetLinkedResolver(MoveIntoPlayerMovementData));
		Resolver.PrepareResolver(MoveIntoPlayerMovementData);

		FVector OutLocation = Owner.ActorLocation;
		FVector OutVelocity = FVector::ZeroVector;
		USceneComponent OutRelativeToComponent = nullptr;
		Resolver.ResolveMoveInto(OutLocation, OutVelocity, OutRelativeToComponent);

		#if EDITOR
		FTemporalLog TemporalLog = GetTemporalLog();

		// Clear the prepare frame since it has been applied
		MoveIntoPlayerMovementData.DebugPreparedFrame = 0;
		TemporalLog.Value(f"MoveIntoPlayer;{Resolver.DebugMoveCategory};Delta", Delta);
		#endif

		SetMovingStatus(true, this);
		
		if(!OutVelocity.IsNearlyZero())
		{
			const FVector PushedDirection = Delta.GetSafeNormal();

			if(!bImpartVelocityOnPushedPlayer)
				OutVelocity = FVector::ZeroVector;

			// Keep all velocity not going in the pushed direction

			FVector OriginalHorizontalVelocity = HorizontalVelocity;
			if(OriginalHorizontalVelocity.DotProduct(PushedDirection) < 0)
				OriginalHorizontalVelocity = OriginalHorizontalVelocity.VectorPlaneProject(PushedDirection);

			FVector OriginalVerticalVelocity = VerticalVelocity;
			if(OriginalVerticalVelocity.DotProduct(PushedDirection) < 0)
				OriginalVerticalVelocity = OriginalVerticalVelocity.VectorPlaneProject(PushedDirection);

			FVector InheritedHorizontalVelocity = OutVelocity.VectorPlaneProject(WorldUp);
			FVector InheritedVerticalVelocity = OutVelocity.ProjectOnToNormal(WorldUp);

			SetVelocityInternal(
				OriginalHorizontalVelocity + InheritedHorizontalVelocity,
				OriginalVerticalVelocity + InheritedVerticalVelocity
			);
		}

		FinalizeMoveInternal(OutLocation, MovedByComponent);
		
		SetMovementPerformedStatus(this);

		if(Resolver.AccumulatedImpacts.HasImpactedAnything())
		{
			for(FMovementHitResult Impact : Resolver.AccumulatedImpacts.GetAllImpacts())
				AccumulatedImpacts.AddImpact(Impact);
			
			ApplyImpacts();
		}

		if (bCrumbSyncRelativeToShape)
			CurrentMoveIntoPlayerRelativeInstigator.Apply(this, OutRelativeToComponent);
	}

	void HandlePlayerMoveIntoRotating(UMoveIntoPlayerShapeComponent MoveIntoPlayerComp, bool bImpartVelocityOnPushedPlayer, FVector Delta, FVector ExtrapolatedDelta, bool bCrumbSyncRelativeToShape = true)
	{
		FScopeCycleCounter CycleCounter(STAT_PlayerMovementComponent_HandlePlayerMoveIntoRotating);

		// Store the state within a GuardValue-esque struct
		// This ensures that the state is reset when we leave this scope, stopping us from interfering with other movement
		FHazeMovementComponentStatusGuardValue GuardValue;
		GuardValue.StoreMovementComponentState(this);

		if (!MoveIntoPlayerRotatingMovementData.PrepareMoveIntoPlayer(this, MoveIntoPlayerComp))
			return;

		MoveIntoPlayerRotatingMovementData.FollowDelta = Delta;
		MoveIntoPlayerRotatingMovementData.ExtrapolatedDelta = ExtrapolatedDelta;

		SetResolvingStatus(MoveIntoPlayerComp, false);

		auto Resolver = Cast<UMoveIntoPlayerRotatingMovementResolver>(GetLinkedResolver(MoveIntoPlayerRotatingMovementData));
		Resolver.PrepareResolver(MoveIntoPlayerRotatingMovementData);

		FVector OutLocation = Owner.ActorLocation;
		FVector OutVelocity = Owner.ActorVelocity;
		USceneComponent OutRelativeToComponent = MoveIntoPlayerComp;
		Resolver.ResolveMoveInto(OutLocation, OutVelocity, OutRelativeToComponent);

		#if EDITOR
		// Clear the prepare frame since it has been applied
		MoveIntoPlayerRotatingMovementData.DebugPreparedFrame = 0;
		#endif

		SetMovingStatus(true, this);

		if(!OutVelocity.IsNearlyZero())
		{
			const FVector PushedDirection = Delta.GetSafeNormal();

			if(!bImpartVelocityOnPushedPlayer)
				OutVelocity = FVector::ZeroVector;

			// Keep all velocity not going in the pushed direction

			FVector OriginalHorizontalVelocity = HorizontalVelocity;
			if(OriginalHorizontalVelocity.DotProduct(PushedDirection) < 0)
				OriginalHorizontalVelocity = OriginalHorizontalVelocity.VectorPlaneProject(PushedDirection);

			FVector OriginalVerticalVelocity = VerticalVelocity;
			if(OriginalVerticalVelocity.DotProduct(PushedDirection) < 0)
				OriginalVerticalVelocity = OriginalVerticalVelocity.VectorPlaneProject(PushedDirection);

			FVector InheritedHorizontalVelocity = OutVelocity.VectorPlaneProject(WorldUp);
			FVector InheritedVerticalVelocity = OutVelocity.ProjectOnToNormal(WorldUp);

			SetVelocityInternal(
				OriginalHorizontalVelocity + InheritedHorizontalVelocity,
				OriginalVerticalVelocity + InheritedVerticalVelocity
			);
		}

		FinalizeMoveInternal(OutLocation, MoveIntoPlayerComp);

		SetMovementPerformedStatus(this);

		if(Resolver.AccumulatedImpacts.HasImpactedAnything())
		{
			for(FMovementHitResult Impact : Resolver.AccumulatedImpacts.GetAllImpacts())
				AccumulatedImpacts.AddImpact(Impact);
			
			ApplyImpacts();
		}

		if (bCrumbSyncRelativeToShape)
			CurrentMoveIntoPlayerRelativeInstigator.Apply(this, OutRelativeToComponent);
	}
}
