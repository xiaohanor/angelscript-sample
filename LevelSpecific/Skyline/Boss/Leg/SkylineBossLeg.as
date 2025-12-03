asset SkylineBossLegSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineBossLegDestroyedCapability);
};

struct FSkylineBossFootSyncedPosition
{
	FVector Location;
	FRotator Rotation;
};

UCLASS(NotBlueprintable)
class USkylineBossFootSyncedPositionComponent : UHazeCrumbSyncedStructComponent
{
	default SyncRate = EHazeCrumbSyncRate::Standard;

	void InterpolateValues(FSkylineBossFootSyncedPosition& OutValue, FSkylineBossFootSyncedPosition A, FSkylineBossFootSyncedPosition B, float Alpha) const
	{
		OutValue.Location = Math::Lerp(A.Location, B.Location, Alpha);
		OutValue.Rotation = Math::LerpShortestPath(A.Rotation, B.Rotation, Alpha);
	}
};

UCLASS(Abstract)
class ASkylineBossLeg : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = true;
	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

//	UPROPERTY(DefaultComponent)
//	UStaticMeshComponent BikeImpactMesh;

//	UPROPERTY(DefaultComponent, Attach = FootPivot)
//	USceneComponent DamagePointsPivot;

//	UPROPERTY(DefaultComponent, Attach = FootPivot)
//	UGravityBikeFreeTargetFocusCameraTargetComponent FocusCameraTargetComp;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponTargetableComponent WeaponTargetableComp;

	UPROPERTY(DefaultComponent)
	USkylineBossFootSyncedPositionComponent FootSyncedPositionComp; 

	UPROPERTY(DefaultComponent, Attach = WeaponTargetableComp)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent, Attach = OutlineComp)
	UHazeSkeletalMeshComponentBase OutlineSkelMesh;
	default OutlineSkelMesh.CastShadow = false;
	default OutlineSkelMesh.bVisibleInReflectionCaptures = false;
	default OutlineSkelMesh.bVisibleInRealTimeSkyCaptures = false;
	default OutlineSkelMesh.bRenderInMainPass = false;
	default OutlineSkelMesh.bRenderInDepthPass = false;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent ProjectileResponseComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;
	default HealthComp.MaxHealth = 45.0;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SkylineBossLegSheet);

	UPROPERTY(DefaultComponent)
	UHazeDecalComponent ShadowDecal;
	default ShadowDecal.SetAbsolute(true, true, false);

	UPROPERTY(DefaultComponent)
	UGravityBikeFreeImpactResponseComponent BikeImpactComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UMovementInstigatorLogComponent MovementInstigatorLogComp;
#endif

	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;

	UPROPERTY(EditAnywhere)
	UMaterialInterface HealthLightMaterial;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	UMaterialInstanceDynamic HealthLightMID;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor MaxHealthColor = FLinearColor::Green;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor MinHealthColor = FLinearColor::Red;

	UPROPERTY(BlueprintReadOnly)
	ASkylineBoss Boss;

	USkylineBossLegComponent OwningLegComp;
	private FVector AnimationTargetLocation;
	private FRotator AnimationTargetRotation;

	bool bPlacingStarted = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WeaponTargetableComp.Disable(this);

		UBasicAIHealthBarSettings::SetHealthBarAttachComponentName(this, n"FootPivot", this);
		UBasicAIHealthBarSettings::SetHealthBarOffset(this, FVector::UpVector * 1800.0, this);

//		HealthLightMID = Material::CreateDynamicMaterialInstance(this, HealthLightMaterial);
		HealthLightMID = Material::CreateDynamicMaterialInstance(this, Boss.Mesh.GetMaterial(2));

		ActorScale3D = Boss.ActorScale3D;

		ProjectileResponseComponent.OnImpact.AddUFunction(this, n"HandleProjectileImpact");
	
		BikeImpactComp.OnImpact.AddUFunction(this, n"HandleBikeImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateHealthLight();

		KillPlayersUnderFoot();

		PlaceShadowDecal();

#if EDITOR
		TickTemporalLog();
#endif
	}

	void KillPlayersUnderFoot()
	{
		for (auto Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;
			
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
			Trace.UseBoxShape(100, 20, 50, Player.ActorQuat);
			//Trace.DebugDrawOneFrame();

			auto Overlaps = Trace.QueryOverlaps(Player.ActorLocation).BlockHits;
			for (auto& Overlap : Overlaps)
			{
				if(Overlap.Component.Owner == this)
				{
					if(bPlacingStarted)
						Player.KillPlayer(FPlayerDeathDamageParams(-FVector::UpVector, NewForceScale = 15.0), Boss.DeathDamageComp.LargeObjectDeathEffect);
				}
			}
		}
	}

	void SetMaterial(FName SlotName)
	{
		Boss.Mesh.SetMaterialByName(SlotName, HealthLightMID);
	}

	UFUNCTION(BlueprintPure)
	FLinearColor GetHealthLightColor() property
	{
		float Alpha = HealthComp.GetHealthFraction();

		if (Alpha <= 0.0)
			return FLinearColor::Black;

//		LightColor = FLinearColor::Red;
//		FLinearColor LightColor = FLinearColor::LerpUsingHSV(MinHealthColor, MaxHealthColor, Alpha);
		FLinearColor LightColor = Math::Lerp(MinHealthColor, MaxHealthColor, Alpha);
		LightColor *= ((Math::Sin(Time::GameTimeSeconds * 16.0 * (1.0 - Alpha)) + 1.0) * 0.5) * 10.0;

		return LightColor;
	}

	private void UpdateHealthLight()
	{
		HealthLightMID.SetVectorParameterValue(n"EmissiveTint", HealthLightColor);
	}

	private void PlaceShadowDecal()
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(this);
		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation - FVector::UpVector * 10000.0);

		ShadowDecal.WorldLocation = HitResult.Location;
	}

	UFUNCTION(BlueprintPure)
	FVector GetFootLocation() const
	{
		return ActorLocation;
	}

	UFUNCTION(BlueprintPure)
	FRotator GetFootRotation() const
	{
		return ActorRotation;
	}

	UFUNCTION(BlueprintPure)
	void GetFootLocationAndRotation(FVector&out OutLocation, FRotator&out OutRotation) const
	{
		OutLocation = ActorLocation;
		OutRotation = ActorRotation;
	}

	UFUNCTION(BlueprintPure)
	void GetFootAnimationTargetTransform(FVector&out OutLocation, FRotator&out OutRotation) const
	{
		OutLocation = AnimationTargetLocation;
		OutRotation = AnimationTargetRotation;
	}

	void SetFootAnimationTargetLocationAndRotation(FVector Location, FRotator Rotation)
	{
		AnimationTargetLocation = Location;
		AnimationTargetRotation = Rotation;
	}

	UFUNCTION()
	private void HandleProjectileImpact(FGravityBikeWeaponImpactData ImpactData)
	{
		if (IsDestroyed())
			return;
		
		HealthComp.TakeDamage(ImpactData.Damage, EDamageType::Default, ImpactData.Instigator);
		Boss.HealthComponent.TakeDamage(ImpactData.Damage * 0.1, EDamageType::Default, ImpactData.Instigator);
	}

	UFUNCTION()
	private void HandleBikeImpact(AGravityBikeFree GravityBike, FGravityBikeFreeOnImpactData Data)
	{
/*
		if (Data.Component == BikeImpactMesh)
			GravityBike.Driver.KillPlayer();
*/
	}

	UFUNCTION()
	void RestoreLeg()
	{
		HealthComp.Reset();
	}

	UFUNCTION(BlueprintPure)
	ESkylineBossLeg GetLegIndex() const property
	{
		return OwningLegComp.LegIndex;
	}

	UFUNCTION(BlueprintPure)
	bool IsDestroyed() const
	{
		return HealthComp.IsDead();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnLegDamaged() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnLegRestored() {}

#if EDITOR
	private void TickTemporalLog()
	{
		FString Category;
		FTemporalLog TemporalLog = GetTemporalLog(Category);

		TemporalLog.Value(f"{Category};Actor", this);
		TemporalLog.Value(f"{Category};Leg Order", f"{Boss.LegOrder[LegIndex]:n}");
		TemporalLog.Value(f"{Category};bPlacingStarted", bPlacingStarted);

		TemporalLog.Transform(f"{Category};Foot Transform", ActorTransform, 5000, 100);

		TemporalLog.Value(f"{Category};Health;Max Health", HealthComp.MaxHealth);
		TemporalLog.Value(f"{Category};Health;Current Health", HealthComp.CurrentHealth);
		TemporalLog.Value(f"{Category};Health;Is Dead", HealthComp.IsDead());
	}

	FTemporalLog GetTemporalLog(FString&out LegCategory) const
	{
		LegCategory = f"0{int(LegIndex)}#Leg {int(LegIndex)} ({LegIndex:n})";
		return TEMPORAL_LOG(Boss, "Legs");
	}

	FLinearColor GetLegDebugColor() const
	{
		switch(LegIndex)
		{
			case ESkylineBossLeg::Left:
				return FLinearColor::Blue;

			case ESkylineBossLeg::Right:
				return FLinearColor::Green;

			case ESkylineBossLeg::Center:
				return FLinearColor::Red;
		}
	}
#endif
}