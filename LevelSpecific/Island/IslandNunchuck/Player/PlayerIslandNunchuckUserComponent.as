
struct FPlayerIslandNunchuckInternalPendingHitTrace
{
	FIslandNunchuckDamage Damage;
	int AvailableImpacts = 0;
	float Radius = 0;
	FName TraceBone = NAME_None;
	FVector ActorLocalOffset = FVector::ZeroVector;
	bool bApplyHitStop = true;
	FIslandNunchuckHitStopData HitStopData;

	FPlayerIslandNunchuckInternalPendingHitTrace()
	{

	}

	FPlayerIslandNunchuckInternalPendingHitTrace(FIslandNunchuckMoveImpactData Other)
	{
		Damage.Type = Other.Type;
		AvailableImpacts = Other.ImpactCount;
		Radius = Other.ImpactRadius;
		TraceBone = Other.ImpactTraceBone;
		ActorLocalOffset = Other.ImpactTraceActorLocalOffset;
		if(Other.ApplyHitStopOnImpactType == EIslandNunchuckHitStopApplyType::Default)
		{
			bApplyHitStop = true;
			HitStopData.Duration = (1.0/30.0);
			HitStopData.DeltaTimeMultiplier = 0;
		}
		else if(Other.ApplyHitStopOnImpactType == EIslandNunchuckHitStopApplyType::Default)
		{
			bApplyHitStop = true;
			HitStopData = Other.CustomHitStop;
		}
	}
}

enum EIslandNunchuckHitStopApplyType
{
	None,
	Default,
	Custom
}

struct FIslandNunchuckHitStopData
{
	UPROPERTY(Category = "HitStop")
	float Duration = 0.1;

	UPROPERTY(Category = "HitStop", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float DeltaTimeMultiplier = 0.0;
}

struct FIslandNunchuckMoveImpactData
{
	/**
	 * What type of damage this move applies to the impact component.
	 * Its a direct link to the 'IslandNunchuckDamageSettings' on the actor.
	 */
	UPROPERTY(Category = "Damage", meta = (ShowOnlyInnerProperties))
	EIslandNunchuckDamageType Type = EIslandNunchuckDamageType::Normal;

	// should we apply the 'CombatHitStopSettings' setting the actor in a freeze frame when we have an impact
	UPROPERTY(Category = "HitStop")
	EIslandNunchuckHitStopApplyType ApplyHitStopOnImpactType = EIslandNunchuckHitStopApplyType::Default;
	
	UPROPERTY(Category = "HitStop", meta = (EditCondition = "ApplyHitStopOnImpactType == EIslandNunchuckHitStopApplyType::Custom", EditConditionHides))
	FIslandNunchuckHitStopData CustomHitStop;

	/** How many imapcts can we trigger. Use -1 to trigger infinite within the radius
	 * This is only used when there is no active 'UIslandNunchuckTargetableComponent'
	 * or the 'UIslandNunchuckTargetableComponent' has an active trace type
	 */
	UPROPERTY(Category = "Damage|Trace")
	int ImpactCount = 1;

	/** If we trace, we use this radius to find valid impacts */
	UPROPERTY(Category = "Damage|Trace")
	float ImpactRadius = 200;

	/** Should we trace from a bone on the actor instead of the actor position */
	UPROPERTY(Category = "Damage|Trace")
	FName ImpactTraceBone = NAME_None;

	/** Offset in the actors local space added to the trace position */
	UPROPERTY(Category = "Damage|Trace")
	FVector ImpactTraceActorLocalOffset = FVector::ZeroVector;
}


/**
 * Base class for the players sci-fi melee system.
 * Should contain BP assets.
 */
UCLASS(Abstract, HideCategories="Activation ComponentTick Variable Cooking ComponentReplication AssetUserData Collision")
class UPlayerIslandNunchuckUserComponent : UActorComponent
{
	UPROPERTY(Category = "Weapon")
	TSubclassOf<AIslandNunchuck> WeaponClass;
	
	UPROPERTY(NotEditable, BlueprintReadOnly, Category = "Weapon")
	AIslandNunchuck Weapon;

	UPROPERTY(Category = "Moves")
	UIslandNunchuckMoveAsset MovesAsset;

	AHazePlayerCharacter PlayerOwner;

	// Impacts
	TArray<FPlayerIslandNunchuckInternalPendingHitTrace> PendingTraces;
	int BlockMovementRotationCounter = 0;

	UPlayerMovementComponent MovementComponent;
	private FInstigator ActiveMoveInstigator;
	private UIslandNunchuckMoveAssetBase ActiveMove;
	private UIslandNunchuckMoveAssetBase PreviousMove;

	FVector LastTargetDirection = FVector::ZeroVector;
	float PreviousAnimationOvershotTime = 0;
	FHitResult PendingGroundImpact;

	private UIslandNunchuckTargetableComponent ActiveTarget;

	#if !RELEASE
	UHazeImmediateDrawer DebugDrawer;
	#endif

	// MOVES
	TArray<UIslandNunchuckNoValidTargetMoveAsset> NoValidTargetMoveAssets;
	TArray<UIslandNunchuckDefaultComboMoveAsset> DefaultComboMoveAssets;
	TArray<UIslandNunchuckTargetWithEndingBackflipMoveAsset> AirTargetWithEndingBackflipAssets;

	// TODO, move to a capability
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		Weapon = SpawnActor(WeaponClass);
		Weapon.AttachRootComponentTo(PlayerOwner.Mesh, n"Root", EAttachLocation::SnapToTarget);
		Weapon.WeaponComponent.PlayerOwner = PlayerOwner;
		Weapon.HideWeapon();
		MovementComponent = UPlayerMovementComponent::Get(PlayerOwner);

		#if !RELEASE
		DebugDrawer = DevMenu::RequestImmediateDevMenu(n"Nunchuck", "🦯");
		#endif

		TArray<UIslandNunchuckMoveAssetBase> Moves;
		{
			TArray<UIslandNunchuckMoveAsset> DefaultArray;
			DefaultArray.Add(MovesAsset);
			ExtractMoves(DefaultArray, Moves);
		}

		for(auto Move : Moves)
		{
			// No valid target
			{
				auto ValidMove = Cast<UIslandNunchuckNoValidTargetMoveAsset>(Move);
				if(ValidMove != nullptr)
				{
					NoValidTargetMoveAssets.AddUnique(ValidMove);	
					continue;	
				}
			}

			// Default Combo
			{
				auto ValidMove = Cast<UIslandNunchuckDefaultComboMoveAsset>(Move);
				if(ValidMove != nullptr)
				{
					DefaultComboMoveAssets.AddUnique(ValidMove);	
					continue;	
				}
			}

			// Air Target
			{
				auto ValidMove = Cast<UIslandNunchuckTargetWithEndingBackflipMoveAsset>(Move);
				if(ValidMove != nullptr)
				{
					AirTargetWithEndingBackflipAssets.AddUnique(ValidMove);	
					continue;	
				}
			}

		}
	}

	private void ExtractMoves(TArray<UIslandNunchuckMoveAsset> MoveSheets, TArray<UIslandNunchuckMoveAssetBase>& OutMoves)
	{
		// Extract all the available assets for this move
		for(auto Sheet : MoveSheets)
		{
			if(Sheet == nullptr)
				continue;
			ExtractMoves(Sheet.MoveSheets, OutMoves);
			OutMoves.Append(Sheet.Moves);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Weapon.DestroyActor();	
		Weapon = nullptr;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Temporal log
		#if !RELEASE
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG(PlayerOwner, "Nunchuck");
			if(ActiveMove != nullptr)
			{
				TemporalLog.Value("Asset", ActiveMove.Name);
				TemporalLog.Value("Chain Name", ActiveMove.ComboChainName);
				TemporalLog.Value("Chain Index", ActiveMove.ComboChainIndex);
				TemporalLog.Value("Target", ActiveTarget);
				TemporalLog.Value("Instigator", ActiveMoveInstigator);
			}
			else
			{
				TemporalLog.Value("Asset", NAME_None);
			}
		}
		#endif
	}

	bool IsInBlockedActionWindow() const
	{
		return false;
	}

	bool IsNunchuckInputBlocked() const
	{
		return false;
	}

	void SetActiveMove(UIslandNunchuckMoveAssetBase NewActiveMove, UIslandNunchuckTargetableComponent Target, FInstigator Instigator)
	{
		ActiveTarget = Target;
		ActiveMove = NewActiveMove;
		ActiveMoveInstigator = Instigator;

		FIslandNunchuckAttackData EffectData;
		EffectData.AttackName = ActiveMove.ComboChainName;
		EffectData.ComboIndex = ActiveMove.ComboChainIndex;
		EffectData.bIsFinalAttackInComboChain = NewActiveMove.bEndComboChain;
		UIslandNunchuckEffectHandler::Trigger_AttackStarted(PlayerOwner, EffectData);	
	}

	void ClearActiveMove(FInstigator Instigator)
	{
		if(ActiveMoveInstigator != Instigator)
			return;
		
		if(ActiveMove != nullptr)
		{
			FIslandNunchuckAttackData EffectData;
			EffectData.AttackName = ActiveMove.ComboChainName;
			EffectData.ComboIndex = ActiveMove.ComboChainIndex;
			EffectData.bIsFinalAttackInComboChain = ActiveMove.bEndComboChain;
			UIslandNunchuckEffectHandler::Trigger_AttackCompleted(PlayerOwner, EffectData);	
		}

		PreviousMove = ActiveMove;
		ActiveMoveInstigator = FInstigator();
		ActiveMove = nullptr;
		ActiveTarget = nullptr;
	}

	UIslandNunchuckTargetableComponent GetActiveMoveTarget() const
	{
		return ActiveTarget;
	}

	bool HasInstigatedCurrentMove(FInstigator Instigator) const
	{
		if (ActiveMove == nullptr)
			return false;

		if (Instigator != ActiveMoveInstigator)
			return false;
		
		return true;
	}

	bool HasActiveMove() const
	{
		return ActiveMove != nullptr;
	}

	bool WasMoveRecentlyActivated(UIslandNunchuckMoveAssetBase Move) const
	{
		return Move == PreviousMove;
	}

	bool ValidateComboChain(UIslandNunchuckMoveAssetBase Asset) const
	{
		// No active combo chain
		if(PreviousMove == nullptr 
			|| !PreviousMove.IsValidComboChain() 
			|| PreviousMove.bEndComboChain)
		{
			if(!Asset.IsValidComboChain())
				return true;

			if(Asset.ComboChainIndex == 1)
				return true;

			return false;
		}
		// We have an active combo chain
		else
		{
			if(Asset.ComboChainName != PreviousMove.ComboChainName)
				return false;

			if(Asset.ComboChainIndex != PreviousMove.ComboChainIndex + 1)
				return false;

			return true;
		}	
	}

	void ClearActiveComboChain()
	{
		if(PreviousMove == nullptr)
			return;

		PreviousMove = nullptr;
	}

	float GetAttackDistanceToTarget(UIslandNunchuckTargetableComponent Target) const
	{
		float ActualDistance = PlayerOwner.GetActorLocation().Distance(Target.WorldLocation);
		ActualDistance -= PlayerOwner.CapsuleComponent.CapsuleRadius;
		ActualDistance -= Target.KeepDistance;
		return ActualDistance;
	}
	
	// Will enable the impact data provided by the active move
	void AddAvailableImpact(FIslandNunchuckMoveImpactData ImpactData)
	{
		PendingTraces.Add(FPlayerIslandNunchuckInternalPendingHitTrace(ImpactData));
	}
}
