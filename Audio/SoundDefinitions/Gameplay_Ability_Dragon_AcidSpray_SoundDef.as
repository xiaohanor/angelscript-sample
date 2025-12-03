
UCLASS(Abstract)
class UGameplay_Ability_Dragon_AcidSpray_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void AcidProjectileImpact(FTeenDragonAcidProjectileImpactParams Params){}

	UFUNCTION(BlueprintEvent)
	void AcidProjectileStopFiring(){}

	UFUNCTION(BlueprintEvent)
	void AcidProjectileFired(FTeenDragonAcidProjectileEventParams Params){}

	UFUNCTION(BlueprintEvent)
	void AcidProjectileStartFiring(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, Category = Emitters)
	UHazeAudioEmitter SprayStreamEmitter;

	UPROPERTY(BlueprintReadOnly, Category = Emitters)
	UHazeAudioEmitter SprayImpactEmitter;

	UPROPERTY(BlueprintReadOnly, Category = Emitters)
	UHazeAudioEmitter SprayEndEmitter;

	UPROPERTY(BlueprintReadWrite, Category = Material)
	TMap<FName, UHazeAudioEvent> MaterialImpactEvents;

	FRotator PrevViewVelo = FRotator::ZeroRotator;

	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAcidSprayComponent SprayComp;	
	UPlayerAimingComponent AimComp;

	AHazePlayerCharacter Zoe;
	UTeenDragonAcidSpraySettings SpraySettings;

	private float SprayDirectionDelta = 0;
	private float CurrentCameraSpeed = 0;
	const float MAX_CAMERA_VIEW_VELO_SPEED = 100;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		DragonComp = UPlayerAcidTeenDragonComponent::Get(PlayerOwner);
		SprayComp = UTeenDragonAcidSprayComponent::Get(PlayerOwner);
		AimComp = UPlayerAimingComponent::Get(PlayerOwner);

		Zoe = PlayerOwner.GetOtherPlayer();
		SpraySettings = UTeenDragonAcidSpraySettings::GetSettings(PlayerOwner);

	}		

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		bUseAttach = false;
		return false;
	}

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate()
	// {
	// 	return DragonComp.bIsFiringAcid;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate()
	// {
	// 	return !DragonComp.bIsFiringAcid;
	// }

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProxyEmitterSoundDef::LinkToActor(this, Game::GetMio());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{	
		FRotator ViewVelo = PlayerOwner.GetViewAngularVelocity();
		const float ViewVeloSpeed = Math::Max(Math::Abs(ViewVelo.Pitch), Math::Abs(ViewVelo.Yaw));	
	
		SprayDirectionDelta = Math::FInterpConstantTo(SprayDirectionDelta, 0, DeltaSeconds, 3);

		const float CameraInterpSpeed = Math::Lerp(3, 0.3, Math::Min(CurrentCameraSpeed / MAX_CAMERA_VIEW_VELO_SPEED, 1));
		CurrentCameraSpeed = Math::FInterpTo(CurrentCameraSpeed, ViewVeloSpeed, DeltaSeconds, CameraInterpSpeed);

		if(Math::Sign(ViewVelo.Yaw) != Math::Sign(PrevViewVelo.Yaw) && Math::Abs(ViewVelo.Yaw) > 0.1 && Math::Abs(PrevViewVelo.Yaw) > 0)
		{	
			SprayDirectionDelta = 1.0;
			//CurrentCameraSpeed = 0.0;
		}
		if(Math::Sign(ViewVelo.Pitch) != Math::Sign(PrevViewVelo.Pitch) && Math::Abs(ViewVelo.Pitch) > 0.1 && Math::Abs(PrevViewVelo.Pitch) > 0)
		{
			SprayDirectionDelta = 1.0;
			//CurrentCameraSpeed = 0.0;
		}	
	
		if(SprayDirectionDelta > 0)
			PrevViewVelo = ViewVelo;
		else if(ViewVelo.Pitch < SMALL_NUMBER && ViewVelo.Yaw < SMALL_NUMBER)
			PrevViewVelo = ViewVelo;
	}

	UFUNCTION(BlueprintCallable)
	void SetSprayStreamEmitterLocations(const FVector Start, const FVector Target)
	{		
		FVector End = Target;
		
		// If this trace were to happen elsewhere in gamelogic, we could use that instead
		FHazeTraceSettings SprayTrace = FHazeTraceSettings();
		SprayTrace.TraceWithPlayerProfile(PlayerOwner);
		FHitResult AimHit = SprayTrace.QueryTraceSingle(Start, End);
		
		if(AimHit.bBlockingHit)
			End = AimHit.Location;

		if(SprayStreamEmitter != nullptr)
		{
			// Set SprayStreamEmitter location
			FVector ClosestZoePos = Math::ClosestPointOnLine(Start, End, Zoe.GetActorCenterLocation());		
			auto SpraySteamEmitterComp = SprayStreamEmitter.GetAudioComponent();
			SpraySteamEmitterComp.SetWorldLocation(ClosestZoePos);	
		}

		if(SprayEndEmitter != nullptr)
		{
			// Set SprayEndEmitter location
			auto SprayEndEmitterComp = SprayEndEmitter.GetAudioComponent();
			SprayEndEmitterComp.SetWorldLocation(Target);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetSprayStreamDirectionDelta()
	{		
		float VeloScaledSprayDirectionDelta = SprayDirectionDelta * Math::Min(CurrentCameraSpeed / MAX_CAMERA_VIEW_VELO_SPEED, 1);
		return VeloScaledSprayDirectionDelta;
	}

	UFUNCTION(BlueprintPure)
	UPhysicalMaterialAudioAsset GetPhysMatFromAcidImpact(const FVector Location, const FVector Normal)
	{
		FHazeTraceSettings TraceSettings = FHazeTraceSettings();
		TraceSettings.TraceWithPlayerProfile(PlayerOwner);

		return Cast<UPhysicalMaterialAudioAsset>(AudioTrace::GetPhysMaterialFromLocation(Location, Normal, TraceSettings).AudioAsset);
	}

	UFUNCTION(BlueprintPure)
	bool IsSpraying() 
	{
		return DragonComp.bIsFiringAcid;
	}
}