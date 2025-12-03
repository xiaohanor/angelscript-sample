enum ETeenDragonAnimationState
{
	FloorMovement,
	FloorSlowdown,
	AirMovement,
	Sprint,
	Jump,

	TailRoll,
	TailRollJump,
	TailRollFromRun,
	RollAreaAttack,

	TailFirstAttack,
	TailFirstAttackSettle,
	TailSecondAttack,
	TailSecondAttackSettle,
	TailThirdAttack,

	TailClimb,
	TailClimbDash,

	Gliding,
	AirBoostDoubleJump,

	GroundPoundAttackDive,
	GroundPoundAttackLanded,
};

event void FOnTopDownActivated();
event void FOnTopDownDeactivated();
event void FOnTeenDragonSpawned();

UCLASS(Abstract)
class UPlayerTeenDragonComponent : UActorComponent
{
	UPROPERTY()
	FOnTopDownActivated OnTopDownActivated;
	
	UPROPERTY()
	FOnTopDownDeactivated OnTopDownDeactivated;

	UPROPERTY(Category = "Setup")
	TSubclassOf<ATeenDragon> TeenDragonClass;
	UPROPERTY(Category = "Setup")
	FName PlayerAttachSocket = n"Spine4";
	UPROPERTY(Category = "Setup")
	FTransform PlayerAttachOffset;

	UPROPERTY(Category = "Settings")
	UMovementGravitySettings GravitySettings;
	UPROPERTY(Category = "Settings")
	UHazeCameraSettingsDataAsset CameraSettings;
	UPROPERTY(Category = "Settings")
	UHazeCameraSettingsDataAsset SprintCameraSettings;
	UPROPERTY(Category = "Settings")
	UPlayerBlobShadowSettings BlobShadowSettings;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> SprintContinuousCameraShake;
	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> LandingCameraShake;
	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect DashRumble;
	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect JumpRumble;

	UPROPERTY(Category = "Landing Lag")
	float CameraLagDuration;
	UPROPERTY(Category = "Landing Lag")
	float CameraLagDistance;

	UPROPERTY()
	UPlayerHighlightSettings TopDownHighlight;

	UPROPERTY()
	UPlayerHighlightSettings CavernChaseHighlights;

	UPROPERTY()
	TSubclassOf<UTeenDragonStaminaWidget> StaminaWidget;
	FVector StaminaWidgetWorldOffset(0.0, 0.0, 130.0);

	bool bLandingBlockedThisFrame = false;

	TArray<FInstigator> NonOrientedInputInstigators;
	TArray<FInstigator> VerticalInputInstigators;

	bool bWantToJump = false;
	bool bIsInAirFromJumping = false;
	bool bHasTouchedGroundSinceLastJump = false;
	bool bJumpInputConsumed = false;
	
	bool bIsSprinting = false;
	bool bIsDashing = false;

	bool bIsLedgeGrabbing = false;
	bool bIsLedgeDowning = false;
	bool bIsLedgeFalling = false;

	TInstigated<ETeenDragonAnimationState> AnimationState;
	float AnimationLeftRightAlpha = 0.0;
	float AnimationForwardBackwardAlpha = 0.0;
	bool bIsRollJumping = false;
	bool bWillHitObjectWhileRollJumping = false;
	bool bIsAboutToLandFromAirRoll = false;

	float CurrentStamina = 1.0;
	TInstigated<float> StaminaRegenerationRate;

	bool bTopDownMode;

	// OBS! Do NOT expose these.
	// The dragon is just a "dead" actor attached to the player
	// The player IS the dragon, moving and having all the capabilities
	protected ATeenDragon TeenDragon;
	protected AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	ATeenDragon SpawnDragon(AHazePlayerCharacter Player, TSubclassOf<ATeenDragon> DragonType)
	{
		PlayerOwner = Player;
		
		TeenDragon = SpawnActor(DragonType, bDeferredSpawn = true);
		TeenDragon.MakeNetworked(Player);
		TeenDragon.SetActorControlSide(Player);

		TeenDragon.SetControllingPlayer(Player);
		TeenDragon.CapsuleComponent.AddComponentCollisionBlocker(TeenDragon);
		FinishSpawningActor(TeenDragon);

		UHazeSequenceRenderSingleton SequenceRenderSingleton = Game::GetSingleton(UHazeSequenceRenderSingleton);
		if (SequenceRenderSingleton != nullptr)
		{
			if (Player.Player == EHazePlayer::Mio)
				SequenceRenderSingleton.TeenDragonMio = TeenDragon;
			else
				SequenceRenderSingleton.TeenDragonZoe = TeenDragon;
		}
		
		return TeenDragon;
	}

	UHazeCharacterSkeletalMeshComponent GetDragonMesh() const property
	{
		return TeenDragon.Mesh;
	}

	UHazeOffsetComponent GetDragonMeshOffsetComponent() const property
	{
		return TeenDragon.MeshOffsetComponent;
	}

	void RequestLocomotionDragonAndPlayer(FName LocomotionTag)
	{
		if (PlayerOwner != nullptr && PlayerOwner.Mesh.CanRequestLocomotion())
		{
			bool bShouldUseSameTag = 
				LocomotionTag == TeenDragonLocomotionTags::Jump
				|| LocomotionTag == TeenDragonLocomotionTags::AirMovement
				|| LocomotionTag == TeenDragonLocomotionTags::Landing
				|| LocomotionTag == TeenDragonLocomotionTags::TeenDragonLedgeUp
				|| LocomotionTag == TeenDragonLocomotionTags::RollMovement
				|| LocomotionTag == TeenDragonLocomotionTags::DragonDash
			;

			if(bShouldUseSameTag)
				PlayerOwner.Mesh.RequestLocomotion(LocomotionTag, this);
			else
				PlayerOwner.Mesh.RequestLocomotion(n"DragonRiding", this);
		}
		
		if (TeenDragon.Mesh.CanRequestLocomotion())
		{
			TeenDragon.Mesh.RequestLocomotion(LocomotionTag, this);
		}
	}

	void PlaySlotAnimationDragonAndPlayer(FHazePlaySlotAnimationParams PlayerAnim, FHazePlaySlotAnimationParams DragonAnim)
	{
		if(DragonAnim.Animation != nullptr)
			TeenDragon.PlaySlotAnimation(DragonAnim);
		if(PlayerAnim.Animation != nullptr)
			PlayerOwner.PlaySlotAnimation(PlayerAnim);
	}

	void AddDragonVisualsBlock(FInstigator Instigator)
	{
		TeenDragon.AddActorVisualsBlock(Instigator);
	}

	void RemoveDragonVisualsBlock(FInstigator Instigator)
	{
		TeenDragon.RemoveActorVisualsBlock(Instigator);
	}

	void ConsumeStamina(float StaminaAmount)
	{
		CurrentStamina = Math::Max(CurrentStamina - StaminaAmount, 0.0);
	}

	float GetCurrentStaminaRegenerationRate() const
	{
		// This isn't the default value on the TInstigated because we want to have it hotreloadable
		if (StaminaRegenerationRate.IsDefaultValue())
			return TeenDragonStamina::RegenerationRate;
		return StaminaRegenerationRate.Get();
	}

	bool IsAcidDragon() const
	{
		return TeenDragon.IsAcidDragon();
	}

	bool IsTailDragon() const
	{
		return TeenDragon.IsTailDragon();
	}

	UFUNCTION()
	void SetCavernChaseHighlights(bool bIsActive)
	{
		if (bIsActive)
			PlayerOwner.ApplySettings(CavernChaseHighlights, this);
		else	
			PlayerOwner.ClearSettingsWithAsset(CavernChaseHighlights, this);
	}

	UFUNCTION()
	void ActivateTopDownMode()
	{
		bTopDownMode = true;
		OnTopDownActivated.Broadcast();
		PlayerOwner.ApplyGameplayPerspectiveMode(EPlayerMovementPerspectiveMode::TopDown, this);
		PlayerOwner.ApplySettings(TopDownHighlight, this);
		PlayerOwner.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::DefaultEvenFullscreen, this, EInstigatePriority::High);
	}

	UFUNCTION()
	void DeactivateTopDownMode()
	{
		bTopDownMode = false;
		OnTopDownDeactivated.Broadcast();
		PlayerOwner.ClearGameplayPerspectiveMode(this);
		PlayerOwner.ClearSettingsWithAsset(TopDownHighlight, this);
		PlayerOwner.ClearOtherPlayerIndicatorMode(this);
	}

	void ConsumeJumpInput()
	{
		bWantToJump = false;
		bJumpInputConsumed = true;
		bHasTouchedGroundSinceLastJump = false;
	}

	//We need a way of getting the teen dragon for specific sequences when they get replaced. Adding this for now, but please change (and let me know) if no good. <3 John.
	ATeenDragon GetTeenDragon()
	{
		return TeenDragon;
	}
};

namespace TeenDragon
{
	UFUNCTION(BlueprintPure, Category = "Player Dragon")
	ATeenDragon GetPlayerTeenDragon(AHazePlayerCharacter Player)
	{
		UPlayerTeenDragonComponent TeenDragonComp = UPlayerTeenDragonComponent::Get(Player);
		if(TeenDragonComp == nullptr)
			return nullptr;

		return TeenDragonComp.GetTeenDragon();
	}
}