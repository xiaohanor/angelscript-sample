event void FOnBombDisposalInteractionCompleted();

class AGameShowArenaBombDisposal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PanelMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BombMesh;
	default BombMesh.bHiddenInGame = true;
	default BombMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UGameShowArenaBombDisposalInteractionComponent MioInteractionComp;
	default MioInteractionComp.RelativeLocation = FVector(0, 0, 0);
	default MioInteractionComp.RelativeRotation = FRotator(0, 0, 0);
	default MioInteractionComp.UsableByPlayers = EHazeSelectPlayer::Mio;
	// default MioInteractionComp.bPlayerCanCancelInteraction = false;
	default MioInteractionComp.InteractionCapability = n"GameShowArenaBombDisposalInteractionCapability";
	default MioInteractionComp.bPlayerCanCancelInteraction = true;
	default MioInteractionComp.MaxInteractionRadius = 120;
	default MioInteractionComp.MinInteractionRadius = 120;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UGameShowArenaBombDisposalInteractionComponent ZoeInteractionComp;
	default ZoeInteractionComp.RelativeLocation = FVector(0, 0, 0);
	default ZoeInteractionComp.RelativeRotation = FRotator(0, 0, 0);
	default ZoeInteractionComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	// default ZoeInteractionComp.bPlayerCanCancelInteraction = false;
	default ZoeInteractionComp.InteractionCapability = n"GameShowArenaBombDisposalInteractionCapability";
	default ZoeInteractionComp.bPlayerCanCancelInteraction = true;
	default ZoeInteractionComp.MaxInteractionRadius = 120;
	default ZoeInteractionComp.MinInteractionRadius = 120;

	UPROPERTY(DefaultComponent, Attach = MioInteractionComp)
	UHazeSkeletalMeshComponentBase MioPreviewMesh;
	default MioPreviewMesh.bIsEditorOnly = true;
	default MioPreviewMesh.bHiddenInGame = true;
	default MioPreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = ZoeInteractionComp)
	UHazeSkeletalMeshComponentBase ZoePreviewMesh;
	default ZoePreviewMesh.bIsEditorOnly = true;
	default ZoePreviewMesh.bHiddenInGame = true;
	default ZoePreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilityClasses.Add(UGameShowArenaPlatformPlayerReactionCapability);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditInstanceOnly)
	AHazeActor LidAnimActor;

	UPROPERTY()
	FOnBombDisposalInteractionCompleted OnBombDisposalInteractionCompleted;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CarrierEnter;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CarrierExit;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CarrierMH;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CarrierThrow;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence HolderEnter;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence HolderExit;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence HolderMH;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence HolderThrow;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LidEnter;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LidExit;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LidMH;
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LidThrow;

	UPROPERTY(EditDefaultsOnly)
	float PanelRotationSpeed = 50;

	UPROPERTY(EditAnywhere)
	bool bOffsetInBeginPlay = true;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor Tint = FLinearColor::LucBlue;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D Texture;

	UPROPERTY(EditAnywhere)
	bool bIsAlternateDecal;

	UPROPERTY(DefaultComponent)
	UGameShowArenaDisplayDecalPlatformComponent DisplayDecalComp;

	FHazeTimeLike MoveBombDisposalTimelike;

	TPerPlayer<bool> InteractingPlayers;
	TPerPlayer<bool> FinishedInteractingPlayers;
	AHazePlayerCharacter LidHoldingPlayer;
	AHazePlayerCharacter BombHoldingPlayer;

	TPerPlayer<UGameShowArenaBombTossPlayerComponent> BombTossComps;

	bool bLidIsRaised = false;
	bool bSequenceCompleted = false;
	bool bHasBlendedOut = false;

	UPROPERTY(EditAnywhere)
	bool bRequiredForAchievement = false;
	
	FRotator DecalRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DisplayDecalComp.AssignTarget(BaseMesh, nullptr);
		FInteractionCondition Condition;
		Condition.BindUFunction(this, n"InteractCondition");
		MioInteractionComp.AddInteractionCondition(this, Condition);
		ZoeInteractionComp.AddInteractionCondition(this, Condition);
		LidAnimActor.AttachToComponent(MeshRoot);
		if (bOffsetInBeginPlay)
			MeshRoot.SetRelativeLocation(FVector(0, 0, -2000));

		MoveBombDisposalTimelike.BindUpdate(this, n"MoveBombDisposalTimelikeUpdate");
		MoveBombDisposalTimelike.BindFinished(this, n"MoveBombDisposalTimelikeFinished");

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PanelMesh.AddLocalRotation(FRotator(0, PanelRotationSpeed * DeltaSeconds, 0));
		FVector ForwardOffset = -ActorForwardVector * 15;
		FVector RightOffset = -ActorRightVector * 15;
		DecalRotation += FRotator(0, 100 * DeltaSeconds, 0);
		DisplayDecalComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(FTransform(DecalRotation, BaseMesh.WorldLocation + ForwardOffset + RightOffset, FVector::OneVector * 140), Texture, DecalColor = Tint), bIsAlternateDecal);
	}

	UFUNCTION()
	private EInteractionConditionResult InteractCondition(
		const UInteractionComponent InteractionComponent,
		AHazePlayerCharacter Player)
	{
		if (BombTossComps[Player] == nullptr)
			BombTossComps[Player] = UGameShowArenaBombTossPlayerComponent::Get(Player);

		auto Bomb = GameShowArena::GetClosestEnabledBombToLocation(Player.ActorLocation);
		if (Bomb != nullptr && Bomb.State.Get() == EGameShowArenaBombState::Exploding)
			return EInteractionConditionResult::Disabled;

		if (!BombTossComps[Player].bHoldingBomb)
		{
			if (LidHoldingPlayer != nullptr)
				return EInteractionConditionResult::DisabledVisible;
		}
		else
		{
			if (Time::GetGameTimeSince(BombTossComps[Player].TimeWhenThrewBomb) < 0.5)
				return EInteractionConditionResult::Disabled;
		}
			

		return EInteractionConditionResult::Enabled;
	}

	UFUNCTION()
	private void MoveBombDisposalTimelikeFinished()
	{
		if (MoveBombDisposalTimelike.IsReversed())
			AddActorDisable(this);
	}

	UFUNCTION()
	private void MoveBombDisposalTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector(0, 0, -2000), FVector::ZeroVector, CurrentValue));
	}

	UFUNCTION()
	void ActivateBombDisposal()
	{
		RemoveActorDisable(this);
		MoveBombDisposalTimelike.PlayFromStart();
		LidAnimActor.SetActorHiddenInGame(false);
	}

	UFUNCTION()
	void DeactivateBombDisposal()
	{
		// MoveBombDisposalTimelike.ReverseFromEnd();

		// Adding a disable instead of lowering it with a timlike. We're moving it during SEQs anyway.
		LidAnimActor.AddActorDisable(this);
		AddActorDisable(this);
	}

	void DisposeBomb()
	{
		if (!HasControl())
			return;

		CrumbDisposeBomb();
	}
	UFUNCTION(CrumbFunction)
	void CrumbDisposeBomb()
	{
		MioInteractionComp.bPlayerCanCancelInteraction = false;
		ZoeInteractionComp.bPlayerCanCancelInteraction = false;
		MioInteractionComp.Disable(this);
		ZoeInteractionComp.Disable(this);

		FHazePlaySlotAnimationParams MioParams;
		MioParams.Animation = GetThrowAnimation(Game::Mio);
		Game::Mio.PlaySlotAnimation(MioParams);

		FHazePlaySlotAnimationParams ZoeParams;
		ZoeParams.Animation = GetThrowAnimation(Game::Zoe);
		Game::Zoe.PlaySlotAnimation(ZoeParams);
		FGameShowArenaBombDisposalBombDisposalStartedParams EventParams;
		EventParams.PlayerHoldingBomb = BombHoldingPlayer;
		EventParams.PlayerHoldingLid = LidHoldingPlayer;
		EventParams.LidLocation = LidAnimActor.ActorLocation;
		UGameShowArenaBombDisposalEffectHandler::Trigger_OnBombDisposalStarted(this, EventParams);

		FHazeAnimationDelegate OnLidThrowBlendedOut;
		OnLidThrowBlendedOut.BindUFunction(this, n"OnLidThrowBlendedOut");
		FHazePlaySlotAnimationParams LidParams;
		LidParams.Animation = LidThrow;
		LidAnimActor.PlaySlotAnimation(FHazeAnimationDelegate(), OnLidThrowBlendedOut, LidParams);
		bLidIsRaised = false;
		bSequenceCompleted = true;
	}

	UFUNCTION()
	private void OnLidThrowBlendedOut()
	{
		if (!bHasBlendedOut)
		{
			bHasBlendedOut = true;
			OnBombDisposalInteractionCompleted.Broadcast();
			FGameShowArenaBombDisposalBombDisposedParams EventParams;
			EventParams.PlayerHoldingBomb = BombHoldingPlayer;
			EventParams.PlayerHoldingLid = LidHoldingPlayer;
			EventParams.LidLocation = LidAnimActor.ActorLocation;
			UGameShowArenaBombDisposalEffectHandler::Trigger_OnBombDisposed(this, EventParams);
		}

		// HideBomb();
		if (HasControl())
		{
			for (auto BombComp : BombTossComps)
			{
				BombComp.CrumbRemoveBomb();
			}
		}
		if (LidHoldingPlayer == Game::Mio)
		{
			MioInteractionComp.KickAnyPlayerOutOfInteraction();
			Game::Mio.StopAllSlotAnimations(0);
		}
		else
		{
			ZoeInteractionComp.KickAnyPlayerOutOfInteraction();
			Game::Zoe.StopAllSlotAnimations(0);
		}
	}

	// void AttachBombToPlayer(AHazePlayerCharacter Player)
	// {
	// 	BombMesh.SetHiddenInGame(false);
	// 	BombMesh.AttachToComponent(Player.Mesh, n"Backpack");
	// 	BombMesh.SetRelativeRotation(FRotator(-90, 0, 0));
	// }

	void HideBomb()
	{
		// BombMesh.SetHiddenInGame(true, false);
		// BombMesh.DetachFromComponent();
		if (BombHoldingPlayer == Game::Mio)
		{
			Game::Mio.StopAllSlotAnimations(0);
			MioInteractionComp.KickAnyPlayerOutOfInteraction();
		}
		else
		{
			Game::Zoe.StopAllSlotAnimations(0);
			ZoeInteractionComp.KickAnyPlayerOutOfInteraction();
		}
	}

	void OpenLid()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = LidEnter;
		LidAnimActor.PlaySlotAnimation(Params);
		bLidIsRaised = true;

		UGameShowArenaBombDisposalEffectHandler::Trigger_OnLidLiftStart(this, FGameShowArenaBombDisposalLidLiftParams(LidAnimActor.ActorLocation, LidHoldingPlayer));
	}

	void CloseLid()
	{
		bLidIsRaised = false;
		// LidHoldingPlayer.StopSlotAnimation(EHazeSlotAnimType::SlotAnimType_Locomotion, 0);

		FHazeAnimationDelegate OnLidCloseBlendedOut;
		OnLidCloseBlendedOut.BindUFunction(this, n"OnLidClosed");
		FHazePlaySlotAnimationParams LidParams;
		LidParams.Animation = LidExit;
		LidAnimActor.PlaySlotAnimation(FHazeAnimationDelegate(), OnLidCloseBlendedOut, LidParams);
		UGameShowArenaBombDisposalEffectHandler::Trigger_OnLidCloseStart(this, FGameShowArenaBombDisposalLidCloseParams(LidAnimActor.ActorLocation, LidHoldingPlayer));
	}

	UFUNCTION()
	private void OnLidClosed()
	{
		LidAnimActor.StopSlotAnimation(EHazeSlotAnimType::SlotAnimType_Default, 0);
		LidHoldingPlayer.StopAllSlotAnimations(0);
		LidHoldingPlayer = nullptr;
	}

	UAnimSequence GetMHAnimation(AHazePlayerCharacter Player)
	{
		UGameShowArenaBombTossPlayerComponent BombTossPlayerComponent = UGameShowArenaBombTossPlayerComponent::Get(Player);
		if (BombTossPlayerComponent.bHoldingBomb)
		{
			return CarrierMH;
		}
		else
		{
			return HolderMH;
		}
	}

	UAnimSequence GetThrowAnimation(AHazePlayerCharacter Player)
	{
		if (Player == BombHoldingPlayer)
		{
			return CarrierThrow;
		}
		else
		{
			return HolderThrow;
		}
	}
};