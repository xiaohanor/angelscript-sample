class ASummitBabyDragonFruit : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;
	default InteractionComp.bPlayerCanCancelInteraction = false;
	default InteractionComp.MovementSettings = FMoveToParams::NoMovement();
	default InteractionComp.bIsImmediateTrigger = true;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazePlaySlotAnimationParams AnimDragonAcid;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazePlaySlotAnimationParams AnimDragonTail;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazePlaySlotAnimationParams AnimPlayerMio;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazePlaySlotAnimationParams AnimPlayerZoe;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float TimeUntilFruitGetsPluckedFromStartOfAnimation = 0.25;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float TimeUntilPlayerIsRotatedUpToFaceFruit = 0.15;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float PluckDistance = 50.0;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float TimeUntilFruitGetsEatenFromStartOfAnimation = 2.07;	

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float ScaleUpTime = 1.5;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UNiagaraSystem EffectWhenFruitGetsEaten;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UForceFeedbackEffect FruitPluckedRumble;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset EatingCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UForceFeedbackEffect FruitEatenRumble;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> FruitEatenCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float CameraSettingsBlendTime = 2.0;

	bool bIsEatingFruit = false;
	bool bAnimationIsPlaying = false;
	bool bFruitIsGrowing = false;
	bool bPlucked = false;
	float TimeLastSpawned;
	float TimeFruitAnimationStartedPlaying;

	FQuat PlayerStartQuat;
	FVector PlayerStartLocation;
	FVector FruitPluckLocation;

	AHazePlayerCharacter Player;

	FVector StartScale;

	default TickGroup = ETickingGroup::TG_HazeInput;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");

		StartScale = ActorScale3D;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float TimeSinceSpawned = Time::GetGameTimeSince(TimeLastSpawned);
		if(TimeSinceSpawned <= ScaleUpTime)
		{
			float Alpha = TimeSinceSpawned / ScaleUpTime;
			Alpha = Math::EaseOut(0.0, 1.0, Alpha, 2);
			Alpha = Math::Clamp(Alpha, 0.001, 1.0);
			SetActorScale3D(StartScale * Alpha);
		}
		else
		{
			if(bFruitIsGrowing)
			{
				SetActorScale3D(StartScale);
				USummitBabyDragonFruitEventHandler::Trigger_OnFruitStoppedGrowing(this);
				bFruitIsGrowing = false;
			}
		}

		if(bIsEatingFruit)
		{
			float TimeSinceStartedPlayingAnimation = Time::GetGameTimeSince(TimeFruitAnimationStartedPlaying);

			FVector DirToFruit = FruitPluckLocation - Player.ActorLocation;
			DirToFruit = DirToFruit.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			FVector TargetLocation = FruitPluckLocation - DirToFruit * PluckDistance;
			float TargetHeight = GetGroundHeightForPlayer(TargetLocation, Player);
			TargetLocation.Z = TargetHeight; 

			if(TimeSinceStartedPlayingAnimation < TimeUntilPlayerIsRotatedUpToFaceFruit)
			{
				float TurnAlpha = Math::Saturate(TimeSinceStartedPlayingAnimation / TimeUntilPlayerIsRotatedUpToFaceFruit);
				TurnAlpha = Math::EaseInOut(0.0, 1.0, TurnAlpha, 2.0);
				FQuat TargetRotation = FQuat::MakeFromXZ(DirToFruit, FVector::UpVector);
				FQuat NewRotation = FQuat::Slerp(PlayerStartQuat, TargetRotation, TurnAlpha);
				Player.SetActorRotation(NewRotation);

				FVector NewLocation = Math::Lerp(PlayerStartLocation, TargetLocation, TurnAlpha);

				float NewHeight = Math::Lerp(PlayerStartLocation.Z, TargetHeight, TurnAlpha); 

				NewLocation.Z = NewHeight;

				TEMPORAL_LOG(Player, "Baby Dragon Fruit")
					.Sphere("Start Location", PlayerStartLocation, 20, FLinearColor::White, 5)
					.Sphere("New Location", NewLocation, 20, FLinearColor::Gray, 5)
					.Sphere("Target Location", TargetLocation, 20, FLinearColor::Black, 5)
					.Value("Target Height", TargetHeight)
				;
				Player.SetActorLocation(NewLocation);
			}
			else
				Player.SetActorLocation(TargetLocation);
			
			if (!bPlucked && TimeSinceStartedPlayingAnimation > TimeUntilFruitGetsPluckedFromStartOfAnimation)
				PluckFruit();
			
			if(TimeSinceStartedPlayingAnimation > TimeUntilFruitGetsEatenFromStartOfAnimation)		
				EatFruit();
		}

		if (bAnimationIsPlaying && Player != nullptr && Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"Movement", this);
	}

	private float GetGroundHeightForPlayer(FVector TargetLocation, AHazePlayerCharacter InPlayer)
	{
		FHazeTraceSettings GroundTrace;
		GroundTrace.TraceWithPlayer(InPlayer);
		GroundTrace.UseLine();
		GroundTrace.IgnorePlayers();

		FVector Start = TargetLocation;
		FVector End = Start + FVector::DownVector * 300.0;

		auto GroundHit = GroundTrace.QueryTraceSingle(Start, End);
		TEMPORAL_LOG(Player, "Baby Dragon Fruit").HitResults("Ground Trace", GroundHit, FHazeTraceShape::MakeLine());
		if(GroundHit.bBlockingHit)
			return GroundHit.ImpactPoint.Z;
		else
			return InPlayer.ActorLocation.Z;
	} 

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter InPlayer)
	{
		Player = InPlayer;

		auto DragonComp = UPlayerBabyDragonComponent::Get(Player);
		if(DragonComp == nullptr)
			return;

		FHazeAnimationDelegate BlendOutDelegate = FHazeAnimationDelegate(this, n"OnAnimationFinished");
		if (InPlayer.IsMio())
		{
			DragonComp.BabyDragon.PlaySlotAnimation(AnimDragonAcid);
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), BlendOutDelegate, AnimPlayerMio);
		}
		else
		{
			DragonComp.BabyDragon.PlaySlotAnimation(AnimDragonTail);
			Player.PlaySlotAnimation(FHazeAnimationDelegate(), BlendOutDelegate, AnimPlayerZoe);
		}

		InteractionComp.Disable(this);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Player.ApplyCameraSettings(EatingCameraSettings, CameraSettingsBlendTime, this);

		Player.SetActorVelocity(FVector::ZeroVector);

		bAnimationIsPlaying = true;
		bIsEatingFruit = true;
		TimeFruitAnimationStartedPlaying = Time::GameTimeSeconds;

		PlayerStartQuat = Player.ActorQuat;
		PlayerStartLocation = Player.ActorLocation;
		FruitPluckLocation = ActorLocation;

		USummitBabyDragonFruitEventHandler::Trigger_OnFruitPickedUp(this, FSummitBabyDragonFruitEventData(Player));
	}

	UFUNCTION()
	void OnAnimationFinished()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		Player.ClearCameraSettingsByInstigator(this);

		bAnimationIsPlaying = false;

		Online::UnlockAchievement(n"FeedBabyDragon");
	}

	private void EatFruit()
	{
		if(EffectWhenFruitGetsEaten != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(EffectWhenFruitGetsEaten, ActorLocation);

		DetachFromActor();
		AddActorDisable(this);

		bPlucked = false;
		bIsEatingFruit = false;

		USummitBabyDragonFruitEventHandler::Trigger_OnFruitEaten(this);

		Player.PlayCameraShake(FruitEatenCameraShake, this);
		Player.PlayForceFeedback(FruitEatenRumble, false, false, this);
	}

	private void PluckFruit()
	{
		AttachToComponent(Player.Mesh, n"LeftAttach", EAttachmentRule::SnapToTarget);
		AddActorLocalRotation(FRotator(-90, 0, 0));
		bPlucked = true;

		Player.PlayForceFeedback(FruitPluckedRumble, false, false, this);
	}

	void Spawn(ASummitBabyDragonFruitBush Bush)
	{
		TimeLastSpawned = Time::GameTimeSeconds;
		AttachToActor(Bush, AttachmentRule = EAttachmentRule::KeepWorld);
		RemoveActorDisable(this);

		SetActorScale3D(StartScale * 0.001);

		InteractionComp.Enable(this);

		bFruitIsGrowing = true;

		USummitBabyDragonFruitEventHandler::Trigger_OnFruitStartedGrowing(this);
	}
};