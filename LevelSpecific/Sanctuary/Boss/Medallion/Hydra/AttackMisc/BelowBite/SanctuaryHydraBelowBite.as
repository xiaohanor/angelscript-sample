class ASanctuaryHydraBelowBite : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BodyRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent TriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent WaterSplashVFXComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditAnywhere)
	EMedallionHydra MainMioHydraType = EMedallionHydra::MioBack;
	ASanctuaryBossMedallionHydra MainMioHydra;

	UPROPERTY(EditAnywhere)
	EMedallionHydra MainZoeHydraType = EMedallionHydra::ZoeBack;
	ASanctuaryBossMedallionHydra MainZoeHydra;

	UPROPERTY(EditInstanceOnly)
	AMedallionHydraBelowBiteBreakablePlatform BreakablePlatform;

	UPROPERTY()
	UPlayerSkydiveSettings SkydiveSettings;

	UPROPERTY()
	TSubclassOf<AMedallionHydra2DProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere)
	bool bLaunchPlayer = false;

	UPROPERTY(EditAnywhere)
	bool bDisabled = false;

	//Settings
	const float SubmergeDistance = 2500.0;
	float AttackDistance = 1000.0;

	bool bBiteEnabled = false;
	bool bStartedBiting = false;

	bool bSubmerged = false;
	bool bActive = false;

	float PlayerSign = 1.0;

	AHazePlayerCharacter TargetPlayer;

	ASanctuaryBossMedallionHydra SubmergedHydra;
	UMedallionPlayerComponent MioMedallionComp;

	AHazeCameraActor CameraActor;
	bool bCameraActive = false;

	bool bSentActivate = false;
	bool bSentSubmerge = false;
	bool bSentForceBite = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bLaunchPlayer)
		{
			HeadRoot.SetRelativeLocation(FVector::UpVector * 1000.0);
			AttackDistance = 500.0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bDisabled)
			return;
		
		if (MainMioHydra == nullptr)
		{
			CacheRefs();
			return;
		}

		if (SanctuaryMedallionHydraDevToggles::Hydra::NoAttacks.IsEnabled())
			return;

		if (!HasControl())
			return;

		for (auto Player : Game::Players)
		{
			float Dist = Player.GetHorizontalDistanceTo(this);
			if (Dist < AttackDistance && !bActive && !bSentActivate && !MioMedallionComp.bCameraFocusFullyMerged)
			{
				bSentActivate = true;
				CrumbActivate(Player);
			}
			if (Dist < SubmergeDistance && !bSubmerged && !bSentSubmerge)
			{
				bSentSubmerge = true;
				CrumbSubmerge(Player);
			}
		}

		if (!bSentForceBite &&
			bBiteEnabled && 
			!bStartedBiting && 
			!bLaunchPlayer && 
			!TriggerComp.IsOverlappingActor(Game::Mio) && 
			!TriggerComp.IsOverlappingActor(Game::Zoe))
		{
			bSentForceBite = true;
			CrumbForceBite();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSubmerge(AHazePlayerCharacter Player)
	{
		bSentSubmerge = false;
		SubmergedHydra = nullptr;

		if (Player == Game::Mio)
		{
			if (!MainMioHydra.bSubmerged)
				SubmergedHydra = MainMioHydra;
			else if (!MainZoeHydra.bSubmerged)
				SubmergedHydra = MainZoeHydra;

			PlayerSign = -1.0;
		}
		else
		{
			if (!MainZoeHydra.bSubmerged)
				SubmergedHydra = MainZoeHydra;
			else if (!MainMioHydra.bSubmerged)
				SubmergedHydra = MainMioHydra;

			PlayerSign = 1.0;
		}
		
		if (SubmergedHydra != nullptr)
		{
			bSubmerged = true;
			SubmergedHydra.OneshotAnimationThenWait(EFeatureTagMedallionHydra::Submerge);
			SubmergedHydra.SetSubmerged(true);
		}

	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivate(AHazePlayerCharacter Player)
	{
		bSentActivate = false;

		if (MioMedallionComp.bCameraFocusFullyMerged) // don't bite while players might highfive
			return;

		bActive = true;

		bStartedBiting = false;
		WaterSplashVFXComp.Activate(true);

		USanctuaryHydraBelowBiteEventHandler::Trigger_Appear(this);

		SubmergedHydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, EMedallionHydraMovePivotPriority::VeryHigh, 0.0, true, true);
		SubmergedHydra.MoveActorComp.ApplyTransform(this, BodyRoot, EMedallionHydraMovePivotPriority::VeryHigh, 0.0, true, true);

		SubmergedHydra.EnterMhAnimation(EFeatureTagMedallionHydra::BiteUnder, bLaunchPlayer ? 1.0 : 2.0, 2.0);
		
		HeadRoot.SetRelativeRotation(FRotator(90.0, 0.0, 30.0 * PlayerSign));

		TargetPlayer = Player;

		TargetPlayer.ActivateCamera(CameraActor, 1.5, this, EHazeCameraPriority::High);
		bCameraActive = true;

		if (bLaunchPlayer)
		{
			QueueComp.Idle(0.25);
			QueueComp.Event(this, n"LaunchPlayer");
			QueueComp.Idle(1.0);
			QueueComp.Event(this, n"EnableSkydive");
			QueueComp.Idle(2.75);
			//QueueComp.Event(this, n"LaunchProjectile", 30.0);
			//QueueComp.Idle(0.5);
			//QueueComp.Event(this, n"LaunchProjectile", 10.0);
			//QueueComp.Idle(0.5);
			//QueueComp.Event(this, n"LaunchProjectile", -10.0);
			//QueueComp.Idle(0.5);
			//QueueComp.Event(this, n"LaunchProjectile", -30.0);
			
			QueueComp.Event(this, n"StartBite");
		}
		else
		{
			QueueComp.Idle(2.2);
			QueueComp.Event(this, n"EnableBite");
			QueueComp.Idle(2.0);
			QueueComp.Event(this, n"StartBite");
		}
	}

	UFUNCTION()
	private void EnableBite()
	{
		bBiteEnabled = true;
	}

	UFUNCTION()
	private void EnableSkydive()
	{
		Game::Zoe.EnableSkydive(this, 
			EPlayerSkydiveMode::Default, 
			EPlayerSkydiveStyle::Falling, 
			EInstigatePriority::Level, 
			SkydiveSettings);
	}

	UFUNCTION()
	private void LaunchPlayer()
	{
		Game::Zoe.AddMovementImpulseToReachHeight(3000.0);
		BreakablePlatform.Break();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbForceBite()
	{
		bSentForceBite = false;
		bStartedBiting = true;
		QueueComp.Empty();
		QueueComp.Event(this, n"StartBite");
	}

	UFUNCTION()
	private void LaunchProjectile(float Angle)
	{
		FVector Direction = FVector::UpVector.RotateAngleAxis(Angle, ActorForwardVector);
		FRotator Rotation = FRotator::MakeFromXZ(Direction, ActorForwardVector);
		FVector Location = HeadRoot.WorldLocation;

		auto Projectile = SpawnActor(
			ProjectileClass, 
			Location, 
			Rotation, 
			bDeferredSpawn = true);

		Projectile.SetActorScale3D(FVector::OneVector * 1.5);
		Projectile.Speed = 1500.0;

		FinishSpawningActor(Projectile);
	}

	UFUNCTION()
	private void StartBite()
	{
		bStartedBiting = true;
		SubmergedHydra.ExitMhAnimation(EFeatureTagMedallionHydra::BiteUnder, 2.0);

		USanctuaryHydraBelowBiteEventHandler::Trigger_Disappear(this);

		if (BreakablePlatform != nullptr)
			BreakablePlatform.Break();

		HeadRoot.SetRelativeRotation(FRotator(90.0, 0.0, 0.0 * PlayerSign));

		QueueComp.Duration(0.5, this, n"TwistHeadUpdate");
		QueueComp.Event(this, n"DeactivateCamera");
		QueueComp.Idle(1.5);

		QueueComp.Event(this, n"ReEmerge");
	}

	UFUNCTION()
	private void TwistHeadUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseInOut(1.0, 0.0, Alpha, 2.0);
		HeadRoot.SetRelativeRotation(FRotator(90.0, 0.0, 45.0 * PlayerSign * CurrentValue));
	}

	UFUNCTION()
	private void DeactivateCamera()
	{
		if (!bCameraActive)
			return;
		TargetPlayer.DeactivateCameraByInstigator(this, 1.5);
		bCameraActive = false;
	}

	UFUNCTION()
	private void ReEmerge()
	{
		SubmergedHydra.OneshotAnimation(EFeatureTagMedallionHydra::Emerge);
		SubmergedHydra.MoveActorComp.Clear(this);
		SubmergedHydra.MoveHeadPivotComp.Clear(this);
		SubmergedHydra.SetSubmerged(false);
	}

	private void CacheRefs()
	{
		TListedActors<ASanctuaryBossMedallionHydraReferences> ListedRefs;
		if (ListedRefs.Array.IsEmpty())
			return; // level streaming

		CameraActor = ListedRefs.Single.BelowBiteCameraActor;

		for (ASanctuaryBossMedallionHydra RefHydra : ListedRefs.Single.Hydras)
		{
			if (RefHydra.HydraType == MainMioHydraType)
				MainMioHydra = RefHydra;
			if (RefHydra.HydraType == MainZoeHydraType)
				MainZoeHydra = RefHydra;
		}

		MioMedallionComp = UMedallionPlayerComponent::GetOrCreate(Game::Mio);
		// MioMedallionComp.OnFocusFullyMerged.AddUFunction(this, n"DeactivateCamera");
	}
};

class USanctuaryHydraBelowBiteEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Appear() {};

	UFUNCTION(BlueprintEvent)
	void Disappear() {};
}