
event void FOnPlayerAttachedToSwingPointSignature(AHazePlayerCharacter Player, USwingPointComponent SwingPoint);
event void FOnPlayerDetachedFromSwingPointSignature(AHazePlayerCharacter Player, USwingPointComponent SwingPoint);
event void FOnGrappleHookReachedSwingPointSignature(AHazePlayerCharacter Player, USwingPointComponent SwingPoint);

UCLASS(Meta = (EditorSpriteTexture = "/Game/Gameplay/Movement/ContextualMoves/ContextualMovesEditorTexture/SwingIconBillboardGradient.SwingIconBillboardGradient"))
class USwingPointComponent : UContextualMovesTargetableComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	default ActivationRange = 1500.0;
	default AdditionalVisibleRange = 1500.0;
	default bTestCollision = true;
	default bVisualizeComponent = true;

	UPROPERTY(Category = Settings, EditAnywhere)
	UPlayerSwingPointSettings SettingsAsset;

	UPROPERTY(Category = Settings, EditAnywhere, meta = (ClampMin="0.0", Units = "Seconds"))
	float ActivationCooldown = 1;

	/*
	 * Range From the point to the center of the character
	 */
	UPROPERTY(Category = Settings, EditAnywhere, meta = (EditCondition = "SettingsAsset==nullptr", EditConditionHides, ClampMin="400.0"))
	float TetherLength = 800.0;

	/**
	 * When the swing point accelerates, apply inertia to the swing movement.
	 */
	UPROPERTY(Category = "Settings", EditAnywhere)
	bool bApplyInertiaFromMovingSwingPoint = true;

	/**
	 * Percentage of the swing point's movement to apply as inertia.
	 * Reducing this below 1.0 will make the player swing influenced less strongly by the swing point's movement.
	 */
	UPROPERTY(Category = "Settings", EditAnywhere, AdvancedDisplay, Meta = (EditCondition = "bApplyInertiaFromMovingSwingPoint", EditConditionHides))
	float MovingSwingInertiaFactor = 1.0;

	/**
	 * Whether the player should follow the yaw rotation if the swing point rotates.
	 */
	UPROPERTY(Category = "Settings", EditAnywhere, AdvancedDisplay, Meta = (EditCondition = "bApplyInertiaFromMovingSwingPoint", EditConditionHides))
	bool bFollowYawRotationOfSwingPoint = true;

	// Don't use any camera or input based aiming for this swing point, only target by closest distance
	UPROPERTY(Category = "Targetable", EditAnywhere, AdvancedDisplay)
	bool bTargetByDistanceOnly = false;

	// Will be activated when you activate the swing point, and cleared when you stop swinging
	UPROPERTY(Category = Settings|Camera, EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings = nullptr;

	UPROPERTY(EditInstanceOnly ,Category = "Settings", AdvancedDisplay)
	bool bDisallowSwingFromSwimming = true;

	UPROPERTY(EditAnywhere, Category = "Audio")
	FSoundDefReference SwingPointSoundDef;

	TPerPlayer<bool> bIsPlayerUsingPoint;
	TPerPlayer<float> Cooldown;

	UPROPERTY()
	FOnPlayerAttachedToSwingPointSignature OnPlayerAttachedEvent;
	UPROPERTY()
	FOnPlayerDetachedFromSwingPointSignature OnPlayerDetachedEvent;
	UPROPERTY()
	FOnGrappleHookReachedSwingPointSignature OnGrappleHookReachedSwingPointEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if(SwingPointSoundDef.SoundDef.IsValid())
		{
			SwingPointSoundDef.SpawnSoundDefAttached(Owner, Owner);
		}
	}

	UFUNCTION()
	void ForceActivateSwingPoint(AHazePlayerCharacter Player)
	{
		UPlayerSwingComponent PlayerSwingComp = UPlayerSwingComponent::GetOrCreate(Player);
		PlayerSwingComp.Data.SwingPointToForceActivate = this;
	}

	void OnPlayerAttached(AHazePlayerCharacter Player)
	{
		bIsPlayerUsingPoint[Player] = true;

		OnPlayerAttachedEvent.Broadcast(Player, this);
	}

	void OnPlayerDetached(AHazePlayerCharacter Player)
	{
		Cooldown[Player] = ActivationCooldown;
		SetComponentTickEnabled(true);

		bIsPlayerUsingPoint[Player] = false;

		OnPlayerDetachedEvent.Broadcast(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) final
	{
		bool bAnyOnCooldown = false;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Cooldown[Player] > 0)
				bAnyOnCooldown = true;
			if (bIsPlayerUsingPoint[Player])
				continue;
			Cooldown[Player] -= DeltaTime;
		}

		if (!bAnyOnCooldown)
			SetComponentTickEnabled(false);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(Query.Player.IsCapabilityTagBlocked(PlayerSwingTags::SwingPointQuery))
		{
			Query.Result.Score = 0;
			return false;
		}

		if (!VerifyBaseTargetableConditions(Query))
			return false;

		// Remove the one you are already on
		if (bIsPlayerUsingPoint[Query.Player])
			return false;

		if (Cooldown[Query.Player] > 0.0)
			return false;
		
		Targetable::ApplyVisibleRange(Query, ActivationRange + AdditionalVisibleRange);
		Targetable::ApplyTargetableRangeWithBuffer(Query, ActivationRange, ActivationBufferRange);
		Targetable::ApplyVisualProgressFromRange(Query, ActivationRange + AdditionalVisibleRange, ActivationRange, ActivationBufferRange);
		Targetable::RequireCapabilityTagNotBlocked(Query, PlayerMovementTags::Swing);

		if (bTargetByDistanceOnly)
			Targetable::ApplyDistanceToScore(Query);
		else
			Targetable::ScoreLookAtAim(Query, false);

		if (bTestCollision)
		{
			// Avoid tracing if we are already lower score than the current primary target
			if (!Query.IsCurrentScoreViableForPrimary())
				return false;
			return Targetable::RequireNotOccludedFromCamera(Query, bIgnoreOwnerCollision = bIgnorePointOwner);
		}

		return true;
	}
	
	void ApplySettings(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if (SettingsAsset != nullptr)
			Player.ApplySettings(SettingsAsset, Instigator);
		else
			UPlayerSwingPointSettings::SetTetherLength(Player, TetherLength, Instigator);
	}
}

#if EDITOR
class USwingPointVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USwingPointComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        USwingPointComponent Comp = Cast<USwingPointComponent>(Component);
        if (Comp == nullptr)
            return;		

		if(!Comp.bAlwaysVisualizeRanges)
		{
			if(Comp.TetherLength > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.TetherLength + 82, FLinearColor::LucBlue, Thickness = 2.0, Segments = 12);
			if(Comp.ActivationRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange, FLinearColor::Blue, Thickness = 2.0, Segments = 12);	
			DrawWireSphere(Comp.WorldLocation, Comp.ActivationRange + Comp.AdditionalVisibleRange, FLinearColor::Purple, 2.0, 12.0);
			if(Comp.MinimumRange > 0.0)
				DrawWireSphere(Comp.WorldLocation, Comp.MinimumRange, FLinearColor::Red, 2.0, 12.0);
		}
    }
}
#endif