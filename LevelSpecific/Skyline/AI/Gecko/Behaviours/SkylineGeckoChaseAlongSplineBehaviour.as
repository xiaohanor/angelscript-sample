struct FGeckoChaseAlongSplineParams
{
	ASkylineGeckoClimbSplineActor Spline;
}	

// Move towards enemy along a climb spline
class USkylineGeckoChaseAlongSplineBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineGeckoComponent GeckoComp;
	USkylineGeckoSettings Settings;

	AHazeActor Target;
	ASkylineGeckoClimbSplineActor ClimbSpline;
	FSplinePosition TargetSplinePos;

	float UpdateTargetPositionTime;
	float DonePerchingTime;
	float InitialTurnDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);

		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Cooldown.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsBlocked())
			return;
#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			for (ASkylineGeckoClimbSplineActor Spline : GeckoComp.ClimbSplines)
			{
				Spline.ClimbSpline.DrawDebug(100, FLinearColor::Gray, 1.0);
				FSplinePosition SplinePos = Spline.GetSplinePositionNearWorldLocation(Owner.ActorCenterLocation); 
				FLinearColor Colour = SplinePos.WorldLocation.IsWithinDist2D(Owner.ActorCenterLocation, Settings.ClimbChaseSplineRange) ? FLinearColor::Yellow : FLinearColor::Red;
				Debug::DrawDebugLine(Owner.ActorCenterLocation, SplinePos.WorldLocation, Colour, 1.0);
			}
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGeckoChaseAlongSplineParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (GeckoComp.bIsLeaping.Get())
			return false;
		ASkylineGeckoClimbSplineActor FoundSpline = GeckoComp.FindClosestSpline(Settings.ClimbChaseSplineRange);
		if (FoundSpline == nullptr)
			return false;
		OutParams.Spline = FoundSpline;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.IsValidTarget(Target))
			return true;
		if (ActiveDuration > Settings.ClimbChaseMaxTime)
			return true;
		if (ActiveDuration > DonePerchingTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGeckoChaseAlongSplineParams Params)
	{
		Super::OnActivated();
		ClimbSpline = Params.Spline;
		Target = TargetComp.Target;
		
		FVector OwnLoc = Owner.ActorCenterLocation;
		FSplinePosition StartPos = ClimbSpline.GetSplinePositionNearWorldLocation(OwnLoc);
		TargetSplinePos = ClimbSpline.GetSplinePositionNearWorldLocation(Target.ActorLocation);
		UpdateTargetPositionTime = 0.8;
		float ToTargetDelta = TargetSplinePos.CurrentSplineDistance - StartPos.CurrentSplineDistance;
		float StartMove = Math::Min(OwnLoc.Distance(DestinationComp.FollowSplinePosition.WorldLocation) * 0.7, Math::Abs(ToTargetDelta * 0.5));
		StartPos.Move(StartMove * Math::Sign(ToTargetDelta));
		DestinationComp.FollowSplinePosition = StartPos;

		if (GeckoComp.CurrentClimbSpline != ClimbSpline.ClimbSpline)
		{
			// Start by turning towards spline
			InitialTurnDuration = 0.7;
			AnimComp.RequestFeature(FeatureTagGecko::Jump, EBasicBehaviourPriority::Medium, this, 0.7);
		}
		else
		{
			InitialTurnDuration = 0.0;
		}

		GeckoComp.ClimbSplineSideOffset = Math::RandRange(-1.0, 1.0) * 30.0; // TODO: Base this on spline width instead

		DonePerchingTime = BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Math::RandRange(0.5, 1.5) * Settings.ClimbChaseCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(Target == nullptr)
			return;

		UpdateTargetPosition(DeltaTime);

		if (ActiveDuration < InitialTurnDuration)
		{
			DestinationComp.RotateTowards(DestinationComp.FollowSplinePosition.WorldLocation);
			return;
		}
		if (InitialTurnDuration > 0.0)
		{
			AnimComp.ClearFeature(this);
			InitialTurnDuration = 0.0;
		}

		if (ShouldStop())
		{
			if (ActiveDuration > Settings.ClimbChaseMinTime - 0.5)
				DonePerchingTime = Math::Min(DonePerchingTime, ActiveDuration + 0.5);
			DestinationComp.MoveAlongSpline(ClimbSpline.ClimbSpline, 0.0, GeckoComp.IsAlignedWithSpline(DestinationComp.FollowSplinePosition));
			return; // Perch in place
		}

		// Keep moving towards target!
		DonePerchingTime = BIG_NUMBER;
		bool bClimbForward = (TargetSplinePos.CurrentSplineDistance > DestinationComp.FollowSplinePosition.CurrentSplineDistance);
		DestinationComp.MoveAlongSpline(ClimbSpline.ClimbSpline, Settings.ChaseMoveSpeed, bClimbForward);
	}

	void UpdateTargetPosition(float DeltaTime)
	{
		if (ActiveDuration > UpdateTargetPositionTime)
		{
			TargetSplinePos = ClimbSpline.GetSplinePositionNearWorldLocation(Target.ActorLocation);
			UpdateTargetPositionTime += 0.8;
			return;
		}
		
		float SanityClamp = 2000.0 * DeltaTime;
		float MoveDist = Math::Clamp(TargetSplinePos.WorldForwardVector.DotProduct(Target.ActorLocation - TargetSplinePos.WorldLocation), -SanityClamp, SanityClamp);
		TargetSplinePos.Move(MoveDist);
	}

	bool ShouldStop() const
	{
		if (Owner.ActorLocation.IsWithinDist(Target.ActorLocation, Settings.ChaseMinRange))
			return true;

		float SplineTargetDistance = Math::Abs(TargetSplinePos.CurrentSplineDistance - DestinationComp.FollowSplinePosition.CurrentSplineDistance);
		if (TargetSplinePos.CurrentSpline.IsClosedLoop() && (SplineTargetDistance > TargetSplinePos.CurrentSpline.SplineLength * 0.5))
			SplineTargetDistance = Math::Abs(TargetSplinePos.CurrentSpline.SplineLength - SplineTargetDistance);
		if (SplineTargetDistance < Settings.ChaseMinRange)
			return true;

		return false;
	}
}
