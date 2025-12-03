enum ETundraShapeshiftShape
{
	None,
	Small,
	Player,
	Big
}

enum ETundraShapeshiftActiveShape
{
	Small,
	Player,
	Big
}

struct FShapeShiftTriggerData
{
	ETundraShapeshiftShape Type = ETundraShapeshiftShape::None;
	bool bUseEffect = false;
	// There are some cases where we always want to force a shapeshift, like just before a cutscene is triggered.
	bool bCheckCollision = true;
}

struct FTundraShapeshiftingAnimData
{
	float MorphAlpha = 0.0;
}

struct FTundraShapeshiftBlockGravityLerpingData
{
	bool bRemoveWhenGravityCanBeSnapped;

	// If we could snap when adding this blocker we must wait until we can no longer snap until we can actually clear this blocker.
	bool bCanClear;
}

delegate bool FOnShapeshiftLocationOverride(AHazePlayerCharacter Player, ETundraShapeshiftShape FromShape, ETundraShapeshiftShape ToShape, FVector& OutLocationOffset);

struct FOnShapeshiftLocationOverrideData
{
	FOnShapeshiftLocationOverride Delegate;
	bool bConsume;
}

event void FOnChangeShape(AHazePlayerCharacter Player, ETundraShapeshiftShape NewShape);

UCLASS(Abstract, NotPlaceable)
class UTundraPlayerShapeshiftingComponent : UActorComponent
{
	access ShapeshiftingSystem = private, UTundraPlayerShapeshiftingCapability, UTundraPlayerShapeshiftingMorphCapability, UTundraPlayerShapeshiftingMorphFailCapability;

	private bool bHasBegunPlay = false;

	UPROPERTY(Category = "Shape")
	UHazeCapabilitySheet SmallFormSheet;

	UPROPERTY(Category = "Shape")
	UHazeCapabilitySheet BigFormSheet;

	UPROPERTY()
	FOnChangeShape OnChangeShape;

	UTundraPlayerShapeshiftingSettings Settings;
	AHazePlayerCharacter Player;
	UTundraPlayerShapeBaseComponent SmallShapeComponent;
	UTundraPlayerShapeBaseComponent BigShapeComponent;

	UPlayerMovementComponent MoveComp;
	UPlayerPoleClimbComponent PoleClimbComp;
	UPlayerGrappleComponent GrappleComp;
	UPlayerWallRunComponent WallRunComp;
	UPlayerSwimmingComponent SwimmingComp;
	UPlayerSwingComponent SwingComp;

	float CurrentMorphDuration;
	float OriginalPlayerGravityAmount;
	float OriginalPlayerTerminalVelocity;

	private	FShapeShiftTriggerData CurrentShapeTypeInternal;
	private FShapeShiftTriggerData PreviousShapeTypeInternal;
	access:ShapeshiftingSystem ETundraShapeshiftShape CurrentMorphFailShapeTarget;
	access:ShapeshiftingSystem ETundraShapeshiftShape PreviousMorphFailShapeTarget;
	access:ShapeshiftingSystem bool bIsMorphing = false;
	access:ShapeshiftingSystem bool bIsFailMorphing = false;
	
	FShapeShiftTriggerData ForceShapeOverride;
	FShapeShiftTriggerData InputShapeRequest;

	private TArray<FInstigator> BigShapeBlockers;
	private TArray<FInstigator> SmallShapeBlockers;
	private TArray<FInstigator> PlayerShapeBlockers;
	
	private TArray<FInstigator> ShapeBlockedPlayFailEffectBlockers;

	private TArray<FInstigator> SpawnAsHumanBlockers;
	private TMap<FInstigator, FTundraShapeshiftBlockGravityLerpingData> GravityLerpBlockers;
	private TInstigated<FOnShapeshiftLocationOverrideData> InstigatedShapeshiftLocationOverride;

	FVector2D PlayerCollisionSize;
	float PlayerPoleClimbMaxHeightOffset;
	float TimeOfLastShapeshift = -100;
	uint FrameOfLastShapeshift = 0;
	bool bOutlineVisible = true;
	FTundraShapeshiftingAnimData AnimData;
	FHazeAcceleratedFloat AcceleratedGravityAmount;
	FHazeAcceleratedFloat AcceleratedTerminalVelocity;
	float TimeOfLastShapeshiftFail = -100.0;
	TMap<ETundraShapeshiftActiveShape, float> TimeOfLastShapeshiftFromShape;
	default TimeOfLastShapeshiftFromShape.Add(ETundraShapeshiftActiveShape::Small, -100.0);
	default TimeOfLastShapeshiftFromShape.Add(ETundraShapeshiftActiveShape::Player, -100.0);
	default TimeOfLastShapeshiftFromShape.Add(ETundraShapeshiftActiveShape::Big, -100.0);

	// Apply settings For shape stuff
	TArray<FTundraShapeshiftingApplySettingsForShapeData> SmallShapeExternalSettings;
	TArray<FTundraShapeshiftingApplySettingsForShapeData> PlayerShapeExternalSettings;
	TArray<FTundraShapeshiftingApplySettingsForShapeData> BigShapeExternalSettings;

	// Apply camera settings for shape stuff
	TArray<FTundraShapeshiftingApplyCameraSettingsForShapeData> SmallShapeExternalCameraSettings;
	TArray<FTundraShapeshiftingApplyCameraSettingsForShapeData> PlayerShapeExternalCameraSettings;
	TArray<FTundraShapeshiftingApplyCameraSettingsForShapeData> BigShapeExternalCameraSettings;

	// Temporal log stuff
	const FString IsCollisionValidCategory = "1#Is Collision Valid";
	const FString IsCollisionValidTracesCategory = "3#Is Collision Valid Traces";
	UTundraPlayerShapeshiftingIgnoreCollisionContainerComponent IgnoreCollisionContainerComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(GetOwner());
		Settings = UTundraPlayerShapeshiftingSettings::GetSettings(Player);

		float32 Radius = 0.0;
		float32 HalfHeight = 0.0;
		Player.CapsuleComponent.GetUnscaledCapsuleSize(Radius, HalfHeight);
		PlayerCollisionSize = FVector2D(Radius, HalfHeight);
		PlayerPoleClimbMaxHeightOffset = UPlayerPoleClimbSettings::GetSettings(Player).MaxHeightOffset;

		// Start as the player
		CurrentShapeTypeInternal.Type = ETundraShapeshiftShape::Player;
		bHasBegunPlay = true;

		IgnoreCollisionContainerComp = UTundraPlayerShapeshiftingIgnoreCollisionContainerComponent::GetOrCreate(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		GrappleComp = UPlayerGrappleComponent::Get(Player);
		WallRunComp = UPlayerWallRunComponent::Get(Player);
		SwimmingComp = UPlayerSwimmingComponent::Get(Player);
		SwingComp = UPlayerSwingComponent::Get(Player);

		auto GravitySettings = UMovementGravitySettings::GetSettings(Player);
		OriginalPlayerGravityAmount = GravitySettings.GravityAmount;
		OriginalPlayerTerminalVelocity = GravitySettings.TerminalVelocity;
		AcceleratedGravityAmount.SnapTo(OriginalPlayerGravityAmount);
		AcceleratedTerminalVelocity.SnapTo(OriginalPlayerTerminalVelocity);

		UMovementGravitySettings::SetGravityAmount(Player, AcceleratedGravityAmount.Value, this);
		UMovementGravitySettings::SetTerminalVelocity(Player, AcceleratedTerminalVelocity.Value, this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HandleLerpGravity(DeltaTime);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog
		.Value(f"Time Of Last Shapeshift", TimeOfLastShapeshift)
		.Value("Current Shape Type", CurrentShapeType);

		TemporalLogBlocksOnActor(SmallShapeComponent.GetShapeActor(), Player.IsMio() ? n"Otter" : n"Fairy");
		TemporalLogBlocksOnActor(BigShapeComponent.GetShapeActor(), Player.IsMio() ? n"SnowGorilla" : n"TreeGuardian");
#endif
	}

#if !RELEASE
	private void TemporalLogBlocksOnActor(AHazeCharacter ShapeActor, FName DebugActorName)
	{
		TArray<FString> ActorDisables;
		TArray<FActorBlockInstigatorDebugStatus> ActorBlocks;
		TArray<FComponentBlockInstigatorDebugStatus> ComponentBlocks;
		ShapeActor.GetDisableInstigatorsDebugInformation(ActorDisables);
		ShapeActor.GetBlockInstigatorsDebugInformation(ActorBlocks);
		ShapeActor.Mesh.GetBlockInstigatorsDebugInformation(ComponentBlocks);

		if(ShapeActor.bHidden)
			TEMPORAL_LOG(this).Value(f"{DebugActorName} Blocks;Actor Hidden In Game", true);

		if(ShapeActor.Mesh.bHiddenInGame)
			TEMPORAL_LOG(this).Value(f"{DebugActorName} Blocks;Mesh Hidden In Game", true);

		if(!ShapeActor.Mesh.bVisible)
			TEMPORAL_LOG(this).Value(f"{DebugActorName} Blocks;Mesh Visible", false);

		for(int i = 0; i < ActorDisables.Num(); i++)
		{
			FString Disable = ActorDisables[i];
			TEMPORAL_LOG(this)
				.Value(f"{DebugActorName} Blocks;{DebugActorName} Actor Disable [{i}]", Disable)
			;
		}

		for(int i = 0; i < ActorBlocks.Num(); i++)
		{
			FActorBlockInstigatorDebugStatus Block = ActorBlocks[i];
			TEMPORAL_LOG(this)
				.Value(f"{DebugActorName} Blocks;Actor Block [{i}] Instigator", Block.Instigator)
				.Value(f"{DebugActorName} Blocks;Actor Block [{i}] bHasBlockedCollision", Block.bHasBlockedCollision)
				.Value(f"{DebugActorName} Blocks;Actor Block [{i}] bHasBlockedTick", Block.bHasBlockedTick)
				.Value(f"{DebugActorName} Blocks;Actor Block [{i}] bHasBlockedVisuals", Block.bHasBlockedVisuals)
			;
		}

		for(int i = 0; i < ComponentBlocks.Num(); i++)
		{
			FComponentBlockInstigatorDebugStatus Block = ComponentBlocks[i];
			TEMPORAL_LOG(this)
				.Value(f"{DebugActorName} Blocks;Mesh Block [{i}] Instigator", Block.Instigator)
				.Value(f"{DebugActorName} Blocks;Mesh Block [{i}] bHasBlockedCollision", Block.bHasBlockedCollision)
				.Value(f"{DebugActorName} Blocks;Mesh Block [{i}] bHasBlockedTick", Block.bHasBlockedTick)
				.Value(f"{DebugActorName} Blocks;Mesh Block [{i}] bHasBlockedVisuals", Block.bHasBlockedVisuals)
			;
		}
	}
#endif

	void HandleLerpGravity(float DeltaTime)
	{
		float TargetGravityAmount = GetGravityAmountForShape(CurrentShapeType);
		float TargetTerminalVelocity = GetTerminalVelocityForShape(CurrentShapeType);
		float BlendTime = GetGravityBlendTimeForShape(CurrentShapeType, PreviousShapeType);
		bool bShouldSnap = ShouldSnapGravityForShape(CurrentShapeType);

		HandleRemoveGravityLerpBlockersWithSnapGravityBool(bShouldSnap);

		if(IsGravityLerpBlocked())
			return;

		if(TargetGravityAmount == AcceleratedGravityAmount.Value && TargetTerminalVelocity == AcceleratedTerminalVelocity.Value)
			return;

		devCheck(BlendTime >= 0.0, "Tried to lerp gravity with negative blend time");

		if(bShouldSnap)
		{
			AcceleratedGravityAmount.SnapTo(TargetGravityAmount);
			AcceleratedTerminalVelocity.SnapTo(TargetTerminalVelocity);
		}
		else
		{
			AcceleratedGravityAmount.AccelerateTo(TargetGravityAmount, BlendTime, DeltaTime);
			AcceleratedTerminalVelocity.AccelerateTo(TargetTerminalVelocity, BlendTime, DeltaTime);
		}
		
		UMovementGravitySettings::SetGravityAmount(Player, AcceleratedGravityAmount.Value, this);
		UMovementGravitySettings::SetTerminalVelocity(Player, AcceleratedTerminalVelocity.Value, this);
	}

	void AddGravityLerpBlocker(FInstigator Instigator, bool bRemoveWhenGravityCanBeSnapped = true)
	{
		FTundraShapeshiftBlockGravityLerpingData Data;
		Data.bRemoveWhenGravityCanBeSnapped = bRemoveWhenGravityCanBeSnapped;

		Data.bCanClear = !ShouldSnapGravityForShape(CurrentShapeType);
		GravityLerpBlockers.FindOrAdd(Instigator) = Data;
	}

	void RemoveGravityLerpBlocker(FInstigator Instigator)
	{
		GravityLerpBlockers.Remove(Instigator);
	}

	bool IsGravityLerpBlocked()
	{
		return GravityLerpBlockers.Num() > 0;
	}

	private void HandleRemoveGravityLerpBlockersWithSnapGravityBool(bool bShouldSnap)
	{
		for(auto& Pair : GravityLerpBlockers)
		{
			if(!Pair.Value.bCanClear && !bShouldSnap)
				Pair.Value.bCanClear = true;

			if(Pair.Value.bRemoveWhenGravityCanBeSnapped && Pair.Value.bCanClear && bShouldSnap)
				Pair.RemoveCurrent();
		}
	}

	float GetPlayerPoleClimbMaxHeightOffset() const
	{
		return PlayerPoleClimbMaxHeightOffset;
	}

	bool PlayerShouldSnapGravity() const
	{
		if(MoveComp.HasGroundContact())
			return true;

		if(PoleClimbComp.IsClimbing())
			return true;

		if(GrappleComp.Data.GrappleState != EPlayerGrappleStates::Inactive)
			return true;

		if(WallRunComp.HasActiveWallRun())
			return true;

		if(SwimmingComp.IsSwimming())
			return true;

		if(SwingComp.HasActivateSwingPoint())
			return true;

		return false;
	}

	TArray<FTundraShapeshiftingApplySettingsForShapeData>& GetExternalSettingsArrayForShape(ETundraShapeshiftActiveShape Shape)
	{
		if(Shape == ETundraShapeshiftActiveShape::Small)
			return SmallShapeExternalSettings;

		if(Shape == ETundraShapeshiftActiveShape::Player)
			return PlayerShapeExternalSettings;

		if(Shape == ETundraShapeshiftActiveShape::Big)
			return BigShapeExternalSettings;

		devError("Forgot to add case");
		return SmallShapeExternalSettings;
	}

	TArray<FTundraShapeshiftingApplyCameraSettingsForShapeData>& GetExternalCameraSettingsArrayForShape(ETundraShapeshiftActiveShape Shape)
	{
		if(Shape == ETundraShapeshiftActiveShape::Small)
			return SmallShapeExternalCameraSettings;

		if(Shape == ETundraShapeshiftActiveShape::Player)
			return PlayerShapeExternalCameraSettings;

		if(Shape == ETundraShapeshiftActiveShape::Big)
			return BigShapeExternalCameraSettings;

		devError("Forgot to add case");
		return SmallShapeExternalCameraSettings;
	}
	
	private void HandleExternalSettingsForCurrentShape()
	{
		// Composable settings
		TArray<FTundraShapeshiftingApplySettingsForShapeData>& PreviousShapeArray = GetExternalSettingsArrayForShape(PreviousActiveShapeType);
		TArray<FTundraShapeshiftingApplySettingsForShapeData>& CurrentShapeArray = GetExternalSettingsArrayForShape(ActiveShapeType);

		for(FTundraShapeshiftingApplySettingsForShapeData Data : PreviousShapeArray)
		{
			Player.ClearSettingsWithAsset(Data.SettingsAsset, Data.Instigator);
		}

		for(FTundraShapeshiftingApplySettingsForShapeData Data : CurrentShapeArray)
		{
			Player.ApplySettings(Data.SettingsAsset, Data.Instigator, Data.Priority);
		}

		// Camera settings
		TArray<FTundraShapeshiftingApplyCameraSettingsForShapeData>& PreviousCameraShapeArray = GetExternalCameraSettingsArrayForShape(PreviousActiveShapeType);
		TArray<FTundraShapeshiftingApplyCameraSettingsForShapeData>& CurrentCameraShapeArray = GetExternalCameraSettingsArrayForShape(ActiveShapeType);

		for(FTundraShapeshiftingApplyCameraSettingsForShapeData Data : PreviousCameraShapeArray)
		{
			Player.ClearCameraSettingsByInstigator(Data.Instigator, Data.BlendOutTime);
		}

		for(FTundraShapeshiftingApplyCameraSettingsForShapeData Data : CurrentCameraShapeArray)
		{
			Player.ApplyCameraSettings(Data.CameraSettings, Data.BlendTime, Data.Instigator, Data.Priority, Data.SubPriority);
		}
	}

	// Applies a shapeshifting location override delegate, if set to auto consume the delegate will automatically be cleared when it has been run (even if it returns false)
	void ApplyShapeshiftingLocationOverride(FOnShapeshiftLocationOverride Delegate, FInstigator Instigator, bool bAutoConsume = false, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		ClearShapeshiftingLocationOverride(Instigator);
		FOnShapeshiftLocationOverrideData Data;
		Data.Delegate = Delegate;
		Data.bConsume = bAutoConsume;
		InstigatedShapeshiftLocationOverride.Apply(Data, Instigator, Priority);
	}

	void ClearShapeshiftingLocationOverride(FInstigator Instigator)
	{
		InstigatedShapeshiftLocationOverride.Clear(Instigator);
	}

	FVector GetShapeshiftingLocationOffset(ETundraShapeshiftShape FromShape, ETundraShapeshiftShape ToShape)
	{
		if(InstigatedShapeshiftLocationOverride.IsDefaultValue())
			return FVector::ZeroVector;

		FVector Location;
		bool bResult = InstigatedShapeshiftLocationOverride.Get().Delegate.Execute(Player, FromShape, ToShape, Location);
		if(InstigatedShapeshiftLocationOverride.Get().bConsume)
			InstigatedShapeshiftLocationOverride.Clear(InstigatedShapeshiftLocationOverride.GetCurrentInstigator());

		if(bResult)
			return Location;

		return FVector::ZeroVector;
	}

	void RegisterShape(UTundraPlayerShapeBaseComponent ShapeComponent)
	{
		if(ShapeComponent.ShapeType == ETundraShapeshiftShape::None || ShapeComponent.ShapeType == ETundraShapeshiftShape::Player)
		{
			devError("Shape components should not have ShapeType == None or ShapeType == Player");
			return;
		}

		if(ShapeComponent.ShapeType == ETundraShapeshiftShape::Big)
		{
			if(BigShapeComponent != nullptr)
			{
				devError("Big shape is already assigned, each player should only have two shape components, one for big, one for small");
				return;
			}
			BigShapeComponent = ShapeComponent;
		}
		else if(ShapeComponent.ShapeType == ETundraShapeshiftShape::Small)
		{
			if(SmallShapeComponent != nullptr)
			{
				devError("Small shape is already assigned, each player should only have two shape components, one for big, one for small");
				return;
			}
			SmallShapeComponent = ShapeComponent;
		}
	}

	void SetCurrentShape(FShapeShiftTriggerData NewShape)
    {
        devCheck(bHasBegunPlay, f"Can call SetCurrentShape on {Player} until 'BeginPlay' has been called on 'TundraPlayerShapeshiftingComponent'");
		devCheck(CurrentShapeTypeInternal.Type != NewShape.Type, f"Can call SetCurrentShape on {Player} to {NewShape.Type} when that is the active form");

		PreviousShapeTypeInternal = CurrentShapeTypeInternal;

		// Update current stats first.
		// SUPER important that we change type here
		// before we update the sheets
        CurrentShapeTypeInternal = NewShape;
		ForceShapeOverride = FShapeShiftTriggerData();

		HandleExternalSettingsForCurrentShape();

		// Stop Previous shapes
		if(PreviousShapeType == ETundraShapeshiftShape::Big)
			Player.StopCapabilitySheet(BigFormSheet, this);
		else if(PreviousShapeType == ETundraShapeshiftShape::Small)
			Player.StopCapabilitySheet(SmallFormSheet, this);

		// Start New shapes
		if(CurrentShapeType == ETundraShapeshiftShape::Big)
			Player.StartCapabilitySheet(BigFormSheet, this);
		else if(CurrentShapeType == ETundraShapeshiftShape::Small)
			Player.StartCapabilitySheet(SmallFormSheet, this);

		SetCapsuleSizeForCurrentShape();
		
		OnChangeShape.Broadcast(Player, NewShape.Type);
    }

	void ClearShape(ETundraShapeshiftShape ShapeToClear, bool bUseEffect = true)
	{
		if(CurrentShapeTypeInternal.Type != ShapeToClear)
			return;
		
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player, bUseEffect);
	}

	UFUNCTION(BlueprintPure)
	ETundraShapeshiftShape GetCurrentShapeType() const property
	{
		return CurrentShapeTypeInternal.Type;
	}

	UFUNCTION(BlueprintPure)
	ETundraShapeshiftShape GetPreviousShapeType() const property
	{
		return PreviousShapeTypeInternal.Type;
	}

	ETundraShapeshiftActiveShape GetActiveShapeType() const property
	{
		if(IsBigShape())
			return ETundraShapeshiftActiveShape::Big;
		if(IsSmallShape())
			return ETundraShapeshiftActiveShape::Small;
		
		return ETundraShapeshiftActiveShape::Player;
	}

	ETundraShapeshiftActiveShape GetPreviousActiveShapeType() const property
	{
		if(PreviousShapeTypeInternal.Type == ETundraShapeshiftShape::Big)
			return ETundraShapeshiftActiveShape::Big;
		if(PreviousShapeTypeInternal.Type == ETundraShapeshiftShape::Small)
			return ETundraShapeshiftActiveShape::Small;
		
		return ETundraShapeshiftActiveShape::Player;
	}

	ETundraShapeshiftShape GetShapeTypeFromActiveShapeType(ETundraShapeshiftActiveShape ActiveType) const
	{
		if(ActiveType == ETundraShapeshiftActiveShape::Big)
			return ETundraShapeshiftShape::Big;
		else if(ActiveType == ETundraShapeshiftActiveShape::Small)
			return ETundraShapeshiftShape::Small;
		
		return ETundraShapeshiftShape::Player;
	}

	ETundraShapeshiftActiveShape GetActiveShapeTypeFromShapeType(ETundraShapeshiftShape ShapeType) const
	{
		if(ShapeType == ETundraShapeshiftShape::Big)
			return ETundraShapeshiftActiveShape::Big;
		else if(ShapeType == ETundraShapeshiftShape::Small)
			return ETundraShapeshiftActiveShape::Small;
		else if(ShapeType == ETundraShapeshiftShape::Player)
			return ETundraShapeshiftActiveShape::Player;

		devError("Tried to convert shape None to active shape, this is not possible!");
		return ETundraShapeshiftActiveShape::Player;
	}

	UHazeCharacterSkeletalMeshComponent GetMeshForShapeType(ETundraShapeshiftShape Shape)
	{
		if(Shape == ETundraShapeshiftShape::Player)
			return Player.Mesh;

		return GetShapeComponentForType(Shape).GetShapeMesh();
	}

	UTundraPlayerShapeBaseComponent GetShapeComponentForType(ETundraShapeshiftShape Type) const
	{
		if(Type == ETundraShapeshiftShape::Player || Type == ETundraShapeshiftShape::None)
		{
			devError("Player or None has no shape component");
			return nullptr;
		}

		switch(Type)
		{
			case ETundraShapeshiftShape::Small:
				return SmallShapeComponent;
			case ETundraShapeshiftShape::Big:
				return BigShapeComponent;
			default:
				devError("Forgot to add case!");
		}

		return nullptr;
	}

	UTundraPlayerShapeBaseComponent GetShapeComponentForCurrentType() const
	{
		return GetShapeComponentForType(GetCurrentShapeType());
	}

	bool ShouldUseActivationEffect() const
	{
		return CurrentShapeTypeInternal.bUseEffect;
	}

	void ReleaseGrappleAndSwing()
	{
		Player.BlockCapabilities(PlayerMovementTags::Grapple, this);
		Player.BlockCapabilities(PlayerMovementTags::Swing, this);
		Player.UnblockCapabilities(PlayerMovementTags::Grapple, this);
		Player.UnblockCapabilities(PlayerMovementTags::Swing, this);
	}

	UFUNCTION(BlueprintPure)
	bool IsBigShape() const
	{
		return CurrentShapeTypeInternal.Type == ETundraShapeshiftShape::Big;
	}

	UFUNCTION(BlueprintPure)
	bool IsSmallShape() const
	{
		return CurrentShapeTypeInternal.Type == ETundraShapeshiftShape::Small;
	}

	UFUNCTION(BlueprintPure)
	bool IsHumanShape() const
	{
		return CurrentShapeTypeInternal.Type == ETundraShapeshiftShape::Player;
	}

	UFUNCTION(BlueprintPure)
	bool IsMorphing() const
	{
		return bIsMorphing || bIsFailMorphing;
	}

	// When compared to the previous shape's capsule size, is the current shape's capsule size bigger in the specified dimensions.
	bool IsCurrentShapeCapsuleBigger(FVector2D& CapsuleSizeDelta, bool bCheckRadius = true, bool bCheckHeight = true) const
	{
		devCheck(bCheckRadius || bCheckHeight, "Checking if previous shape capsule size was smaller, but both bCheckRadius and bCheckHeight is false, will always return true");
		if(PreviousShapeType == ETundraShapeshiftShape::None)
			return false;

		FVector2D PreviousCapsuleSize = GetCapsuleSizeForShape(PreviousShapeType);
		FVector2D CurrentCapsuleSize = GetCapsuleSizeForShape(CurrentShapeType);

		CapsuleSizeDelta = CurrentCapsuleSize - PreviousCapsuleSize;
		if((!bCheckRadius || PreviousCapsuleSize.X < CurrentCapsuleSize.X) && (!bCheckHeight || PreviousCapsuleSize.Y < CurrentCapsuleSize.Y))
			return true;

		return false;
	}

	void AddShapeTypeBlocker(ETundraShapeshiftShape Type, FInstigator Instigator)
	{
		if(Type == ETundraShapeshiftShape::Big)
			BigShapeBlockers.AddUnique(Instigator);

		else if(Type == ETundraShapeshiftShape::Small)
			SmallShapeBlockers.AddUnique(Instigator);

		else if(Type == ETundraShapeshiftShape::Player)
			PlayerShapeBlockers.AddUnique(Instigator);
	}

	void RemoveShapeTypeBlockerInstigator(FInstigator Instigator)
	{
		BigShapeBlockers.RemoveSingleSwap(Instigator);
		SmallShapeBlockers.RemoveSingleSwap(Instigator);
		PlayerShapeBlockers.RemoveSingleSwap(Instigator);	
	}

	bool ShapeTypeIsBlocked(ETundraShapeshiftShape Type) const
	{
		if(Type == ETundraShapeshiftShape::Big)
			return BigShapeBlockers.Num() > 0;

		if(Type == ETundraShapeshiftShape::Small)
			return SmallShapeBlockers.Num() > 0;

		if(Type == ETundraShapeshiftShape::Player)
			return PlayerShapeBlockers.Num() > 0;

		return false;
	}

	void AddShapeBlockedShouldPlayFailEffectBlocker(FInstigator Instigator)
	{
		ShapeBlockedPlayFailEffectBlockers.AddUnique(Instigator);
	}

	void RemoveShapeBlockedShouldPlayFailEffectBlocker(FInstigator Instigator)
	{
		ShapeBlockedPlayFailEffectBlockers.RemoveSingleSwap(Instigator);
	}

	bool IsShapeBlockedShouldPlayFailEffectBlocked() const
	{
		return ShapeBlockedPlayFailEffectBlockers.Num() > 0;
	}

	void AddSpawnAsHumanBlocker(FInstigator Instigator)
	{
		SpawnAsHumanBlockers.AddUnique(Instigator);
	}

	void RemoveSpawnAsHumanBlocker(FInstigator Instigator)
	{
		SpawnAsHumanBlockers.RemoveSingleSwap(Instigator);
	}

	bool IsSpawnAsHumanBlocked() const
	{
		return SpawnAsHumanBlockers.Num() > 0;
	}

	float GetGravityAmountForShape(ETundraShapeshiftShape Shape) const
	{
		devCheck(Shape != ETundraShapeshiftShape::None, "The shapeshifting shape None is not a valid shape to get gravity from");

		if(Shape == ETundraShapeshiftShape::Player)
			return OriginalPlayerGravityAmount;

		return GetShapeComponentForType(Shape).GetShapeGravityAmount();
	}

	float GetTerminalVelocityForShape(ETundraShapeshiftShape Shape) const
	{
		devCheck(Shape != ETundraShapeshiftShape::None, "The shapeshifting shape None is not a valid shape to get terminal velocity from");

		if(Shape == ETundraShapeshiftShape::Player)
			return OriginalPlayerTerminalVelocity;

		return GetShapeComponentForType(Shape).GetShapeTerminalVelocity();
	}

	bool ShouldSnapGravityForShape(ETundraShapeshiftShape Shape) const
	{
		devCheck(Shape != ETundraShapeshiftShape::None, "The shapeshifting shape None is not a valid shape to check if we should snap gravity from");

		if(Shape == ETundraShapeshiftShape::Player)
			return PlayerShouldSnapGravity();

		return GetShapeComponentForType(Shape).ShouldSnapGravity();
	}

	float GetGravityBlendTimeForShape(ETundraShapeshiftShape Shape, ETundraShapeshiftShape PreviousShape) const
	{
		devCheck(Shape != ETundraShapeshiftShape::None, "The shapeshifting shape None is not a valid shape to get gravity blend time from");

		if(Shape == ETundraShapeshiftShape::Player)
		{
			// This case is exceedingly rare since we will pretty much always have a previous shape
			if(PreviousShape == ETundraShapeshiftShape::None)
				return 0.5;

			return GetShapeComponentForType(PreviousShape).GetFromShapeToPlayerGravityBlendTime();
		}

		return GetShapeComponentForType(Shape).GetToShapeGravityBlendTime();
	}

	float GetPoleClimbMaxHeightOffsetForShape(ETundraShapeshiftShape Shape)
	{
		devCheck(Shape != ETundraShapeshiftShape::None, "The shapeshifting shape None is not a valid shape to get pole climb max height offset from");

		if(Shape == ETundraShapeshiftShape::Player)
			return GetPlayerPoleClimbMaxHeightOffset();

		return GetShapeComponentForType(Shape).GetShapePoleClimbMaxHeightOffset();
	}

	FVector2D GetCapsuleSizeForShape(ETundraShapeshiftShape Shape) const
	{
		if(Shape == ETundraShapeshiftShape::Player)
			return PlayerCollisionSize;

		UTundraPlayerShapeBaseComponent Comp = GetShapeComponentForType(Shape);
		return Comp.GetShapeCollisionSize();
	}

	private void SetCapsuleSizeForCurrentShape()
	{
		ETundraShapeshiftShape ShapeType = GetCurrentShapeType();

		if(ShapeType == ETundraShapeshiftShape::Player)
		{
			ClearCapsuleSizeOverride();
			return;
		}

		UTundraPlayerShapeBaseComponent Comp = GetShapeComponentForType(ShapeType);
		ApplyCapsuleSizeOverride(Comp.GetShapeCollisionSize());
	}

	private void ApplyCapsuleSizeOverride(FVector2D NewCapsuleSize)
	{
		Player.CapsuleComponent.OverrideCapsuleSize(NewCapsuleSize.X, NewCapsuleSize.Y, this, EInstigatePriority::Low);
	}

	private void ClearCapsuleSizeOverride()
	{
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);
	}

	FVector2D GetCapsuleSizeForShape(ETundraShapeshiftShape Shape)
	{
		if(Shape == ETundraShapeshiftShape::Player)
		{
			return Player.CapsuleComponent.DefaultSize;
		}
		else
		{
			UTundraPlayerShapeBaseComponent ShapeComp = GetShapeComponentForType(Shape);
			return ShapeComp.GetShapeCollisionSize();
		}
	}

	/* Will return true if found a valid location for the bigger capsule that wont result in penetration, LocationOffset will return the delta to offset the player to result in a valid non-penetrating location */
	access:ShapeshiftingSystem bool IsCollisionValidForShapeshifting(ETundraShapeshiftShape FromShape, ETundraShapeshiftShape ToShape, bool&out bOffsetLocation, FVector&out LocationOffset)
	{
		bool bResult = IsCollisionValidForShapeshifting_Internal(FromShape, ToShape, bOffsetLocation, LocationOffset);

#if !RELEASE
		FVector2D CurrentCapsuleSize = GetCapsuleSizeForShape(FromShape);
		FVector2D NewCapsuleSize = GetCapsuleSizeForShape(ToShape);

		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value(f"{IsCollisionValidCategory};Is Collision Valid", bResult);

		TemporalLog.Value(f"{IsCollisionValidCategory};Offset Location", bOffsetLocation);
		if(bOffsetLocation)
			TemporalLog.DirectionalArrow(f"{IsCollisionValidCategory};Location Offset", Player.ActorLocation, LocationOffset);

		FVector2D FinalCapsuleSize = bResult ? NewCapsuleSize : CurrentCapsuleSize;
		TemporalLog.Capsule(f"{IsCollisionValidCategory};Initial Capsule", Player.ActorLocation + FVector::UpVector * CurrentCapsuleSize.Y, CurrentCapsuleSize.X, CurrentCapsuleSize.Y, FRotator::ZeroRotator, FLinearColor::Red);
		TemporalLog.Capsule(f"{IsCollisionValidCategory};Final Capsule", Player.ActorLocation + FVector::UpVector * FinalCapsuleSize.Y + LocationOffset, FinalCapsuleSize.X, FinalCapsuleSize.Y, FRotator::ZeroRotator, FLinearColor::Green);
#endif

		return bResult;
	}

	private bool IsCollisionValidForShapeshifting_Internal(ETundraShapeshiftShape FromShape, ETundraShapeshiftShape ToShape, bool&out bOffsetLocation, FVector&out LocationOffset)
	{
		// When performing a shapeshift this function will check if the collision around the player is valid to fit a bigger capsule size.
		// It will also offset the capsule slightly if a valid spot can be found nearby. This is checked in a series of steps as follows:
		//
		// Step 1: If the new capsule is smaller in both width and height the collision is valid without offseting.
		//
		// Step 2: Do an initial sphere trace multi from the bottom of where the new big capsule would start to the top of the new big capsule
		// (the sphere should have the same radius as the big capsule). Add together all wall normals (and remove any verticality)
		// to determine which direction we should trace for the floor (or ceiling).
		// Step 3: Do a capsule trace to find the ceiling or ground to place the player against
		// (or if the trace doesn't hit anything, just move it horizontally away from any walls)

		FVector2D CurrentCapsuleSize = GetCapsuleSizeForShape(FromShape);
		FVector2D NewCapsuleSize = GetCapsuleSizeForShape(ToShape);

		LocationOffset = GetShapeshiftingLocationOffset(FromShape, ToShape);
		bOffsetLocation = !LocationOffset.Equals(FVector::ZeroVector);

		// Step 1
		if(!bOffsetLocation && NewCapsuleSize.X < CurrentCapsuleSize.X && NewCapsuleSize.Y < CurrentCapsuleSize.Y)
			return true;

		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		// The origin of the big capsule
		FVector Origin = Player.ActorLocation + FVector::UpVector * NewCapsuleSize.Y + LocationOffset;
		FVector OriginalOrigin = Origin;

		FHazeTraceSettings Trace = Trace::InitProfile(n"PlayerCharacter");
		Trace.IgnorePlayers();
		Trace.IgnoreActors(IgnoreCollisionContainerComp.ActorsToIgnore);

		//If we are on a pole while shapeshifting we ignore the pole actor aswell
		if(PoleClimbComp != nullptr && PoleClimbComp.Data.ActivePole != nullptr)
			Trace.IgnoreActor(PoleClimbComp.Data.ActivePole);

		Trace.UseCapsuleShape(NewCapsuleSize.X, NewCapsuleSize.Y);

		FHazeTraceSettings SphereTrace = Trace;
		SphereTrace.UseSphereShape(NewCapsuleSize.X);

		// Step 2
		FVector TraceDirection;
		FVector CombinedNormalOfWalls;
		if(IsCollisionValid_InitialSphereTrace(SphereTrace, LocationOffset, NewCapsuleSize, TraceDirection, CombinedNormalOfWalls))
			return true;

		// If we are tracing upwards, we need to move the capsule down to treat the top of the old capsule as the player location (so the tops of the two capsules line up).
		// This:		Becomes this:
		//	_				_
		// ╱ ╲			   ╱0╲
		// |  |			   |  |		0 -> Small capsule
		// |  |			   |  |
		// ╲0╱			   ╲ ╱
		//  ▔			   ▔
		if(TraceDirection.Z > 0.0)
			Origin += FVector::DownVector * ((NewCapsuleSize.Y * 2.0) - (CurrentCapsuleSize.Y * 2.0));

		// Step 3
		TArray<FVector> TraceLocations;
		{
			const float RadiusOffset = NewCapsuleSize.X - CurrentCapsuleSize.X + 0.125;

			TraceLocations.Add(Origin + CombinedNormalOfWalls * RadiusOffset * Math::Sqrt(2.0)); // If in a perfect corner, Sqrt(2) will make you unstuck
			TraceLocations.Add(Origin + CombinedNormalOfWalls * RadiusOffset * 2.0); // Try a bit further away as well to see if this will work
		}

		// We should start big capsule traces BigCapsuleRadius above the origin and end the trace BigCapsuleRadius below the origin in case the ground is higher/lower
		const float TraceHalfDistance = NewCapsuleSize.X;
		const FVector TraceHeightOffset = TraceDirection * TraceHalfDistance;

		for(int i = 0; i < TraceLocations.Num(); i++)
		{
			FVector Location = TraceLocations[i];

			FHitResult Current = Trace.QueryTraceSingle(Location - TraceHeightOffset, Location + TraceHeightOffset);
			TemporalLog.HitResults(f"{IsCollisionValidTracesCategory};Sweep {i + 1}", Current, Trace.Shape);

			// This is not a valid location since the trace resulted in a penetration, try the next one
			if(Current.bStartPenetrating)
				continue;

			// Hooray! The location is valid, now we just need to figure out whether we should offset the player's height
			bOffsetLocation = true;
			LocationOffset += Location - Origin;

			if(Current.bBlockingHit)
			{
				// We should offset the player's height, the trace found ground (or ceiling)
				float HeightOffset = Current.Location.Z - OriginalOrigin.Z;
				HeightOffset += 1.0 * Math::Sign(HeightOffset);
				LocationOffset += FVector::UpVector * HeightOffset;

				return true;
			}
			else
			{
				// We shouldn't offset the player's height, we are in the air
				return true;
			}
		}

		return false;
	}

	private bool IsCollisionValid_InitialSphereTrace(FHazeTraceSettings TraceSettings, FVector ShapeshiftingLocationOffset, FVector2D NewCapsuleSize, FVector&out TraceDirection, FVector&out CombinedNormalOfWalls)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		FVector Origin = Player.ActorLocation + FVector::UpVector * NewCapsuleSize.X + ShapeshiftingLocationOffset;
		FVector Destination = Origin + FVector::UpVector * ((NewCapsuleSize.Y * 2.0) - (NewCapsuleSize.X * 2.0));

		// Overlap check first to figure out if we even need to offset
		FHitResultArray InitialHits = TraceSettings.QueryTraceMulti(Origin, Destination);
		TemporalLog.HitResults(f"{IsCollisionValidCategory};Initial Sweep", InitialHits, Origin, Destination, TraceSettings.Shape);
		if(!InitialHits.HasBlockHits())
			return true;

		float NormalDegreeCombinedWeight = 0.0;

		int NormalNumber = 0;
		for(FHitResult Hit : InitialHits.BlockHits)
		{
			// Straight up is 90, straight down is -90
			FVector Normal = Hit.bStartPenetrating ? Hit.Normal : Hit.ImpactNormal;
			float DegreesUpwards = -(Normal.GetAngleDegreesTo(FVector::UpVector) - 90.0);

			TemporalLog.DirectionalArrow(f"{IsCollisionValidCategory};Normal {NormalNumber} ({DegreesUpwards})", Hit.ImpactPoint, Normal * 100.0);

			NormalDegreeCombinedWeight += DegreesUpwards;

			if(!IsPointingDownwards(Hit.Normal) && !IsPointingUpwards(Hit.Normal))
			{
				FVector HorizontalNormal = Hit.Normal.VectorPlaneProject(FVector::UpVector);
				// float Dot = HorizontalNormal.DotProduct(CombinedNormalOfWalls);
				// HorizontalNormal -= CombinedNormalOfWalls * Dot;
				
				CombinedNormalOfWalls += HorizontalNormal;
			}
			++NormalNumber;
		}

		CombinedNormalOfWalls = CombinedNormalOfWalls.GetSafeNormal();

		TemporalLog.Value(f"{IsCollisionValidCategory};Normal Degree Combined Weight", NormalDegreeCombinedWeight);

		if(NormalDegreeCombinedWeight >= 0.0 || MoveComp.HasGroundContact())
		{
			TraceDirection = FVector::DownVector;
			TemporalLog.Value(f"{IsCollisionValidCategory};Trace Direction", "Down");
		}
		else
		{
			TraceDirection = FVector::UpVector;
			TemporalLog.Value(f"{IsCollisionValidCategory};Trace Direction", "Up");
		}
		

		TemporalLog.DirectionalArrow(f"{IsCollisionValidCategory};Trace Direction Arrow", Player.ActorLocation, TraceDirection);
		return false;
	}

	private bool IsCollisionValid_CapsuleOverlapCheck(FHazeTraceSettings TraceSettings, FVector Origin)
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		FOverlapResultArray InitialOverlaps = TraceSettings.QueryOverlaps(Origin);
		TemporalLog.OverlapResults(f"{IsCollisionValidCategory};Overlap Results", InitialOverlaps);
		if(!InitialOverlaps.HasBlockHit())
			return true;

		return false;
	}

	private bool IsPointingUpwards(FVector Direction) const
	{
		return Direction.GetAngleDegreesTo(FVector::UpVector) <= 45.0;
	}

	private bool IsPointingDownwards(FVector Direction) const
	{
		return Direction.GetAngleDegreesTo(FVector::UpVector) >= 135.0;
	}

	ETundraShapeshiftShape GetAnimationTargetShapeType()
	{
		return bIsFailMorphing ? CurrentMorphFailShapeTarget : CurrentShapeTypeInternal.Type;
	}

	ETundraShapeshiftShape GetAnimationPreviousShapeType()
	{
		return bIsFailMorphing ? PreviousMorphFailShapeTarget : PreviousShapeTypeInternal.Type;
	}
}

/* Will set the player's shapeshifting shape, this will not be instant, but will happen the next time the ShapeshiftingCapability's ShouldActivate runs. */
UFUNCTION()
mixin void TundraSetPlayerShapeshiftingShape(AHazePlayerCharacter Player, ETundraShapeshiftShape NewShape, bool bTransitionWithVisualEffects = true, bool bCheckCollision = false)
{
	auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	devCheck(ShapeshiftingComp != nullptr, "Tried to call TundraSetPlayerShapeshiftingShape but couldn't get shapeshifting comp from player");

	ShapeshiftingComp.ForceShapeOverride.Type = NewShape;
	ShapeshiftingComp.ForceShapeOverride.bUseEffect = bTransitionWithVisualEffects;
	ShapeshiftingComp.ForceShapeOverride.bCheckCollision = bCheckCollision;
}

UFUNCTION()
mixin void TundraShapeshiftingSetOutlineVisibility(AHazePlayerCharacter Player, bool bNewOutlineVisibility)
{
	auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);

	devCheck(ShapeshiftingComp != nullptr, "Tried to call TundraShapeshiftingSetOutlineVisibility but couldn't get shapeshifting comp from player");
	
	// Outline is already in this state!
	if(ShapeshiftingComp.bOutlineVisible == bNewOutlineVisibility)
		return;

	if(bNewOutlineVisibility)
	{
		Outline::ClearOutlineOnActor(Player, 													Player.OtherPlayer, ShapeshiftingComp);
		Outline::ClearOutlineOnActor(ShapeshiftingComp.BigShapeComponent.GetShapeActor(), 		Player.OtherPlayer, ShapeshiftingComp);
		Outline::ClearOutlineOnActor(ShapeshiftingComp.SmallShapeComponent.GetShapeActor(), 	Player.OtherPlayer, ShapeshiftingComp);
	}
	else
	{
		Outline::ApplyNoOutlineOnActor(Player, 												Player.OtherPlayer, ShapeshiftingComp, EInstigatePriority::High);
		Outline::ApplyNoOutlineOnActor(ShapeshiftingComp.BigShapeComponent.GetShapeActor(), 	Player.OtherPlayer, ShapeshiftingComp, EInstigatePriority::High);
		Outline::ApplyNoOutlineOnActor(ShapeshiftingComp.SmallShapeComponent.GetShapeActor(), 	Player.OtherPlayer, ShapeshiftingComp, EInstigatePriority::High);
	}

	ShapeshiftingComp.bOutlineVisible = bNewOutlineVisibility;
}

UFUNCTION()
mixin void TundraShapeshiftingApplySettingsForShape(AHazePlayerCharacter Player, UHazeComposableSettings SettingsAsset, ETundraShapeshiftActiveShape Shape, FInstigator Instigator, EHazeSettingsPriority Priority = EHazeSettingsPriority::Gameplay)
{
	auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	devCheck(ShapeshiftingComp != nullptr, "Shapeshifting component was null when trying to apply settings for shape");

	TArray<FTundraShapeshiftingApplySettingsForShapeData>& RelevantArray = ShapeshiftingComp.GetExternalSettingsArrayForShape(Shape);

	#if !RELEASE
	for(FTundraShapeshiftingApplySettingsForShapeData Data : RelevantArray)
	{
		if(Data.SettingsAsset == SettingsAsset)
		{
			devError("Settings asset already applied for this shape");
			return;
		}
	}
	#endif

	bool bIsCurrentShape = Shape == ShapeshiftingComp.ActiveShapeType;
	if(bIsCurrentShape)
	{
		Player.ApplySettings(SettingsAsset, Instigator, Priority);
	}

	FTundraShapeshiftingApplySettingsForShapeData Data;
	Data.SettingsAsset = SettingsAsset;
	Data.Instigator = Instigator;
	Data.Priority = Priority;
	RelevantArray.Add(Data);
}

UFUNCTION()
mixin void TundraShapeshiftingClearSettingsForShape(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape, FInstigator Instigator)
{
	auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	devCheck(ShapeshiftingComp != nullptr, "Shapeshifting component was null when trying to clear settings for shape");

	bool bIsCurrentShape = Shape == ShapeshiftingComp.ActiveShapeType;

	TArray<FTundraShapeshiftingApplySettingsForShapeData>& RelevantArray = ShapeshiftingComp.GetExternalSettingsArrayForShape(Shape);
	for(int i = RelevantArray.Num() - 1; i >= 0; i--)
	{
		FTundraShapeshiftingApplySettingsForShapeData Data = RelevantArray[i];
		if(Data.Instigator == Instigator)
		{
			if(bIsCurrentShape)
			{
				Player.ClearSettingsWithAsset(Data.SettingsAsset, Data.Instigator);
			}

			RelevantArray.RemoveAt(i);
		}
	}
}

UFUNCTION()
mixin void TundraShapeshiftingApplyCameraSettingsForShape(AHazePlayerCharacter Player, UHazeCameraSpringArmSettingsDataAsset CameraSettings, ETundraShapeshiftActiveShape Shape, float BlendTime, FInstigator Instigator, float BlendOutTime = -1.0, EHazeCameraPriority Priority = EHazeCameraPriority::Default, int SubPriority = 0)
{
	auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	devCheck(ShapeshiftingComp != nullptr, "Shapeshifting component was null when trying to apply camera settings for shape");

	TArray<FTundraShapeshiftingApplyCameraSettingsForShapeData>& RelevantArray = ShapeshiftingComp.GetExternalCameraSettingsArrayForShape(Shape);

	#if !RELEASE
	for(FTundraShapeshiftingApplyCameraSettingsForShapeData Data : RelevantArray)
	{
		if(Data.CameraSettings == CameraSettings)
		{
			devError("Camera settings asset already applied for this shape");
			return;
		}
	}
	#endif

	bool bIsCurrentShape = Shape == ShapeshiftingComp.ActiveShapeType;
	if(bIsCurrentShape)
	{
		Player.ApplyCameraSettings(CameraSettings, BlendTime, Instigator, Priority, SubPriority);
	}

	FTundraShapeshiftingApplyCameraSettingsForShapeData Data;
	Data.CameraSettings = CameraSettings;
	Data.Instigator = Instigator;
	Data.Priority = Priority;
	Data.SubPriority = SubPriority;
	Data.BlendTime = BlendTime;
	Data.BlendOutTime = BlendOutTime < 0.0 ? BlendTime : BlendOutTime;
	RelevantArray.Add(Data);
}

UFUNCTION()
mixin void TundraShapeshiftingClearCameraSettingsForShape(AHazePlayerCharacter Player, ETundraShapeshiftActiveShape Shape, FInstigator Instigator, float OverrideBlendTime = -1.0)
{
	auto ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	devCheck(ShapeshiftingComp != nullptr, "Shapeshifting component was null when trying to clear camera settings for shape");

	bool bIsCurrentShape = Shape == ShapeshiftingComp.ActiveShapeType;

	TArray<FTundraShapeshiftingApplyCameraSettingsForShapeData>& RelevantArray = ShapeshiftingComp.GetExternalCameraSettingsArrayForShape(Shape);
	for(int i = RelevantArray.Num() - 1; i >= 0; i--)
	{
		FTundraShapeshiftingApplyCameraSettingsForShapeData Data = RelevantArray[i];
		if(Data.Instigator == Instigator)
		{
			if(bIsCurrentShape)
			{
				Player.ClearCameraSettingsByInstigator(Data.Instigator, OverrideBlendTime < 0.0 ? Data.BlendOutTime : OverrideBlendTime);
			}

			RelevantArray.RemoveAt(i);
		}
	}
}

struct FTundraShapeshiftingApplySettingsForShapeData
{
	UHazeComposableSettings SettingsAsset;
	FInstigator Instigator;
	EHazeSettingsPriority Priority;
}

struct FTundraShapeshiftingApplyCameraSettingsForShapeData
{
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;
	float BlendTime;
	float BlendOutTime;
	FInstigator Instigator;
	EHazeCameraPriority Priority;
	int SubPriority;
}