UCLASS(NotBlueprintable)
class ULimitLeadingPlayerDistanceAlongSplineResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(USteppingMovementResolver);
	default SupportedResolverClasses.Add(USweepingMovementResolver);
	default SupportedResolverClasses.Add(USimpleMovementResolver);
	default SupportedResolverClasses.Add(UTeleportingMovementResolver);
	
	UBaseMovementResolver Resolver;
	FLimitLeadingPlayerDistanceAlongSplineResolverExtensionSettings Settings;

	float PlayerSplineDistance;
	float OtherPlayerSplineDistance;

	float SoftLimitSplineDistance;
	float HardLimitSplineDistance;
	float DistanceAlpha;

	FVector SplineDirection;

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		auto Other = Cast<ULimitLeadingPlayerDistanceAlongSplineResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		Settings = Other.Settings;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);
		
		Resolver = InResolver;

		auto MaxDistanceComp = ULimitLeadingPlayerDistanceAlongSplineComponent::Get(Resolver.Owner);
		if (MaxDistanceComp != nullptr)
			Settings = MaxDistanceComp.Settings.Get();
	}

	bool OnPrepareNextIteration(bool bFirstIteration) override
	{
		const AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Resolver.Owner);

		if(Settings.bOnlyActiveWhileOtherPlayerIsAlive && Player.OtherPlayer.IsPlayerDead())
		{
			// The other player is dead, and we require them to be alive
			return true;
		}

		PlayerSplineDistance = Settings.Spline.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		OtherPlayerSplineDistance = Settings.Spline.GetClosestSplineDistanceToWorldLocation(Player.OtherPlayer.ActorLocation);

		// Both players need to be "on" the spline for this to work
		if(PlayerSplineDistance < KINDA_SMALL_NUMBER || PlayerSplineDistance > Settings.Spline.SplineLength - KINDA_SMALL_NUMBER)
			return true;

		if(OtherPlayerSplineDistance < KINDA_SMALL_NUMBER || OtherPlayerSplineDistance > Settings.Spline.SplineLength - KINDA_SMALL_NUMBER)
			return true;

		if(!IsLeadingPlayer())
		{
			// We only clamp the leading player
			return true;
		}

		GetLimits(SoftLimitSplineDistance, HardLimitSplineDistance, DistanceAlpha);

		if(DistanceAlpha < KINDA_SMALL_NUMBER)
		{
			// The distance isn't big enough to require clamping
			return true;
		}

		SplineDirection = Settings.Spline.GetWorldRotationAtSplineDistance(PlayerSplineDistance).ForwardVector;
		if(!Settings.bForwardOnSpline)
			SplineDirection *= -1;

		for (auto It : Resolver.IterationState.DeltaStates)
		{
			FMovementDelta OriginalDelta = It.Value.ConvertToDelta();
			FMovementDelta NewDelta;
			if(CalculateWantedDelta(Resolver.IterationState.CurrentLocation, Resolver.IterationState.WorldUp, OriginalDelta, NewDelta))
			{
				if(!Settings.bClampVelocity)
					NewDelta.Velocity = OriginalDelta.Velocity;

				Resolver.IterationState.OverrideDelta(It.Key, NewDelta);
			}
		}

		return true;
	}

	bool CalculateWantedDelta(FVector CurrentLocation, FVector WorldUp, FMovementDelta OriginalDelta, FMovementDelta&out NewDelta) const
	{
		if(!IsMovingAwayFromTrailingPlayer(OriginalDelta))
		{
			// We only clamp if moving away from the trailing player
			return false;
		}

		if(Settings.bHardClamp && DistanceAlpha > 1.0 - KINDA_SMALL_NUMBER)
		{
			// Hard clamp when we reach the limit of the spline
			FTransform CurrentSplineTransform = Settings.Spline.GetWorldTransformAtSplineDistance(PlayerSplineDistance);
			FVector RelativeLocation = CurrentSplineTransform.InverseTransformPositionNoScale(CurrentLocation);

			FTransform HardLimitTransform = Settings.Spline.GetWorldTransformAtSplineDistance(HardLimitSplineDistance);

			FVector TargetLocation = HardLimitTransform.TransformPositionNoScale(RelativeLocation);

			FMovementDelta VerticalDelta = OriginalDelta.GetVerticalPart(WorldUp);
			TargetLocation += VerticalDelta.Delta;

			const FVector DeltaToTrace = TargetLocation - CurrentLocation;

			const FMovementHitResult Hit = Resolver.QueryShapeTrace(CurrentLocation, DeltaToTrace, Resolver.GenerateTraceTag(n"LimitLeadingPlayerDistanceAlongSpline_HardClampValidation"));
			if(Hit.bStartPenetrating)
			{
				// FB TODO: Do we need to handle this?
				PrintWarning("LimitLeadingPlayerDistanceAlongSpline failed a sweep. Please contact your resident movement person (Filip B)");
				return false;
			}
			else if(Hit.bBlockingHit)
			{
				// If we hit something, we may want to smoothly get out once we stop hitting something? At the moment, we just snap
				TargetLocation = Hit.Location;
			}

			NewDelta.Delta = (TargetLocation - CurrentLocation);
			NewDelta.Velocity = NewDelta.Delta / Resolver.IterationTime;

			// Maintain original vertical velocity
			NewDelta += VerticalDelta;
			return true;
		}
		else
		{
			// Fade out velocity
			FMovementDelta VerticalDelta = OriginalDelta.GetVerticalPart(WorldUp);
			FMovementDelta HorizontalDelta = OriginalDelta.GetHorizontalPart(WorldUp);

			FMovementDelta SplineDelta = HorizontalDelta.ProjectOntoNormal(SplineDirection);
			FMovementDelta NonSplineDelta = HorizontalDelta - SplineDelta;

			SplineDelta *= (1.0 - DistanceAlpha);
			HorizontalDelta = SplineDelta + NonSplineDelta;

			NewDelta = HorizontalDelta + VerticalDelta;
			return true;
		}
	}

	bool IsLeadingPlayer() const
	{
		if(Settings.bForwardOnSpline)
		{
			if(PlayerSplineDistance > OtherPlayerSplineDistance)
				return true;
			else
				return false;
		}
		else
		{
			if(PlayerSplineDistance < OtherPlayerSplineDistance)
				return true;
			else
				return false;
		}
	}

	bool IsMovingAwayFromTrailingPlayer(FMovementDelta MovementDelta) const
	{
		if(MovementDelta.Delta.DotProduct(SplineDirection) < 0)
			return false;

		return true;
	}

	void GetLimits(float&out OutSoftLimitDistanceAlongSpline, float&out OutHardLimitDistanceAlongSpline, float&out OutDistanceAlpha) const
	{
		if(Settings.bForwardOnSpline)
		{
			OutHardLimitDistanceAlongSpline = Math::Min(OtherPlayerSplineDistance + Settings.DistanceAlongSplineLimit, Settings.Spline.SplineLength);
			OutSoftLimitDistanceAlongSpline = Math::Max(OtherPlayerSplineDistance, OutHardLimitDistanceAlongSpline - Settings.FadeMargin);
		}
		else
		{
			OutHardLimitDistanceAlongSpline = Math::Max(OtherPlayerSplineDistance - Settings.DistanceAlongSplineLimit, 0);
			OutSoftLimitDistanceAlongSpline = Math::Min(OtherPlayerSplineDistance, OutHardLimitDistanceAlongSpline + Settings.FadeMargin);
		}

		OutDistanceAlpha = Math::GetPercentageBetweenClamped(OutSoftLimitDistanceAlongSpline, OutHardLimitDistanceAlongSpline, PlayerSplineDistance);
	}

#if !RELEASE
	void LogFinal(FTemporalLog ExtensionPage, FTemporalLog FinalSectionLog) const override
	{
		Super::LogFinal(ExtensionPage, FinalSectionLog);

		FinalSectionLog.Struct("Settings;", Settings);
		
		if(Settings.Spline == nullptr)
			return;

		FinalSectionLog.Value("Is Leading Player", IsLeadingPlayer());

		if(!IsLeadingPlayer())
			return;

		const FTransform SoftLimitTransform = Settings.Spline.GetWorldTransformAtSplineDistance(SoftLimitSplineDistance);
		const FTransform HardLimitTransform = Settings.Spline.GetWorldTransformAtSplineDistance(HardLimitSplineDistance);

		FinalSectionLog.Value("Soft Limit Distance", SoftLimitSplineDistance);
		FinalSectionLog.Plane("Soft Limit Plane", SoftLimitTransform.Location, SoftLimitTransform.Rotation.ForwardVector, Color = FLinearColor::Yellow);

		FinalSectionLog.Value("Hard Limit Distance", HardLimitSplineDistance);
		FinalSectionLog.Plane("Hard Limit Plane", HardLimitTransform.Location, HardLimitTransform.Rotation.ForwardVector, Color = FLinearColor::Red);

		FinalSectionLog.Value("Distance Alpha", DistanceAlpha);
	}
#endif
};

UCLASS(NotBlueprintable, NotPlaceable)
class ULimitLeadingPlayerDistanceAlongSplineComponent : UActorComponent
{
	TInstigated<FLimitLeadingPlayerDistanceAlongSplineResolverExtensionSettings> Settings;
};

struct FLimitLeadingPlayerDistanceAlongSplineResolverExtensionSettings
{
	UPROPERTY()
	UHazeSplineComponent Spline = nullptr;

	UPROPERTY()
	bool bForwardOnSpline = true;;

	// Maximum distance we allow the leading player to be from the trailing player before preventing them from moving further
	UPROPERTY()
	float DistanceAlongSplineLimit = 2000.0;

	/**
	 * At this distance before the DistanceAlongSplineLimit distance, start fading out the delta
	 */
	UPROPERTY()
	float FadeMargin = 500;

	/**
	 * If true, the leading player will be forcibly moved if too far away.
	 * If false, only stop the player from moving further away.
	 */
	UPROPERTY()
	bool bHardClamp = false;

	/**
	 * If false, only the delta will be constrained.
	 * This effectively means that the player will keep running visually, but not actually move.
	 */
	UPROPERTY()
	bool bClampVelocity = true;

	UPROPERTY()
	bool bOnlyActiveWhileOtherPlayerIsAlive = true;
};

namespace Boundary
{
	/**
	 * Apply a constraint to how far away the "leading" player can be from the other player along a spline.
	 * This prevents one player from running away from the other player in a linear level.
	 */
	UFUNCTION(Category = "Player|Movement")
	void ApplyLimitLeadingPlayerDistanceAlongSpline(AHazePlayerCharacter Player, FLimitLeadingPlayerDistanceAlongSplineResolverExtensionSettings Settings, FInstigator Instigator)
	{
		auto Comp = ULimitLeadingPlayerDistanceAlongSplineComponent::GetOrCreate(Player);
		Comp.Settings.Apply(Settings, Instigator);

		auto MoveComp = UHazeMovementComponent::Get(Player);
		MoveComp.ApplyResolverExtension(ULimitLeadingPlayerDistanceAlongSplineResolverExtension, Instigator);
	}

	UFUNCTION(Category = "Player|Movement")
	void ClearLimitLeadingPlayerDistanceAlongSpline(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		auto Comp = ULimitLeadingPlayerDistanceAlongSplineComponent::GetOrCreate(Player);
		Comp.Settings.Clear(Instigator);

		auto MoveComp = UHazeMovementComponent::Get(Player);
		MoveComp.ClearResolverExtensions(Instigator);
	}
};