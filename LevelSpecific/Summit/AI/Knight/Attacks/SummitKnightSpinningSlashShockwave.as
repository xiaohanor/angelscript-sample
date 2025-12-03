class USummitKnightSpinningSlashShockwaveLauncher : UBasicAIProjectileLauncherComponent
{
}

class ASummitKnightSpinningSlashShockwave : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBasicAIProjectileComponent ProjectileComp;

	UPROPERTY(DefaultComponent)
	UHazeActorRespawnableComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	USummitKnightSettings Settings;
	USummitKnightComponent KnightComp;

	TArray<AHazePlayerCharacter> PotentialTargets;
	float Radius;
	float Speed;
	float StartExpireTime;
	FHazeAcceleratedFloat TrailingEdgesAngle;
	FVector PrevArcStart;
	FVector PrevArcEnd;

	void Launch()
	{
		Settings = USummitKnightSettings::GetSettings(ProjectileComp.Launcher);
		KnightComp = USummitKnightComponent::Get(ProjectileComp.Launcher);
		ActorLocation = KnightComp.GetArenaLocation(ActorLocation) + FVector(0.0, 0.0, -50.0);
		ActorRotation = FRotator::MakeFromZX(FVector::UpVector, KnightComp.Arena.Center - ActorLocation);
		PotentialTargets = Game::Players;

		Speed = ProjectileComp.Velocity.Size();
		Radius = 1000.0;
		TrailingEdgesAngle.SnapTo(0.0);

		// We'll expire when encompassing all of arena
		float ExpectedLifeTime = Math::Max(2.0, (KnightComp.Arena.Radius + ActorLocation.Dist2D(KnightComp.Arena.Center) - Radius) / Speed);
		USummitKnightSpinningSlashShockwaveEventHandler::Trigger_OnLaunch(this, FKnightSpinningSlashShockwaveParams(Spline, ExpectedLifeTime));

		// Backup time, will be reduced when arena is fully encompassed
		StartExpireTime = Time::GameTimeSeconds + ExpectedLifeTime + 5.0;

		ForceFeedback::PlayWorldForceFeedback(ForceFeedback::Default_Medium, ActorLocation, false, this, 1000, 4000);
		for(AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 5000);
	}

	void UpdateSpline(float DeltaTime)
	{
		if (DeltaTime < SMALL_NUMBER)
			return;

		FTransform WorldToLocal = ActorTransform.Inverse();
		Spline.SplinePoints.SetNum(3);
		FVector ArcStart, StartTangent;
		FVector ArcEnd, EndTangent;
		FVector ArenaCenterLocal = WorldToLocal.TransformPosition(KnightComp.Arena.Center);
		ArenaCenterLocal.Z = 0.0;
		float Dist = ArenaCenterLocal.Size2D();
		FVector Fwd = ArenaCenterLocal / Dist;
		FVector Side = Fwd.CrossProduct(FVector::UpVector);
		float ArenaRadius = KnightComp.Arena.Radius;
		if (Dist > Radius + ArenaRadius - 0.1)
		{
			// Shockwave is outside arena, use shortish front arc only
			ArcStart = (Fwd * 2.0 - Side * 1.0).GetSafeNormal2D() * Radius;
			ArcEnd = (Fwd * 2.0 + Side * 1.0).GetSafeNormal2D() * Radius;
		}
		 else if (Dist < ArenaRadius - Radius)
		{
			// Shockwave is wholly inside arena, go almost full circle
			ArcStart = (-Fwd * 2.0 - Side * 1.0).GetSafeNormal2D() * Radius;
			ArcEnd = (-Fwd * 2.0 + Side * 1.0).GetSafeNormal2D() * Radius;
		}
		else if (Dist < Radius - ArenaRadius + 0.1)
		{
			// Shockwave encompasses arena, maintain current arc
			ArcStart = PrevArcStart;
			ArcEnd = PrevArcEnd;
		}
		else
		{
			// Shockwave intersects arena in two places
			float DistToIntersectCenter = ((Math::Square(Radius) - Math::Square(ArenaRadius) + Math::Square(Dist)) * 0.5 / Dist);
			FVector IntersectCenter = Fwd * DistToIntersectCenter;
			float IntersectHalfWidth = Math::Sqrt(Math::Max(Math::Square(Radius) - Math::Square(DistToIntersectCenter), 0.0));
			ArcStart = IntersectCenter;
			ArcStart.X += IntersectHalfWidth * Fwd.Y; 
			ArcStart.Y += IntersectHalfWidth * Fwd.X; 
			ArcEnd = IntersectCenter;
			ArcEnd.X -= IntersectHalfWidth * Fwd.Y; 
			ArcEnd.Y -= IntersectHalfWidth * Fwd.X; 
			TrailingEdgesAngle.AccelerateTo(40.0 * Math::Square(0.5 * ArcStart.X / Dist), 0.2, DeltaTime);
		}

		float StartToCenterCircleDist = Math::Acos(Fwd.DotProduct(ArcStart.GetSafeNormal2D())) * Radius;
		StartTangent = ArcStart.CrossProduct(FVector::UpVector).GetSafeNormal2D() * StartToCenterCircleDist;
		float CenterToEndCircleDist = Math::Acos(Fwd.DotProduct(ArcEnd.GetSafeNormal2D())) * Radius;
		EndTangent = ArcEnd.CrossProduct(FVector::UpVector).GetSafeNormal2D() * CenterToEndCircleDist;

		// Main spline arc spanning across the arena
		Spline.SplinePoints[0].RelativeLocation = ArcStart; 
		Spline.SplinePoints[0].ArriveTangent = StartTangent; 
		Spline.SplinePoints[0].LeaveTangent = StartTangent;  
		Spline.SplinePoints[0].RelativeRotation = StartTangent.ToOrientationQuat();
		Spline.SplinePoints[0].bOverrideTangent = true;
		Spline.SplinePoints[1].RelativeLocation = Fwd * Radius; 
		Spline.SplinePoints[1].ArriveTangent = Side * StartToCenterCircleDist; 
		Spline.SplinePoints[1].LeaveTangent = Side * CenterToEndCircleDist;  
		Spline.SplinePoints[1].RelativeRotation = Side.ToOrientationQuat();
		Spline.SplinePoints[1].bOverrideTangent = true;
		Spline.SplinePoints[2].RelativeLocation = ArcEnd;   
		Spline.SplinePoints[2].ArriveTangent = EndTangent;   
		Spline.SplinePoints[2].LeaveTangent = EndTangent;   
		Spline.SplinePoints[2].RelativeRotation = EndTangent.ToOrientationQuat();
		Spline.SplinePoints[2].bOverrideTangent = true;

		if (TrailingEdgesAngle.Value > SMALL_NUMBER)
		{
			// At each end of spline some effects remain along the sides of the arena where the arc was dragged along
			FHazeSplinePoint Before;
			Before.RelativeLocation = ArenaCenterLocal + (ArcStart - ArenaCenterLocal).RotateAngleAxis(TrailingEdgesAngle.Value, FVector::UpVector); 
			float TrailingEdgeDist = ArcStart.Dist2D(Before.RelativeLocation);
			Before.ArriveTangent = FVector::UpVector.CrossProduct(ArenaCenterLocal - Before.RelativeLocation).GetSafeNormal2D() * TrailingEdgeDist; 
			Before.LeaveTangent = Before.ArriveTangent;  
			Before.RelativeRotation = Before.ArriveTangent.ToOrientationQuat();
			Before.bOverrideTangent = true;
			Spline.SplinePoints[0].ArriveTangent = (Spline.SplinePoints[0].LeaveTangent + FVector::UpVector.CrossProduct(ArenaCenterLocal - ArcStart)).GetSafeNormal2D() * TrailingEdgeDist;
			FHazeSplinePoint After;
			After.RelativeLocation = ArenaCenterLocal + (ArcEnd - ArenaCenterLocal).RotateAngleAxis(-TrailingEdgesAngle.Value, FVector::UpVector);  
			After.ArriveTangent = FVector::UpVector.CrossProduct(ArenaCenterLocal - After.RelativeLocation).GetSafeNormal2D() * TrailingEdgeDist;
			After.LeaveTangent = After.ArriveTangent;  
			After.RelativeRotation = After.ArriveTangent.ToOrientationQuat();
			After.bOverrideTangent = true;
			Spline.SplinePoints[2].LeaveTangent = (Spline.SplinePoints[2].ArriveTangent + FVector::UpVector.CrossProduct(ArenaCenterLocal - ArcEnd)).GetSafeNormal2D() * TrailingEdgeDist;
			Spline.SplinePoints.Insert(Before, 0);
			Spline.SplinePoints.Add(After);
		}

		Spline.UpdateSpline();

		PrevArcStart = ArcStart;
		PrevArcEnd = ArcEnd;
	}

	// Projectile will start ticking when launched and will be disabled when it expires
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!ProjectileComp.bIsLaunched)
			return;

		if (Time::GameTimeSeconds > StartExpireTime + 5.0)	
		{
			ProjectileComp.Expire();
			return;
		}

		if (Time::GameTimeSeconds > StartExpireTime)
		{
			UpdateSpline(DeltaTime);
			return; // Let effects die out
		}

		// Expand inexorably dealing damage to targets
		// Local simulation, effect should be pretty consistent on both sides in network
		Radius += Speed * DeltaTime;
		UpdateSpline(DeltaTime);

		// Deal damage
		for (int i = PotentialTargets.Num() - 1; i >= 0; i--)
		{
			if (!PotentialTargets[i].HasControl())
				continue;
			// Is shockwave passing us by?
			FVector SplineLoc = Spline.GetClosestSplineWorldLocationToWorldLocation(PotentialTargets[i].ActorLocation);
			if (SplineLoc.IsWithinDist(PotentialTargets[i].ActorLocation, Settings.SpinningSlashShockwaveHeight))
			{
				HitPlayer(PotentialTargets[i]);
				PotentialTargets.RemoveAtSwap(i);
			}
		}

		if (Radius > KnightComp.Arena.Radius + ActorLocation.Dist2D(KnightComp.Arena.Center))
			StartExpiring(); // Shockwave has encompassed the entire arena

		for(AHazePlayerCharacter Player : Game::Players)
		{
			FVector SplineLoc = Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
			const float EffectDistance = 1000;
			float Distance = SplineLoc.Distance(Player.ActorLocation);
			if(Distance < EffectDistance)
			{
				float FFFrequency = 200.0;
				float FFIntensity = 1;
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * FFFrequency) * FFIntensity;
				Player.SetFrameForceFeedback(FF, 1 - Distance / EffectDistance);
			}
		}

#if EDITOR
		// ProjectileComp.Launcher.bHazeEditorOnlyDebugBool = true
		if (ProjectileComp.Launcher.bHazeEditorOnlyDebugBool)
		{
			Spline.DrawDebug(100, FLinearColor::Purple, 100.0);
		}
#endif		
	}

	void HitPlayer(AHazePlayerCharacter Player)
	{
		// Note that player damage and stumbles are networked so we need only make sure effects are replicated.
		Player.DealTypedDamage(KnightComp.Owner, Settings.SpinningSlashShockwaveDamage, EDamageEffectType::Explosion, EDeathEffectType::Explosion, false);

		if (Settings.SpinningSlashShockwaveStumbleHeight > 0.0)
		{
			// Throw dragon up in the air, to regain control while falling
			UTeenDragonStumbleComponent StumbleComp = UTeenDragonStumbleComponent::GetOrCreate(Player);		
			if (Time::GetGameTimeSince(StumbleComp.LastStumbleTime) > 0.0)
			{
				FTeenDragonStumble Stumble;
				Stumble.Duration = 0.5;
				float Distance = Settings.SpinningSlashShockwaveStumbleHeight * 0.8;
				Stumble.Move = (ProjectileComp.Velocity.GetSafeNormal2D() * 0.2 + FVector::UpVector * 0.8) * Distance;
				Stumble.ArcHeight = Settings.SpinningSlashShockwaveStumbleHeight - Distance;
				Stumble.Apply(Player);
			}
		}

		if (Player.HasControl())
			KnightComp.CrumbShockwaveHitPlayerEffect(Player, Settings.SpinningSlashShockwaveDamage, (ProjectileComp.Velocity.GetSafeNormal2D() + FVector::UpVector) * 0.5);	
	}

	void StartExpiring()
	{
		USummitKnightSpinningSlashShockwaveEventHandler::Trigger_OnExpired(this);
		StartExpireTime = Time::GameTimeSeconds;
	}	
}

UCLASS(Abstract)
class USummitKnightSpinningSlashShockwaveEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLaunch(FKnightSpinningSlashShockwaveParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExpired() {}

	UFUNCTION()
	void DrawDebugSpline()
	{
		auto Shockwave = Cast<ASummitKnightSpinningSlashShockwave>(Owner);
		if (!Shockwave.ProjectileComp.bIsLaunched)
			return;
		UHazeSplineComponent Spline = Shockwave.Spline; 
		Spline.RelativeLocation = FVector(0.0, 0.0, 100.0);
		Spline.DrawDebug(100, FLinearColor::LucBlue, 100.0);
		Spline.RelativeLocation = FVector(0.0, 0.0, 0.0);
	}
}

struct FKnightSpinningSlashShockwaveParams
{
	UPROPERTY()
	UHazeSplineComponent Spline;

	UPROPERTY()
	float LifeTime = 5.0;

	FKnightSpinningSlashShockwaveParams(UHazeSplineComponent WaveSpline, float ExpectedLifeTime)
	{
		Spline = WaveSpline;
		LifeTime = ExpectedLifeTime;
	}
}
