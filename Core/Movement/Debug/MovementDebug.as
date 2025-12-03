#if EDITOR
void MovementCheck(bool bCondition)
{
	if(UMovementDebugConfig::Get().bEnableRerun)
		check(bCondition);
}

void MovementCheck(bool bCondition, FString Message)
{
	if(UMovementDebugConfig::Get().bEnableRerun)
		check(bCondition, Message);
}

void MovementDevCheck(bool bCondition)
{
	if(UMovementDebugConfig::Get().bEnableRerun)
		devCheck(bCondition);
}

void MovementDevCheck(bool bCondition, FString Message)
{
	if(UMovementDebugConfig::Get().bEnableRerun)
		devCheck(bCondition, Message);
}
#endif

bool MovementEnsure(bool bCondition)
{
#if EDITOR
	if(UMovementDebugConfig::Get().bEnableRerun)
		return ensure(bCondition);
#endif

	return bCondition;
}

bool MovementEnsure(bool bCondition, FString Message)
{
#if EDITOR
	if(UMovementDebugConfig::Get().bEnableRerun)
		return ensure(bCondition, Message);
#endif

	return bCondition;
}

bool MovementDevEnsure(bool bCondition)
{
#if EDITOR
	if(UMovementDebugConfig::Get().bEnableRerun)
		return devEnsure(bCondition);
#endif

	return bCondition;
}

bool MovementDevEnsure(bool bCondition, FString Message)
{
#if EDITOR
	if(UMovementDebugConfig::Get().bEnableRerun)
		return devEnsure(bCondition, Message);
#endif

	return bCondition;
}

#if !RELEASE
namespace MovementDebug
{
	const FString CategoryInfo = "10#Info";
	const FString CategoryCustom = "20#Custom Info";
	const FString CategoryFalling = "25#Falling";
	const FString CategoryInput = "26#Input";
	const FString CategoryAlign = "30#Align";

	const FString CategoryPendingImpulses = "42#Pending Impulses";
	const FString CategoryRequestLocal = "50#Local Request";
	const FString CategoryRequestWorld = "51#World Request";
	const FString CategoryFinalLocal = "52#Local Final";
	const FString CategoryFinalWorld = "53#World Final";

	const FString CategoryRequestDeltas = "70#Request Delta States";
	const FString CategoryFinalDeltas = "71#Final Delta States";
	const FString CategoryDirections = "72#Orientation Direction";

	const FString CategoryTrace = "90#Trace";

	const FString CategoryMisc = "100#Misc";
	
	float RoundFloat(float Value)
	{
		return Math::RoundToFloat(Value * 1000.0) / 1000.0;
	}

	FVector RoundVector(FVector Value)
	{
		return FVector(RoundFloat(Value.X), RoundFloat(Value.Y), RoundFloat(Value.Z));
	}

	FString ImpactToString(FHitResult Value)
	{
		FString Out = "";
		if(!Value.bBlockingHit)
		{
			Out = "None";
		}
		else
		{
			if(Value.Actor == nullptr)
			{
				Out += "Actor " + "BSP?";
			}
			else
			{
				Out += "Actor " + Value.Actor.GetActorNameOrLabel();
			}
		}
		return Out;
	}

	void AddInitialDebugInfo(
		const UHazeMovementComponent MovementComponent, 
		const UBaseMovementData MovementData, 
		const UBaseMovementResolver Resolver
	)
	{
		if(!ensure(!MovementComponent.IsApplyingInParallel(), "AddInitialDebugInfo called on a resolver running in parallel, debug information is not allowed to be used while resolving in parallel!"))
			return;

		// Prepare the temporal logger
		FTemporalLog TemporalLog = MovementComponent.GetTemporalLog();

		TemporalLog
		.Value("Resolver", Resolver.Class)
		.Value("Instigator", MovementData.DebugMoveInstigatorClass)
		.Value("Has Movement Control", MovementComponent.HasMovementControl())
		;

		// Log ignored
		LogIgnoredPage(MovementComponent, MovementData);
	}

	void AddMovementResolvedState(
		const UHazeMovementComponent MovementComponent, 
		const UBaseMovementData MovementData, 
		const UBaseMovementResolver Resolver,
		FMovementResolverState IterationState, 
		float IterationTime)
	{
		AddMovementResolvedData(MovementComponent, MovementData, Resolver,
			IterationState.PerformedMoveAmount,
			IterationState.CurrentLocation, 
			IterationState.CurrentRotation.Rotator(), 
			IterationState.WorldUp, 
			IterationState.DeltaStates, 
			IterationState.PhysicsState,
			IterationTime);
	}

	const FStatID STAT_MovementResolverTemporalLog(n"MovementResolverTemporalLog");

	void AddMovementResolvedData(
		const UHazeMovementComponent MovementComponent, 
		const UBaseMovementData MovementData, 
		const UBaseMovementResolver Resolver,
		float FinalMovedAmount,
		FVector FinalLocation,
		FRotator FinalRotation,
		FVector FinalWorldUp,
		TMap<EMovementIterationDeltaStateType, FMovementDeltaWithWorldUp> FinalDeltaStates,
		FMovementContacts FinalPhysicsState, 
		float IterationTime)
	{
		if(MovementComponent.IsApplyingInParallel())
			return;

		FScopeCycleCounter ScopeCounter(STAT_MovementResolverTemporalLog);

		FTemporalLog TemporalLog = MovementComponent.GetTemporalLog();
		FTemporalLog TemporalLogState = TemporalLog.Page("State");

	 	auto SteppingData = Cast<USteppingMovementData>(MovementData);
	 	auto SweepingData = Cast<USweepingMovementData>(MovementData);
	 	auto FloatingData = Cast<UFloatingMovementData>(MovementData);

	 	const FVector StartLocation = MovementData.OriginalActorTransform.Location;
	 	const FRotator StartRotation = MovementData.OriginalActorTransform.Rotator();
	 	const FVector StartWorldUp = MovementData.WorldUp;

	 	const FCollisionShape Shape = MovementComponent.GetCollisionShape().Shape;
		
		const FVector FinalShapeLocation = MovementComponent.ShapeComponent.WorldLocation;
		const FVector StartShapeLocation = MovementData.OriginalShapeTransform.Location;
		const FRotator FinalShapeRotation = MovementComponent.ShapeComponent.WorldRotation;
		const FRotator StartShapeRotation = MovementData.OriginalShapeTransform.Rotator();
		const FVector ShapeOffset = FinalShapeLocation - FinalLocation;

		const float DebugArrowSizeLarge = Shape.GetExtent().Size() * 3;
		const float DebugArrowSizeMedium = Shape.GetExtent().Size() * 2.5;
		const float DebugArrowSizeSmall = Shape.GetExtent().Size() * 2;

		// TArray<FDebugHitResultContainer> IterationTraces = Resolver.IterationTraceSettings.GetDebugHitResults();
		// int NumLineTraces = 0;
		// int NumShapeTraces = 0;

		// for(auto Trace : IterationTraces)
		// {
		// 	if(Trace.Shape.IsLine())
		// 		NumLineTraces++;
		// 	else
		// 		NumShapeTraces++;
		// }

		TemporalLog
		// .Value(f"{CategoryInfo};Traces", IterationTraces.Num())
		// .Value(f"{CategoryInfo};Line Traces", NumLineTraces)
		// .Value(f"{CategoryInfo};Shape Traces", NumShapeTraces)
		.Value(f"{CategoryInfo};Redirect Iterations", Resolver.IterationCount)
		//.Value(f"{CategoryInfo};Stepdown Iterations", Resolver.IterationGroundTraceCount)
		//.Value(f"{CategoryInfo};Depenetration Iterations", Resolver.IterationDepenetrationCount)
		.Value(f"{CategoryInfo};Iterations Time", IterationTime)
		.Value(f"{CategoryInfo};Walkable Slope Angle", Math::Abs(MovementData.WalkableSlopeAngle))
		.Value(f"{CategoryInfo};Ceiling Angle", Math::Abs(MovementData.CeilingAngle))
		.Value(f"{CategoryInput};Input", RoundVector(StartRotation.UnrotateVector(MovementComponent.GetMovementInput())))
		.DirectionalArrow(f"{CategoryInput};Direction", FinalShapeLocation, MovementComponent.GetMovementInput() * DebugArrowSizeLarge, Color = FLinearColor::Black)
		;

		if(!MovementComponent.HasMovementControl())
		{
			TemporalLog
			.Value(f"{CategoryInput};Synced Input", RoundVector(StartRotation.UnrotateVector(MovementComponent.GetSyncedMovementInputForAnimationOnly())))
			.DirectionalArrow(f"{CategoryInput};Synced Direction", FinalShapeLocation, MovementComponent.GetSyncedMovementInputForAnimationOnly() * DebugArrowSizeLarge, Color = FLinearColor::Black)
			;
		}

		MovementComponent.AddComponentSpecificDebugInfo(TemporalLog);

		// Remote
		if(!MovementComponent.HasMovementControl())
		{
			TemporalLog
			.Value(f"{CategoryInfo};Should Sync Location", MovementData.bHasSyncedLocationInfo)
			.Value(f"{CategoryInfo};Should Sync Rotation", MovementData.bHasSyncedRotationInfo)
			;
		}

		// Log falling
		{
			auto FallingSection = TemporalLog.Section("Falling", SortOrder = 25);
			FallingSection.Value(f"Was falling", MovementComponent.FallingData.bWasFalling);
			FallingSection.Value(f"Is falling", MovementComponent.FallingData.bIsFalling);
			FallingSection.Value(f"End World Velocity", RoundVector(MovementComponent.FallingData.EndVelocity));
		}

		LogFollowPage(MovementComponent, StartShapeLocation);

		// Log world up alignment
		{
			TOptional<FMovementAlignWithImpactSettings> AlignWithImpactSettings;	
			if(SteppingData != nullptr)
			{
				AlignWithImpactSettings = SteppingData.AlignWithImpactSettings;
			}
			else if(SweepingData != nullptr)
			{
				AlignWithImpactSettings = SweepingData.AlignWithImpactSettings;
			}
			else if(FloatingData != nullptr)
			{
				AlignWithImpactSettings = FloatingData.AlignWithImpactSettings;
			}

			if(AlignWithImpactSettings.IsSet())
			{
				TemporalLog
					.Value(f"{CategoryAlign};Ground", AlignWithImpactSettings.Value.bAlignWithGround)
					.Value(f"{CategoryAlign};Wall", AlignWithImpactSettings.Value.bAlignWithWall)
					.Value(f"{CategoryAlign};Ceiling", AlignWithImpactSettings.Value.bAlignWithCeiling)
				;
			}
			else
			{
				TemporalLog
					.Value(f"{CategoryAlign};Unsupported by type", MovementData.Class)
				;
			}
		}

		EMovementEdgeHandlingType EdgeHandling = EMovementEdgeHandlingType::None;
		EMovementEdgeNormalRedirectType EdgeRedirect = EMovementEdgeNormalRedirectType::None;

		// Log custom settings
		{
			if(SteppingData != nullptr)
			{
				EdgeHandling = SteppingData.EdgeHandling;
				EdgeRedirect = SteppingData.EdgeRedirectType;

				auto SteppingResolver = Cast<USteppingMovementResolver>(Resolver);
				if(SteppingResolver != nullptr)
				{
					TemporalLog.Value(f"{CategoryCustom};Vertical Direction", SteppingResolver.VerticalDirection);
					TemporalLog.Value(f"{CategoryInfo};SubStep", SteppingResolver.bPerformSubStep);
					if(SteppingResolver.bPerformSubStep)
						TemporalLog.Value(f"{CategoryInfo};SubStep Reason", SteppingResolver.PerformSubStepReason);

					TemporalLog.Value(f"{CategoryCustom};Bottom Of Capsule Mode", SteppingData.BottomOfCapsuleMode);
					TemporalLog.Value(f"{CategoryCustom};bOnlyFlatBottomOfCapsuleIfLeavingEdge", SteppingData.bOnlyFlatBottomOfCapsuleIfLeavingEdge);
					TemporalLog.Value(f"{CategoryCustom};MaxEdgeDistanceUntilUnstable", SteppingData.MaxEdgeDistanceUntilUnstable);
					TemporalLog.Circle(f"{CategoryCustom};MaxEdgeDistanceUntilUnstable Circle", FinalLocation, SteppingData.MaxEdgeDistanceUntilUnstable, FinalRotation);
				}

				const float StepUp = SteppingData.StepUpSize;
				const float StepDown = FinalPhysicsState.GroundContact.IsAnyGroundContact() ? SteppingData.StepDownOnGroundSize : SteppingData.StepDownInAirSize;

				// Log Stepping
				if(StepUp >= 0)
				{
					TemporalLog
					.Value(f"{CategoryCustom};StepUp Size", StepUp)
					.Plane(
						f"{CategoryCustom};Step Up Plane",
						FinalLocation + (FinalWorldUp * StepUp),
						FinalWorldUp,
						SteppingData.ShapeSizeForMovement,
						3,
						3,
						FLinearColor(0.0, 1.0, 0.0)
					);
				}

				if(StepDown >= 0)
				{
					TemporalLog
					.Value(f"{CategoryCustom};StepDown Size", StepDown)
					.Plane(
						f"{CategoryCustom};Step Down Plane",
						FinalLocation - (FinalWorldUp * StepDown),
						FinalWorldUp,
						SteppingData.ShapeSizeForMovement,
						3,
						3,
						FLinearColor(1.0, 0.0, 0.0))
					;
				}
			}
			else if(SweepingData != nullptr)
			{
				EdgeHandling = SweepingData.EdgeHandling;
				EdgeRedirect = SweepingData.EdgeRedirectType;

				TemporalLog
				.Value(f"{CategoryCustom};CanPerformGroundTrace", SweepingData.bCanPerformGroundTrace)
				.Value(f"{CategoryCustom};Bonus Grounded Trace Distance While Grounded", SweepingData.BonusGroundedTraceDistanceWhileGrounded)
				.Value(f"{CategoryCustom};Redirect on Ground", SweepingData.bRedirectMovementOnGroundImpacts)
				.Value(f"{CategoryCustom};Redirect on Wall", SweepingData.bRedirectMovementOnWallImpacts)
				.Value(f"{CategoryCustom};Redirect on Ceiling", SweepingData.bRedirectMovementOnCeilingImpacts)
				;

				auto SweepingResolver = Cast<USweepingMovementResolver>(Resolver);
				if(SweepingResolver != nullptr)
				{
					//TemporalLog.Value(f"{CategoryCustom};Vertical Direction", SweepingResolver.VerticalDirection);

					TemporalLog.Value(f"{CategoryInfo};SubStep", SweepingResolver.bPerformSubStep);
					if(SweepingResolver.bPerformSubStep)
						TemporalLog.Value(f"{CategoryInfo};SubStep Reason", SweepingResolver.PerformSubStepReason);
				}
			}
		}


	 	// Log request
	 	{
	 		const FMovementIterationDeltaStates RequestedTotalStates = MovementData.GetDebugDeltaStates();
	 		const FMovementDelta RequestedTotalMovementDelta = RequestedTotalStates.GetDelta();

	 		const FVector RequestedTotalDelta = RequestedTotalMovementDelta.Delta;
	 		const FVector RequestedTotalVelocity = RequestedTotalMovementDelta.Velocity;

			// Pending impulses
			{
				TemporalLogState.Value(f"{CategoryPendingImpulses};Impulses Count", MovementComponent.Impulses.Num());
				for(int i = 0; i < MovementComponent.Impulses.Num(); i++)
				{
					const FMovementImpulse Impulse = MovementComponent.Impulses[i];
					const FString Category = FString(f"{CategoryPendingImpulses};{i + 1} - {Impulse.Instigator}");
					TemporalLogState.DirectionalArrow(f"{Category};Impulse", StartLocation, Impulse.Impulse);
					TemporalLogState.Value(f"{Category};Impulse Added Frame", Impulse.AddedFrame);
					TemporalLogState.Value(f"{Category};Added After Movement", Impulse.bDebugOnlyMovementPerformedWhenAdded);
					TemporalLogState.Value(f"{Category};Is Old", Impulse.AddedFrame < Time::GetFrameNumber() - 1);
				}
			}

	 		// Log request
	 		{
				TemporalLogState
				.Value(f"{CategoryRequestLocal};Horizontal Speed", RoundFloat(RequestedTotalDelta.VectorPlaneProject(StartWorldUp).Size() / IterationTime))
				.Value(f"{CategoryRequestLocal};Vertical Speed", RoundFloat(RequestedTotalDelta.ProjectOnToNormal(StartWorldUp).Size() / IterationTime))
				.Value(f"{CategoryRequestLocal};Terminal Velocity", MovementData.TerminalVelocity)
				.Value(f"{CategoryRequestLocal};Delta", RoundVector(StartRotation.UnrotateVector(RequestedTotalDelta)))
				.Value(f"{CategoryRequestLocal};Velocity", RoundVector(StartRotation.UnrotateVector(RequestedTotalVelocity)))
				.Value(f"{CategoryRequestLocal};Horizontal Delta", RoundVector(StartRotation.UnrotateVector(RequestedTotalDelta.VectorPlaneProject(StartWorldUp))))
				.Value(f"{CategoryRequestLocal};Horizontal Velocity", RoundVector(StartRotation.UnrotateVector(RequestedTotalVelocity.VectorPlaneProject(StartWorldUp))))
				.Value(f"{CategoryRequestLocal};Vertical Delta", RoundVector(StartRotation.UnrotateVector(RequestedTotalDelta.ProjectOnToNormal(StartWorldUp))))
				.Value(f"{CategoryRequestLocal};Vertical Velocity", RoundVector(StartRotation.UnrotateVector(RequestedTotalVelocity.ProjectOnToNormal(StartWorldUp))))
	 		;	
			}

			// World Request
			{
				
				TemporalLogState

				.DirectionalArrow(
					f"{CategoryRequestWorld};Delta",
					StartLocation,
					RequestedTotalDelta,
					Color = FLinearColor::Black + FLinearColor(0.25, 0, 0)
				)

				.DirectionalArrow(
					f"{CategoryRequestWorld};Velocity",
					StartShapeLocation,
					RequestedTotalVelocity,
					Color = FLinearColor::Black + FLinearColor(0, 0.25, 0)
				)

				.DirectionalArrow(
					f"{CategoryRequestWorld};Delta Direction",
					StartShapeLocation,
					(RequestedTotalDelta.GetSafeNormal() * DebugArrowSizeLarge),
					Color = FLinearColor::Black + FLinearColor(0, 0, 0.25)
				)

				.DirectionalArrow(
					f"{CategoryRequestWorld};Facing Direction",
					FinalShapeLocation,
					MovementData.TargetRotation.ForwardVector * DebugArrowSizeLarge,
					Color = FLinearColor::Black + FLinearColor(0.25, 0, 0.25)
				)
				;
			}

	 		// Draw all the requested deltas
			int DeltaTypeIndex = 0;
	 		for(auto State : RequestedTotalStates.States)
	 		{
				DeltaTypeIndex++;
				EMovementIterationDeltaStateType DeltaType = State.Key;
				FLinearColor Color = GetDeltaTypeColor(DeltaType);

				const FVector StateDelta = State.Value.Delta;
				const FVector StateVelocity = State.Value.Velocity;

				const FString Category = FString(f"{CategoryRequestDeltas};{DeltaTypeIndex} - {DeltaType:n};");
				TemporalLogState
				
				.DirectionalArrow(
					Category + "Delta",
					StartLocation,
					StateDelta,
					Color = Color
				)

				.DirectionalArrow(
					Category + "Velocity",
					StartShapeLocation,
					StateVelocity,
					Color = Color - FLinearColor(0.25, 0, 0)
				)

				.DirectionalArrow(
					Category + "Direction",
					StartShapeLocation,
					StateDelta.GetSafeNormal() * DebugArrowSizeLarge,
					Color = Color - FLinearColor(0, 0, 0.25)
				)
				;
			}		
	 	}


		// Contacts
		LogContactsPage(MovementComponent);

		// Gravity
		LogGravityPage(MovementComponent);

		// Status
		{
			FString GroundState = "";
			FCustomMovementStatus CustomStatus = MovementComponent.GetCustomMovementStatusDebugInformation();
			if(CustomStatus.Name != NAME_None)
			{
				GroundState = "<Custom> " + CustomStatus.Name.ToString();
				TemporalLog.Status(GroundState, CustomStatus.DebugColor);
			}
			else if(MovementComponent.IsOnWalkableGround())
			{
				GroundState = "Walkable Ground";
				TemporalLog.Status(GroundState, FLinearColor::Green);
				
				if(MovementComponent.NewStateIsOnWalkableGround())
					TemporalLog.Event("Became grounded");
			}
			else if(MovementComponent.IsOnSlidingGround())
			{
				GroundState = "Unwalkable Ground";
				TemporalLog.Status(GroundState, FLinearColor::Red);

				if(MovementComponent.NewStateIsOnWalkableGround())
					TemporalLog.Event("Became sliding");
			}
			else
			{
				GroundState = "Airborne";
				TemporalLog.Status(GroundState, FLinearColor::Blue);

				if(MovementComponent.NewStateIsInAir())
					TemporalLog.Event("Became airborne");
			}
		}

		// Ground
		{
			const float UnstableEdgeDistance = SteppingData != nullptr ? SteppingData.MaxEdgeDistanceUntilUnstable : -1;
			LogGroundPage(MovementComponent, UnstableEdgeDistance, ShapeOffset, DebugArrowSizeLarge, DebugArrowSizeMedium, DebugArrowSizeSmall, EdgeHandling, EdgeRedirect);
		}

		// Log final values
		{
		 	const FVector FinalTotalDelta = FinalLocation - StartLocation;
			const FVector FinalHorizontalVelocity = MovementComponent.HorizontalVelocity;
			const FVector RealHorizontalVelocity = FinalTotalDelta.VectorPlaneProject(FinalWorldUp) / IterationTime;
			const FVector FinalVerticalVelocity = MovementComponent.VerticalVelocity;
			//const FRotator FinalMovementOrientation = FinalTotalDelta.IsNearlyZero() ? FinalRotation : FRotator::MakeFromXZ(FinalTotalDelta, FinalWorldUp);
			const FRotator FinalMovementOrientation = FinalRotation;

			// Log finalized values
			{
				TemporalLog
				.Value(f"{CategoryFinalLocal};Speed", RoundFloat(FinalMovedAmount / IterationTime))
				.Value(f"{CategoryFinalLocal};Delta", RoundVector(FinalMovementOrientation.UnrotateVector(FinalTotalDelta)))
				.Value(f"{CategoryFinalLocal};Horizontal Velocity", RoundVector(FinalMovementOrientation.UnrotateVector(FinalHorizontalVelocity)))
				.Value(f"{CategoryFinalLocal};Real Horizontal Velocity", RoundVector(FinalMovementOrientation.UnrotateVector(RealHorizontalVelocity)))
				.Value(f"{CategoryFinalLocal};Vertical Velocity", RoundVector(FinalMovementOrientation.UnrotateVector(FinalVerticalVelocity)))

				.DirectionalArrow(
					f"{CategoryFinalWorld};Delta",
					StartLocation,
					FinalLocation - StartLocation,
					Color = FLinearColor::Black + FLinearColor(0.25, 0, 0)
				)

				.DirectionalArrow(
					f"{CategoryFinalWorld};Delta Direction",
					FinalShapeLocation,
					FinalTotalDelta.GetSafeNormal() * DebugArrowSizeLarge,
					Color = FLinearColor::Black + FLinearColor(0, 0, 0.25)
				)

				.DirectionalArrow(
					f"{CategoryFinalWorld};Velocity",
					FinalShapeLocation,
					FinalHorizontalVelocity + FinalVerticalVelocity,
					Color = FLinearColor::Black + FLinearColor(0, 0.25, 0)
				)

				.DirectionalArrow(
					f"{CategoryFinalWorld};Horizontal Velocity",
					FinalShapeLocation,
					FinalHorizontalVelocity,
					Color = FLinearColor::Black + FLinearColor(0, 0.25, 0)
				)

				.DirectionalArrow(
					f"{CategoryFinalWorld};Vertical Velocity",
					FinalShapeLocation,
					FinalVerticalVelocity,
					Color = FLinearColor::Black + FLinearColor(0, 0.25, 0)
				)
			;	
			}

			// Draw all the final deltas
			int DeltaTypeIndex = 0;
			for(auto State : FinalDeltaStates)
			{
				DeltaTypeIndex++;
				EMovementIterationDeltaStateType DeltaType = State.Key;
				FLinearColor Color = GetDeltaTypeColor(DeltaType);

				const FVector StateDelta = State.Value.Delta;
				const FVector StateVelocity = State.Value.Velocity;

				TemporalLogState
				
				.DirectionalArrow(
					f"{CategoryFinalDeltas};{DeltaTypeIndex} - {DeltaType:n};Delta",
					StartLocation,
					StateDelta,
					Color = Color
				)

				.DirectionalArrow(
					f"{CategoryFinalDeltas};{DeltaTypeIndex} - {DeltaType:n};Velocity",
					FinalShapeLocation,
					StateVelocity,
					Color = Color - FLinearColor(0.25, 0, 0)
				)

				.DirectionalArrow(
					f"{CategoryFinalDeltas};{DeltaTypeIndex} - {DeltaType:n};Direction",
					FinalShapeLocation,
					StateDelta.GetSafeNormal() * DebugArrowSizeLarge,
					Color = Color - FLinearColor(0, 0, 0.25)
				)
			;
			}
		}

		// Orientation Directions
		{
			TemporalLogState
			
			// Log world up direction
			.DirectionalArrow(f"{CategoryDirections};WorldUp Direction Start",
				FinalLocation,
				StartWorldUp * DebugArrowSizeMedium,
				3.0, 20.0,
				FLinearColor::Red - FLinearColor(0.25, 0.25, 0.25))

			// Log world up direction
			.DirectionalArrow(f"{CategoryDirections};WorldUp Direction Final",
				FinalLocation,
				FinalWorldUp * DebugArrowSizeLarge,
				2.0, 20.0,
				FLinearColor::Red)

			// Draw Start Rotation
			.Rotation(f"{CategoryDirections};Actor Rotation Start",
				StartRotation,
				FinalLocation,
			)

			// Draw Final Rotation
			.Rotation(f"{CategoryDirections};Actor Rotation Final",
				FinalRotation,
				FinalLocation,
			)
			;
		}


		// Log the shape transforms
		{
			LogShapePage(MovementComponent, Resolver);

			TemporalLogState.Point(
				f"{CategoryMisc};Location Start",
				StartLocation,
				20,
				FLinearColor::LucBlue
			);

			TemporalLogState.Point(
				f"{CategoryMisc};Location Final",
				FinalLocation,
				20,
				FLinearColor::Blue
			);


			if(Shape.IsCapsule())
			{
				TemporalLogState.Capsule(
					f"{CategoryMisc};Capsule Start",
					StartShapeLocation,
					Shape.GetCapsuleRadius(),
					Shape.GetCapsuleHalfHeight(),
					StartShapeRotation,
					FLinearColor::LucBlue);

				TemporalLogState.Capsule(
					f"{CategoryMisc};Capsule Final",
					FinalShapeLocation,
					Shape.GetCapsuleRadius(),
					Shape.GetCapsuleHalfHeight(),
					FinalShapeRotation,
					FLinearColor::Blue);

				if(!MovementComponent.HasMovementControl() && MovementData.bHasSyncedLocationInfo)
				{
					TemporalLogState.Capsule(
					f"{CategoryMisc};Capsule Synced",
					MovementData.SyncedActorData.WorldLocation + ShapeOffset,
					Shape.GetCapsuleRadius(),
					Shape.GetCapsuleHalfHeight(),
					FinalShapeRotation,
					FLinearColor::DPink);
				}
			}
			else if(Shape.IsSphere())
			{
				TemporalLogState.Sphere(
					f"{CategoryMisc};Sphere Start",
					StartShapeLocation,
					Shape.GetSphereRadius(),
					FLinearColor::LucBlue);

				TemporalLogState.Sphere(
					f"{CategoryMisc};Sphere Final",
					FinalShapeLocation,
					Shape.GetSphereRadius(),
					FLinearColor::Blue);

				if(!MovementComponent.HasMovementControl() && MovementData.bHasSyncedLocationInfo)
				{
					TemporalLogState.Sphere(
					f"{CategoryMisc};Sphere Synced",
					MovementData.SyncedActorData.WorldLocation + ShapeOffset,
					Shape.GetSphereRadius(),
					FLinearColor::DPink);
				}
			}
			else if(Shape.IsBox())
			{
				TemporalLogState.Box(
					f"{CategoryMisc};Box Start",
					StartShapeLocation,
					Shape.GetExtent(),
					MovementData.OriginalShapeTransform.Rotator(),
					FLinearColor::LucBlue);

				TemporalLogState.Box(
					f"{CategoryMisc};Box Final",
					FinalShapeLocation,
					Shape.GetExtent(),
					FinalShapeRotation,
					FLinearColor::Blue);

				if(!MovementComponent.HasMovementControl() && MovementData.bHasSyncedLocationInfo)
				{
					TemporalLogState.Box(
						f"{CategoryMisc};Box Synced",
						MovementData.SyncedActorData.WorldLocation + ShapeOffset,
						Shape.GetExtent(),
						MovementData.OriginalShapeTransform.Rotator(),
						FLinearColor::DPink);
				}
			}
			else
			{
				// Not implemented
				check(false);
			}
		}

		// Log ignored
		{
			const FTemporalLog IgnoredLog = TemporalLog.Page("Ignored");

			{
				const FTemporalLog ResolverSection = IgnoredLog.Section("Final Ignored on Resolver", 4);
				const FTemporalLog ResolverActorSection = ResolverSection.Section("Actors", 1);
				const FTemporalLog ResolverComponentSection = ResolverSection.Section("Components", 2);
				const TArray<AActor> IgnoredActorsInTraceSettings = Resolver.IterationTraceSettings.GetDebugIgnoredActors();
				ResolverActorSection.Value("Count", IgnoredActorsInTraceSettings.Num());
				for(int i = 0; i < IgnoredActorsInTraceSettings.Num(); i++)
					ResolverActorSection.Value(f"Actor {i + 1}", IgnoredActorsInTraceSettings[i]);

				const TArray<UPrimitiveComponent> IgnoredComponentsInTraceSettings = Resolver.IterationTraceSettings.GetDebugIgnoredPrimitives();
				ResolverComponentSection.Value("Count", IgnoredComponentsInTraceSettings.Num());
				for(int i = 0; i < IgnoredComponentsInTraceSettings.Num(); i++)
					ResolverComponentSection.Value(f"Component {i + 1}", IgnoredComponentsInTraceSettings[i]);
			}
		}

		FTemporalLog TemporalLogExtensions = TemporalLog.Page("Extensions");
		FTemporalLog ActiveExtensionsLog = TemporalLogExtensions.Section("Active Extensions");
		ActiveExtensionsLog.Value("Count", Resolver.Extensions.Num());

		for(int i = 0; i < Resolver.Extensions.Num(); i++)
		{
			UMovementResolverExtension Extension = Resolver.Extensions[i];
			ActiveExtensionsLog.Value(f"[{i}]", Extension.Class.Name.ToString());

			FTemporalLog ExtensionPageLog = Extension.GetTemporalLogPage(TemporalLog, i + 1);
			ExtensionPageLog.Value("ExtensionClass", Extension.Class);

			FTemporalLog ExtensionFinalSectionLog = ExtensionPageLog.Section("Final", 999);
			Extension.LogFinal(ExtensionPageLog, ExtensionFinalSectionLog);
		}
	}

	void LogImpactsPage(const UHazeMovementComponent MovementComponent)
	{
		FTemporalLog TemporalLogImpacts = MovementComponent.GetTemporalLog().Page("Impacts");

		const FVector ShapeLocation = MovementComponent.ShapeComponent.WorldLocation;
		const FVector ShapeOffset = ShapeLocation - MovementComponent.Owner.ActorLocation;

		// Log all accumulated impacts
		{
			const FHazeTraceShape CollisionShape = MovementComponent.GetCollisionShape();

			const TArray<FMovementHitResult>& AllImpacts = MovementComponent.GetAllImpacts();
			for(int i = 0; i < AllImpacts.Num(); i++)
			{
				FTemporalLog AllImpactsLog = TemporalLogImpacts.Section("All");
				AllImpactsLog.HitResults(
					f"Impact {i + 1}",
					AllImpacts[i].ConvertToHitResult(),
					CollisionShape,
					ShapeOffset,
					false
				);
			}

			const TArray<FHitResult>& GroundImpacts = MovementComponent.GetAllGroundImpacts();
			for(int i = 0; i < GroundImpacts.Num(); i++)
			{
				FTemporalLog GroundImpactsLog = TemporalLogImpacts.Section("Ground");
				GroundImpactsLog.HitResults(
					f"Ground Impact {i + 1}",
					GroundImpacts[i],
					CollisionShape,
					ShapeOffset,
					false
				);
			}

			const TArray<FHitResult>& WallImpacts = MovementComponent.GetAllWallImpacts();
			for(int i = 0; i < WallImpacts.Num(); i++)
			{
				FTemporalLog WallImpactsLog = TemporalLogImpacts.Section("Wall");
				WallImpactsLog.HitResults(
					f"Wall Impact {i + 1}",
					WallImpacts[i],
					CollisionShape,
					ShapeOffset,
					false
				);
			}

			const TArray<FHitResult>& CeilingImpacts = MovementComponent.GetAllCeilingImpacts();
			for(int i = 0; i < CeilingImpacts.Num(); i++)
			{
				FTemporalLog CeilingImpactsLog = TemporalLogImpacts.Section("Ceiling");
				CeilingImpactsLog.HitResults(
					f"Ceiling Impact {i + 1}",
					CeilingImpacts[i],
					CollisionShape,
					ShapeOffset,
					false
				);
			}
		}
	}

	void LogIgnoredPage(
		const UHazeMovementComponent MovementComponent,
		const UBaseMovementData MovementData,
	)
	{
		const FTemporalLog TemporalLog = MovementComponent.GetTemporalLog();
		const FTemporalLog IgnoredPage = TemporalLog.Page("Ignored");

		{
			const FTemporalLog MovementComponentSection = IgnoredPage.Section("Ignored on MovementComponent", 1);

			MovementComponentSection.Value(f"Actor Count", MovementComponent.InternalIgnoreActors.Num());
			int ActorIndex = 0;
			for(auto IgnoredActor : MovementComponent.InstigatedIgnoreActors)
			{
				if(IgnoredActor.Value.Instigators.IsEmpty())
					continue;

				ActorIndex++;
				const FTemporalLog ActorSection = MovementComponentSection.Section(f"Actor {IgnoredActor.Key}", ActorIndex);
				ActorSection.Value("Actor", IgnoredActor.Key);
				for(int i = 0; i < IgnoredActor.Value.Instigators.Num(); i++)
					ActorSection.Value(f"Instigator {i + 1}", IgnoredActor.Value.Instigators[i]);
			}

			MovementComponentSection.Value(f"Component Count", MovementComponent.InstigatedIgnoreComponents.Num());
			int ComponentIndex = 0;
			for(auto IgnoredComponent : MovementComponent.InstigatedIgnoreComponents)
			{
				if(IgnoredComponent.Value.Instigators.IsEmpty())
					continue;

				ComponentIndex++;
				const FTemporalLog ComponentSection = MovementComponentSection.Section(f"Component {IgnoredComponent.Key}", ComponentIndex);
				ComponentSection.Value("Component", IgnoredComponent.Key);
				for(int i = 0; i < IgnoredComponent.Value.Instigators.Num(); i++)
					ComponentSection.Value(f"Instigator {i + 1}", IgnoredComponent.Value.Instigators[i]);
			}
		}

		{
			const FTemporalLog MoveDataSection = IgnoredPage.Section("Ignored this frame on MovementData", 2);
			const FTemporalLog MoveDataActorsSection = MoveDataSection.Section("Actors", 1);
			const FTemporalLog MoveDataComponentSection = MoveDataSection.Section("Components", 2);

			MoveDataActorsSection.Value(f"Count", MovementData.IgnoredActorsThisFrame.Num());
			for(int i = 0; i < MovementData.IgnoredActorsThisFrame.Num(); i++)
				MoveDataActorsSection.Value(f"Actor {i + 1}", MovementData.IgnoredActorsThisFrame[i]);

			MoveDataComponentSection.Value(f"Count", MovementData.IgnoredComponents.Num());
			for(int i = 0; i < MovementData.IgnoredComponents.Num(); i++)
				MoveDataComponentSection.Value(f"Component {i + 1}", MovementData.IgnoredComponents[i]);
		}

		{
			const FTemporalLog MoveDataSection = IgnoredPage.Section("Initial Ignored on MovementData", 3);
			const FTemporalLog MoveDataActorsSection = MoveDataSection.Section("Actors", 1);
			const FTemporalLog MoveDataComponentSection = MoveDataSection.Section("Components", 2);

			const TArray<AActor> IgnoredActorsInTraceSettings = MovementData.TraceSettings.GetDebugIgnoredActors();
			MoveDataActorsSection.Value(f"Count", IgnoredActorsInTraceSettings.Num());
			for(int i = 0; i < IgnoredActorsInTraceSettings.Num(); i++)
				MoveDataActorsSection.Value(f"Actor {i + 1}", IgnoredActorsInTraceSettings[i]);

			const TArray<UPrimitiveComponent> IgnoredComponentsInTraceSettings = MovementData.TraceSettings.GetDebugIgnoredPrimitives();
			MoveDataComponentSection.Value(f"Count", IgnoredComponentsInTraceSettings.Num());
			for(int i = 0; i < IgnoredComponentsInTraceSettings.Num(); i++)
				MoveDataComponentSection.Value(f"Component {i + 1}", IgnoredComponentsInTraceSettings[i]);
		}
	}

	void LogShapePage(const UHazeMovementComponent MovementComponent, const UBaseMovementResolver Resolver)
	{
		const FTemporalLog TemporalLog = MovementComponent.GetTemporalLog();
		const FTemporalLog ShapePage = TemporalLog.Page("Shape");

		ShapePage.Value("Shape Component", MovementComponent.ShapeComponent);

		const FHazeTraceShape& TraceShape = Resolver.IterationTraceSettings.TraceShape;
		if(!TraceShape.IsValid())
		{
			ShapePage.Status("Invalid Shape", FLinearColor::Red);
			return;
		}

		FLinearColor ShapeColor;
		const FVector ShapeLocation = Resolver.IterationState.CurrentLocation + Resolver.IterationTraceSettings.CollisionShapeOffset;

		switch(Resolver.GetMovementShapeType())
		{
			case EMovementShapeType::Invalid:
			{
				ShapePage.Status("Invalid Shape", FLinearColor::Red);
				return;
			}

			case EMovementShapeType::Box:
			{
				ShapeColor = FLinearColor::Yellow;
				ShapePage.Status("Box", ShapeColor);
				ShapePage.Value("Extents", TraceShape.Extent);
				ShapePage.Rotation("Orientation", TraceShape.Orientation, ShapeLocation);
				break;
			}

			case EMovementShapeType::Sphere:
			{
				ShapeColor = FLinearColor::Green;
				ShapePage.Status("Sphere", ShapeColor);
				ShapePage.Value("Radius", TraceShape.Shape.SphereRadius);
				break;
			}

			case EMovementShapeType::AlignedCapsule:
			{
				ShapeColor = FLinearColor::Green;
				ShapePage.Status("Capsule", ShapeColor);
				
				ShapePage.Value("Radius", TraceShape.Shape.CapsuleRadius);
				ShapePage.Value("Half Height", TraceShape.Shape.CapsuleHalfHeight);
				ShapePage.Rotation("Orientation", TraceShape.Orientation, ShapeLocation);
				break;
			}

			case EMovementShapeType::FlippedCapsule:
			{
				ShapeColor = FLinearColor::Yellow;
				ShapePage.Status("Capsule (Upside Down)", ShapeColor);

				ShapePage.Value("Radius", TraceShape.Shape.CapsuleRadius);
				ShapePage.Value("Half Height", TraceShape.Shape.CapsuleHalfHeight);
				ShapePage.Rotation("Orientation", TraceShape.Orientation, ShapeLocation);
				break;
			}

			case EMovementShapeType::NonAlignedCapsule:
			{
				ShapeColor = FLinearColor::Yellow;
				ShapePage.Status("Capsule (Non-aligned)", ShapeColor);

				ShapePage.Value("Radius", TraceShape.Shape.CapsuleRadius);
				ShapePage.Value("Half Height", TraceShape.Shape.CapsuleHalfHeight);
				ShapePage.Rotation("Orientation", TraceShape.Orientation, ShapeLocation);
				break;
			}
		}

		ShapePage.Shape(
			"Shape",
			ShapeLocation,
			TraceShape.Shape,
			TraceShape.Orientation.Rotator(),
			ShapeColor
		);
	}

	void LogFollowPage(const UHazeMovementComponent MovementComponent, FVector StartShapeLocation)
	{
		const FTemporalLog FollowPage = MovementComponent.GetFollowPage();
		
		const FTemporalLog FollowLog = FollowPage.Section("Current Follow");
		const FTemporalLog FollowEnablementStatusLog = FollowLog.Section("Follow Enabled Status");

		const FTemporalLog ReferenceFrameLog = FollowPage.Section("Reference Frame", 1);

		if(MovementComponent.GetFollowEnabledStatus() != EMovementFollowEnabledStatus::FollowDisabled)
		{
			// Follow
			{
				const FHazeMovementComponentAttachment& FollowData = MovementComponent.GetCurrentMovementFollowAttachment();
				FollowEnablementStatusLog
           			.Value("Value", MovementComponent.GetFollowEnabledStatus())
					.Value("Instigator", MovementComponent.GetFollowEnabledStatusInstigator())	
					.Value("Priority", f"{MovementComponent.GetFollowEnabledStatusPriority():n}")
					;

				if(FollowData.IsValid())
				{
					FollowPage.Status("Following", FLinearColor::Green);

					FollowLog
						.Value("Instigator", FollowData.Instigator)
						.Value("Priority", FollowData.Priority)

						.Value("Component", FollowData.Component)
						.Value("SocketName", FollowData.SocketName)

						.Value("Type", FollowData.Type)
						.Value("InheritType", FollowData.InheritType)

						.Value("bFollowHorizontal", FollowData.bFollowHorizontal)
						.Value("bFollowVerticalUp", FollowData.bFollowVerticalUp)
						.Value("bFollowVerticalDown", FollowData.bFollowVerticalDown)

						.DirectionalArrow("Velocity (Value)", StartShapeLocation, FollowData.Velocity)
						.Value("VelocityAddedFrame", FollowData.VelocityAddedFrame)
						.DirectionalArrow("Follow Velocity (Function)", StartShapeLocation, FollowData.GetFollowVelocity())

						.Value("FrameToBeRemovedAt", FollowData.FrameToBeRemovedAt)

						.DirectionalArrow("Follow Velocity", StartShapeLocation, MovementComponent.GetFollowVelocity(), Color = FLinearColor::Teal)
					;

					auto PlayerTrigger = Cast<UHazeMovablePlayerTriggerComponent>(FollowData.DebugableInstigatorObject);
					if(PlayerTrigger != nullptr)
					{
						FHazeShapeSettings ZoneShape = PlayerTrigger.Shape;
						if(PlayerTrigger.bUseSeparateExitShape)
						{
							ZoneShape = PlayerTrigger.ExitShape;
						}

						if(ZoneShape.Type == EHazeShapeType::Box)
							FollowLog.Box("ZoneBox", PlayerTrigger.WorldLocation, ZoneShape.BoxExtents, PlayerTrigger.WorldRotation);
						else if(ZoneShape.Type == EHazeShapeType::Sphere)
							FollowLog.Sphere("ZoneSphere", PlayerTrigger.WorldLocation, ZoneShape.SphereRadius);
						else if(ZoneShape.Type == EHazeShapeType::Capsule)
							FollowLog.Capsule("ZoneCapsule", PlayerTrigger.WorldLocation, ZoneShape.CapsuleHalfHeight, ZoneShape.CapsuleHalfHeight, PlayerTrigger.WorldRotation);
					}
				}
				else
				{
					FollowPage.Status("Not Following", FLinearColor::Yellow);
				}
			}

			// Ref Frame
			{
				const FHazeMovementComponentAttachment& ReferenceFrameData = MovementComponent.GetCurrentMovementReferenceFrame();

				if(ReferenceFrameData.IsValid())
				{
					ReferenceFrameLog.Status("Has Reference Frame", FLinearColor::Green);

					ReferenceFrameLog
						.Value("Instigator", ReferenceFrameData.Instigator)	

						.Value("Component", ReferenceFrameData.Component)
						.Value("SocketName", ReferenceFrameData.SocketName)

						.Value("Type", ReferenceFrameData.Type)
						.Value("InheritType", ReferenceFrameData.InheritType)

						.Value("bFollowHorizontal", ReferenceFrameData.bFollowHorizontal)
						.Value("bFollowVerticalUp", ReferenceFrameData.bFollowVerticalUp)
						.Value("bFollowVerticalDown", ReferenceFrameData.bFollowVerticalDown)

						.DirectionalArrow("Velocity (Value)", StartShapeLocation, ReferenceFrameData.Velocity)
						.Value("VelocityAddedFrame", ReferenceFrameData.VelocityAddedFrame)
						.DirectionalArrow("Follow Velocity (Function)", StartShapeLocation, ReferenceFrameData.GetFollowVelocity())

						.Value("FrameToBeRemovedAt", ReferenceFrameData.FrameToBeRemovedAt)
					;

					auto PlayerTrigger = Cast<UHazeMovablePlayerTriggerComponent>(ReferenceFrameData.DebugableInstigatorObject);
					if(PlayerTrigger != nullptr)
					{
						FHazeShapeSettings ZoneShape = PlayerTrigger.Shape;
						if(PlayerTrigger.bUseSeparateExitShape)
						{
							ZoneShape = PlayerTrigger.ExitShape;
						}

						if(ZoneShape.Type == EHazeShapeType::Box)
							ReferenceFrameLog.Box("ZoneBox", PlayerTrigger.WorldLocation, ZoneShape.BoxExtents, PlayerTrigger.WorldRotation);
						else if(ZoneShape.Type == EHazeShapeType::Sphere)
							ReferenceFrameLog.Sphere("ZoneSphere", PlayerTrigger.WorldLocation, ZoneShape.SphereRadius);
						else if(ZoneShape.Type == EHazeShapeType::Capsule)
							ReferenceFrameLog.Capsule("ZoneCapsule", PlayerTrigger.WorldLocation, ZoneShape.CapsuleHalfHeight, ZoneShape.CapsuleHalfHeight, PlayerTrigger.WorldRotation);
					}
				}
				else
				{
					ReferenceFrameLog.Status("No Reference Frame", FLinearColor::Yellow);
				}
			}
		}
		// Blocked by default
		else if(MovementComponent.GetFollowEnabledStatusIsDefault())
		{
			FollowPage.Status("Follow Disabled (by Default)", FLinearColor::Red);
			FollowEnablementStatusLog
				.Value("Default Value", f"{MovementComponent.GetFollowEnabledStatus():n}")
            ;
		}
		// Blocked by instigator(s)
        else
        {
			FollowPage.Status("Follow Blocked", FLinearColor::Red);
			FollowEnablementStatusLog
				.Value("Default Value", f"{MovementComponent.GetFollowEnabledStatus():n}")
				;

			FollowLog
				.Value("Blocked By", MovementComponent.GetFollowEnabledCurrentInstigator())
			;
        }
	}

	void LogGroundPage(
		const UHazeMovementComponent MovementComponent,
		float UnstableEdgeDistance,
		FVector ShapeOffset,
		float DebugArrowSizeLarge,
		float DebugArrowSizeMedium,
		float DebugArrowSizeSmall,
		EMovementEdgeHandlingType EdgeHandling,
		EMovementEdgeNormalRedirectType EdgeRedirect
	)
	{
		FTemporalLog TemporalLogGround = MovementComponent.GetGroundPage();

		// Info
		{
			FTemporalLog InfoSection = TemporalLogGround.Section("Info");
			InfoSection.Value("Walkable Slope Angle", MovementComponent.WalkableSlopeAngle);

			if(UnstableEdgeDistance > 0)
				InfoSection.Value("Unstable Edge Distance", UnstableEdgeDistance);
		}

		// Current
		{
			FTemporalLog CurrentGroundSection = TemporalLogGround.Section("Current Ground", 1);
			LogGroundContact(CurrentGroundSection, MovementComponent, MovementComponent.GroundContact, ShapeOffset, DebugArrowSizeLarge, DebugArrowSizeMedium);
		}

		// Previous
		{
			FTemporalLog PreviousGroundSection = TemporalLogGround.Section("Previous Ground", 2);
			LogGroundContact(PreviousGroundSection, MovementComponent, MovementComponent.PreviousGroundContact, ShapeOffset, DebugArrowSizeLarge, DebugArrowSizeMedium);
		}

		// Edge
		{
			FTemporalLog EdgeGroundSection = TemporalLogGround.Section("Edge", 3);
			LogEdge(EdgeGroundSection, MovementComponent, DebugArrowSizeSmall, EdgeHandling, EdgeRedirect, UnstableEdgeDistance);
		}
	}

	void LogGroundContact(FTemporalLog SectionLog, const UHazeMovementComponent MovementComponent, FMovementHitResult GroundContact, FVector ShapeOffset, float DebugArrowSizeLarge, float DebugArrowSizeMedium)
	{
		if(GroundContact.IsAnyGroundContact())
		{
			// Log Movement normal
			SectionLog
				.Value("Walkable", GroundContact.bIsWalkable)
				.Value("Unstable", GroundContact.EdgeResult.IsEdge() && GroundContact.EdgeResult.IsUnstable())

				.HitResults("Contact", 
					GroundContact.ConvertToHitResult(), 
					MovementComponent.GetCollisionShape(), 
					ShapeOffset, 
					false)

				.DirectionalArrow("Normal",
					GroundContact.ImpactPoint,
					GroundContact.Normal * DebugArrowSizeLarge,
					Color = FLinearColor::Black
				)

				// Log Movement normal
				.DirectionalArrow("Impact Normal",
					GroundContact.ImpactPoint,
					GroundContact.ImpactNormal * DebugArrowSizeMedium,
					Color = FLinearColor::Gray
				)
			;
		}
	}

	void LogEdge(FTemporalLog SectionLog, const UHazeMovementComponent MovementComponent, float DebugArrowSizeSmall, EMovementEdgeHandlingType EdgeHandling, EMovementEdgeNormalRedirectType EdgeRedirect, float UnstableEdgeDistance)
	{
		SectionLog.Value("Edge Handling", EdgeHandling);
		if(EdgeHandling == EMovementEdgeHandlingType::None)
			return;

		const FMovementHitResult GroundContact = MovementComponent.GroundContact;
		const FMovementEdge EdgeResult = GroundContact.EdgeResult;
		const bool bHasEdge = EdgeResult.IsEdge();

		SectionLog.Value("Has Ground Edge", bHasEdge);	

		if(bHasEdge)
		{
			SectionLog.Value("EdgeRedirect", EdgeRedirect);
			SectionLog.Value("UnstableEdgeDistance", UnstableEdgeDistance);

			SectionLog
				.Value("On the Empty Side", EdgeResult.bIsOnEmptySideOfLedge)
				.Value("Moving Past Edge", EdgeResult.bMovingPastEdge)
				.Value("Edge Distance", EdgeResult.Distance)
				.Value("Is Unstable", EdgeResult.IsUnstable())

				// Log Movement normal
				.Plane("Edge Normal",
					MovementComponent.GroundContact.ImpactPoint,
					EdgeResult.EdgeNormal * DebugArrowSizeSmall,
					100,
					4,
					1,
					Color = FLinearColor::Red)

				.Plane("Edge Ground Normal",
					MovementComponent.GroundContact.ImpactPoint,
					EdgeResult.GroundNormal * DebugArrowSizeSmall,
					100,
					4,
					1,
					Color = FLinearColor::Green)
			;

			if(!MovementComponent.GroundContactEdge.OverrideRedirectNormal.IsNearlyZero())
			{
				SectionLog.Plane("Edge OverrideRedirectNormal",
					MovementComponent.GroundContact.ImpactPoint,
					EdgeResult.OverrideRedirectNormal * DebugArrowSizeSmall,
					100,
					4,
					Color = FLinearColor::Blue)
				;
			}
		}
	}

	void LogContactsPage(const UHazeMovementComponent MovementComponent)
	{
		FTemporalLog TemporalLog = MovementComponent.GetTemporalLog();
		FTemporalLog ContactsPage = TemporalLog.Page("Contacts");

		FTemporalLog GroundContactsSection = ContactsPage.Section("Ground Contact", 1);
		FTemporalLog WallContactsSection = ContactsPage.Section("Wall Contact", 2);
		FTemporalLog CeilingContactsSection = ContactsPage.Section("Ceiling Contact", 3);

		LogContactSection(GroundContactsSection, MovementComponent, EMovementImpactType::Ground);
		LogContactSection(WallContactsSection, MovementComponent, EMovementImpactType::Wall);
		LogContactSection(CeilingContactsSection, MovementComponent, EMovementImpactType::Ceiling);
	}

	void LogContactSection(FTemporalLog SectionLog, const UHazeMovementComponent MovementComponent, EMovementImpactType ImpactType)
	{
		const FVector ShapeOffset = MovementComponent.ShapeComponent.WorldLocation - MovementComponent.Owner.ActorLocation;

		const FMovementHitResult& Contact = MovementComponent.GetContact(ImpactType);
		const FHitResult ContactHit = Contact.ConvertToHitResult();

		SectionLog
			.Value("Is Valid Contact Contact", ContactHit.IsValidBlockingHit())
			.HitResults("Hit", ContactHit, MovementComponent.CollisionShape, ShapeOffset)
		;

		LogContactOverrides(SectionLog, MovementComponent, ImpactType);
	}

	void LogContactOverrides(FTemporalLog ContactsPageLog, const UHazeMovementComponent MovementComponent, EMovementImpactType ImpactType)
	{
		const TArray<FInstigator>& Instigators = MovementComponent.CurrentContacts.GetOverrideInstigators(ImpactType);

		if(Instigators.IsEmpty())
			return;

		FTemporalLog Section;
		switch(ImpactType)
		{
			case EMovementImpactType::Ground:
				Section = ContactsPageLog.Section("Overrides");
				break;

			case EMovementImpactType::Wall:
				Section = ContactsPageLog.Section("Overrides");
				break;

			case EMovementImpactType::Ceiling:
				Section = ContactsPageLog.Section("Overrides");
				break;

			default:
				return;
		}

		Section.Value("Count", Instigators.Num());

		for(int i = 0; i < Instigators.Num(); i++)
			Section.Value(f"[{i}]", Instigators[i]);
	}

	void LogGravityPage(const UHazeMovementComponent MovementComponent)
	{
		FTemporalLog TemporalLog = MovementComponent.GetTemporalLog();
		FTemporalLog GravityPage = TemporalLog.Page("Gravity");

		GravityPage.DirectionalArrow("Gravity", MovementComponent.ShapeComponent.WorldLocation, MovementComponent.Gravity, Color = FLinearColor::Green);
		GravityPage.DirectionalArrow("Gravity Direction", MovementComponent.ShapeComponent.WorldLocation, MovementComponent.GravityDirection * 100, Color = FLinearColor::Green);
		GravityPage.Value("Gravity Force", MovementComponent.GravityForce);
		GravityPage.Value("Gravity Multiplier", MovementComponent.GravityMultiplier);

		{
			FTemporalLog DirectionSection = GravityPage.Section("Gravity Direction", 1);

			const FMovementGravityDirection GravityDirection = MovementComponent.InternalGravityDirection.Get();
			DirectionSection.Value("Mode", GravityDirection.Mode);
			DirectionSection.DirectionalArrow("Direction", MovementComponent.ShapeComponent.WorldLocation, GravityDirection.Direction * 100, Color = FLinearColor::Green);
			DirectionSection.Value("TargetComponent", GravityDirection.TargetComponent);
			DirectionSection.Value("Instigator", MovementComponent.InternalGravityDirection.CurrentInstigator);
			DirectionSection.Value("Priority", MovementComponent.InternalGravityDirection.CurrentPriority);
		}

		{
			FTemporalLog SettingsSection = GravityPage.Section("Settings", 2);
			const UMovementGravitySettings Settings = MovementComponent.InternalGravitySettings;
			SettingsSection.Value("Use World Settings Gravity", Settings.bUseWorldSettingsGravity);
			SettingsSection.Value("Gravity Amount", Settings.GravityAmount);
			SettingsSection.Value("Gravity Scale", Settings.GravityScale);
			SettingsSection.Value("Terminal Velocity", Settings.TerminalVelocity);
		}
	}

	FLinearColor GetDeltaTypeColor(EMovementIterationDeltaStateType DeltaType)
	{
		switch(DeltaType)
		{
			case EMovementIterationDeltaStateType::Movement:
				return FLinearColor::White;

			case EMovementIterationDeltaStateType::Horizontal:
				return FLinearColor::Blue;

			case EMovementIterationDeltaStateType::Impulse:
				return FLinearColor::Red;

			case EMovementIterationDeltaStateType::Sum:
				return FLinearColor::Green;
		}
	}
};
#endif