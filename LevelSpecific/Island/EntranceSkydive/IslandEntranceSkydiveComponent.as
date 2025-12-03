namespace IslandEntranceSkydive
{
	UFUNCTION()
	void IslandAddSpeedEffectBlocker(FInstigator Instigator, AHazePlayerCharacter Player)
	{
		auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
		SkydiveComp.SpeedEffectBlockers.AddUnique(Instigator);
	}

	UFUNCTION()
	void IslandRemoveSpeedEffectBlocker(FInstigator Instigator, AHazePlayerCharacter Player)
	{
		auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
		SkydiveComp.SpeedEffectBlockers.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IslandIsSpeedEffectBlocker(AHazePlayerCharacter Player)
	{
		auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
		return SkydiveComp.SpeedEffectBlockers.Num() > 0;
	}

}

struct FIslandEntranceSkydiveAnimData
{
	FVector2D SkydiveInput;
	int BarrelRollDirection = 0;
	int HitReactionDirection = 0;
}

UCLASS(Abstract)
class UIslandEntranceSkydiveComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactFF;
	
	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect BarrelRollFF;

	TArray<FInstigator> SpeedEffectBlockers;

	private TArray<FInstigator> SkydivingInstigators;
	private TArray<FInstigator> SlowMovementInstigators;
	private AHazePlayerCharacter PlayerOwner;
	private UPlayerMovementComponent MoveComp;
	UIslandEntranceSkydiveSettings Settings;
	FVector CurrentHorizontalVelocity;
	UIslandEntranceSkydiveBoundarySplineContainerComponent BoundarySplineContainer;
	TOptional<FVector> PreviousSplineClosestLocation;
	FHazeAcceleratedFloat AcceleratedTerminalVelocity;

	FIslandEntranceSkydiveAnimData AnimData;
	int CurrentHitReactionRequest = 0;
	bool bActivatedFromCutscene = false;
	bool bOverrideGravity = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoundarySplineContainer = UIslandEntranceSkydiveBoundarySplineContainerComponent::GetOrCreate(Game::Mio);
		MoveComp = UPlayerMovementComponent::Get(PlayerOwner);
		Settings = UIslandEntranceSkydiveSettings::GetSettings(PlayerOwner);
	}

	UFUNCTION()
	void StartSkydiving(FInstigator Instigator, bool bFromCutscene = false)
	{
		if(!IsSkydiving())
		{
			bActivatedFromCutscene = bFromCutscene;
			OnStartSkydive();
		}

		SkydivingInstigators.AddUnique(Instigator);
	}

	UFUNCTION()
	void StopSkydiving(FInstigator Instigator)
	{
		SkydivingInstigators.RemoveSingleSwap(Instigator);

		if(!IsSkydiving())
		{
			OnStopSkydive();
		}
	}

	void ClearSkydivingInstigators()
	{
		if(SkydivingInstigators.Num() > 0)
			OnStopSkydive();

		SkydivingInstigators.Reset();
	}

	void OnStartSkydive()
	{
		CurrentHorizontalVelocity = MoveComp.HorizontalVelocity;
		AcceleratedTerminalVelocity.SnapTo(UMovementGravitySettings::GetSettings(PlayerOwner).TerminalVelocity);
		UPlayerCoreMovementEffectHandler::Trigger_Skydive_Started(PlayerOwner);
	}

	void OnStopSkydive()
	{
		MoveComp.RemoveMovementIgnoresActor(this);
		MoveComp.RemoveMovementIgnoresComponents(this);
		UPlayerCoreMovementEffectHandler::Trigger_Skydive_Stopped(PlayerOwner);
		ClearGravityAudioSyncOverride();
	}

	void ClearGravityAudioSyncOverride()
	{
		if(!bOverrideGravity)
			return;

		UMovementGravitySettings::ClearGravityAmount(PlayerOwner, this, EHazeSettingsPriority::Final);
		bOverrideGravity = false;
	}

	void AddSpeedEffectBlocker(FInstigator Instigator)
	{
		SpeedEffectBlockers.AddUnique(Instigator);
	}

	void RemoveSpeedEffectBlocker(FInstigator Instigator)
	{
		SpeedEffectBlockers.RemoveSingleSwap(Instigator);
	}

	bool IsSpeedEffectBlocked() const
	{
		return SpeedEffectBlockers.Num() > 0;
	}

	UFUNCTION(BlueprintPure)
	bool IsSkydiving() const
	{
		return SkydivingInstigators.Num() > 0;
	}

	UFUNCTION()
	void EnableSlowMovement(FInstigator Instigator)
	{
		SlowMovementInstigators.AddUnique(Instigator);
	}

	UFUNCTION()
	void DisableSlowMovement(FInstigator Instigator)
	{
		SlowMovementInstigators.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsSlowMovementEnabled() const
	{
		return SlowMovementInstigators.Num() > 0;
	}

	void OnImpacts(
		const TArray<FIslandEntranceSkydiveObstacleImpact>& Impacts,
		const TArray<AActor>& ActorsToIgnore,
		const TArray<UPrimitiveComponent>& ComponentsToIgnore
	)
	{
		if(!Impacts.IsEmpty())
		{
			for(auto Impact : Impacts)
				Impact.ResponseComponent.BroadcastOnImpact(PlayerOwner, Impact.ImpactPoint);
		}

		MoveComp.AddMovementIgnoresActors(this, ActorsToIgnore);
		MoveComp.AddMovementIgnoresComponents(this, ComponentsToIgnore);
	}

	void RequestHitReaction(FVector SourceOfHit)
	{
		if(CurrentHitReactionRequest != 0)
			return;

		FVector LocalSourceOfHit = PlayerOwner.ActorTransform.InverseTransformPosition(SourceOfHit);
		CurrentHitReactionRequest = LocalSourceOfHit.Y > 0.0 ? -1 : 1;
	}

	FVector GetBoundarySplineCounterForce(FVector Location, float CurrentMaxSpeed)
	{
		UIslandEntranceSkydiveBoundarySplineComponent BoundarySpline = GetCurrentBoundarySplineComponent();
		if(BoundarySpline == nullptr)
			return FVector();

		FTransform ClosestTransform;
		float Alpha = BoundarySpline.GetDistanceAlphaToCenter(Location, ClosestTransform);
		return (ClosestTransform.Location - Location).VectorPlaneProject(ClosestTransform.Rotation.ForwardVector).VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal() * (CurrentMaxSpeed * Alpha);
	}

	UIslandEntranceSkydiveBoundarySplineComponent GetCurrentBoundarySplineComponent()
	{
		UIslandEntranceSkydiveBoundarySplineComponent LowestDistanceBoundary = nullptr;
		float LowestDistance = MAX_flt;
		for(UIslandEntranceSkydiveBoundarySplineComponent BoundaryComp : BoundarySplineContainer.BoundarySplineComponents)
		{
			float Dist = BoundaryComp.Spline.GetClosestSplineDistanceToWorldLocation(PlayerOwner.ActorLocation);
			// Player is outside spline so this isn't valid!
			if(Math::IsNearlyZero(Dist) || Math::IsNearlyEqual(Dist, BoundaryComp.Spline.SplineLength))
				continue;

			if(Dist < LowestDistance)
			{
				LowestDistance = Dist;
				LowestDistanceBoundary = BoundaryComp;
			}
		}

		return LowestDistanceBoundary;
	}

	/* Takes in velocity and drag and delta time and returns the velocity to add. */
	FVector GetFrameRateIndependentDrag(FVector Velocity, float Drag, float DeltaTime)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		FVector TargetVelocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);
		return TargetVelocity - Velocity;
	}

	float GetAccelerationWithDrag(float DeltaTime, float DragFactor, float MaxSpeed, float DragExponent = 1.0) const
	{
		const float IntegratedDragFactor = Math::Exp(-DragFactor);
		const float NewSpeed = MaxSpeed * Math::Pow(IntegratedDragFactor, DeltaTime);
		float Drag = Math::Abs(NewSpeed - MaxSpeed);

		// Optional, to make the drag more exponential. Might feel nicer
		if(DragExponent > 1.0 + KINDA_SMALL_NUMBER)
			Drag = Math::Pow(Drag, DragExponent);

		return Drag / DeltaTime;
	}
}

UFUNCTION(DisplayName = "Island Enable Entrance Skydive")
mixin void IslandEnableEntranceSkydive(AHazePlayerCharacter Player, FInstigator Instigator, UIslandEntranceSkydiveSettings SkydiveSettings, bool bFromCutscene = false, EHazeSettingsPriority SettingsPriority = EHazeSettingsPriority::Gameplay)
{
	if(SkydiveSettings != nullptr)
		Player.ApplySettings(SkydiveSettings, Instigator, SettingsPriority);

	auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
	SkydiveComp.StartSkydiving(Instigator, bFromCutscene);
}

UFUNCTION(DisplayName = "Island Disable Entrance Skydive")
mixin void IslandDisableEntranceSkydive(AHazePlayerCharacter Player, FInstigator Instigator)
{
	Player.ClearSettingsOfClass(UIslandEntranceSkydiveSettings, Instigator);

	auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
	SkydiveComp.StopSkydiving(Instigator);
}

UFUNCTION(DisplayName = "Island Entrance Skydive Enable Slow Movement")
mixin void IslandEntranceSkydiveEnableSlowMovement(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
	SkydiveComp.EnableSlowMovement(Instigator);
}

UFUNCTION(DisplayName = "Island Entrance Skydive Disable Slow Movement")
mixin void IslandEntranceSkydiveDisableSlowMovement(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
	SkydiveComp.DisableSlowMovement(Instigator);
}

UFUNCTION(DisplayName = "Island Entrance Request Hit Reaction")
mixin void IslandEntranceSkydiveRequestHitReaction(AHazePlayerCharacter Player, FVector SourceHit)
{
	auto SkydiveComp = UIslandEntranceSkydiveComponent::Get(Player);
	SkydiveComp.RequestHitReaction(SourceHit);
}
