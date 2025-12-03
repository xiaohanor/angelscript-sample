UCLASS(Abstract)
class AMoonMarketLightningStrike : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent Capsule;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent PointLight;

	AHazePlayerCharacter OwningPlayer;
	float SpawnTime;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve LightIntensityCurve;

	UPROPERTY()
	const float ScreenShakeOuterRadius;

	UPROPERTY()
	UNiagaraSystem ImpactVfx;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY()
	float Duration = 0.2;

	float LightIntenstiy;

	FVector ImpactPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnTime = Time::GameTimeSeconds;
		LightIntenstiy = PointLight.Intensity;

		for(auto Player : Game::GetPlayers())
		{
			FVector Epicenter = ActorLocation;
			Player.PlayWorldCameraShake(CameraShakeClass, this, Epicenter, Capsule.CapsuleRadius, ScreenShakeOuterRadius, 1.0);
		}

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactVfx, ImpactPoint);

		FHazeTraceSettings ImpactTraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		ImpactTraceSettings.UseCapsuleShape(Capsule.CapsuleRadius, Capsule.CapsuleHalfHeight);
		ImpactTraceSettings.IgnoreActor(this);	
		ImpactTraceSettings.IgnoreActor(OwningPlayer);

		if(OwningPlayer.HasControl())
		{
			FOverlapResultArray Hits = ImpactTraceSettings.QueryOverlaps(Capsule.WorldLocation);

			for(auto Hit : Hits)
			{
				if(Hit.Actor == nullptr)
					continue;
				
				UMoonMarketThunderStruckComponent ThunderResponseComp = UMoonMarketThunderStruckComponent::Get(Hit.Actor);
				if(ThunderResponseComp == nullptr)
					continue;

				ThunderResponseComp.NetStrike((ThunderResponseComp.Owner.ActorLocation - ActorLocation).VectorPlaneProject(FVector::UpVector).GetSafeNormal(), OwningPlayer);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float Lifetime = Time::GetGameTimeSince(SpawnTime);

		if(Lifetime > Duration)
			DestroyActor();

		const float Percentage = Lifetime / Duration;
		PointLight.SetIntensity(LightIntensityCurve.GetFloatValue(Percentage) * LightIntenstiy);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, ScreenShakeOuterRadius);
	}
#endif
};