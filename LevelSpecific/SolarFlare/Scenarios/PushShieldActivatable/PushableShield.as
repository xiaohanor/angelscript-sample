class APushableShield : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent ShieldMesh;
	default ShieldMesh.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractLeft;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractRight;

	UPROPERTY(DefaultComponent, Attach = Root)
	USolarFlareCoverOverlapComponent CoverComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(EditAnywhere)
	ASplineActor Spline;

	UPROPERTY()
	UAnimSequence IdleAnim;
	UPROPERTY()
	UAnimSequence PushAnim;
	UPROPERTY()
	UAnimSequence StruggleAnim;
	UPROPERTY()
	UAnimSequence ActivateAnim;

	UPROPERTY()
	UHazeCapabilitySheet CapabilitySheet;

	FSplinePosition SplinePos;

	TPerPlayer<bool> PlayersPushing;
	TPerPlayer<bool> PlayersActivating;
	TPerPlayer<bool> PlayersUsing;

	float MoveSpeed = 200.0;
	bool bPushPromptActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplinePos = Spline.Spline.GetSplinePositionAtSplineDistance(0.0);
		InteractLeft.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractLeft.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
		InteractRight.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractRight.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CanPush())
		{
			SplinePos.Move(MoveSpeed * DeltaSeconds);

			if (!bPushPromptActive)
			{
				bPushPromptActive = true;

				for (AHazePlayerCharacter Player : Game::Players)
				{
					Player.SetTutorialPromptState(FInstigator(this, n"PushPrompt"), ETutorialPromptState::Unavailable);
				}
			}
		}
		else
		{
			if (bPushPromptActive)
			{
				bPushPromptActive = false;

				for (AHazePlayerCharacter Player : Game::Players)
				{
					Player.SetTutorialPromptState(FInstigator(this, n"PushPrompt"), ETutorialPromptState::Normal);
				}
			}
		}

		ActorLocation = SplinePos.WorldLocation;
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		UPushableShieldUserComponent UserComp = UPushableShieldUserComponent::Get(Player);

		if (UserComp != nullptr)
			UserComp.Shield = this;

		Player.AttachToComponent(InteractionComponent, NAME_None, EAttachmentRule::KeepWorld);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.StartCapabilitySheet(CapabilitySheet, this);

		PlayersUsing[Player] = true;

		Player.ActivateCamera(CameraComp, 1.5, this);

		if (BothPlayersUsing())
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Fast);

		UCameraSettings::GetSettings(Player).FOV.Apply(60.0, this, 1.0);
		PlayIdle(Player);
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.StopCapabilitySheet(CapabilitySheet, this);

		Player.DeactivateCamera(CameraComp, 1.5);
		PlayersUsing[Player] = false;
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, EHazeViewPointBlendSpeed::Normal);
		UCameraSettings::GetSettings(Player).FOV.Clear(this, 1.5);
		Player.StopSlotAnimation();
	}

	void StartShieldPush(AHazePlayerCharacter Player)
	{
		PlayersPushing[Player] = true;

		if (CanPush())
		{
			for (AHazePlayerCharacter CurrentPlayer : Game::Players)
				PlayPush(CurrentPlayer);
		}
		else
		{
			PlayStruggle(Player);
		}
	}

	void StopShieldPush(AHazePlayerCharacter Player)
	{
		PlayersPushing[Player] = false;
		PlayIdle(Player);
		if (PlayersPushing[Player.OtherPlayer])
			PlayStruggle(Player.OtherPlayer);
	}

	void StartShieldActivation(AHazePlayerCharacter Player)
	{
		PlayersActivating[Player] = true;
		BP_ActivateShieldFeedback();

		if (CanActivate())
		{
			CoverComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			ShieldMesh.SetHiddenInGame(false);
			Game::Mio.SetTutorialPromptState(FInstigator(this, n"ActivatePrompt"), ETutorialPromptState::Unavailable);
			Game::Zoe.SetTutorialPromptState(FInstigator(this, n"ActivatePrompt"), ETutorialPromptState::Unavailable);
		}
	}

	void StopShieldActivation(AHazePlayerCharacter Player)
	{
		PlayersActivating[Player] = false;

		if (!CanActivate())
		{
			CoverComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			ShieldMesh.SetHiddenInGame(true);
			Game::Mio.SetTutorialPromptState(FInstigator(this, n"ActivatePrompt"), ETutorialPromptState::Normal);
			Game::Zoe.SetTutorialPromptState(FInstigator(this, n"ActivatePrompt"), ETutorialPromptState::Normal);
		}

		if (!PlayersActivating[0] && !PlayersActivating[1])
			BP_DeactivateShieldFeedback();
	}

	bool CanPush()
	{
		return PlayersPushing[0] == true && PlayersPushing[1] == true;
	}

	bool CanActivate()
	{
		return PlayersActivating[0] == true && PlayersActivating[1] == true;
	}

	bool BothPlayersUsing()
	{
		return PlayersUsing[0] == true && PlayersUsing[1] == true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateShieldFeedback() {}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateShieldFeedback() {}

	void PlayIdle(AHazePlayerCharacter Player)
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = IdleAnim;
		Params.bLoop = true;
		Params.BlendTime = 0.25;
		Player.PlaySlotAnimation(Params);
	}

	void PlayPush(AHazePlayerCharacter Player)
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = PushAnim;
		Params.bLoop = true;
		Params.BlendTime = 0.25;
		Player.PlaySlotAnimation(Params);
	}

	void PlayStruggle(AHazePlayerCharacter Player)
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = StruggleAnim;
		Params.bLoop = true;
		Params.BlendTime = 0.25;
		Player.PlaySlotAnimation(Params);		
	}

	void PlayActivate(AHazePlayerCharacter Player)
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = ActivateAnim;
		Params.bLoop = true;
		Params.BlendTime = 0.25;
		Player.PlaySlotAnimation(Params);
	}

}
