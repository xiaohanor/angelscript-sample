

enum EIslandNunchuckMeleeTargetableType
{
	// This one counts as a grounded target
	Grounded,

	// This one counts as a flying target
	Flying,

	/**
	 * This one counts as massive target
	 * and can trigger both air and ground combos
	 * If the player is airbourn, this one counts as flying and vice versa
	*/ 
	AirAndGround,

	// Use the current status of the movement component
	MoveCompStatus
}

enum EIslandNunchuckImpactResponseTraceType
{
	// We skip the tracing, we just hit the actor and all of its 
	AlwaysHitIgnoreTrace,

	// We trace against the owner and only perform impact
	// on the found primitives
	PerformTrace,
}

enum EIslandNunchuckTargetableTagsSetting
{
	RequiresAll,
	RequiresAny
}

/** A component  */
class UIslandNunchuckTargetableComponent : UTargetableComponent
{
	default TargetableCategory = n"ScifiMelee";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;
	default TargetableCategory = n"Nunchuck";
	default SetbAbsoluteRotation(true);

	// At what range is this target valid
	UPROPERTY(Category = "Targetable")
	FHazeRange TargetableRange = FHazeRange(0, 1000);

	// Should we trace to the target to see if we can actually hit it
	UPROPERTY(Category = "Targetable")
	bool bCheckIfCanReachedUnblocked = true;

	// Is this attach to an actor that is concidered grounded or flying
	UPROPERTY(Category = "Melee")
	EIslandNunchuckMeleeTargetableType GroundedType = EIslandNunchuckMeleeTargetableType::Grounded;

	// Stationary targets can't get knockedback and the player will play a stationary animation at the target location
	UPROPERTY(Category = "Melee")
	bool bTargetIsStationary = false;

	// If true, the player will move to the target when activting a melee move that allowes traversal
	UPROPERTY(Category = "Melee")
	bool bCanTraversToTarget = true;

	// Use for triggering specific attacks on this target
	UPROPERTY(Category = "Melee")
	TArray<FName> RequiredComboTags;

	// How should the tags be validated
	UPROPERTY(Category = "Melee")
	EIslandNunchuckTargetableTagsSetting RequiredComboTagsType = EIslandNunchuckTargetableTagsSetting::RequiresAll;

	// How far away should the player end up when traversing to this target
	UPROPERTY(Category = "Melee", meta=(ClampMin="0.0", UIMin="0.0"))
	float KeepDistance = 0;

	/** How we trace for the 'IslandNunchuckImpactResponseComponent'
	 * If we always hit, we just apply the impact to all the response components
	 * If we do a trace, we only trigger impacts on the response components with a relation to the primitives we impacted with
	 */
	UPROPERTY(Category = "Melee")
	EIslandNunchuckImpactResponseTraceType TraceType = EIslandNunchuckImpactResponseTraceType::AlwaysHitIgnoreTrace;

	// Should this target be more or less prioritized
	UPROPERTY(Category = "Targetable", meta=(ClampMin="0.0", UIMin="0.0", ClampMax="1.0", UIMax="1.0"))
	float ScoreMultiplier = 1;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{	
		if (Query.DistanceToTargetable > TargetableRange.Max)
		{
			// Cannot be targeted from this distance
			Query.Result.bVisible = false;
			Query.Result.bPossibleTarget = false;
			return false;
		}

		if (Query.DistanceToTargetable <= TargetableRange.Min)
		{
			// Cannot be targeted from this distance
			Query.Result.bVisible = false;
			Query.Result.bPossibleTarget = false;
			return false;
		}

		Targetable::MarkVisibilityHandled(Query);
		Targetable::ScoreWantedMovementInput(Query, bAllowWithZeroInput = true);
		Targetable::ScoreCameraTargetingInteraction(Query, TargetableRange.Max);

		if(bCheckIfCanReachedUnblocked)
			Targetable::RequirePlayerCanReachUnblocked(Query, true, true, KeepDistance);

		// Make sure the target is actually on screen at all
		FVector TargetLocation = Query.Component.WorldLocation;
		FVector2D ScreenPosition;
		bool bInFrontOfScreen = SceneView::ProjectWorldToViewpointRelativePosition(Query.Player, TargetLocation, ScreenPosition);
		if (!bInFrontOfScreen)
		{
			Query.Result.Score = 0.0;
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
		}

		FVector DirToTarget = (TargetLocation - Query.ViewLocation).GetSafeNormal();
		if(DirToTarget.DotProduct(Query.ViewForwardVector) < 0.4)
		{
			Query.Result.Score = 0.0;
			Query.Result.bPossibleTarget = false;
			Query.Result.bVisible = false;
		}

		Query.Result.Score *= ScoreMultiplier;
		return true;
	}

	bool ValidateTags(TArray<FName> ActiveTags) const
	{	
		bool bHasTags = ActiveTags.Num() > 0;
		bool bRequiresTags = RequiredComboTags.Num() > 0;

		if(!bHasTags && !bRequiresTags)
			return true;

		if(bHasTags != bRequiresTags)
			return false;

		if(RequiredComboTagsType == EIslandNunchuckTargetableTagsSetting::RequiresAll)
		{
			for(auto RequiredTag : RequiredComboTags)
			{
				if(!ActiveTags.Contains(RequiredTag))
					return false;
			}

			return true;
		}
		else if(RequiredComboTagsType == EIslandNunchuckTargetableTagsSetting::RequiresAny)
		{
			for(auto AnyValidTag : RequiredComboTags)
			{
				if(!ActiveTags.Contains(AnyValidTag))
					return true;
			}
		}

		return false;
	}

	// UPROPERTY(Category = "Melee")
	// bool bUseParent = false;

	// // Should we trace to the target to see if we can actually hit it
	// UPROPERTY(Category = "Melee")
	// bool bCheckIfCanReachedUnblocked = true;

	// protected uint LastInsideRangeFrame = 0;
	// protected float InsideRangeTime = 0;

	// void ApplyInRangeTime(float DeltaTime)
	// {
	// 	uint CurrentFrame = Time::FrameNumber;
	// 	if(LastInsideRangeFrame + 1 == CurrentFrame)
	// 	{
	// 		InsideRangeTime += DeltaTime;
	// 	}
	// 	else
	// 	{		
	// 		InsideRangeTime = 0;
	// 	}
	// 	LastInsideRangeFrame = CurrentFrame;
	// }
	
	// bool CheckTargetable(FTargetableQuery& Query) const override
	// {
	// 	bool RecentlyRendered = Owner.WasRecentlyRendered();
	// 	AActor ParentActor = Owner.GetParentActor();
	// 	bool ParentRecentlyRendered = ParentActor != nullptr && !ParentActor.WasRecentlyRendered();
	// 	if((!bUseParent && !RecentlyRendered) || (bUseParent && ParentRecentlyRendered))
	// 	{
	// 		Query.Result.bVisible = false;	
	// 		Query.Result.Score = 0.0;
	// 		return false;
	// 	}

	// 	auto MeleeComp = UPlayerIslandNunchuckUserComponent::Get(Query.Player);
	// 	if(MeleeComp == nullptr)
	// 	{
	// 		Query.Result.bVisible = false;
	// 		Query.Result.Score = 0.0;
	// 		return false;
	// 	}

	// 	if(!MeleeComp.ActionEpiCenter.IsValid())
	// 	{
	// 		Query.ComputedDistance = Query.Player.ActorLocation.Distance(Query.Component.Owner.ActorLocation);
	// 	}
	// 	else
	// 	{
	// 		Query.ComputedDistance = MeleeComp.ActionEpiCenter.CurrentLocation.Distance(Query.Component.Owner.ActorLocation);		
	// 	}
		

	// 	// Are we inside the aim range
	// 	const float TargetableRange = MeleeComp.GetReachTargetRange(this);
	// 	if (Query.ComputedDistance > TargetableRange)
	// 	{
	// 		Query.Result.Score = 0.0;
	// 		return false;
	// 	}

	// 	// Is the target obstructed by something
	// 	if(bCheckIfCanReachedUnblocked)
	// 	{
	// 		if(!Targetable::RequirePlayerCanReachUnblocked(Query, bUseParent, KeepDistance))
	// 		{
	// 			Query.Result.Score = 0.0;
	// 			return false;
	// 		}
	// 	}

	// 	auto Movement = UHazeMovementComponent::Get(Query.Player);
	// 	const FVector DirToTarget = (Query.Component.Owner.ActorLocation - Query.Player.ActorLocation).GetSafeNormal();
	// 	const FVector MovementInputDirection = Movement.MovementInput.GetSafeNormal();	
	// 	const FVector CameraDirection = Query.Player.ViewRotation.ForwardVector;

	// 	FIslandNunchuckEpiCenterData EpicenterSettings;
	// 	if(!MeleeComp.ActionEpiCenter.IsValid() || !MeleeComp.Settings.GetEpicenterData(Query.ComputedDistance, MeleeComp.DefaultReachTargetRange, EpicenterSettings))
	// 	{
	// 		// Camera
	// 		{
	// 			const float Dot = DirToTarget.DotProduct(CameraDirection);
	// 			const float Degrees = Math::DotToDegrees(Dot);
	// 			if(Degrees <= MeleeComp.Settings.MaxCameraAngle)
	// 			{
	// 				Query.Result.Score += ((Dot + 1) * 0.5) * MeleeComp.Settings.CameraAngleScore;
	// 			}	
	// 			else if(MeleeComp.Settings.bOutsideMaxCameraAngleIsInvalid)
	// 			{
	// 				Query.Result.Score = 0.0;
	// 				return false;
	// 			}	
	// 		}

	// 		// Distance
	// 		{
	// 			const float DistanceAlpha = Query.ComputedDistance / Math::Max(TargetableRange, 1.0);
	// 			Query.Result.Score += (1.0 - DistanceAlpha) * MeleeComp.Settings.DistanceScore;
	// 		}

	// 		// Input
	// 		if(!MovementInputDirection.IsNearlyZero())
	// 		{
	// 			const float Dot = DirToTarget.DotProduct(MovementInputDirection);
	// 			const float Degrees = Math::DotToDegrees(Dot);
	// 			if(Degrees <= MeleeComp.Settings.MaxInputAngle)
	// 			{
	// 				Query.Result.Score += ((Dot + 1) * 0.5) * MeleeComp.Settings.InputScore;
	// 			}
	// 			else if(MeleeComp.Settings.bOutsideMaxInputAngleIsInvalid)
	// 			{
	// 				Query.Result.Score = 0.0;
	// 				return false;
	// 			}
	// 		}
	// 	}
	// 	// Inside epicenter
	// 	else
	// 	{		
	// 		// Camera
	// 		{
	// 			const float Dot = DirToTarget.DotProduct(CameraDirection);
	// 			const float Degrees = Math::DotToDegrees(Dot);
	// 			if(Degrees <= EpicenterSettings.MaxCameraAngle)
	// 			{
	// 				Query.Result.Score += ((Dot + 1) * 0.5) * EpicenterSettings.CameraAngleScore;
	// 			}	
	// 			else if(EpicenterSettings.bOutsideMaxCameraAngleIsInvalid)
	// 			{
	// 				Query.Result.Score = 0.0;
	// 				return false;
	// 			}		
	// 		}

	// 		// Distance
	// 		{
	// 			const float DistanceAlpha = Query.ComputedDistance / Math::Max(TargetableRange, 1.0);
	// 			Query.Result.Score += (1.0 - DistanceAlpha) * EpicenterSettings.DistanceScore;
	// 		}

	// 		// Input
	// 		if(!MovementInputDirection.IsNearlyZero())
	// 		{
	// 			const float Dot = DirToTarget.DotProduct(MovementInputDirection);
	// 			const float Degrees = Math::DotToDegrees(Dot);
	// 			if(Degrees <= EpicenterSettings.MaxInputAngle)
	// 			{
	// 				Query.Result.Score += ((Dot + 1) * 0.5) * EpicenterSettings.InputScore;
	// 			}	
	// 			else if(EpicenterSettings.bOutsideMaxInputAngleIsInvalid)
	// 			{
	// 				Query.Result.Score = 0.0;
	// 				return false;
	// 			}	
	// 		}

	// 		// The more away from the last direction, the bigger the chance of getting picked
	// 		auto Combat = UPlayerIslandNunchuckUserComponent::Get(Query.Player);
	// 		if(!Combat.LastTargetDirection.IsNearlyZero())
	// 		{
	// 			const float LastDirAlpha = 1.0 - DirToTarget.DotProductNormalized(Combat.LastTargetDirection);
	// 			Query.Result.Score += EpicenterSettings.LastTargetDirectionInvertScore * LastDirAlpha;
	// 		}

	// 		// Add time score
	// 		{
	// 			// The longer we have been inside the target, the long time 
	// 			float TimeSinceTargetAlpha = Math::Min(InsideRangeTime / EpicenterSettings.TimeScoreMaxTime, 1.0);
	// 			Query.Result.Score += EpicenterSettings.TimeScore * TimeSinceTargetAlpha;
	// 		}
	// 	}

	// 	#if !RELEASE
	// 	if(MeleeComp.DebugDrawer.IsVisible())
	// 	{	
	// 		Debug::DrawDebugString(GetWorldLocation(), f"Scores: {Query.Result.Score :.0}",  FLinearColor::Teal, Scale = 1.4);
	// 	}
	// 	#endif

	// 	return true;
	// }

	// protected bool CheckAutoAimable(AHazePlayerCharacter Player) const
	// {		
	// 	auto HealthComp = UBasicAIHealthComponent::Get(Owner);
	// 	if(HealthComp != nullptr && HealthComp.IsDead())
	// 		return false;

	// 	FVector Forward = Player.ActorForwardVector;
	// 	Forward.Z = 0;
	// 	FVector CompLoc = Owner.GetActorLocation();
	// 	CompLoc.Z = 0;
	// 	FVector PlayerLoc = Player.GetActorLocation();
	// 	PlayerLoc.Z = 0;
	// 	FVector Direction = CompLoc - PlayerLoc;
	// 	Direction.Normalize();
	// 	float Dot = Forward.DotProduct(Direction);
	// 	float Degrees = Math::RadiansToDegrees(Math::Acos(Dot));
		
	// 	if(Degrees > ValidAngle)
	// 		return false;

	// 	return true;
	// }

	// protected float GetReachTargetRange(AHazePlayerCharacter Player) const
	// {
	// 	auto MeleeComp = UPlayerIslandNunchuckUserComponent::Get(Player);
	// 	if(MeleeComp == nullptr)
	// 		return TargetRange;

	// 	return MeleeComp.GetReachTargetRange(this);
	// }

	// protected bool IsVisible(FTargetableQuery Query) const
	// {
	// 	if(!Owner.WasRecentlyRendered())
	// 		return false;

	// 	return true;
	// }

	// bool TargetIsGrounded() const
	// {
	// 	return GroundedType == EScifiMeleeTargetableType::Grounded;
	// }
};

// class UUIslandNunchuckTargetableComponentVisualizer : UHazeScriptComponentVisualizer
// {
//     default VisualizedClass = UIslandNunchuckTargetableComponent;

//     UFUNCTION(BlueprintOverride)
//     void VisualizeComponent(const UActorComponent Component) 
//     {
//         auto TargetableComponent = Cast<UIslandNunchuckTargetableComponent>(Component);
	
// 		if(TargetableComponent == nullptr)
// 			return;

// 		auto MeleeComponent = Cast<UPlayerIslandNunchuckUserComponent>(UPlayerIslandNunchuckUserComponent.DefaultObject);
		
// 		// Activate range
// 		// {
// 		// 	const float Range = MeleeComponent.GetReachTargetRange(TargetableComponent);
// 		// 	if(TargetableComponent.TargetableType == EScifiMeleeTargetableType::Grounded)
// 		// 	{
// 		// 		DrawCircle(TargetableComponent.Owner.GetActorLocation(), Range, FLinearColor::LucBlue);
// 		// 	}
// 		// 	else if(TargetableComponent.TargetableType == EScifiMeleeTargetableType::Grounded)
// 		// 	{
// 		// 		DrawWireSphere(TargetableComponent.WorldLocation, Range, Color = FLinearColor::LucBlue);
// 		// 	}
// 		// }

// 		// // Stand at location
// 		// {
// 		// 	const float Range = MeleeComponent.GetFinalizedStandardMoveData(EScifiMeleeTargetableDirection::MAX).BonusKeepDistanceAmount;
// 		// 	if(TargetableComponent.TargetableType == EScifiMeleeTargetableType::Grounded)
// 		// 	{
// 		// 		DrawCircle(TargetableComponent.Owner.GetActorLocation(), Range, FLinearColor::Green);
// 		// 	}
// 		// 	else if(TargetableComponent.TargetableType == EScifiMeleeTargetableType::Flying)
// 		// 	{
// 		// 		DrawWireSphere(TargetableComponent.WorldLocation, Range, FLinearColor::Green);
// 		// 	}
// 		// }
//     }   
// } 