struct FSummitKnightTargetCurve
{
	FVector Start;
	FVector Control;
	FVector End;
}

class USummitKnightHomingFireballsBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	USummitKnightHomingFireballsLauncher Launcher;
	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;

	FBasicAIAnimationActionDurations Durations;
	float LaunchTime;
	int NumToLaunch;
	int NumLaunched;

	AHazePlayerCharacter CurTarget;
	TPerPlayer<FSummitKnightTargetCurve> TargetCurves;
	TPerPlayer<UTargetTrailComponent> TrailComps;	

	float FireballFlightDurationFactor = 1.0;
	float AnimTimeScale = 1.0;

	USummitKnightHomingFireballsBehaviour(float AnimPlayRate, float ProjectileSpeedFactor)
	{
		AnimTimeScale = AnimPlayRate;
		FireballFlightDurationFactor = 1.0 / Math::Max(0.5, ProjectileSpeedFactor);
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		Launcher = USummitKnightHomingFireballsLauncher::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner); 
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		CurTarget = Game::Zoe;

		TrailComps[Game::Zoe] = UTargetTrailComponent::GetOrCreate(Game::Zoe);
		TrailComps[Game::Mio] = UTargetTrailComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Durations.Telegraph = Settings.HomingFireballsTelegraphDuration;
		Durations.Anticipation = Settings.HomingFireballsAnticipationDuration;
		Durations.Action = Settings.HomingFireballsAttackDuration;
		Durations.Recovery = Settings.HomingFireballsRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::HomingFireballs, NAME_None, Durations);
		Durations.ScaleAll(AnimTimeScale);
		AnimComp.RequestAction(SummitKnightFeatureTags::HomingFireballs, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		LaunchTime = Durations.Telegraph + Durations.Anticipation;
		NumToLaunch = Math::TruncToInt(Durations.Action / Settings.HomingFireballsLaunchInterval);
		NumLaunched = 0;

		USummitKnightEventHandler::Trigger_OnTelegraphHomingFireballs(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		USummitKnightEventHandler::Trigger_OnStopHomingFireballs(Owner);	
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
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > LaunchTime)
		{
			NumLaunched++;
			CurTarget = CurTarget.OtherPlayer;			

			if (NumLaunched == NumToLaunch)
				LaunchTime = BIG_NUMBER;
			else
				LaunchTime += Settings.HomingFireballsLaunchInterval;

			UBasicAIProjectileComponent Projectile = Launcher.Launch(Launcher.WorldRotation.ForwardVector * 1000.0);	
			Projectile.Target = CurTarget;
			Cast<ASummitKnightHomingFireball>(Projectile.Owner).LaunchAt(GetTargetLocation(CurTarget), FireballFlightDurationFactor, Launcher); 

			if (NumLaunched == 1)
				USummitKnightEventHandler::Trigger_OnStartLaunchingHomingFireballs(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
			USummitKnightEventHandler::Trigger_OnLaunchHomingFireball(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
			if (NumLaunched == NumToLaunch)
				USummitKnightEventHandler::Trigger_OnStopLaunchingHomingFireballs(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
		}

		if (Durations.IsBeforeAction(ActiveDuration))
			DestinationComp.RotateTowards(KnightComp.GetSpellFocus());	
	}

	FVector GetTargetLocation(AHazePlayerCharacter Target)
	{
		// Walk the blasts across the players predicted path
		if (NumLaunched == 1)
		{
			// Set up starting points of trail towards players
			BuildTargetCurve(Game::Zoe, TargetCurves[Game::Zoe]); 
			BuildTargetCurve(Game::Mio, TargetCurves[Game::Mio]); 
		}

		float Alpha = NumLaunched / float(NumToLaunch);
		FVector CurLoc = BezierCurve::GetLocation_1CP(TargetCurves[Target].Start, TargetCurves[Target].Control, TargetCurves[Target].End, Alpha);
		CurLoc = KnightComp.Arena.GetClampedToArena(CurLoc, 20.0);
		FVector OwnLoc = Owner.ActorLocation;
		if (CurLoc.IsWithinDist2D(OwnLoc, CurveKnightClearance))
			CurLoc = OwnLoc + (CurLoc - OwnLoc).GetSafeNormal2D() * CurveKnightClearance;				
		return CurLoc;
	}

	const float CurveKnightClearance = 1500.0;
	const float CurveMinStartOffset = 1200.0;
	const float CurveMinWidth = 4000.0;

	void BuildTargetCurve(AHazePlayerCharacter Player, FSummitKnightTargetCurve& TargetCurve)
	{
		FVector KnightLoc = Owner.ActorLocation;
		FVector TargetLoc = KnightComp.Arena.GetAtArenaHeight(Player.ActorLocation);
		FRotator ViewRot = FRotator(0.0, Player.ViewRotation.Yaw, 0.0);
		FVector ViewFwd = ViewRot.ForwardVector;
		FVector ViewRight = ViewRot.RightVector;

		FVector PredictedVelocity = TrailComps[Player].GetAverageVelocity(0.1);
		PredictedVelocity.Z = 0.0;
		if (PredictedVelocity.IsNearlyZero(1.0))
			PredictedVelocity = ViewRight; // This will cause curve to cut through stationary player
		float PredictedSpeed = PredictedVelocity.Size2D();
		FVector PredictedLoc = TargetLoc + PredictedVelocity * (Settings.HomingFireballsFlightDuration + Durations.Action * 1.0);
		PredictedLoc = KnightComp.Arena.GetClampedToArena(PredictedLoc);

		// Start some ways into view which is closest to knight at a distance we should
		float StartOffset = Math::Max(PredictedSpeed * (Settings.HomingFireballsFlightDuration + Settings.HomingFireballsDamageDuration * 0.25), CurveMinStartOffset);
		FVector RightViewLoc = TargetLoc + (ViewFwd + ViewRight) * 0.707 * StartOffset;
		FVector LeftViewLoc = TargetLoc + (ViewFwd - ViewRight) * 0.707 * StartOffset;
		TargetCurve.Start = LeftViewLoc;
		if (RightViewLoc.DistSquared2D(KnightLoc) < LeftViewLoc.DistSquared2D(KnightLoc))
			TargetCurve.Start = RightViewLoc;
		if (TargetCurve.Start.IsWithinDist2D(PredictedLoc, CurveMinWidth * 0.5))
			TargetCurve.Start = PredictedLoc + (TargetCurve.Start - PredictedLoc).GetSafeNormal2D() * CurveMinWidth * 0.5;
		TargetCurve.Start = KnightComp.Arena.GetClampedToArena(TargetCurve.Start);

		// Curve past predicted location	
		TargetCurve.Control = PredictedLoc;

		float StartDist = TargetCurve.Start.Dist2D(PredictedLoc);
		float EndDist = Math::Max(CurveMinWidth * 0.25, CurveMinWidth - StartDist);
		
		FVector EndDir = (PredictedLoc - TargetCurve.Start) / StartDist;
		if (PredictedSpeed > 100.0)
			EndDir = PredictedVelocity.GetSafeNormal2D().CrossProduct(FVector::UpVector);
		if (EndDir.DotProduct(PredictedLoc - TargetCurve.Start) < 0.0)		
			EndDir *= -1.0;
		TargetCurve.End = KnightComp.Arena.GetClampedToArena(PredictedLoc + EndDir * EndDist);
	}
}

