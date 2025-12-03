class UTundraPlayerSnowMonkeyCeilingMovementResolver : USteppingMovementResolver
{
	default RequiredDataType = UTundraPlayerSnowMonkeyCeilingMovementData;

	// This is usually const but since we need to swap the OriginalContacts ground contact and ceiling contact it can't be const
	private UTundraPlayerSnowMonkeyCeilingMovementData CeilingData;

	// Temporal log stuff
	const FString CategoryCeilingClimbInfo = "12#Ceiling Climb Info";
	const FString CategoryCeilingClimbSplineInfo = "14#Ceiling Climb Spline Info";
	const FString CategoryCeilingClimbCubeInfo = "16#Ceiling Climb Cube Info";
	const float TemporalLogDebugCeilingHeightOffset = -20.0;
	// End temporal log stuff

	bool bWasConstrained = false;
	UTundraPlayerSnowMonkeyCeilingClimbComponent NewClimbComp;

	void PrepareResolver(const UBaseMovementData Movement) override
	{
		CeilingData = Cast<UTundraPlayerSnowMonkeyCeilingMovementData>(Movement);

		Super::PrepareResolver(Movement);

		NewClimbComp = nullptr;
	}

#if EDITOR
	void ResolveRerun() override
	{
		// Store the original contacts
		FMovementContacts OriginalContacts = CeilingData.OriginalContacts;

		Super::ResolveRerun();

		// Restore them after a rerun
		CeilingData.OriginalContacts = OriginalContacts;
	}
#endif

	protected void Resolve() override
	{
		// For the cursed ceiling climb, we flip the movement upside down
		IterationState.WorldUp *= -1;

		// Then we swap the ground and ceiling contacts
		SwapGroundAndCeilingContacts(CeilingData.OriginalContacts);

		Super::Resolve();
		
		// Then we flip the movement back
		IterationState.WorldUp *= -1;

		// And swap the contacts from the resolver
		SwapGroundAndCeilingContacts(IterationState.PhysicsState);
	}

	void SwapGroundAndCeilingContacts(FMovementContacts& StateToChange)
	{
		// Within the resolver ground is treated as ceiling and ceiling as ground
		// This is because we want to get step ups and apply horizontal velocity along the ground normal (or ceiling normal in this case).
		const FMovementContacts OriginalState = StateToChange;
		
		{
			StateToChange.GroundContact = OriginalState.CeilingContact;
			if(StateToChange.GroundContact.IsValidBlockingHit())
				StateToChange.GroundContact.Type = EMovementImpactType::Ground;
		}

		{
			StateToChange.CeilingContact = OriginalState.GroundContact;
			if(StateToChange.CeilingContact.IsValidBlockingHit())
				StateToChange.CeilingContact.Type = EMovementImpactType::Ceiling;
		}
	}

	bool PrepareNextIteration() override
	{
		bool bResult = Super::PrepareNextIteration();

		ConstrainDeltaToWithinCeiling();

		return bResult;
	}

	protected bool IsLeavingGround() const override
	{
		return false;
	}

	bool HandleStepUpOnMovementImpact(FMovementHitResult& OutIterationHit, bool bApplyMovement) override
	{
		// We don't want to step up on anything that isn't a ceiling climb
		if(!IsComponentClimbable(OutIterationHit.Component))
			return false;

		return Super::HandleStepUpOnMovementImpact(OutIterationHit, bApplyMovement);
	}

	// This leads to the monkey having velocity when trying to climb into collision, so don't do this!
	// void ApplyImpactOnDeltas(FMovementResolverState& State, FMovementHitResult Impact) const override
	// {
	// 	if(!IsComponentClimbable(Impact.Component))
	// 		return;

	// 	Super::ApplyImpactOnDeltas(State, Impact);
	// }

	bool ShouldProjectMovementOnImpact(FMovementHitResult Impact) const override
	{
		if(Impact.Type == EMovementImpactType::Wall)
		{
			if(bWasConstrained)
				return false;

			if(HandleDiscardDelta(CeilingData.MovementInput, Impact.Normal, "ShouldProjectMovementOnImpact"))
				return false;
		}

		return Super::ShouldProjectMovementOnImpact(Impact);
	}

	bool IsComponentClimbable(UPrimitiveComponent Component) const
	{
		auto ClimbComp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Component.Owner);
		if(ClimbComp == nullptr || ClimbComp.IsDisabled() || !ClimbComp.ComponentIsClimbable(Cast<UPrimitiveComponent>(Component)))
			return false;

		return true;
	}

	private void ConstrainDeltaToWithinCeiling()
	{
		FVector TargetLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;
		FVector InitialDelta = IterationState.DeltaToTrace;
		bWasConstrained = false;
		bool bDiscardDelta = false;

		// This is the position right on the edge of the ceiling (with CeilingEdgePushback)
		FVector ClosestConstrainedPosition;
		FVector EdgeNormal;

		if(IterationState.DeltaToTrace != FVector::ZeroVector)
		{
			if(CeilingData.CurrentCeiling.ConstrainToCeiling(TargetLocation, ClosestConstrainedPosition))
			{
				bool bShouldBeConstrained = true;
				for(FTundraPlayerSnowMonkeyCeilingData Current : CeilingData.AdjacentCeilings)
				{
					if(Current.IsPointWithinCeiling(TargetLocation))
					{
						bShouldBeConstrained = false;
						NewClimbComp = Current.ClimbComp;
					}
				}

				if(bShouldBeConstrained)
				{
					EdgeNormal = (ClosestConstrainedPosition - TargetLocation).GetSafeNormal();
					FVector NewLocation = ClosestConstrainedPosition;

					// The below ground trace does nothing it seems!
					// float StepdownSize = GetStepDownSize();
					// FMovementResolverGroundTraceSettings Settings;
					// Settings.bRedirectTraceIfInvalidGround = false;
					// Settings.CustomTraceTag = n"CeilingMovementGroundTrace";
					// FMovementHitResult NewGround = QueryGroundShapeTrace(
					// 	NewLocation, -CurrentWorldUp * StepdownSize, Settings);
					// ChangeGroundedState(IterationState, NewGround, false);
					// NewLocation = NewGround.Location;
					
					FVector NewDelta = NewLocation - IterationState.CurrentLocation;
					bDiscardDelta = HandleDiscardDelta(CeilingData.MovementInput, EdgeNormal, "ConstrainDeltaToWithinCeiling");

					if(!bDiscardDelta)
						IterationState.DeltaToTrace = NewDelta;
					else
						IterationState.DeltaToTrace = FVector::ZeroVector;

					IterationState.OverrideDelta(EMovementIterationDeltaStateType::Horizontal, FMovementDelta(IterationState.DeltaToTrace, IterationState.DeltaToTrace / IterationTime));
					bWasConstrained = true;
				}
			}
		}

#if !RELEASE
		auto Movement = TEMPORAL_LOG(GetOwner(), "Movement");
		Movement
		.Value(f"{CategoryCeilingClimbInfo};Constrained To Ceiling", bWasConstrained)
		.Value(f"{CategoryCeilingClimbInfo};Discarded Delta", bDiscardDelta)
		.Point(f"{CategoryCeilingClimbInfo};Initial Target Location", TargetLocation, 10.f, FLinearColor::Red)
		.DirectionalArrow(f"{CategoryCeilingClimbInfo};Initial Delta", IterationState.CurrentLocation, InitialDelta);

		if(bWasConstrained)
		{
			Movement.Point(f"{CategoryCeilingClimbInfo};Constrained Position", ClosestConstrainedPosition, 10.f, FLinearColor::Green);

			float CapsuleHeight = IterationTraceSettings.GetCollisionShape().CapsuleHalfHeight * 2;
			FVector EdgeNormalOrigin = ClosestConstrainedPosition - IterationState.WorldUp * (CapsuleHeight + TemporalLogDebugCeilingHeightOffset);
			Movement.DirectionalArrow(f"{CategoryCeilingClimbInfo};Edge Normal", EdgeNormalOrigin, EdgeNormal * 100.0);
		}

		TemporalLogCeilingBounds();
#endif
	}
	
	// Sets delta to zero if speed along right vector is below min slide speed, returns true if it did clamp, false if not
	bool HandleDiscardDelta(FVector Delta, FVector EdgeNormal, FString Tag) const
	{
		if(CeilingData.CeilingEdgeSlideMinSpeed <= 0.0)
			return false;

		FVector MaxSpeedDelta = Delta * CeilingData.CeilingMaxSpeed;
		FVector SlideDelta = MaxSpeedDelta.VectorPlaneProject(EdgeNormal);

		float SlideSpeed = SlideDelta.Size();

#if !RELEASE
		TEMPORAL_LOG(GetOwner(), "Movement")
			.DirectionalArrow(f"{Tag}::MaxSpeedDelta", IterationState.CurrentLocation, MaxSpeedDelta)
			.Value(f"{Tag}::SlideSpeed", SlideSpeed);
		;
#endif
		// Debug::DrawDebugArrow(Game::Mio.ActorLocation, Game::Mio.ActorLocation + MaxSpeedDelta, 10.0, FLinearColor::Red);
		// Debug::DrawDebugArrow(Game::Mio.ActorLocation, Game::Mio.ActorLocation + EdgeNormal * 100.0, 10.0, FLinearColor::Green);
		// PrintToScreen(f"{SlideSpeed=}");

		if(SlideSpeed < CeilingData.CeilingEdgeSlideMinSpeed)
			return true;

		return false;
	}

	EMovementCapsuleImpactSide GetCapsuleImpactType(FHitResult HitResult) const override
	{
		EMovementCapsuleImpactSide Type = Super::GetCapsuleImpactType(HitResult);

		if(Type == EMovementCapsuleImpactSide::Top)
			return EMovementCapsuleImpactSide::Bottom;

		if(Type == EMovementCapsuleImpactSide::Bottom)
			return EMovementCapsuleImpactSide::Top;

		return Type;
	}

	void ApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::ApplyResolvedData(MovementComponent);
		
		if(HasControl())
		{
			auto SnowMonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(MovementComponent.Owner);

			if(SnowMonkeyComp.bCeilingMovementWasConstrained != bWasConstrained)
				SnowMonkeyComp.CrumbSetCeilingMovementWasConstrained(bWasConstrained);

			if(NewClimbComp != nullptr && SnowMonkeyComp.CurrentCeilingComponent != NewClimbComp)
				SnowMonkeyComp.CrumbTrySetCurrentCeilingComponent(NewClimbComp);
		}
	}

#if !RELEASE
	private void TemporalLogCeilingBounds()
	{
		FTundraPlayerSnowMonkeyCeilingData Data = CeilingData.CurrentCeiling;
		if(Data.Spline != nullptr)
		{
			FVector TargetLocation = IterationState.CurrentLocation + IterationState.DeltaToTrace;
			float SplineMeshWidth = Data.SplineMeshWidth;
			float SplineDistance = Data.Spline.GetClosestSplineDistanceToWorldLocation(TargetLocation);
			FTransform ClosestSplineTransform = Data.Spline.GetWorldTransformAtSplineDistance(SplineDistance);

			const float BoxSize = 100.0;
			const float SplineUpVectorSign = Math::Sign(ClosestSplineTransform.Rotation.UpVector.DotProduct(FVector::UpVector));

			float ScaledMaxLocalOffset = SplineMeshWidth * ClosestSplineTransform.Scale3D.Y - Data.Pushback;
			FVector ValidBoxLocation = ClosestSplineTransform.Location + ClosestSplineTransform.Rotation.UpVector * (TemporalLogDebugCeilingHeightOffset * SplineUpVectorSign);
			FVector ValidBoxExtent = FVector(BoxSize, ScaledMaxLocalOffset, 0.0);
			FRotator ValidBoxRotation = ClosestSplineTransform.Rotator();

			auto Movement = TEMPORAL_LOG(GetOwner(), "Movement");
			Movement.Box(f"{CategoryCeilingClimbSplineInfo};Valid Area", ValidBoxLocation, ValidBoxExtent, ValidBoxRotation);

			FTransform SplineStartTransform = Data.Spline.GetWorldTransformAtSplineDistance(0.0);
			FTransform SplineEndTransform = Data.Spline.GetWorldTransformAtSplineDistance(Data.Spline.SplineLength);

			FVector StartLineOrigin = SplineStartTransform.Location + -SplineStartTransform.Rotation.RightVector * ScaledMaxLocalOffset + SplineStartTransform.Rotation.UpVector * (TemporalLogDebugCeilingHeightOffset * SplineUpVectorSign);
			FVector StartLineTarget = SplineStartTransform.Location + SplineStartTransform.Rotation.RightVector * ScaledMaxLocalOffset + SplineStartTransform.Rotation.UpVector * (TemporalLogDebugCeilingHeightOffset * SplineUpVectorSign);
			FVector EndLineOrigin = SplineEndTransform.Location + -SplineEndTransform.Rotation.RightVector * ScaledMaxLocalOffset + SplineEndTransform.Rotation.UpVector * (TemporalLogDebugCeilingHeightOffset * SplineUpVectorSign);
			FVector EndLineTarget = SplineEndTransform.Location + SplineEndTransform.Rotation.RightVector * ScaledMaxLocalOffset + SplineEndTransform.Rotation.UpVector * (TemporalLogDebugCeilingHeightOffset * SplineUpVectorSign);

			Movement
			.Line(f"{CategoryCeilingClimbSplineInfo};Spline Start", StartLineOrigin, StartLineTarget, 2.0, FLinearColor::Green)
			.Line(f"{CategoryCeilingClimbSplineInfo};Spline End", EndLineOrigin, EndLineTarget, 2.0, FLinearColor::Red);
		}
		else
		{
			FVector BoundsLocation;
			FVector BoundsExtents;
			Data.CeilingLocalBounds.GetCenterAndExtents(BoundsLocation, BoundsExtents);

			BoundsExtents *= Data.CeilingTransform.Scale3D;
			BoundsLocation = Data.CeilingTransform.TransformPosition(BoundsLocation);

			BoundsLocation += Data.CeilingTransform.Rotation.UpVector * (-BoundsExtents.Z + TemporalLogDebugCeilingHeightOffset);
			BoundsExtents.X -= Data.Pushback;
			BoundsExtents.Y -= Data.Pushback;
			BoundsExtents.Z = 0.0;

			auto Movement = TEMPORAL_LOG(GetOwner(), "Movement");
			Movement.Box(f"{CategoryCeilingClimbCubeInfo};Ceiling Bounds",
				BoundsLocation,
				BoundsExtents,
				Data.CeilingTransform.Rotator(),
				FLinearColor::Red,
				2.0);
		}
	}
#endif
}