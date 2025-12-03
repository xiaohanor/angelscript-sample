namespace GravityBikeWhip
{
	const FHazeDevToggleCategory ToggleCategory = FHazeDevToggleCategory(n"GravityBikeWhip");

	const FHazeDevToggleBool AutoThrow = FHazeDevToggleBool(ToggleCategory, n"Auto Throw");
	const FHazeDevToggleBool AutoTarget = FHazeDevToggleBool(ToggleCategory, n"Auto Target");
	const FHazeDevToggleBool HoldInput = FHazeDevToggleBool(ToggleCategory, n"Hold Input");
};

enum EGravityBikeWhipState
{
	None,
	StartGrab,
	Pull,
	Lasso,
	ThrowRebound,
	Throw,
};

UCLASS(Abstract, HideCategories = "ComponentTick Activation Cooking Debug Variable Disable Tags Replication Collision Navigation")
class UGravityBikeWhipComponent : UActorComponent
{
	access Internal = private, UGravityBikeWhipCapability;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Whip")
	TSubclassOf<AGravityBikeWhip> GravityBikeWhipClass;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Whip")
	TSubclassOf<UGravityBikeWhipGrabWidget> GrabTargetWidgetClass;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Whip")
	TSubclassOf<UGravityBikeWhipCanvasWidget> ThrowCanvasWidgetClass;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Whip")
	TSubclassOf<UGravityBikeWhipThrowWidget> ThrowTargetWidgetClass;

	UPROPERTY(EditDefaultsOnly, Category = "Bike Whip")
	ULocomotionFeatureGravityBikeWhip FeatureData;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter Player;
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeSpline GravityBike;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AGravityBikeWhip WhipActor;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	TArray<UGravityBikeWhipGrabTargetComponent> ThrownTargets;

	private EGravityBikeWhipState CurrentState;
	TArray<UGravityBikeWhipGrabTargetComponent> GrabbedTargets;

	access:Internal
	UHazeCrumbSyncedVector2DComponent Input;
	bool bReleasedInput = false;
	FVector2D SmoothInput;

	private UPlayerTargetablesComponent PlayerTargetablesComp;
	private UGravityBikeWhipThrowTargetComponent ThrowTargetComp;
	UGravityBikeWhipCanvasWidget ThrowCanvasWidget;
	const float HorizontalRange = 0.3;
	const float VerticalRange = 0.3;
	bool bIsHolstered = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerTargetablesComp = UPlayerTargetablesComponent::Get(Player);

		ThrowCanvasWidget = Cast<UGravityBikeWhipCanvasWidget>(
			Widget::AddFullscreenWidget(ThrowCanvasWidgetClass, EHazeWidgetLayer::Crosshair)
		);

		check(ThrowCanvasWidget != nullptr);
		ThrowCanvasWidget.OverrideWidgetPlayer(GetScreenPlayer());

		Input = UHazeCrumbSyncedVector2DComponent::GetOrCreate(Owner, n"GravityBikeWhipInput");
		Input.Compression = EHazeCrumbSyncedVector2DCompression::CompressNormal;
		
		GravityBikeWhip::AutoThrow.MakeVisible();
		GravityBikeWhip::AutoTarget.MakeVisible();
		GravityBikeWhip::HoldInput.MakeVisible();

		WhipActor = GetOrCreateWhipActor();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Widget::RemoveFullscreenWidget(ThrowCanvasWidget);
		ThrowCanvasWidget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(int i = ThrownTargets.Num() - 1; i >= 0; i--)
		{
			if(!IsValid(ThrownTargets[i]))
				ThrownTargets.RemoveAtSwap(i);
		}

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Value("01#Info;CurrentState", CurrentState);

		TemporalLog.Value(f"02#Thrown Targets;Count", ThrownTargets.Num());
		for(int i = 0; i < ThrownTargets.Num(); i++)
			TemporalLog.Value(f"02#Thrown Targets;Target {i}", ThrownTargets[i]);

		TemporalLog.Value(f"03#Grabbed Targets;Count", GrabbedTargets.Num());
		for(int i = 0; i < GrabbedTargets.Num(); i++)
			TemporalLog.Value(f"03#Grabbed Targets;Target {i}", GrabbedTargets[i]);


		TemporalLog.Value("04#Input;Stick Input", Input.Value);
		TemporalLog.Value("04#Input;bReleasedInput", bReleasedInput);
		TemporalLog.Value("04#Input;SmoothInput", SmoothInput);
#endif
	}

	AGravityBikeWhip GetOrCreateWhipActor()
	{
		if(WhipActor == nullptr)
		{
			WhipActor = SpawnActor(GravityBikeWhipClass);
		}

		return WhipActor;
	}

	void SetWhipState(EGravityBikeWhipState WhipState)
	{
		CurrentState = WhipState;
	}

	EGravityBikeWhipState GetWhipState() const
	{
		return CurrentState;
	}

	bool IsThrowing() const
	{
		switch(CurrentState)
		{
			case EGravityBikeWhipState::None:
				return false;

			case EGravityBikeWhipState::StartGrab:
				return false;

			case EGravityBikeWhipState::Pull:
				return false;

			case EGravityBikeWhipState::Lasso:
				return false;

			case EGravityBikeWhipState::ThrowRebound:
				return true;

			case EGravityBikeWhipState::Throw:
				return true;
		}
	}

	void Grab(TArray<UGravityBikeWhipGrabTargetComponent> GrabTargets)
	{
		check(GrabTargets.Num() != 0);

		for(UGravityBikeWhipGrabTargetComponent GrabTarget : GrabTargets)
		{
			Grab_Internal(GrabTarget);
		}

		FGravityBikeWhipGrabEventData EventData;
		EventData.GrabTargets = GrabTargets;
		UGravityBikeWhipEventHandler::Trigger_OnGrabTargets(Player, EventData);
	}

	UFUNCTION(CrumbFunction)
	void CrumbGrab(TArray<UGravityBikeWhipGrabTargetComponent> GrabTargets)
	{
		Grab(GrabTargets);
	}

	private void Grab_Internal(UGravityBikeWhipGrabTargetComponent GrabTarget)
	{
#if EDITOR
		if(HasControl())
		{
			// Everything we grab MUST be on the Zoe side to prevent issues where the actor has been destroyed on
			// Mios side, but has been grabbed on Zoes side.
			check(GrabTarget.HasControl());
		}
#endif

		check(IsValid(GrabTarget));
		check(!HasGrabbedTarget(GrabTarget));

		GrabTarget.Disable(this);
		GrabTarget.OnDestroyed.AddUFunction(this, n"OnGrabTargetDestroyed");
		GrabbedTargets.Add(GrabTarget);

		GrabTarget.Grabbed(this);

		check(IsValid(GrabTarget), "It is not valid to destroy a grabbed actor from calling Grabbed!");
		check(GrabbedTargets.Num() <= GrabbedTargets[0].MaxMultiGrabCount);
	}

	UFUNCTION()
	private void OnGrabTargetDestroyed(UGravityBikeWhipGrabTargetComponent GrabTarget)
	{
		// The GrabTarget was destroyed, remove it from our array so that we don't keep using an invalid actor
		GrabbedTargets.RemoveSingleSwap(GrabTarget);
	}

	void PollMultiGrab()
	{
		if(!ensure(HasControl()))
		{
			// Only control side can poll multi grab grab!
			return;
		}

		if(HasGrabbedAnything() && GetGrabbedCount() >= GetMultiGrabMaxCount())
			return;

		TArray<UGravityBikeWhipGrabTargetComponent> ValidGrabTargets = GetAllValidGrabTargets();

		if(HasGrabbedAnything())
		{
			// Make sure we don't grab too many!
			const int CanGrabCount = GetMultiGrabMaxCount() - GetGrabbedCount();
			while(ValidGrabTargets.Num() > CanGrabCount)
				ValidGrabTargets.SetNum(ValidGrabTargets.Num() - 1);
		}

		if(ValidGrabTargets.IsEmpty())
			return;

		CrumbGrab(ValidGrabTargets);
	}

	int GetMultiGrabMaxCount() const
	{
		check(HasGrabbedAnything());
		return GrabbedTargets[0].MaxMultiGrabCount;
	}

	void ThrowAll(UGravityBikeWhipThrowTargetComponent InThrowTarget)
	{
		for(auto& GrabTarget : GrabbedTargets)
		{
			Drop_Internal(GrabTarget, EGravityBikeWhipGrabState::Thrown, InThrowTarget);
		}

		FGravityBikeWhipThrowEventData EventData = GetThrowEventData(GrabbedTargets);
		UGravityBikeWhipEventHandler::Trigger_OnThrowTargets(Player, EventData);

		GrabbedTargets.Reset();
	}

	void Throw(UGravityBikeWhipGrabTargetComponent InGrabTarget, UGravityBikeWhipThrowTargetComponent InThrowTarget)
	{
		Drop_Internal(InGrabTarget, EGravityBikeWhipGrabState::Thrown, InThrowTarget);
		GrabbedTargets.RemoveSingleSwap(InGrabTarget);

		TArray<UGravityBikeWhipGrabTargetComponent> GrabTargets;
		GrabTargets.Add(InGrabTarget);
		FGravityBikeWhipThrowEventData EventData = GetThrowEventData(GrabTargets);
		UGravityBikeWhipEventHandler::Trigger_OnThrowTargets(Player, EventData);
	}

	void DropAll()
	{
		for(UGravityBikeWhipGrabTargetComponent GrabTarget : GrabbedTargets)
			Drop_Internal(GrabTarget, EGravityBikeWhipGrabState::Dropped, nullptr);

		FGravityBikeWhipDropEventData EventData;
		EventData.DroppedGrabTargets = GrabbedTargets;
		UGravityBikeWhipEventHandler::Trigger_OnDropAll(Player, EventData);

		GrabbedTargets.Reset();
	}

	private void Drop_Internal(UGravityBikeWhipGrabTargetComponent InGrabTarget, EGravityBikeWhipGrabState InGrabState, UGravityBikeWhipThrowTargetComponent InThrowTarget)
	{
		InGrabTarget.Enable(this);
		InGrabTarget.Dropped(this, InGrabState, InThrowTarget);
		ThrownTargets.Add(InGrabTarget);
	}

	UGravityBikeWhipThrowTargetComponent GetThrowTarget() const
	{
		return ThrowTargetComp;
	}

	void SetThrowTarget(UGravityBikeWhipThrowTargetComponent ThrowTarget)
	{
		ThrowTargetComp = ThrowTarget;
	}

	void CrumbSetThrowTarget(UGravityBikeWhipThrowTargetComponent ThrowTarget)
	{
		if(!ensure(HasControl()))
			return;

		CrumbSetThrowTargetInternal(ThrowTarget);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetThrowTargetInternal(UGravityBikeWhipThrowTargetComponent ThrowTarget)
	{
		SetThrowTarget(ThrowTarget);
	}

	void Reset()
	{
		bReleasedInput = false;
		CurrentState = EGravityBikeWhipState::None;
		GrabbedTargets.Reset();

		UGravityBikeWhipEventHandler::Trigger_OnWhipReset(Player);
	}

	UFUNCTION(BlueprintPure)
	bool HasGrabbedAnything() const
	{
		return GrabbedTargets.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	int GetGrabbedCount() const
	{
		return GrabbedTargets.Num();
	}

	bool IsMultiGrab() const
	{
		return GrabbedTargets.Num() > 1;
	}

	int FindGrabbedTargetIndex(const UGravityBikeWhipGrabTargetComponent TargetComp) const
	{
		for(int i = 0; i < GrabbedTargets.Num(); i++)
		{
			if(GrabbedTargets[i] == TargetComp)
				return i;
		}
		return -1;
	}

	bool HasGrabbedTarget(const UGravityBikeWhipGrabTargetComponent TargetComp) const
	{
		return FindGrabbedTargetIndex(TargetComp) >= 0;
	}

	TArray<UGravityBikeWhipGrabTargetComponent> GetAllPossibleGrabTargets() const
	{
		TArray<UGravityBikeWhipGrabTargetComponent> WhipTargets;
		TArray<UTargetableComponent> Targets;
		PlayerTargetablesComp.GetPossibleTargetables(GravityBikeWhip::TargetableCategoryGrab, Targets);

		if(Targets.Num() == 0)
			return WhipTargets;

		for(auto Target : Targets)
		{
			if(!IsValid(Target))
				continue;

			auto WhipTargetComp = Cast<UGravityBikeWhipGrabTargetComponent>(Target);
			if (WhipTargetComp == nullptr)
				continue;

			WhipTargets.Add(WhipTargetComp);
		}

		return WhipTargets;
	}

	TArray<UGravityBikeWhipGrabTargetComponent> GetAllValidGrabTargets() const
	{
		TArray<UGravityBikeWhipGrabTargetComponent> PossibleTargets = GetAllPossibleGrabTargets();
		TArray<UGravityBikeWhipGrabTargetComponent> ValidTargets;

		for(auto PossibleTarget : PossibleTargets)
		{
			// Filter out so that all valid targets are the same actor class
			if(!ValidTargets.IsEmpty())
			{
				if(!IsSameGrabCategory(ValidTargets[0], PossibleTarget))
					continue;
			}

			if(HasGrabbedAnything())
			{
				// This target is already grabbed (should not be possible since we disable grabbed targets)
				if(HasGrabbedTarget(PossibleTarget))
					continue;

				// Is the new possible target the same class as the current held objects?
				if(!IsSameGrabCategory(GetMainGrabbed(), PossibleTarget))
					continue;
			}

			ValidTargets.Add(PossibleTarget);

			// Limit the max amount of targets
			if(ValidTargets.Num() >= PossibleTargets[0].MaxMultiGrabCount)
				break;
		}

		return ValidTargets;
	}

	private bool IsSameGrabCategory(UGravityBikeWhipGrabTargetComponent Main, UGravityBikeWhipGrabTargetComponent Possible) const
	{
		if(Main.GrabCategory == EGravityBikeWhipGrabCategory::UseClass)
		{
			return Main.Owner.Class == Possible.Owner.Class;
		}
		else
		{
			return Main.GrabCategory == Possible.GrabCategory;
		}
	}

	AHazePlayerCharacter GetScreenPlayer() const
	{
		if(SceneView::IsFullScreen())
			return SceneView::FullScreenPlayer;
		
		auto DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
		if(DriverComp != nullptr)
			return Player;
		else
			return Player.OtherPlayer;
	}

	FTransform GetWhipReferenceTransform() const
	{
		return FTransform(
			FRotator::MakeFromZX(GravityBike.AccBikeUp.Value.UpVector, GravityBike.ActorForwardVector),
			GravityBike.MeshPivot.WorldLocation
		);
	}

	FVector GetWhipImmediateLocation() const
	{
		const FVector AnimationLocation = Player.Mesh.GetSocketLocation(n"Align");
		FVector RelativeToPlayerLocation = Player.ActorTransform.InverseTransformPositionNoScale(AnimationLocation);

		float OffsetMultiplier = 1;
		const UGravityBikeWhipGrabTargetComponent MainGrabbed = GetMainGrabbed();
		if(MainGrabbed != nullptr)
			OffsetMultiplier = MainGrabbed.OffsetMultiplier;

		RelativeToPlayerLocation = Math::Lerp(
			FVector(0, 0, 150),
			RelativeToPlayerLocation,
			OffsetMultiplier
		);

		const FVector SplineLocation = GetWhipReferenceTransform().TransformPositionNoScale(RelativeToPlayerLocation);
		return SplineLocation;
	}

	FTransform GetWhipImmediateTransform() const
	{
		const FVector WhipLocation = GetWhipImmediateLocation();
		const FTransform SplineTransform = GravityBike.GetSplineTransform();
		return FTransform(SplineTransform.Rotation, WhipLocation);
	}

	FVector2D GetInputDirection() const
	{
		// if(Player.IsUsingGamepad())
		// {
			return Input.GetValue();
		// }
		// else
		// {
		// 	return Input.Value - FVector2D(0.5, 0.5);
		// }
	}

	FVector2D GetSmoothInputDirection() const
	{
		//check(Player.IsUsingGamepad());
		return SmoothInput;
	}

	UFUNCTION(BlueprintPure)
	UGravityBikeWhipGrabTargetComponent GetMainGrabbed() const
	{
		if(!HasGrabbedAnything())
			return nullptr;

		return GrabbedTargets[0];
	}

	FVector2D GetMainGrabTargetDirection() const
	{
		UGravityBikeWhipGrabTargetComponent MainGrabbedTarget = GetMainGrabbed();
		if(MainGrabbedTarget == nullptr)
			return FVector2D::ZeroVector;

		FVector2D PlayerUV;
		SceneView::ProjectWorldToViewpointRelativePosition(
			GetScreenPlayer(), Player.ActorLocation, PlayerUV
		);

		FVector2D TargetUV;
		SceneView::ProjectWorldToViewpointRelativePosition(
			GetScreenPlayer(), MainGrabbedTarget.WorldLocation, TargetUV
		);

		FVector2D ToTarget = (TargetUV - PlayerUV).GetSafeNormal();

		// FB TODO: Should we really flip this?
		ToTarget.Y *= -1;

		return ToTarget;
	}

	bool HasThrowTarget() const
	{
		return IsValid(ThrowTargetComp);
	}

	FVector2D GetThrowTargetScreenUV() const
	{
		if(!ensure(IsValid(ThrowTargetComp)))
			return FVector2D::ZeroVector;

		FVector2D TargetLocation;
		SceneView::ProjectWorldToViewpointRelativePosition(
			GetScreenPlayer(), ThrowTargetComp.WorldLocation, TargetLocation
		);

		return TargetLocation;
	}

	FVector2D GetPlayerToThrowTargetVectorUV() const
	{
		if(!ensure(IsValid(ThrowTargetComp)))
			return FVector2D::ZeroVector;

		FVector2D PlayerUV;
		SceneView::ProjectWorldToViewpointRelativePosition(
			GetScreenPlayer(), Player.ActorLocation, PlayerUV
		);

		FVector2D TargetUV = GetThrowTargetScreenUV();
		return TargetUV - PlayerUV;
	}

	FGravityBikeWhipThrowEventData GetThrowEventData(TArray<UGravityBikeWhipGrabTargetComponent> GrabTargets) const
	{
		FGravityBikeWhipThrowEventData ThrowEventData;

		for(auto GrabbedTarget : GrabTargets)
		{
			FGravityBikeWhipThrowData ThrowData;
			ThrowData.GrabTargetComp = GrabbedTarget;
			ThrowData.ThrowTargetComp = ThrowTargetComp;
			ThrowEventData.ThrowDatas.Add(ThrowData);
		}
		
		return ThrowEventData;
	}

	FVector GetThrowCrosshairWorldDirection() const
	{
		FVector WorldLocation;
		FVector WorldDirection;
		SceneView::DeprojectScreenToWorld_Relative(GetScreenPlayer(), GetThrowCrosshairTargetScreenUV(), WorldLocation, WorldDirection);
		return WorldDirection;
	}

	FVector2D GetThrowCrosshairTargetScreenUV() const
	{
		// if(Player.IsUsingGamepad())
		// {
			FVector2D ScreenUV;
			ScreenUV.X = HorizontalRange * GetSmoothInputDirection().X;
			ScreenUV.Y = VerticalRange * -GetSmoothInputDirection().Y;
			ScreenUV += FVector2D(0.5, 0.5);	// Move origin to center of screen
			return ScreenUV;
		// }
		// else
		// {
		// 	return FVector2D();
		// }
	}
};