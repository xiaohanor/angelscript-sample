struct FIslandOverseerLaserAttackPattern
{
	float Speed;
	float SineSpeed;
	float SineMagnitude;
	bool bTrack;
	EIslandOverseerLaserType Type;
}

class UIslandOverseerLaserAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerLaserAttackComponent LaserAttackComp;

	FBasicAIAnimationActionDurations Durations;
	AAIIslandOverseer Overseer;
	FIslandOverseerLaserAttackData Data;

	FIslandOverseerLaserAttackPattern CurrentPattern;
	TArray<FIslandOverseerLaserAttackPattern> Patterns;
	int PatternIndex;

	TArray<float> DisallowedDistances;
	float StartOffset = 600;
	float TargetDistance = 3000;
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Overseer = Cast<AAIIslandOverseer>(Owner);
		Settings = UIslandOverseerSettings::GetSettings(Overseer);
		Data = FIslandOverseerLaserAttackData();
		Owner.GetComponentsByClass(UIslandOverseerLaserAttackEmitter, Data.Lasers);
		LaserAttackComp = UIslandOverseerLaserAttackComponent::Get(Owner);

		TArray<AIslandOverseeerLaserAttackDisallowedPoint> DisallowedPoints = TListedActors<AIslandOverseeerLaserAttackDisallowedPoint>().GetArray();

		AIslandOverseerTowardsChaseMoveSplineContainer Container = TListedActors<AIslandOverseerTowardsChaseMoveSplineContainer>()[0];
		TArray<AActor> Actors;
		Container.GetAttachedActors(Actors);
		Spline = Cast<ASplineActor>(Actors[0]).Spline;

		for(AIslandOverseeerLaserAttackDisallowedPoint Point : DisallowedPoints)
			DisallowedDistances.Add(Spline.GetClosestSplineDistanceToWorldLocation(Point.ActorLocation));

		// {
		// 	FIslandOverseerLaserAttackPattern Pattern1 = FIslandOverseerLaserAttackPattern();
		// 	Pattern1.Speed = 1000;
		// 	Pattern1.Type = EIslandOverseerLaserType::Straight;
		// 	Patterns.Add(Pattern1);
		// }

		{
			FIslandOverseerLaserAttackPattern Pattern = FIslandOverseerLaserAttackPattern();
			Pattern.Speed = 500;
			Pattern.SineSpeed = 10;
			Pattern.SineMagnitude = 0.15;
			Pattern.Type = EIslandOverseerLaserType::Sine;
			Patterns.Add(Pattern);
		}

		// {
		// 	FIslandOverseerLaserAttackPattern Pattern = FIslandOverseerLaserAttackPattern();
		// 	Pattern.Speed = 500;
		// 	Pattern.bTrack = true;
		// 	Pattern.Type = EIslandOverseerLaserType::Tracking;
		// 	Patterns.Add(Pattern);
		// }		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		for(float DisallowedDistance : DisallowedDistances)
		{
			float CurrentDistance = Spline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);
			float Diff = DisallowedDistance - CurrentDistance;
			if(Diff > 0 && Diff < 2500)
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ReachedTarget())
			return true;
		if(!Data.Lasers[0].bActive && !Data.Lasers[1].bActive)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		CurrentPattern = Patterns[PatternIndex];
		PatternIndex++;
		if(PatternIndex >= Patterns.Num())
			PatternIndex = 0;

		ActivateLaser(Data.Lasers[0]);
		ActivateLaser(Data.Lasers[1]);
		
		Data.Type = CurrentPattern.Type;
		UIslandOverseerEventHandler::Trigger_OnLaserAttackStart(Owner, Data);
	}

	private bool ReachedTarget() const
	{
		if(Data.Lasers[0].Distance < TargetDistance)
			return false;
		if(Data.Lasers[1].Distance < TargetDistance)
			return false;
		return true;
	}

	void ActivateLaser(UIslandOverseerLaserAttackEmitter Laser)
	{
		Laser.Target = Game::Zoe;

		if(Laser.bLeft)
		{
			if(Owner.ActorRightVector.DotProduct(Game::Mio.ActorLocation) < Owner.ActorRightVector.DotProduct(Game::Zoe.ActorLocation))
				Laser.Target = Game::Mio;
		}
		else
		{
			if(Owner.ActorRightVector.DotProduct(Game::Mio.ActorLocation) > Owner.ActorRightVector.DotProduct(Game::Zoe.ActorLocation))
				Laser.Target = Game::Mio;
		}

		FVector LaserStartLocation = Laser.WorldLocation + Owner.ActorForwardVector * StartOffset;

		if(Laser.Target.IsPlayerDead())
			Laser.Target = Laser.Target.OtherPlayer;
		if(Owner.ActorForwardVector.DotProduct(Laser.Target.ActorLocation - LaserStartLocation) < 0)
			Laser.Target = Laser.Target.OtherPlayer;

		SetLocalTargetLocation(Laser);
		Laser.bActive = true;
		Laser.bPassedTarget = false;
		Laser.TargetTrail = UTargetTrailComponent::GetOrCreate(Laser.Target);
		Laser.InitialTrailLocal = Overseer.ActorTransform.InverseTransformPosition(LaserStartLocation);
		Laser.InitialTrailLocal.Z = 0;
		Laser.Direction = (Laser.Target.ActorLocation - Laser.WorldLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		Laser.Distance = 0;
		Laser.Sine = 0;
		Laser.BeamWidth = 15;
		Laser.AccBeamWidth.SnapTo(Laser.BeamWidth);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandOverseerEventHandler::Trigger_OnLaserAttackStop(Owner, Data);
	}

	private void SetLocalTargetLocation(UIslandOverseerLaserAttackEmitter Laser)
	{
		FVector LocalDirection = (Laser.Target.ActorLocation - Laser.WorldLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		LocalDirection = LocalDirection.ClampInsideCone(Owner.ActorForwardVector, 70);
		Laser.EndLocation = Laser.WorldLocation + LocalDirection * TargetDistance;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bool bBothPassedTarget = true;
		for(UIslandOverseerLaserAttackEmitter Laser : Data.Lasers)
		{
			if(!Laser.bPassedTarget)
				bBothPassedTarget = false;
		}

		for(UIslandOverseerLaserAttackEmitter Laser : Data.Lasers)
		{
			if(!Laser.bActive)
				continue;

			FVector TargetLocation = Laser.TargetTrail.GetTrailLocation(0.5);
			FVector InitialTrailLocation = Overseer.ActorTransform.TransformPosition(Laser.InitialTrailLocal);

			Laser.TrailStart = Laser.WorldLocation;
			Laser.Direction = (TargetLocation - Laser.WorldLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
			Laser.Direction = Laser.Direction.ClampInsideCone(Owner.ActorForwardVector, 70);

			if(ActiveDuration < 1)
			{
				Laser.AccBeamWidth.AccelerateTo(75, 1, DeltaTime);
				Laser.BeamWidth = Laser.AccBeamWidth.Value;
				SetLocalTargetLocation(Laser);
			}
			else
			{
				Laser.Distance += DeltaTime * CurrentPattern.Speed;
				Laser.Sine += DeltaTime * CurrentPattern.SineSpeed;
			}

			FVector Dir = (Laser.EndLocation - Laser.WorldLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();		
			Dir = (Dir + (Owner.ActorRightVector * CurrentPattern.SineMagnitude * Math::Sin(Laser.Sine))).GetSafeNormal();

			if(CurrentPattern.bTrack && !TargetLocation.IsWithinDist2D(InitialTrailLocation, Laser.Distance))
			{
				FVector BehindLocation = TargetLocation.PointPlaneProject(InitialTrailLocation + Overseer.ActorForwardVector * Laser.Distance, Overseer.ActorForwardVector);
				Dir = (BehindLocation - InitialTrailLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
				SetLocalTargetLocation(Laser);
			}

			Laser.TrailEnd = InitialTrailLocation + Dir * Laser.Distance;

			if(!Laser.bPassedTarget)
			{
				if(Laser.Target.IsPlayerDead())
					Laser.bPassedTarget = true;

				if(Laser.Distance > InitialTrailLocation.Distance(TargetLocation))
					Laser.bPassedTarget = true;
			}

			if(bBothPassedTarget)
			{
				Laser.AccBeamWidth.AccelerateTo(0, 1, DeltaTime);
				Laser.BeamWidth = Laser.AccBeamWidth.Value;

				if(Laser.BeamWidth < SMALL_NUMBER)
					Laser.bActive = false;
			}

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
			Trace.UseLine();
			Trace.IgnoreActor(Owner);
			FHitResult Hit = Trace.QueryTraceSingle(Laser.TrailStart, Laser.TrailEnd);

			Laser.ImpactLocation = Laser.TrailEnd;
			if(Hit.bBlockingHit)
			{
				Laser.ImpactLocation = Hit.Location;
				auto HitPlayer = Cast<AHazePlayerCharacter>(Hit.Actor);
				if ((HitPlayer != nullptr) && HitPlayer.HasControl())
				{
					HitPlayer.DealBatchedDamageOverTime(Settings.LaserAttackPlayerDamagePerSecond * DeltaTime, FPlayerDeathDamageParams(), LaserAttackComp.DamageEffect, LaserAttackComp.DeathEffect);
					HitPlayer.ApplyAdditiveHitReaction(Laser.Direction, EPlayerAdditiveHitReactionType::Small);
					UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(HitPlayer);
				}
			}
		}
	}
}

struct FIslandOverseerLaserAttackData
{
	UPROPERTY(BlueprintReadOnly)
	TArray<UIslandOverseerLaserAttackEmitter> Lasers;

	UPROPERTY(BlueprintReadOnly)
	EIslandOverseerLaserType Type;
}

enum EIslandOverseerLaserType
{
	Straight,
	Sine,
	Tracking
}