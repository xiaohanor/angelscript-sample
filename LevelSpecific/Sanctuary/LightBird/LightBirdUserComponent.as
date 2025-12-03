struct FLightBirdAnimationData
{
	bool bIsAiming = false;
	FVector2D AimSpace = FVector2D::ZeroVector;
}

enum ELightBirdState
{
	Hover,
	Aiming,
	Attached,
	Lantern,
}

struct FLightBirdTargetData
{
       USceneComponent SceneComponent = nullptr;
       FName SocketName = NAME_None;
       FVector RelativeLocation = FVector::ZeroVector;
       bool bObstructed = false;

       FLightBirdTargetData(USceneComponent InSceneComponent,
               FName InSocketName,
               FVector InWorldLocation,
               bool bInObstructed)
       {
               SceneComponent = InSceneComponent;
               SocketName = InSocketName;
               RelativeLocation = InWorldLocation;
               bObstructed = bInObstructed;

               if (SceneComponent != nullptr)
               {
                       RelativeLocation = SceneComponent
                               .GetSocketTransform(SocketName)
                               .InverseTransformPositionNoScale(RelativeLocation);
               }
       }

       FLightBirdTargetData(FVector InWorldLocation, bool bInObstructed)
       {
               SceneComponent = nullptr;
               SocketName = NAME_None;
               RelativeLocation = InWorldLocation;
               bObstructed = bInObstructed;
       }


       FVector GetWorldLocation() const property
       {
               if (SceneComponent != nullptr)
               {
                       return SceneComponent.
                               GetSocketTransform(SocketName).
                               TransformPositionNoScale(RelativeLocation);
               }

               return RelativeLocation;
       }

       bool IsValid() const
       {
               if (SceneComponent == nullptr)
                       return false;
               if (SceneComponent.IsBeingDestroyed())
                       return false;

               return true;
       }
}

class ULightBirdUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird")
	TSubclassOf<UCrosshairWidget> CrosshairWidgetClass;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Light Bird")
	FLightBirdAnimationData AnimationData;

	UPROPERTY(BlueprintReadOnly, Category = "Light Bird")
	UHazeCameraSettingsDataAsset CameraAimSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Companion")
	TSubclassOf<AAISanctuaryLightBirdCompanion> CompanionClass;

	UPROPERTY(EditDefaultsOnly, Category = "UI")
	TSubclassOf<UTargetableWidget> FullscreenTargetableWidget;

	FLightBirdTargetData AimTargetData;
	FLightBirdTargetData AttachedTargetData;
	FLightBirdTargetData PreviousInvalidTargetData;
	ULightBirdResponseComponent AttachResponse;

	ELightBirdState PreviousState = ELightBirdState::Hover;
	ELightBirdState State = ELightBirdState::Hover;
	float StateTimestamp;

	bool bIsIlluminating = false;

	AHazePlayerCharacter Player;

	UPROPERTY()
	AAISanctuaryLightBirdCompanion Companion;

	const FName ActivationDisabledName = n"ActivationDisabled";

	bool bIsIntroducing = false;
	FVector IntroLocation;
	FRotator IntroRotation;

	bool bWantsRecall = false;
	float LastAimStartTime = 0.0;

	FVector GetLightBirdLocation()
	{
		return Companion.ActorLocation;
	}

	void Initialize()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		FVector WatsonLocation = LightBirdCompanion::GetWatsonTeleportLocation(Player);
		Companion = SpawnActor(CompanionClass, WatsonLocation, Player.ActorRotation, bDeferredSpawn = true, Level = Player.Level);
		Companion.MakeNetworked(Player, n"LightBirdCompanion");
		Companion.CompanionComp.SetPlayer(Player);

		FinishSpawningActor(Companion);
	}
	
	void Lantern()
	{
		ResetAttachment();
		SetState(ELightBirdState::Lantern);
	}

	void Attach(FLightBirdTargetData TargetData)
	{
		ResetAttachment();
		SetState(ELightBirdState::Attached);

		AttachedTargetData = TargetData;
		AttachResponse = ULightBirdResponseComponent::Get(TargetData.SceneComponent.Owner);
		if (AttachResponse != nullptr && !AttachResponse.IsListener())
			AttachResponse.Attach();
	}

	void Hover()
	{
		ResetAttachment();
		SetState(ELightBirdState::Hover);
	}

	void Aim()
	{
		// Do not reset attachment, we'll count as attached until companion is launched somewhere else
		SetState(ELightBirdState::Aiming);
	}

	bool ConsumeIllumination()
	{
		bool bWasConsumed = bIsIlluminating;
		bIsIlluminating = false;
		return bWasConsumed;
	}

	UFUNCTION(BlueprintPure)
	bool IsIlluminating() const
	{
		return bIsIlluminating;
	}

	UFUNCTION(BlueprintPure)
	bool AttachedWantsExclusivity() const
	{
		if (AttachResponse == nullptr)
			return false;
		if (!AttachResponse.bExclusiveAttachedIllumination)
			return false;
		
		return true;
	}

	private void ResetAttachment()
	{
		if (AttachResponse != nullptr && !AttachResponse.IsListener())
			AttachResponse.Detach();
		AttachResponse = nullptr;
	}

	FLightBirdTargetData GetTargetDataFromTrace(FVector Origin, FVector Destination, bool bAttachToSurfaces)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);

		auto HitResult = Trace.QueryTraceSingle(Origin, Destination);
		
		if (HitResult.bBlockingHit)
		{
			if (bAttachToSurfaces)
			{
				return FLightBirdTargetData(
					HitResult.Component,
					HitResult.BoneName,
					HitResult.ImpactPoint + HitResult.ImpactNormal * 100.0,
					true);
			}
			return FLightBirdTargetData(HitResult.ImpactPoint + HitResult.ImpactNormal * 100.0, true);
		}
		else
		{
			return FLightBirdTargetData(HitResult.TraceEnd, false);
		}
	}

	UFUNCTION(BlueprintPure)
	ELightBirdCompanionState GetCompanionState()
	{
		return Companion.CompanionComp.State;
	}

	UFUNCTION(BlueprintCallable)
	void SetCompanionState(ELightBirdCompanionState InState)
	{
		Companion.CompanionComp.State = InState;
	}

	private void SetState(ELightBirdState InState)
	{
		PreviousState = State;
		State = InState;
		StateTimestamp = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (Companion != nullptr)
		{
			Companion.DestroyActor();
			Companion = nullptr;
		}
	}
}
