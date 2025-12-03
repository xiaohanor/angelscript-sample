UCLASS(Abstract)
class AGravityBikeSplineFlyingEnemy : AGravityBikeSplineEnemy
{
	access Resolver = protected, UGravityBikeSplineFlyingEnemyMovementResolver;

	FHazeAcceleratedQuat AccMeshRotation;
	float DamageImpulseTime = -1;
	float ReflectOffWallTime = -1;

	void AddImpulseAsAngularImpulse(FVector LinearImpulse)
	{
		if(LinearImpulse.IsNearlyZero())
			return;

		const FVector AngularImpulse = ActorUpVector.CrossProduct(LinearImpulse);
		AccMeshRotation.VelocityAxisAngle += AngularImpulse;
	}

	access:Resolver
	void HitImpactResponseComponent(UGravityBikeSplineImpactResponseComponent ResponseComp, FGravityBikeSplineOnImpactData ImpactData)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event("HitImpactResponseComponent");
		TEMPORAL_LOG(this).Value("HitImpactResponseComponent;ResponseComponent", ResponseComp);
		TEMPORAL_LOG(this).Struct("HitImpactResponseComponent;ResponseComponent;ImpactData", ImpactData);
#endif

		if(!HasControl())
			return;

		// Notify the response component of the impact
		ResponseComp.OnImpact.Broadcast(this, ImpactData);
	}

	access:Resolver
	void ApplyHitFlyingEnemy(FVector HitImpulse, FVector HitImpactPoint, AGravityBikeSplineFlyingEnemy FlyingEnemy)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event("ApplyHitFlyingEnemy");

		FTemporalLog SectionLog = TemporalLog.Section("ApplyHitFlyingEnemy");
		SectionLog.DirectionalArrow("HitImpulse", ActorLocation, HitImpulse);
		SectionLog.Point("HitImpactPoint", HitImpactPoint);
		SectionLog.Value("FlyingEnemy", FlyingEnemy);
#endif

		AddImpulseAsAngularImpulse(HitImpulse.GetSafeNormal() * GravityBikeSpline::CarEnemy::WallReflectAngularImpulse);

		FlyingEnemy.AddMovementImpulse(-HitImpulse);
		FlyingEnemy.AddImpulseAsAngularImpulse(HitImpulse.GetSafeNormal() * -GravityBikeSpline::CarEnemy::WallReflectAngularImpulse);

		DamageImpulseTime = Time::GameTimeSeconds;
		FlyingEnemy.DamageImpulseTime = Time::GameTimeSeconds;

		{
			const FGravityBikeSplineFlyingOnHitOtherFlyingEnemyEventData EventData(
				HitImpulse,
				HitImpactPoint,
				FlyingEnemy
			);
			UGravityBikeSplineFlyingEnemyEventHandler::Trigger_OnImpact(this, EventData);
		}

		{
			const FGravityBikeSplineFlyingOnHitOtherFlyingEnemyEventData EventData(
				-HitImpulse,
				HitImpactPoint,
				this
			);
			UGravityBikeSplineFlyingEnemyEventHandler::Trigger_OnImpacted(FlyingEnemy, EventData);
		}
	}

	access:Resolver
	void ExplodeFromImpact()
	{
	}

	access:Resolver
	void ApplyReflectOffWall(FVector ReflectionImpulse, FVector WallImpactPoint, FVector WallImpactNormal)
	{
#if !RELEASE
		TEMPORAL_LOG(this).Event("ApplyReflectOffWall");
		TEMPORAL_LOG(this).DirectionalArrow("ApplyReflectOffWall;ReflectionImpulse", ActorLocation, ReflectionImpulse);
		TEMPORAL_LOG(this).Point("ApplyReflectOffWall;WallImpactPoint", WallImpactPoint);
		TEMPORAL_LOG(this).DirectionalArrow("ApplyReflectOffWall;WallImpactNormal", WallImpactPoint, WallImpactNormal * 500);
#endif

		AddImpulseAsAngularImpulse(ReflectionImpulse.GetSafeNormal() * GravityBikeSpline::CarEnemy::WallReflectAngularImpulse);
		ReflectOffWallTime = Time::GameTimeSeconds;

		const FGravityBikeSplineFlyingEnemyOnReflectOffWallEventData EventData(
			ReflectionImpulse,
			WallImpactPoint,
			WallImpactNormal
		);
		UGravityBikeSplineFlyingEnemyEventHandler::Trigger_OnReflectOffWall(this, EventData);
	}
};