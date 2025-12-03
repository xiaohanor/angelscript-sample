asset IcePalaceThrowableRockZCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.13|     ..··''''''''··.                                            |
	    |..··'               ''·.                                        |
	    |                        ''·.                                    |
	    |                            '··.                                |
	    |                                '·.                             |
	    |                                   '·.                          |
	    |                                      '·.                       |
	    |                                         '·.                    |
	    |                                            '·.                 |
	    |                                               '·.              |
	    |                                                  '.            |
	    |                                                    '·.         |
	    |                                                       ·.       |
	    |                                                         '.     |
	    |                                                           '·   |
	0.0 |                                                             '·.|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 1.0, 0.757909);
	AddAutoCurveKey(0.272574, 1.104438);
	AddCurveKeyTangent(1.0, 0.0, -2.165448);
}

event void FOnRockThrown(ATundra_IcePalace_ThrowableRock Rock);
class ATundra_IcePalace_ThrowableRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraShapeshiftingInteractionComponent InteractionComp;
	default InteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	default InteractionComp.bShowWhileDisabled = true;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PickupAnim;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence ThrowAnim;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem RockHitFX;

	FOnRockThrown OnRockThrown;

	bool bInteractionDisabled = false;
	bool bThrowingRock = false;
	float ThrowDuration = 5.5;
	float ThrowSpeed = 6000.0;
	float CurveTimer = 0;
	float StartingZValue = 0;
	float DeactivationTimer = 0;
	bool bPermanentlyDisabled = false;
	bool bShouldLerpRockToHand = false;
	FVector RockRelativeLocBeforeLerp;
	float RockToHandTimer = 0.0;
	FVector PointOfInterestLocation;

	bool bRockShouldHitBird = false;
	
	UCurveFloat ZAdditionCurve = IcePalaceThrowableRockZCurve;

	default TickGroup = ETickingGroup::TG_HazeInput;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"InteractionStarted");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bShouldLerpRockToHand)
		{
			RockToHandTimer += DeltaSeconds;
			MeshRoot.SetRelativeLocation(Math::Lerp(RockRelativeLocBeforeLerp, FVector(51, 0, 20), (RockToHandTimer / 0.15)));

			if(RockToHandTimer >= 0.15)
				bShouldLerpRockToHand = false;
		}

		if(UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh().IsPlayingAnimAsSlotAnimation(ThrowAnim))
		{
			if(Game::Mio.Mesh.CanRequestLocomotion())
				Game::Mio.RequestLocomotion(n"Movement", this);
		}

		if(!bThrowingRock)
			return;

		CurveTimer += DeltaSeconds / ThrowDuration;
		DeactivationTimer += DeltaSeconds;

		FVector NewLoc = MeshRoot.WorldLocation + ActorForwardVector * (ThrowSpeed * DeltaSeconds);
		NewLoc.Z = StartingZValue + Math::Lerp(-16000, 0, ZAdditionCurve.GetFloatValue(CurveTimer));
		MeshRoot.SetWorldLocation(NewLoc);

		float Rot = Math::EaseOut(-1000, -100, Math::Saturate(CurveTimer), 2);
		Rot *= DeltaSeconds;
		Mesh.AddLocalRotation(FRotator(0, 0, Rot));

		if(bRockShouldHitBird)
		{
			if(CurveTimer >= ThrowDuration * 0.5)
			{
				Niagara::SpawnOneShotNiagaraSystemAtLocation(RockHitFX, MeshRoot.WorldLocation);
				SetActorTickEnabled(false);
				SetActorHiddenInGame(true);
			}
		}

		if(DeactivationTimer >= 10)
		{
			SetActorTickEnabled(false);
			SetActorHiddenInGame(true);
		}
	}

	UFUNCTION()
	private void InteractionStarted(UInteractionComponent InteractionComponent,
	                                AHazePlayerCharacter Player)
	{
		InteractionComp.bShowWhileDisabled = false;
		InteractionComp.Disable(this);
		
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big, true);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = PickupAnim;
		AnimParams.bLoop = false;
		FHazeAnimationDelegate BlendingOut;
		BlendingOut.BindUFunction(this, n"OnPickupBlendingOut");
		UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh().PlaySlotAnimation(FHazeAnimationDelegate(), BlendingOut, AnimParams);

		Timer::SetTimer(this, n"AttachRock", 0.2);
		OnRockThrown.Broadcast(this);

		Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;

		FUnluckyBirdThrowableRockEventData Data;
		Data.Rock = this;
		UTundra_IcePalace_UnluckyBirdEventHandler::Trigger_OnStartedThrowingRock(this, Data);
	}

	UFUNCTION()
	void AttachRock()
	{
		MeshRoot.AttachToComponent(UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh(), n"RightHandMiddle1", AttachmentRule = EAttachmentRule::KeepWorld);
		RockRelativeLocBeforeLerp = MeshRoot.RelativeLocation;
		BP_PickupFF();
		bShouldLerpRockToHand = true;
	}

	UFUNCTION()
	private void OnPickupBlendingOut()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = ThrowAnim;
		AnimParams.bLoop = false;
		FHazeAnimationDelegate BlendingOut;
		BlendingOut.BindUFunction(this, n"OnThrowBlendingOut");
		UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh().PlaySlotAnimation(FHazeAnimationDelegate(), BlendingOut, AnimParams);

		Timer::SetTimer(this, n"ThrowRock", 0.15);
	}

	UFUNCTION()
	void ThrowRock()
	{
		MeshRoot.DetachFromComponent(EDetachmentRule::KeepWorld);
		StartingZValue = MeshRoot.WorldLocation.Z;
		bThrowingRock = true;
		BP_ThrowFF();

		if(bRockShouldHitBird)
		{
			FVector PredictedLocation = MeshRoot.WorldLocation + ActorForwardVector * ((ThrowSpeed * ThrowDuration) * 0.5);
			PredictedLocation.Z = StartingZValue + Math::Lerp(-16000, 0, ZAdditionCurve.GetFloatValue(0.5));
			PointOfInterestLocation = PredictedLocation;

			ATundra_IcePalace_UnluckyBird UnluckyBird = TListedActors<ATundra_IcePalace_UnluckyBird>().GetSingle();
			UnluckyBird.ActivateUnluckyBird(PredictedLocation, ThrowDuration * 0.5);

			Timer::SetTimer(this, n"SetPointOfInterest", 0.5);			
		}
	}

	UFUNCTION()
	void SetPointOfInterest()
	{
		FHazePointOfInterestFocusTargetInfo TargetInfo;
		TargetInfo.SetFocusToWorldLocation(PointOfInterestLocation);
		TargetInfo.LocalOffset = FVector::DownVector * 3000;
		FApplyPointOfInterestSettings PoiSettings;
		PoiSettings.Duration = 1;
		PoiSettings.RegainInputTime = 1;
		Game::Mio.ApplyPointOfInterest(this, TargetInfo, PoiSettings, 1);
	}

	UFUNCTION()
	private void OnThrowBlendingOut()
	{
		UTundraPlayerSnowMonkeyComponent::Get(Game::Mio).GetShapeMesh().StopAllSlotAnimations();
		InteractionComp.KickAnyPlayerOutOfInteraction();
		InteractionComp.bShowWhileDisabled = false;
		bPermanentlyDisabled = true;
	}

	void SetRockToHitBird()
	{
		bRockShouldHitBird = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_PickupFF(){}

	UFUNCTION(BlueprintEvent)
	void BP_ThrowFF(){}
};