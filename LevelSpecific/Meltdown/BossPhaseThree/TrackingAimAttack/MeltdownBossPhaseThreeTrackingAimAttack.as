struct FMeltdownBossPhaseThreeTrackingAimConfig
{
	// How far in front of the player the portal spawns
	UPROPERTY()
	float ForwardOffsetFromPlayer = 3000.0;
	// Delay until the portal opens
	UPROPERTY()
	float OpenDelay = 0.0;
	// Delay after the portal opens before the attack starts
	UPROPERTY()
	float StartDelay = 0.0;
	// How long the beam tracks the player
	UPROPERTY()
	float TrackDuration = 1.8;
	// How fast the telegraph tracks the player
	UPROPERTY()
	float TrackSpeed = 20.0;
	// How long before the beam fires at the player
	UPROPERTY()
	float FireDelay = 2.0;
	// How long the beam is active for
	UPROPERTY()
	float BeamDuration = 1.5;
}

UCLASS(Abstract)
class AMeltdownBossPhaseThreeTrackingAimAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent PortalMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent TelegraphRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent BeamRoot;

	UPROPERTY(DefaultComponent)
	UDamageTriggerComponent DamageTrigger;

	UPROPERTY(DefaultComponent, Attach = BeamRoot)
	UNiagaraComponent Beam;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UStaticMeshComponent Laser01;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UStaticMeshComponent Laser02;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UStaticMeshComponent Laser03;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UStaticMeshComponent Laser04;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UStaticMeshComponent Laser05;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UStaticMeshComponent Laser06;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UStaticMeshComponent Laser07;

	UPROPERTY(DefaultComponent, Attach = TelegraphRoot)
	UStaticMeshComponent Laser08;

	FRotator TargetRotation = FRotator(0.0,0.0,0.0);

	FHazeTimeLike OpenPortal;
	default OpenPortal.Duration = 1.0;
	default OpenPortal.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FVector StartScale = FVector(0.01);
	UPROPERTY()
	FVector EndScale = FVector(4.0);

	AHazePlayerCharacter TargetPlayer;
	FMeltdownBossPhaseThreeTrackingAimConfig Config;

	bool bPortalOpen = false;
	bool bStarted = false;
	bool bFired = false;
	bool bClosing = false;
	float StateTimer = 0;

	FTransform RelativeFrame;
	FVector RelativePosition;

	FHazeTimeLike LaserTelegraph;
	default LaserTelegraph.Duration = 2.0;
	default LaserTelegraph.UseSmoothCurveZeroToOne();

	TArray<UStaticMeshComponent> Lasers;
	TArray<FRotator> LaserStartRotations;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		OpenPortal.BindFinished(this, n"PortalFinished");
		OpenPortal.BindUpdate(this, n"PortalUpdate");

		TelegraphRoot.SetHiddenInGame(true, true);
		BeamRoot.SetHiddenInGame(true, true);
		DamageTrigger.DisableDamageTrigger(this);

		LaserTelegraph.BindUpdate(this, n"LaserUpdate");
		LaserTelegraph.BindFinished(this, n"LaserFinished");

		Lasers.Add(Laser01);
		Lasers.Add(Laser02);
		Lasers.Add(Laser03);
		Lasers.Add(Laser04);
		Lasers.Add(Laser05);
		Lasers.Add(Laser06);
		Lasers.Add(Laser07);
		Lasers.Add(Laser08);

		for (UStaticMeshComponent Laser : Lasers)
			LaserStartRotations.Add(Laser.RelativeRotation);
	}
	
	UFUNCTION()
	private void LaserUpdate(float CurrentValue)
	{
		for (int i = 0, Count = Lasers.Num(); i < Count; ++i)
			Lasers[i].SetRelativeRotation(Math::LerpShortestPath(LaserStartRotations[i], TargetRotation, CurrentValue));
	}

	UFUNCTION()
	private void LaserFinished()
	{
	}

	UFUNCTION()
	private void PortalUpdate(float CurrentValue)
	{
		PortalMesh.SetRelativeScale3D(Math::Lerp(StartScale,EndScale,CurrentValue));
	}

	UFUNCTION()
	private void PortalFinished()
	{
		if (OpenPortal.IsReversed())
		{
			AddActorDisable(this);
			bClosing = false;
			bFired = false;
			bStarted = false;
			bPortalOpen = false;
			TelegraphRoot.SetHiddenInGame(true, true);
			BeamRoot.SetHiddenInGame(true, true);
			Beam.Deactivate();
		}
		else
		{
			bPortalOpen = true;
			StateTimer = 0;
		}
	}

	UFUNCTION(DevFunction)
	void Launch(AHazePlayerCharacter Player, FMeltdownBossPhaseThreeTrackingAimConfig AttackConfig)
	{
		RemoveActorDisable(this);

		TargetPlayer = Player;
		Config = AttackConfig;

		AddActorVisualsBlock(this);

		if (Config.OpenDelay > 0)
			Timer::SetTimer(this, n"StartOpening", Config.OpenDelay);
		else
			StartOpening();
	}

	UFUNCTION()
	private void StartOpening()
	{
		RemoveActorVisualsBlock(this);
		OpenPortal.PlayFromStart();
	}

	FTransform GetTargetPlayerRelativeFrame()
	{
		auto Comp = UMeltdownBossFlyingComponent::Get(TargetPlayer);
		return FTransform(
			FQuat::MakeFromXZ(Comp.CenterPoint.ActorLocation - TargetPlayer.ActorCenterLocation, FVector::UpVector),
			TargetPlayer.ActorCenterLocation
		);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bClosing)
			return;

		if (bFired)
		{
			StateTimer += DeltaSeconds;

			if (StateTimer > Config.BeamDuration)
			{
				BeamRoot.SetHiddenInGame(true, true);
				DamageTrigger.DisableDamageTrigger(this);

				StateTimer = 0;
				bClosing = true;
				OpenPortal.ReverseFromEnd();
			}
		}
		else if (bStarted)
		{
			StateTimer += DeltaSeconds;
			if (StateTimer < Config.TrackDuration)
			{
				FTransform WantedFrame = GetTargetPlayerRelativeFrame();
				RelativeFrame = FTransform(
					Math::QInterpTo(RelativeFrame.Rotation, WantedFrame.Rotation, DeltaSeconds, Config.TrackSpeed),
					Math::VInterpTo(RelativeFrame.Location, WantedFrame.Location, DeltaSeconds, Config.TrackSpeed),
					
				);
			}

			if (StateTimer > Config.FireDelay)
			{
				TelegraphRoot.SetHiddenInGame(true, true);
				BeamRoot.SetHiddenInGame(false, true);
				Beam.Activate();
				DamageTrigger.EnableDamageTrigger(this);

				StateTimer = 0;
				bFired = true;
			}
		}
		else
		{
			RelativeFrame = GetTargetPlayerRelativeFrame();

			if (bPortalOpen)
			{
				StateTimer += DeltaSeconds;
				if (StateTimer >= Config.StartDelay)
				{
					bStarted = true;
					StateTimer = 0;

					RelativePosition = RelativeFrame.InverseTransformPosition(ActorLocation);
					TelegraphRoot.SetHiddenInGame(false, true);
					LaserTelegraph.PlayFromStart();
				}
			}
		}

		FVector PortalStart = RelativeFrame.TransformPosition(
			FVector(Config.ForwardOffsetFromPlayer, 0, 0)
		);
		SetActorLocationAndRotation(PortalStart,
			FRotator::MakeFromXZ(-RelativeFrame.Rotation.ForwardVector, FVector::UpVector));
	}
};