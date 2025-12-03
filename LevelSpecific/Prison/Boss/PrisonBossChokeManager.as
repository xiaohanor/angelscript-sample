event void FPrisonBossChokeManagerEvent();

UCLASS(Abstract)
class APrisonBossChokeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY()
	FPrisonBossChokeManagerEvent OnSuccess;

	UPROPERTY()
	FPrisonBossChokeManagerEvent OnFail;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset ZoeCamSettings;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence DarkMioMH;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence DarkMioLeftHitAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence DarkMioRightHitAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence DarkMioLeftSuccessAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence DarkMioRightSuccessAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MioMH;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MioLeftHitAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MioRightHitAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MioLeftSuccessAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MioRightSuccessAnim;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(EditInstanceOnly)
	ABlockingVolume BlockingVolume;

	UPROPERTY(EditInstanceOnly)
	AActor MidPoint;

	UPROPERTY(EditInstanceOnly)
	AActor CutsceneActor;

	bool bAdjustingCutsceneLocation = false;
	FVector CutsceneLocation = FVector::ZeroVector;

	APrisonBoss Boss;
	AHazePlayerCharacter Mio;

	bool bChokeActive = false;

	int TimesMagnetBursted = 0;

	bool bSucceeded = false;

	bool bApplyBlackAndWhiteEffect = false;
	float BlackAndWhiteStrength = 0.0;

	float CurrentChokeProgress = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = TListedActors<APrisonBoss>().Single;
		Mio = Game::Mio;
		SetActorControlSide(Game::Zoe);

		UHazeMovementComponent MioMoveComp = UHazeMovementComponent::Get(Mio);
		MioMoveComp.AddMovementIgnoresActor(this, BlockingVolume);

		BlockingVolume.SetActorEnableCollision(false);
	}

	UFUNCTION()
	void AdjustCutsceneLocation()
	{
		FVector DirFromMidToPlayer = (Mio.ActorLocation - MidPoint.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		float DistFromMid = Math::Clamp(MidPoint.ActorLocation.Dist2D(Mio.ActorLocation, FVector::UpVector), 0.0, PrisonBoss::GrabPlayerMaxDistanceFromMid);
		CutsceneLocation = MidPoint.ActorLocation + (DirFromMidToPlayer * DistFromMid);
		bAdjustingCutsceneLocation = true;
		
		Game::Zoe.ApplyCameraSettings(ZoeCamSettings, 5.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bAdjustingCutsceneLocation)
		{
			FVector Loc = Math::VInterpConstantTo(CutsceneActor.ActorLocation, CutsceneLocation, DeltaTime, PrisonBoss::GrabPlayerAdjustSpeed);
			CutsceneActor.SetActorLocation(Loc);
			if (Loc.Equals(CutsceneLocation))
				bAdjustingCutsceneLocation = false;
		}

		if (bChokeActive)
		{
			float FFMultiplier = Math::Lerp(1.0, 0.3, Mio.GetButtonMashProgress(this));
			float LeftFF = Math::Sin(Time::GameTimeSeconds * 8.0 * FFMultiplier) * (0.5 * FFMultiplier);
			float RightFF = Math::Sin(-Time::GameTimeSeconds * 8.0 * FFMultiplier) * (0.5 * FFMultiplier);
			Mio.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);

			CurrentChokeProgress = Mio.GetButtonMashProgress(this);
		}

		if (bApplyBlackAndWhiteEffect)
		{
			UPostProcessingComponent PostProcessComp = UPostProcessingComponent::Get(Game::Mio);
			BlackAndWhiteStrength = Math::FInterpConstantTo(BlackAndWhiteStrength, 1.0, DeltaTime, 5.0);
			PostProcessComp.BlackAndWhiteStrength.Apply(BlackAndWhiteStrength, this);
		}
	}

	UFUNCTION()
	void StartChoke()
	{
		Mio.BlockCapabilities(CapabilityTags::Movement, this);
		Mio.BlockCapabilities(CapabilityTags::GameplayAction, this);

		Boss.PlayEventAnimation(Animation = DarkMioMH, bLoop = true);
		Mio.PlayEventAnimation(Animation = MioMH, bLoop = true);

		Mio.PlayCameraShake(CamShake, this, 0.5);

		USceneComponent ButtonMashAttachComp = USceneComponent::Create(Mio);
		ButtonMashAttachComp.AttachToComponent(Mio.Mesh, n"Neck");
		ButtonMashAttachComp.SetRelativeLocation(FVector(30.0, 0.0, 10.0));

		FButtonMashSettings MashSettings;
		MashSettings.Difficulty = EButtonMashDifficulty::ActuallyImpossible;
		MashSettings.ProgressionMode = EButtonMashProgressionMode::StartFullDecayDown;
		MashSettings.WidgetAttachComponent = ButtonMashAttachComp;
		MashSettings.Duration = PrisonBoss::MaxChokeDuration;
		FOnButtonMashCompleted MashCompleted;
		MashCompleted.BindUFunction(this, n"MashCompleted");
		Mio.StartButtonMash(MashSettings, this, MashCompleted);

		Boss.MagneticFieldResponseComp.OnBurst.AddUFunction(this, n"BossMagnetBursted");

		BlockingVolume.SetActorLocationAndRotation(Mio.ActorLocation, Mio.ActorRotation);
		BlockingVolume.SetActorEnableCollision(true);

		bChokeActive = true;

		UPrisonBossEffectEventHandler::Trigger_GrabPlayerStartChoke(Boss);
		UPrisonBossChokeEffectEventHandler::Trigger_StartChoking(this);
	}

	UFUNCTION()
	private void MashCompleted()
	{
		if (HasControl())
			CrumbTriggerFail();
	}

	UFUNCTION()
	private void BossMagnetBursted(FMagneticFieldData Data)
	{
		if (!bChokeActive)
			return;

		FVector Direction = (Game::Zoe.ActorLocation - Boss.MagnetCollider.WorldLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		float Dot = Direction.DotProduct(Boss.ActorRightVector);
		bool bLeft = Dot >= 0.0;

		float NewProgress = Mio.GetButtonMashProgress(this) + PrisonBoss::ChokeButtonMashGainPerMagnetBurst;
		Mio.SnapButtonMashProgress(this, NewProgress);
		CurrentChokeProgress = NewProgress;

		TimesMagnetBursted++;
		if (TimesMagnetBursted >= PrisonBoss::ChokeMagnetBurstsRequired)
		{
			if (HasControl())
				CrumbTriggerSuccess(bLeft);
		}
		else
		{	
			if (HasControl())
				CrumbTriggerHit(bLeft);
		}

		UPrisonBossEffectEventHandler::Trigger_GrabPlayerMagnetBlasted(Boss);
		UPrisonBossChokeEffectEventHandler::Trigger_MagnetBlasted(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerHit(bool bLeft)
	{
		UAnimSequence DarkMioAnim = bLeft ? DarkMioLeftHitAnim : DarkMioRightHitAnim;
		FHazeAnimationDelegate DarkMioAnimFinished;
		DarkMioAnimFinished.BindUFunction(this, n"DarkMioHitReactionFinished");
		Boss.PlayEventAnimation(OnBlendingOut = DarkMioAnimFinished, Animation = DarkMioAnim);

		UAnimSequence MioAnim = bLeft ? MioLeftHitAnim : MioRightHitAnim;
		FHazeAnimationDelegate MioAnimFinished;
		MioAnimFinished.BindUFunction(this, n"MioHitReactionFinished");
		Mio.PlayEventAnimation(OnBlendingOut = MioAnimFinished, Animation = MioAnim);
	}

	UFUNCTION()
	private void DarkMioHitReactionFinished()
	{
		Boss.PlayEventAnimation(Animation = DarkMioMH, bLoop = true);
	}

	UFUNCTION()
	private void MioHitReactionFinished()
	{
		Mio.PlayEventAnimation(Animation = MioMH, bLoop = true);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerFail()
	{
		bChokeActive = false;

		Boss.MagneticFieldResponseComp.OnBurst.UnbindObject(this);

		OnFail.Broadcast();

		Timer::SetTimer(this, n"StartApplyingBlackAndWhiteEffect", PrisonBoss::ChokeFailBlackAndWhiteDelay);

		UPrisonBossChokeEffectEventHandler::Trigger_PlayerFail(this);
		UPrisonBossEffectEventHandler::Trigger_GrabPlayerGameOver(Boss);
	}

	UFUNCTION()
	private void StartApplyingBlackAndWhiteEffect()
	{
		bApplyBlackAndWhiteEffect = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerSuccess(bool bLeft)
	{
		bChokeActive = false;
		bSucceeded = true;

		Mio.StopSlotAnimation();
		Boss.StopSlotAnimation();

		Mio.StopCameraShakeByInstigator(this, false);

		Mio.StopButtonMash(this);

		Boss.MagneticFieldResponseComp.OnBurst.UnbindObject(this);

		OnSuccess.Broadcast();

		Game::Zoe.ClearCameraSettingsByInstigator(this);

		BlockingVolume.SetActorEnableCollision(false);

		FHazeAnimationDelegate MioAnimFinishedDelegate;
		MioAnimFinishedDelegate.BindUFunction(this, n"MioSuccessAnimFinished");

		UAnimSequence MioAnim = bLeft ? MioLeftSuccessAnim : MioRightSuccessAnim;
		Mio.PlayEventAnimation(OnBlendingOut = MioAnimFinishedDelegate, Animation = MioAnim);

		UAnimSequence DarkMioAnim = bLeft ? DarkMioLeftSuccessAnim : DarkMioRightSuccessAnim;
		Boss.PlayEventAnimation(Animation = DarkMioAnim);

		FHazePointOfInterestFocusTargetInfo PoiInfo;
		PoiInfo.SetFocusToComponent(Boss.MagnetCollider);
		PoiInfo.SetWorldOffset(FVector(0.0, 0.0, -350.0));
		FApplyPointOfInterestSettings PoiSettings;
		PoiSettings.Duration = 1.0;
		Mio.ApplyPointOfInterest(this, PoiInfo, PoiSettings, 1.0, EHazeCameraPriority::High);

		UPrisonBossEffectEventHandler::Trigger_GrabPlayerSaved(Boss);
		UPrisonBossChokeEffectEventHandler::Trigger_PlayerSuccess(this);
	}

	UFUNCTION()
	private void MioSuccessAnimFinished()
	{
		Mio.UnblockCapabilities(CapabilityTags::Movement, this);
		Mio.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentProgress() const
	{
		return CurrentChokeProgress;
	}
}