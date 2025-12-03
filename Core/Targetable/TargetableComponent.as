
struct FTargetableTriggerPlayerData
{
	TArray<FInstigator> DisableInstigators;
	bool bRegistered = false;
	bool bShouldBeConsidered = true;
};

#if !RELEASE
struct FTargetableQueryTraceDebug
{
	FString TraceTag;
	FHitResult Hit;
	FHazeTraceShape TraceShape;
	FVector ShapeWorldOffset;

	FTargetableQueryTraceDebug(
		FString InTraceTag,
		FHitResult InHit,
		FHazeTraceShape InTraceShape,
		FVector InShapeWorldOffset
	)
	{
		TraceTag = InTraceTag;
		Hit = InHit;
		TraceShape = InTraceShape;
		ShapeWorldOffset = InShapeWorldOffset;
	}
}
#endif

struct FTargetableQuery
{
	UTargetableComponent Component;
	AHazePlayerCharacter Player;

	bool bIsDisabled = false;
	bool bWasPreviousPrimary = false;

	float DistanceToTargetable = -1.0;
	bool bDistanceAppliedToScore = false;
	bool bHasPerformedTrace = false;
	bool bHasHandledVisibility = false;

	FName QueryCategory;

	EPlayerTargetingMode TargetingMode;
	FVector ViewLocation;
	FRotator ViewRotation;
	FVector ViewForwardVector;
	FVector PlayerMovementInput;
	FVector PlayerFacingInputDirection;
	FVector PlayerTargetingInput;
	FVector PlayerNonLockedMovementInput;
	FVector PlayerWorldUp;
	FVector PlayerLocation;
	FVector TargetableLocation;
	UHazeMovementComponent PlayerMovementComponent;

	UTargetableComponent CurrentEvalPrimaryTarget;
	float CurrentEvalPrimaryScore = -1.0;
	float CurrentEvalPrimaryFilterScore = 0.0;
	float CurrentEvalPrimaryFilterScoreThreshold = 0.0;

	FAimingRay AimRay;

	FTargetableResult Result;

	#if !RELEASE
	TArray<FTargetableQueryTraceDebug> DebugTraces;
	#endif

	bool Is2DTargeting() const
	{
		return (TargetingMode != EPlayerTargetingMode::ThirdPerson && TargetingMode != EPlayerTargetingMode::MovingTowardsCamera);
	}

	bool IsCurrentScoreViableForPrimary() const
	{
		if (Result.FilterScore < CurrentEvalPrimaryFilterScore - CurrentEvalPrimaryFilterScoreThreshold)
			return false;
		if (Result.FilterScore - Result.FilterScoreThreshold > CurrentEvalPrimaryFilterScore)
			return true;
		if (Result.Score < CurrentEvalPrimaryScore)
			return false;
		return true;
	}
};

class UTargetableComponent : USceneComponent
{
	access EditOnly = private, * (readonly, editdefaults);

	// Targetable category. One targetable per category can be targeted.
	access:EditOnly
	FName TargetableCategory;

	// Which players can use this targetable
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Targetable")
	access:EditOnly
	EHazeSelectPlayer UsableByPlayers = EHazeSelectPlayer::Both;

	// If checked, still show the widget even if not usable for that player
	UPROPERTY(EditAnywhere, BlueprintReadOnly, AdvancedDisplay, Category = "Targetable")
	bool bShowForOtherPlayer = false;

	// Whether to show the widget when the targetable is disabled
	UPROPERTY(EditAnywhere, BlueprintReadOnly, AdvancedDisplay, Category = "Targetable")
	bool bShowWhileDisabled = false;

	// Widget type that should be rendered for this targetable
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Visuals", AdvancedDisplay)
	TSubclassOf<UTargetableWidget> WidgetClass;

	// Relative offset of targetable widget to the component location
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Visuals", Meta = (MakeEditWidget))
	FVector WidgetVisualOffset;

	/**
	 * Override from subclass to determine targeting behavior
	 * 
	 * See the Targetable:: helper namespace for standard targeting check functions.
	 */
	bool CheckTargetable(FTargetableQuery& Query) const
	{
		return false;
	}

	/**
	 * Can be overridden to update additional data inside the widget.
	 */
	void UpdateWidget(UTargetableWidget Widget, FTargetableResult QueryResult) const
	{
	}

	/**
	 * Can be overridden to dynamically determine the attach offset of the widget.
	 */
	FVector CalculateWidgetVisualOffset(AHazePlayerCharacter Player, UTargetableWidget Widget) const
	{
		return WidgetVisualOffset;
	}

	/**
	 * Can be overridden to dynamically determine where the widget should be attached.
	 */
	USceneComponent GetWidgetAttachComponent(AHazePlayerCharacter Player, UTargetableWidget Widget)
	{
		return this;
	}

	/**
	 * Whether this targetable is fully disabled.
	 * Fully disabled means neither player is currently able to use it.
	 */
	UFUNCTION(BlueprintPure)
	bool IsDisabled() const
	{
		for (auto Player : Game::GetPlayersSelectedBy(UsableByPlayers))
		{
			if (!IsDisabledForPlayer(Player))
				return false;
		}
		return true;
	}

	/**
	 * Whether this targetable is currently disabled for a specific player.
	 * Targetables that are not set to be usable by this player at all are also considered disabled for that player.
	 */
	UFUNCTION(BlueprintPure)
	bool IsDisabledForPlayer(AHazePlayerCharacter Player) const
	{
		if (Player == nullptr)
			return true;
		if (!Player.IsSelectedBy(UsableByPlayers))
			return true;
		if (Owner == nullptr || Owner.IsActorBeingDestroyed() || IsBeingDestroyed())
			return true;
		return TriggerPlayerData[Player].DisableInstigators.Num() != 0;
	}

	/**
	 * Disable this targetable for both players.
	 */
	UFUNCTION()
	void Disable(FInstigator Instigator)
	{
		for (auto Player : Game::Players)
			DisableForPlayer(Player, Instigator);
	}

	/**
	 * Enable this targetable for both players.
	 */
	UFUNCTION()
	void Enable(FInstigator Instigator)
	{
		for (auto Player : Game::Players)
			EnableForPlayer(Player, Instigator);
	}

	/**
	 * Disable this targetable for a specific player.
	 */
	UFUNCTION()
	void DisableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if (Player == nullptr)
			return;

		FTargetableTriggerPlayerData& Data = TriggerPlayerData[Player];
		bool bWasEnabled = Data.DisableInstigators.Num() == 0;
		Data.DisableInstigators.AddUnique(Instigator);

		UpdateRegistration(Player);

		if (bWasEnabled)
			OnUpdateEnableStatus(Player, false);
	}

	/**
	 * Enable this targetable for a specific player.
	 */
	UFUNCTION()
	void EnableForPlayer(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		if (Player == nullptr)
			return;

		FTargetableTriggerPlayerData& Data = TriggerPlayerData[Player];
		bool bWasEnabled = Data.DisableInstigators.Num() == 0;

		Data.DisableInstigators.Remove(Instigator);

		UpdateRegistration(Player);

		if (!bWasEnabled && Data.DisableInstigators.Num() == 0)
			OnUpdateEnableStatus(Player, true);
	}

// ===============

	/**
	 * Subclasses can set the targetable to be considered or not.
	 * Usually based on the player being in a volume or not.
	 */
	protected void SetTargetableConsidered(AHazePlayerCharacter Player, bool bConsidered)
	{
		FTargetableTriggerPlayerData& Data = TriggerPlayerData[Player];
		if (Data.bShouldBeConsidered == bConsidered)
			return;

		Data.bShouldBeConsidered = bConsidered;
		UpdateRegistration(Player);
	}

	/**
	 * Can be overridden to add behavior when the disable status changes.
	 */
	protected void OnUpdateEnableStatus(AHazePlayerCharacter Player, bool bEnabled)
	{
	}

// ===============

	private TPerPlayer<FTargetableTriggerPlayerData> TriggerPlayerData;
	private bool bIsActorDisabled;

	void SetUsableByPlayers(EHazeSelectPlayer Players)
	{
		UsableByPlayers = Players;

		if (HasBegunPlay())
		{
			for (auto Player : Game::Players)
				UpdateRegistration(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::Players)
			UpdateRegistration(Player);
	}

	private void UpdateRegistration(AHazePlayerCharacter Player)
	{
		FTargetableTriggerPlayerData& Data = TriggerPlayerData[Player];

		bool bRegister = Data.bShouldBeConsidered
			&& (Data.DisableInstigators.Num() == 0 || (bShowWhileDisabled && !bIsActorDisabled))
			&& (Player.IsSelectedBy(UsableByPlayers) || bShowForOtherPlayer);

		if (bRegister != Data.bRegistered)
		{
			auto Container = UPlayerTargetablesComponent::GetOrCreate(Player);
			ApplyTargetableRegistration(Container, bRegister);
			Data.bRegistered = bRegister;
		}
	}

	// Can be overridden for special cases that should have the same targetable in multiple categories
	protected void ApplyTargetableRegistration(UPlayerTargetablesComponent PlayerComp, bool bRegister)
	{
		if (bRegister)
			PlayerComp.RegisterTargetable(TargetableCategory, this);
		else
			PlayerComp.UnregisterTargetable(TargetableCategory, this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		for (auto Player : Game::Players)
		{
			FTargetableTriggerPlayerData& Data = TriggerPlayerData[Player];
			if (!Data.bRegistered)
				continue;

			auto Container = UPlayerTargetablesComponent::GetOrCreate(Player);
			ApplyTargetableRegistration(Container, false);
			Data.bRegistered = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	private void OnActorDisabled()
	{
		bIsActorDisabled = true;
		Disable(n"ActorDisabled");
	}

	UFUNCTION(BlueprintOverride)
	private void OnActorEnabled()
	{
		bIsActorDisabled = false;
		Enable(n"ActorDisabled");
	}
};