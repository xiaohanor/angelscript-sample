class AMedallionHydraBallistaLaneLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent RecoilQueueComp;

	UPROPERTY()
	FRuntimeFloatCurve RecoilCurve;

	ASanctuaryBossMedallionHydra Hydra;

	UMedallionPlayerReferencesComponent Refs;
	bool bIsCached = false;

	UPROPERTY(EditAnywhere)
	float AttackDuration = 5.0;

	//Settings
	UPROPERTY()
	const float StartPitch = -80.0;
	UPROPERTY()
	const float EndPitch = -10.0;
	UPROPERTY()
	const float EndForwardOffset = 3000.0;
	const float LaserForceMultiplier = 30.0;

	UPROPERTY()
	float TelegraphDuration = 2.0;

	float LaserLength;
	float LaserRadius = 200.0;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Refs = UMedallionPlayerReferencesComponent::GetOrCreate(Game::Mio);
	}

	UFUNCTION()
	void Activate(ASanctuaryBossMedallionHydra HydraActor, float NewAttackDuration)
	{
		TryCache();

		if (bActive)
		{
			PrintToScreenScaled("Already Active", 3.0, FLinearColor::Red);
			return;
		}

		AttackDuration = NewAttackDuration;

		bActive = true;

		RotationRoot.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator(StartPitch, 0.0, 0.0));

		Hydra = HydraActor;

		LaserLength = Hydra.LaserActor.LaserLength;

		Hydra.BlockLaunchProjectiles(this);

		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, 
			EMedallionHydraMovePivotPriority::High, 
			1.0);

		Hydra.EnterMhAnimation(EFeatureTagMedallionHydra::LaserForward);

		QueueComp.Idle(1.0);
		QueueComp.Event(this, n"StartLaser");
		QueueComp.Idle(2.0);
		QueueComp.Duration(AttackDuration, this, n"LaneLaserUpdate");
		QueueComp.Event(this, n"DeactivateLaser");
		QueueComp.Idle(0.5);
		QueueComp.Event(this, n"Deactivate");
	}

	private void TryCache()
	{
		if (bIsCached)
			return;
		if (Refs.Refs == nullptr)
			return;
		bIsCached = true;
		Refs.Refs.HydraAttackManager.OnPhaseChanged.AddUFunction(this, n"HandlePhaseChanged");
	}

	UFUNCTION()
	private void HandlePhaseChanged(EMedallionPhase Phase, bool bNaturalProgression)
	{
		if (Phase == EMedallionPhase::BallistaPlayersAiming1 ||
			Phase == EMedallionPhase::BallistaPlayersAiming2 ||
			Phase == EMedallionPhase::BallistaPlayersAiming3 ||
			Phase == EMedallionPhase::BallistaArrowShot1 ||
			Phase == EMedallionPhase::BallistaArrowShot2 ||
			Phase == EMedallionPhase::BallistaArrowShot3)
		{
			QueueComp.Empty();
			QueueComp.Event(this, n"DeactivateLaser");
			QueueComp.Idle(0.5);
			QueueComp.Event(this, n"Deactivate");
		}
	}

	UFUNCTION()
	private void StartLaser()
	{
		Hydra.ActivateLaser(TelegraphDuration, true, LaserType = EMedallionHydraLaserType::BallistaUpwardsSweep);
		RecoilQueueComp.Idle(TelegraphDuration);
		RecoilQueueComp.Duration(1.5, this, n"RecoilUpdate");
	}

	UFUNCTION()
	private void LaneLaserUpdate(float Alpha)
	{
		float CurrentValue = Math::EaseIn(0.0, 1.0, Alpha, 2.0);
		FVector Location = FVector::ForwardVector * Math::Lerp(0.0, EndForwardOffset, CurrentValue);
		FRotator Rotation = FRotator(Math::Lerp(StartPitch, EndPitch, CurrentValue), 0.0, 0.0);
		RotationRoot.SetRelativeLocationAndRotation(Location, Rotation);

		//Apply Faux Physics Force To Actors

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.UseSphereShape(LaserRadius);

		int Safety = 10;
		while (Safety > 0)
		{	
			auto HitResult = Trace.QueryTraceSingle(HeadRoot.WorldLocation, HeadRoot.ForwardVector * LaserLength);

			if (!HitResult.bBlockingHit)
			{
				break;
			}
			else
			{
				auto HitPlatform = Cast<ABallistaHydraSplinePlatform>(HitResult.Actor);

				if (HitPlatform != nullptr)
				{
					float ForceSidewaysMultiplier = HitResult.ImpactPoint.Dist2D(HitResult.Location, HeadRoot.ForwardVector) / LaserRadius;
					FVector LaserForce = HeadRoot.ForwardVector * LaserForceMultiplier * HitPlatform.PlayerWeightComp.PlayerForce * ForceSidewaysMultiplier;
					FauxPhysics::ApplyFauxForceToActorAt(HitPlatform, HitResult.ImpactPoint, LaserForce);

					Trace.IgnoreActor(HitPlatform);
				}
				else
				{
					Trace.IgnoreActor(HitResult.Actor);
				}
			}

			Safety--;
		}
	}

	UFUNCTION()
	private void DeactivateLaser()
	{
		Hydra.DeactivateLaser();
		if (!Hydra.bIsBallistaAttacked)
			Hydra.ExitMhAnimation(EFeatureTagMedallionHydra::LaserForward);
		Hydra.ClearBlockLaunchProjectiles(this);
	}

	UFUNCTION()
	private void Deactivate()
	{
		bActive = false;
		Hydra.MoveHeadPivotComp.Clear(this);
	}

	UFUNCTION()
	private void RecoilUpdate(float Alpha)
	{
		float CurrentValue = RecoilCurve.GetFloatValue(Alpha);

		FVector RelativeLocation = FVector::ForwardVector * Math::Lerp(0.0, -800.0, CurrentValue);
		HeadRoot.SetRelativeLocation(RelativeLocation);
	}
};