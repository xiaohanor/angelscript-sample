event void FSkylineGrappleTowerFallingSignature();

class ASkylineMallChaseGrappleTower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FallRoot;

	UPROPERTY(DefaultComponent, Attach = FallRoot)
	USceneComponent MioRootComp;

	UPROPERTY(DefaultComponent, Attach = FallRoot)
	USceneComponent ZoeRootComp;

	UPROPERTY(EditInstanceOnly)
	AGrapplePoint ZoeGrapple;

	UPROPERTY(EditInstanceOnly)
	AGrapplePoint MioGrapple;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY()
	UAnimSequence LandedAnim;

	UPROPERTY()
	FHazeTimeLike FallTimeLike;
	default FallTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	FSkylineGrappleTowerFallingSignature OnStartFalling;

	UPROPERTY()
	FSkylineGrappleTowerFallingSignature OnStopFalling;


	UPROPERTY(EditAnywhere)
	FRotator TargetRotation;
	
	UPROPERTY(EditAnywhere)
	AActor PlayerLaunchTargetPoint;

	UPROPERTY(EditAnywhere)
	float JumpHeight = 100.0;

	bool bOnePlayerLanded = false;
	bool bPlayerInitiated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ZoeGrapple.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"HandleGrappleFinished");
		MioGrapple.OnPlayerFinishedGrapplingToPointEvent.AddUFunction(this, n"HandleGrappleFinished");
		ZoeGrapple.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"HandleGrappleInitiated");
		MioGrapple.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"HandleGrappleInitiated");

		FallTimeLike.BindUpdate(this, n"FallTimeLikeUpdate");
		FallTimeLike.BindFinished(this, n"FallTimeLikeFinished");

		
		auto HealthCompMio = UPlayerHealthComponent::GetOrCreate(Game::Mio);
		HealthCompMio.OnFinishDying.AddUFunction(this, n"HandleMioRespawn");

		auto HealthCompZoe = UPlayerHealthComponent::GetOrCreate(Game::Zoe);
		HealthCompZoe.OnFinishDying.AddUFunction(this, n"HandleZoeRespawn");
	}

	UFUNCTION()
	private void HandleGrappleInitiated(AHazePlayerCharacter Player,
	                                    UGrapplePointBaseComponent GrapplePoint)
	{
		bPlayerInitiated = true;
	}

	UFUNCTION()
	private void HandleMioRespawn()
	{
		if (bPlayerInitiated)
		{
			//AttachMio();
			MioGrapple.GrapplePoint.Disable(this);
			Collapse();
			//Timer::SetTimer(this, n"DelayedCollapse", 0.2);
		}
	}

	UFUNCTION()
	private void HandleZoeRespawn()
	{
		if (bPlayerInitiated)
		{
			//AttachZoe();
			ZoeGrapple.GrapplePoint.Disable(this);
			Collapse();
			//Timer::SetTimer(this, n"DelayedCollapse", 0.2);
		}
	}

	UFUNCTION()
	private void HandleGrappleFinished(AHazePlayerCharacter Player,
	                                   UGrapplePointBaseComponent GrapplePoint)
	{
		GrapplePoint.Disable(this);

		if (bOnePlayerLanded)
		{
			Collapse();
		}
		else
			bOnePlayerLanded = true;

		// if (Player == Game::Mio)
		// 	Timer::SetTimer(this, n"AttachMio", 0.7);
		// else
		// 	Timer::SetTimer(this, n"AttachZoe", 0.7);
	}

	UFUNCTION()
	private void DelayedCollapse()
	{
		Collapse();

		// for (auto Player : Game::Players)
		// {	
		// 	Player.PlaySlotAnimation(Animation = LandedAnim, bLoop = true);
		// }
	}

	UFUNCTION()
	private void AttachMio()
	{
		auto Player = Game::Mio;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.AttachToComponent(FallRoot, NAME_None, EAttachmentRule::KeepWorld);
		Player.PlaySlotAnimation(Animation = LandedAnim, bLoop = true);
		//Player.SmoothTeleportActor(MioRootComp.WorldLocation, MioRootComp.WorldRotation, this, 0.5);
	}

	UFUNCTION()
	private void AttachZoe()
	{
		auto Player = Game::Zoe;

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.AttachToComponent(FallRoot, NAME_None, EAttachmentRule::KeepWorld);
		Player.PlaySlotAnimation(Animation = LandedAnim, bLoop = true);
		//Player.SmoothTeleportActor(ZoeRootComp.WorldLocation, ZoeRootComp.WorldRotation, this, 0.5);
	}

	private void Collapse()
	{
		FallTimeLike.PlayFromStart();
		OnStartFalling.Broadcast();
		bPlayerInitiated = false;
	}
	
	UFUNCTION()
	private void FallTimeLikeUpdate(float CurrentValue)
	{
		FallRoot.SetRelativeRotation(Math::LerpShortestPath(FRotator::ZeroRotator, TargetRotation, CurrentValue));
	}

	UFUNCTION()
	private void FallTimeLikeFinished()
	{
		for (auto Player : Game::GetPlayers())
		{
			//Player.UnblockCapabilities(CapabilityTags::Movement, this);
			//Player.DetachFromActor(EDetachmentRule::KeepWorld);
			Player.StopAllSlotAnimations();

			auto LaunchComp = USkylineLaunchPadUserComponent::Get(Player);
			FVector TargetLocationWorld;

			if (PlayerLaunchTargetPoint != nullptr)
				TargetLocationWorld = PlayerLaunchTargetPoint.ActorLocation;

			LaunchComp.Launch(TargetLocationWorld, JumpHeight, true);
		}

		OnStopFalling.Broadcast();
	}
};