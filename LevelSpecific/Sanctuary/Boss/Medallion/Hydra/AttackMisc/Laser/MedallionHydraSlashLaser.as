class AMedallionHydraSlashLaser : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot2;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent RecoilQueueComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TelegraphRoot;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UGodrayComponent TelegraphGodRay;

	UPROPERTY()
	FRuntimeFloatCurve RecoilCurve;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer TargetPlayer;
	AHazePlayerCharacter Player;

	ASanctuaryBossMedallionHydra Hydra;

	ASanctuaryBossMedallionHydra Hydra2;

	const float ForwardsOffset = 0.0;
	bool bActive = false;
	bool bTelegraphing = false;

	float PlayerSign = 1.0;

	float SplineProgress;
	FHazeAcceleratedFloat AccSplineProgress;

	FRotator StartRotation;
	FVector TargetLocation;

	float StartPitch = 25.0;
	float EndPitch = -60.0;

	float TelegraphMaxOpacity = 0.4;

	UPROPERTY()
	FRuntimeFloatCurve TelegraphOpacityCurve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TargetPlayer == EHazePlayer::Zoe)
			PlayerSign = -1.0;

		Player = Game::GetPlayer(TargetPlayer);

		SplineComp = UHazeSplineComponent::Get(SplineActor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bActive)
		{
			AccSplineProgress.AccelerateTo(SplineProgress, 1.0, DeltaSeconds);
			
			FVector Location = SplineComp.GetWorldLocationAtSplineDistance(AccSplineProgress.Value);
			FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(AccSplineProgress.Value);
			
			SetActorLocationAndRotation(Location, Rotation);

			FRotator Head2Rotation = 
				(Player.ActorLocation - HeadRoot2.WorldLocation)
				.GetSafeNormal()
				.ToOrientationRotator();
			
			HeadRoot2.SetWorldRotation(Head2Rotation);
		}
	}

	UFUNCTION()
	void Activate(ASanctuaryBossMedallionHydra HydraActor)
	{
		if (bActive)
		{
			PrintToScreenScaled("Already Active", 3.0, FLinearColor::Red);
			return;
		}

		bActive = true;

		SplineProgress = SplineComp.GetClosestSplineDistanceToWorldLocation(
			Player.ActorLocation) + ForwardsOffset * PlayerSign;
		AccSplineProgress.SnapTo(SplineProgress);

		RotationRoot.SetRelativeRotation(FRotator(StartPitch, 90.0, 0.0));

		Hydra = HydraActor;
		SetOtherHydra();

		Hydra.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot, 
			EMedallionHydraMovePivotPriority::High, 
			2.0);

		Hydra2.MoveHeadPivotComp.ApplyHeadPivot(this, HeadRoot2,
			EMedallionHydraMovePivotPriority::High,
			2.0);

		Hydra.EnterMhAnimation(EFeatureTagMedallionHydra::LaserForward);

		QueueComp.Duration(2.0, this, n"TargetUpdate");
		QueueComp.Event(this, n"Telegraph");
		QueueComp.Duration(2.5, this, n"SlashLaserUpdate");
		QueueComp.Event(this, n"DeactivateLaser");
		QueueComp.Idle(0.5);
		QueueComp.Event(this, n"Deactivate");

		RecoilQueueComp.Idle(2.0);
		RecoilQueueComp.Duration(1.5, this, n"RecoilUpdate");

		Hydra.ActivateLaser(2.0, LaserType = EMedallionHydraLaserType::SidescrollerDownwardsSweep);
	}

	private void SetOtherHydra()
	{
		EMedallionHydra Hydra2Type = EMedallionHydra::ZoeBack;

		if (Hydra.HydraType == EMedallionHydra::MioLeft)
			Hydra2Type = EMedallionHydra::MioRight;
		if (Hydra.HydraType == EMedallionHydra::MioRight)
			Hydra2Type = EMedallionHydra::MioLeft;
		if (Hydra.HydraType == EMedallionHydra::ZoeLeft)
			Hydra2Type = EMedallionHydra::ZoeRight;
		if (Hydra.HydraType == EMedallionHydra::ZoeRight)
			Hydra2Type = EMedallionHydra::ZoeLeft;

		for (auto HydraActor : Hydra.Refs.Hydras)
		{
			if (HydraActor.HydraType == Hydra2Type)
			{
				Hydra2 = HydraActor;
				break;
			}
		}

		HeadRoot2.SetRelativeLocation(
			RotationRoot.RelativeLocation + 
			FVector::ForwardVector *
			(Hydra2Type == EMedallionHydra::ZoeLeft || Hydra2Type == EMedallionHydra::MioLeft ? -2000.0 : 2000.0)
			+ FVector::RightVector * -1000.0);
	}

	UFUNCTION()
	private void TargetUpdate(float Alpha)
	{
		SplineProgress = SplineComp.GetClosestSplineDistanceToWorldLocation(
			Player.ActorLocation) + ForwardsOffset * PlayerSign;
		
		TelegraphGodRay.SetGodrayOpacity(Alpha * TelegraphMaxOpacity);	
	}

	UFUNCTION()
	private void Telegraph()
	{
		TelegraphGodRay.SetGodrayOpacity(1.0);
	}

	UFUNCTION()
	private void SlashLaserUpdate(float Alpha)
	{
		float Pitch = Math::EaseInOut(StartPitch, EndPitch, Alpha, 4.0);
		RotationRoot.SetRelativeRotation(FRotator(Pitch, 90.0, 0.0));

		float Opacity = TelegraphOpacityCurve.GetFloatValue(Alpha);
		TelegraphGodRay.SetGodrayOpacity(Opacity);	
	}

	UFUNCTION()
	private void DeactivateLaser()
	{
		Hydra.ExitMhAnimation(EFeatureTagMedallionHydra::LaserForward);
		Hydra.DeactivateLaser();
	}

	UFUNCTION()
	private void Deactivate()
	{
		bActive = false;

		Hydra.MoveHeadPivotComp.Clear(this);
		Hydra2.MoveHeadPivotComp.Clear(this);
	}

	UFUNCTION()
	private void RecoilUpdate(float Alpha)
	{
		float CurrentValue = RecoilCurve.GetFloatValue(Alpha);

		FVector RelativeLocation = FVector::ForwardVector * Math::Lerp(800.0, -800.0, CurrentValue);
		HeadRoot.SetRelativeLocation(RelativeLocation);
	}
};