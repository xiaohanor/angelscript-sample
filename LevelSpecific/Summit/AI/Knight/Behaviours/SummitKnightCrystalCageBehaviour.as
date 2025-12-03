class USummitKnightCrystalCageBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USummitKnightSettings Settings;
	USummitKnightCrystalCageLauncher Launcher;
	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightStageComponent StageComp;
	
	FBasicAIAnimationActionDurations Durations;
	float LaunchTime;
	ASummitKnightCrystalCage ActiveCage;
	AHazePlayerCharacter Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		Launcher = USummitKnightCrystalCageLauncher::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::Get(Owner);
		StageComp = USummitKnightStageComponent::Get(Owner);
		Target = Game::Mio;

		Launcher.PrepareProjectiles(1);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Launcher.PrepareProjectiles(1);

		//USummitKnightEventHandler::Trigger_OnTelegraphCrystalWall(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));

		Durations.Telegraph = Settings.CrystalWallTelegraphDuration;
		Durations.Anticipation = Settings.CrystalWallAnticipationDuration;
		Durations.Action = Settings.CrystalWallAttackDuration;
		Durations.Recovery = Settings.CrystalWallRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SummonCritters, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::SummonCritters, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		LaunchTime = Durations.Telegraph + Durations.Anticipation;

		ActiveCage = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Target);

		if (HasControl() && (ActiveDuration > LaunchTime))
		{
			FVector ArcStart; 
			FVector ArcStartTangent; 
			FVector ArcEnd; 
			FVector ArcEndTangent;
			FVector TargetLoc = KnightComp.Arena.GetClampedToArena(Target.ActorLocation);
			FVector ArenaCenter = KnightComp.Arena.Center;
			float Dist = TargetLoc.Dist2D(ArenaCenter);
			FVector Fwd = (ArenaCenter - TargetLoc) / Dist;
			FVector Side = Fwd.CrossProduct(FVector::UpVector);
			float CageRadius = Settings.CrystalCageRadius;
			float ArenaRadius = KnightComp.Arena.Radius + 200.0;
			if (Dist > CageRadius + ArenaRadius - 0.1)
			{
				// Cage is wholly outside arena. Should not happen but let's clamp cage to side of arena just the same.
				check(false);
				ArcStart = KnightComp.Arena.GetClampedToArena(TargetLoc + Side * CageRadius);
				ArcEnd = KnightComp.Arena.GetClampedToArena(TargetLoc - Side * CageRadius);
			}
			else if (Dist < ArenaRadius - CageRadius)
			{
				// Cage is wholly inside arena, go full circle
				ArcStart = TargetLoc + Fwd * CageRadius + Side * 0.1;
				ArcEnd = TargetLoc + Fwd * CageRadius - Side * 0.1;
			}
			else if (Dist < CageRadius - ArenaRadius + 0.1)
			{
				// Cage encompasses arena, full circle around arena edge
				ArcStart = ArenaCenter + Fwd * (ArenaRadius - 200.0) - Side * 0.1;
				ArcEnd = ArenaCenter + Fwd * (ArenaRadius - 200.0) + Side * 0.1;
			}
			else
			{
				// Cage intersects arena in two places
				float DistToIntersectCenter = ((Math::Square(CageRadius) - Math::Square(ArenaRadius) + Math::Square(Dist)) * 0.5 / Dist);
				FVector IntersectCenter = TargetLoc + Fwd * DistToIntersectCenter;
				float IntersectHalfWidth = Math::Sqrt(Math::Max(Math::Square(CageRadius) - Math::Square(DistToIntersectCenter), 0.0));
				ArcStart = IntersectCenter;
				ArcStart.X += IntersectHalfWidth * Fwd.Y; 
				ArcStart.Y += IntersectHalfWidth * Fwd.X; 
				ArcEnd = IntersectCenter;
				ArcEnd.X -= IntersectHalfWidth * Fwd.Y; 
				ArcEnd.Y -= IntersectHalfWidth * Fwd.X; 

			}

			float StartToCenterCircleDist = Math::Acos(Fwd.DotProduct(ArcStart.GetSafeNormal2D())) * CageRadius;
			float CenterToEndCircleDist = Math::Acos(Fwd.DotProduct(ArcEnd.GetSafeNormal2D())) * CageRadius;
			ArcStartTangent = (ArcStart - TargetLoc).CrossProduct(FVector::UpVector).GetSafeNormal2D() * StartToCenterCircleDist * 1.5;
			ArcEndTangent = (ArcEnd - TargetLoc).CrossProduct(FVector::UpVector).GetSafeNormal2D() * CenterToEndCircleDist * 1.5;

			CrumbLaunch(ArcStart, ArcStartTangent, ArcEnd, ArcEndTangent, TargetLoc + Fwd * CageRadius * 3.0);
		}

// Debug::DrawDebugLine(IntersectCenter + o, IntersectCenter + o + FVector(0,0,500), FLinearColor::Yellow);				
// Debug::DrawDebugLine(ArcStart + o, ArcStart + o + FVector(0,0,500), FLinearColor::Green);				
// Debug::DrawDebugLine(ArcEnd + o, ArcEnd + o + FVector(0,0,500), FLinearColor::LucBlue);				
// Debug::DrawDebugCircle(TargetLoc + o, CageRadius, 22, FLinearColor::Red, 20);				
// Debug::DrawDebugCircle(ArenaCenter + o, ArenaRadius, 22, FLinearColor::Green, 20);				
// Debug::DrawDebugArrow(TargetLoc + o, TargetLoc + o + Fwd * 1000);
// Debug::DrawDebugArrow(ArcStart + o*5, ArcStart + o*5 + ArcStartTangent, 20, FLinearColor::Purple, 10);
// Debug::DrawDebugArrow(ArcEnd + o*5, ArcEnd + o*5 + ArcEndTangent, 20, FLinearColor::Purple, 10);
// BezierCurve::DebugDraw_3CP(ArcStart, ArcStart + ArcStartTangent, TargetLoc + Fwd * CageRadius * 3.0, ArcEnd - ArcEndTangent, ArcEnd, FLinearColor::Yellow, 20);		
	}


	UFUNCTION(CrumbFunction)
	void CrumbLaunch(FVector ArcStart, FVector ArcStartTangent, FVector ArcEnd, FVector ArcEndTangent, FVector FrontPoint)
	{
		LaunchTime = BIG_NUMBER;
		UBasicAIProjectileComponent Projectile = Launcher.Launch(Launcher.WorldRotation.ForwardVector * Settings.CrystalWallMoveSpeedTarget * 0.1);
		ActiveCage = Cast<ASummitKnightCrystalCage>(Projectile.Owner);	
		ActiveCage.Spawn(Target, KnightComp.Arena, ArcStart, ArcStartTangent, ArcEnd, ArcEndTangent, FrontPoint);
		UHazeActorRespawnableComponent::Get(ActiveCage).OnUnspawn.AddUFunction(this, n"OnCageExpire");
		//USummitKnightEventHandler::Trigger_OnLaunchCrystalWall(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
	}	


	UFUNCTION()
	private void OnCageExpire(AHazeActor RespawnableActor)
	{
		UHazeActorRespawnableComponent::Get(RespawnableActor).OnUnspawn.UnbindObject(this);
		if (RespawnableActor != ActiveCage)
			return;
		ActiveCage = nullptr;
	}
}

