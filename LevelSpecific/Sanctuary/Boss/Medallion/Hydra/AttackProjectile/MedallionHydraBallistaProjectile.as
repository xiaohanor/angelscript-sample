struct FMedallionHydraBallistaProjectileHitPlatformData
{
	ABallistaHydraSplinePlatform TargetPlatform;
	FVector OffsetInPlatformSpace;
	FVector DecalNormal;
}

struct FMedallionHydraBallistaProjectileHitWaterData
{
	float SplineDistanceOffset;
	FVector OffsetToSpline;
}

class AMedallionHydraBallistaProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TelegraphRoot;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UHazeDecalComponent DecalComp;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UGodrayComponent GodRayComp;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	FMedallionHydraBallistaProjectileHitPlatformData HitPlatformData;
	FMedallionHydraBallistaProjectileHitWaterData HitWaterData;
	float CreationTimestamp;
	FVector StartLocation;
	bool bIsHitPlatform = false;

	const float Duration = 3.0;
	const float ArcHeight = 3000.0;
	const float Damage = 0.5;
	const float DamageRadius = 200.0;
	const float ImpulseMultiplier = 2.0;

	private UBallistaHydraActorReferencesComponent BallistaRefs;
	private UMedallionPlayerReferencesComponent MedallionRefsComp;

	UPROPERTY()
	ASanctuaryBossMedallionHydra HydraShooter;

	FHazeRuntimeSpline DebugSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MedallionRefsComp = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);

		if (!bIsHitPlatform)
		{
			BallistaRefs = UBallistaHydraActorReferencesComponent::GetOrCreate(Game::Mio);
			TelegraphRoot.SetAbsolute(true, true);
			TelegraphRoot.SetWorldLocation(FVector::OneVector * 100000.0);
		}
		else
		{
			FVector TelegraphWorldLocation = HitPlatformData.TargetPlatform.ActorLocation + HitPlatformData.OffsetInPlatformSpace;
			TelegraphRoot.SetWorldLocation(TelegraphWorldLocation);
			TelegraphRoot.SetWorldRotation(FRotator::MakeFromZ(HitPlatformData.DecalNormal));
			TelegraphRoot.AttachToComponent(HitPlatformData.TargetPlatform.FloatingComp, NAME_None, EAttachmentRule::KeepWorld);
		}

		CreationTimestamp = Time::GameTimeSeconds;
		StartLocation = ActorLocation;
		BP_Activate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float AliveDuration = Time::GameTimeSeconds - CreationTimestamp; 
		float Alpha = Math::Saturate(AliveDuration / Duration);
		if (bIsHitPlatform)
			HitPlatformFlightUpdate(Alpha);
		else
			HitWaterFlightUpdate(Alpha);

		UpdateTelegraph(Alpha);

		if (Alpha >= 1.0 - KINDA_SMALL_NUMBER)
		{
			if (bIsHitPlatform)
				HitPlatform();
			else
				HitWater();

			for (auto Player : Game::Players)
			{
				if (Player.GetDistanceTo(this) < DamageRadius)
					Player.DamagePlayerHealth(Damage);
			}

			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

			DestroyActor();
		}
	}

	private void UpdateTelegraph(float Alpha)
	{
		float ClampedAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.5), FVector2D(0.0, 1.0), Alpha);
		float CurrentValue = Math::EaseOut(0.0, 1.0, ClampedAlpha, 2.0);
		DecalComp.SetRelativeScale3D(FVector(1.0, CurrentValue, CurrentValue));
		GodRayComp.SetGodrayOpacity(CurrentValue * 0.5);
	}
	
	private void HitPlatformFlightUpdate(float Alpha)
	{
		FVector TargetLocation = HitPlatformData.TargetPlatform.ActorTransform.TransformPosition(HitPlatformData.OffsetInPlatformSpace);
		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		FVector Direction = (Location - ActorLocation).GetSafeNormal(); 

		if (!Direction.IsNearlyZero())
			SetActorRotation(Direction.Rotation());

		SetActorLocation(Location);

		if (SanctuaryBallistaHydraDevToggles::Draw::HydraProjectiles.IsEnabled())
		{
			TArray<FVector> Points;
			Points.Add(StartLocation);
			Points.Add(Math::Lerp(StartLocation, TargetLocation, 0.5) + FVector::UpVector * ArcHeight);
			Points.Add(TargetLocation);
			DebugSpline.SetPoints(Points);
			DebugSpline.DrawDebugSpline();
			Debug::DrawDebugSphere(TargetLocation, 100.0, LineColor = ColorDebug::Ruby, bDrawInForeground = true);
			Debug::DrawDebugString(TargetLocation, "" + HitPlatformData.TargetPlatform.GetName(), ColorDebug::Carrot);
			Debug::DrawDebugArrow(TargetLocation, HitPlatformData.TargetPlatform.ActorLocation, 5.0, ColorDebug::Carrot, bDrawInForeground = true);
		}
	}

	private void HitWaterFlightUpdate(float Alpha)
	{
		float SplineDistance = HitWaterData.SplineDistanceOffset + BallistaRefs.Refs.Spline.LocalSplineDistance;
		FVector ClosestLocation = BallistaRefs.Refs.Spline.Spline.GetWorldLocationAtSplineDistance(SplineDistance);
		FVector TargetLocation = ClosestLocation + HitWaterData.OffsetToSpline;
		FVector Location = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Location.Z += Math::Sin(Alpha * PI) * ArcHeight;

		FVector Direction = (Location - ActorLocation).GetSafeNormal(); 

		if (!Direction.IsNearlyZero())
			SetActorRotation(Direction.Rotation());

		SetActorLocation(Location);

		if (SanctuaryBallistaHydraDevToggles::Draw::HydraProjectiles.IsEnabled())
		{
			TArray<FVector> Points;
			Points.Add(StartLocation);
			Points.Add(Math::Lerp(StartLocation, TargetLocation, 0.5) + FVector::UpVector * ArcHeight);
			Points.Add(TargetLocation);
			DebugSpline.SetPoints(Points);
			DebugSpline.DrawDebugSpline();
			Debug::DrawDebugSphere(TargetLocation, 100.0, LineColor = ColorDebug::Cyan, bDrawInForeground = true);
			Debug::DrawDebugString(TargetLocation, "Water", ColorDebug::Blue);
		}
	}

	private void HitPlatform()
	{
		FVector ImpulseForce = ActorForwardVector * HitPlatformData.TargetPlatform.PlayerWeightComp.PlayerForce * ImpulseMultiplier;
		FauxPhysics::ApplyFauxImpulseToActorAt(HitPlatformData.TargetPlatform, ActorLocation, ImpulseForce);
		BP_HitPlatformExplode();

		FSanctuaryBossMedallionManagerEventProjectileData Params;
		Params.Projectile = this;
		Params.Hydra = HydraShooter;
		Params.StartLocation = StartLocation;	
		Params.ProjectileType = EMedallionHydraProjectileType::BallistaRain;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnProjectileImpact(MedallionRefsComp.Refs.HydraAttackManager, Params);
	}

	private void HitWater()
	{
		FSanctuaryBossMedallionManagerEventProjectileData Params;
		Params.Projectile = this;
		Params.Hydra = HydraShooter;
		Params.StartLocation = StartLocation;	
		Params.ProjectileType = EMedallionHydraProjectileType::BallistaRain;

		UMedallionHydraAttackManagerEventHandler::Trigger_OnProjectileHitWater(MedallionRefsComp.Refs.HydraAttackManager, Params);
		BP_HitWaterSplash();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Activate(){}

	UFUNCTION(BlueprintEvent)
	private void BP_HitPlatformExplode(){}
	UFUNCTION(BlueprintEvent)
	private void BP_HitWaterSplash(){}
};
