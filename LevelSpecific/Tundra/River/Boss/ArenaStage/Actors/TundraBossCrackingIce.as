event void FOnCrackingIceExploded();
event void FOnCrackingIceCracked();

class ATundraBossCrackingIce : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent IceMesh;
	default IceMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundraBossHomingIceChunk> HomingIceChunks;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionFX;

	UPROPERTY()
	FHazeTimeLike IceOpacityLerpTimelike;
	default IceOpacityLerpTimelike.Duration = 3;

	UPROPERTY()
	FOnCrackingIceExploded OnCrackingIceExploded;

	UPROPERTY()
	FOnCrackingIceCracked OnCrackingIceCracked; 

	UBoxComponent Box;

	float IceOpacityMax = 0.75;
	float IceOpacityFresnelMax = 0.17;
	float IceRefractionMax = 1;

	int NumberOfExplosions = 0;
	int ExplosionsRequired = 5;

	bool bIceHasExploded = false;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent IceCrackAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UHazeAudioEvent IceBreakAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio", Meta = (EditCondition = "IceCrackAudioEvent != nullptr || IceBreakAudioEvent != nullptr"))
	FHazeAudioFireForgetEventParams AudioParams;

	private float AudioEventTriggerDelayTime = 0.25;

	UFUNCTION(NotBlueprintCallable)
	void TriggerIceCrackAudio()
	{
		if(!bIceHasExploded)
		{
			if(IceCrackAudioEvent != nullptr)
				AudioComponent::PostFireForget(IceCrackAudioEvent, AudioParams);
		}
		else
		{
			if(IceBreakAudioEvent != nullptr)
				AudioComponent::PostFireForget(IceBreakAudioEvent, AudioParams);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto IceChunk : HomingIceChunks)
			IceChunk.OnIceChunkExploded.AddUFunction(this, n"OnIceChunkExploded");

		IceOpacityLerpTimelike.BindUpdate(this, n"IceOpacityLerpTimelikeUpdate");

		IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"Opacity", 0);
		IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"OpacityFresnel", 0);
		IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"Refraction", 0);

		AudioParams.AttachComponent = MeshRoot;
	}

	UFUNCTION()
	private void IceOpacityLerpTimelikeUpdate(float CurrentValue)
	{
		IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"Opacity", Math::Lerp(0, IceOpacityMax, CurrentValue));
		IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"OpacityFresnel", Math::Lerp(0, IceOpacityFresnelMax, CurrentValue));
		IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"Refraction", Math::Lerp(0, IceRefractionMax, CurrentValue));
	}

	UFUNCTION()
	private void OnIceChunkExploded(FVector ExplosionLocation)
	{
		//TODO: Rethink this
		if(!HasControl())
			return;

		float X = Math::Abs(ExplosionLocation.X - ActorLocation.X);
		float Y = Math::Abs(ExplosionLocation.Y - ActorLocation.Y);
		
		if(X < 1350 && Y < 1000)
		{
			CrumbShowCracks(ExplosionLocation);
		}
	}

	void LaunchPlayers()
	{
		for(auto Player : Game::GetPlayers())
		{
			float X = Math::Abs(Player.ActorLocation.X - ActorLocation.X);
			float Y = Math::Abs(Player.ActorLocation.Y - ActorLocation.Y);
			
			if(X < 1350 && Y < 1000)
			{
				float DistToCenter =  ActorLocation.Dist2D(Player.ActorLocation, FVector::UpVector);
				FVector LaunchDir = (Player.ActorLocation - ActorLocation).GetSafeNormal2D();
				FPlayerLaunchToParameters Params;
				Params.LaunchToLocation = FVector(Player.ActorLocation + LaunchDir * (2000 - DistToCenter));
				Player.LaunchPlayerTo(this, Params);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbShowCracks(FVector ExplosionLocation, bool bVisualsOnly = false)
	{
		ShowCracks(ExplosionLocation, bVisualsOnly);
	}

	UFUNCTION()
	void ShowCracks(FVector ExplosionLocation, bool bVisualsOnly = false)
	{
		if(bVisualsOnly)
		{
			ShowCrackEffects(FVector::ZeroVector, false);
			return;
		}

		NumberOfExplosions++;

		if(NumberOfExplosions >= ExplosionsRequired && !bIceHasExploded)
		{
			bIceHasExploded = true;
			ExplodeIce();
			ShowCrackEffects(ExplosionLocation, true);

			return;
		}

		if(!bIceHasExploded)
		{
			ShowCrackEffects(ExplosionLocation, false);
			OnCrackingIceCracked.Broadcast();
		}
	}

	void ShowCrackEffects(FVector ExplosionLocation, bool bFurballWillExplodeIce)
	{
		FTundraBossCrackingIceEffectParams Params;
		Params.ExplosionLocation = ExplosionLocation;
		Params.ExplosionLocation.Z = IceMesh.WorldLocation.Z;
		Params.bFurballWillExplodeIce = bFurballWillExplodeIce;

		if(ExplosionLocation != FVector::ZeroVector)
		{
			UTundraBossCrackingIce_EffectHandler::Trigger_OnFurballExploded(this, Params);
			Timer::SetTimer(this, n"TriggerIceCrackAudio", AudioEventTriggerDelayTime);
		}
	}

	void ExplodeIce()
	{
		UTundraBossCrackingIce_EffectHandler::Trigger_OnIceDestroyed(this);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionFX, ActorLocation);
		SetActorHiddenInGame(true);
		IceMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
		LaunchPlayers();
		OnCrackingIceExploded.Broadcast();
		Timer::SetTimer(this, n"TriggerIceCrackAudio", AudioEventTriggerDelayTime);
	}

	UFUNCTION()
	void BuildIce(bool bInstant)
	{
		SetActorHiddenInGame(false);
		IceMesh.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		NumberOfExplosions = 0;
		
		if(bInstant)
		{
			IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"Opacity", IceOpacityMax);
			IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"OpacityFresnel", IceOpacityFresnelMax);
			IceMesh.SetScalarParameterValueOnMaterialIndex(0, n"Refraction", IceRefractionMax);
		}
		else
		{
			IceOpacityLerpTimelike.PlayFromStart();
		}
	}
};