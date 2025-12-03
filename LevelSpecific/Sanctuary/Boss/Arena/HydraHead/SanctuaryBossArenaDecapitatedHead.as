class ASanctuaryBossArenaDecapitatedHead : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BasePivot;

	UPROPERTY(DefaultComponent, Attach = BasePivot)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.RelativeScale3D = FVector::OneVector * 0.7;

	UPROPERTY(EditAnywhere)
	UAnimSequence Hydra1DeathAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence Hydra2DeathAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence Hydra3DeathAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence Hydra4DeathAnimation;

	UPROPERTY(EditAnywhere)
	UAnimSequence Hydra5DeathAnimation;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
#if EDITOR
		if (SanctuaryMedallionHydraDevToggles::Hydra::AddDebugMeshComp.IsEnabled())
		{
			UHazeMeshPoseDebugComponent Comp = UHazeMeshPoseDebugComponent::GetOrCreate(this);
		}
#endif
	}

	void PlayDecapitationAnimation(ASanctuaryBossArenaHydraHead Original)
	{
		TeleportActor(Original.ActorLocation, Original.ActorRotation, this);

		FHazePlaySlotAnimationParams Params;
		Params.BlendTime = 0.0;
		Params.StartTime = 0.5;

		if (Original.Player == EHazeSelectPlayer::None)
			Params.Animation = Hydra5DeathAnimation;
		else if (Original.Player == EHazeSelectPlayer::Zoe)
			Params.Animation = Original.HalfSide == ESanctuaryArenaSideOctant::Left ? Hydra1DeathAnimation : Hydra2DeathAnimation;
		else
			Params.Animation = Original.HalfSide == ESanctuaryArenaSideOctant::Left ? Hydra3DeathAnimation : Hydra4DeathAnimation;

		if (Params.Animation != nullptr)
			SkeletalMesh.PlaySlotAnimation(Params);
		else
			PrintToScreen("Death Animation not set!");
	}

	void PlayDecapitationAnimation(ASanctuaryBossSplineRunHydra Original)
	{
		TeleportActor(Original.ActorLocation, Original.ActorRotation, this);

		FHazePlaySlotAnimationParams Params;
		Params.BlendTime = 0.0;
		Params.StartTime = 0.5;

		if (Original.HeadID == ESanctuaryBossSplineRunHydraID::Center)
			Params.Animation = Hydra2DeathAnimation;
		else if (Original.HeadID == ESanctuaryBossSplineRunHydraID::Left)
			Params.Animation = Hydra1DeathAnimation;
		else if (Original.HeadID == ESanctuaryBossSplineRunHydraID::Right)
			Params.Animation = Hydra2DeathAnimation;

		if (Params.Animation != nullptr)
		{
			FHazeAnimationDelegate OnBlendOut, OnBlendIn;
			OnBlendOut.BindUFunction(this, n"OnAnimationDone");
			SkeletalMesh.PlaySlotAnimation(OnBlendIn, OnBlendOut, Params);
		}
		else
			PrintToScreen("Death Animation not set!");
	}

	void PlayDecapitationAnimation(ASanctuaryBossMedallionHydra Original)
	{
		TeleportActor(Original.ActorLocation, Original.ActorRotation, this);
		FHazePlaySlotAnimationParams Params;
		Params.BlendTime = 0.0;
		Params.StartTime = 0.2;
		
		Params.Animation = Hydra5DeathAnimation;

		if (Params.Animation != nullptr)
		{
			FHazeAnimationDelegate OnBlendOut, OnBlendIn;
			OnBlendOut.BindUFunction(this, n"OnMedallionAnimationDone");
			SkeletalMesh.PlaySlotAnimation(OnBlendIn, OnBlendOut, Params);
		}
		else
			PrintToScreen("Death Animation not set!");
	}

	UFUNCTION()
	private void OnMedallionAnimationDone()
	{
		SetActorHiddenInGame(true);
	}

	UFUNCTION()
	private void OnAnimationDone()
	{
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SanctuaryMedallionHydraDevToggles::Draw::DecapHead.IsEnabled())
		{
			ColorDebug::DrawTintedTransform(ActorLocation, ActorRotation, ColorDebug::White);
		}
	}
};