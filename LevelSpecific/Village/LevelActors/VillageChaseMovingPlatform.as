event void FVillageChaseMovingPlatformEvent(AHazePlayerCharacter Player);

UCLASS(Abstract)
class AVillageChaseMovingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ChainRoot;

	UPROPERTY(DefaultComponent, Attach = ChainRoot)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UBoxComponent MioBlocker;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UBoxComponent ZoeBlocker;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.0;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	FVillageChaseMovingPlatformEvent OnPlayerLanded;

	UPROPERTY()
	FVillageChaseMovingPlatformEvent OnStartedMoving;

	FSplinePosition SplinePos;

	UPROPERTY(EditAnywhere)
	FHazeAcceleratedFloat AccMoveSpeed;

	UPROPERTY(EditAnywhere)
	float MaxMoveSpeed = 400.0;

	UPROPERTY(EditInstanceOnly)
	AActor LaunchDirectionActor;

	bool bMoving = false;

	TArray<AHazePlayerCharacter> PlayersOnPlatform;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineActor != nullptr)
		{
			SetActorLocationAndRotation(SplineActor.Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation), SplineActor.Spline.GetClosestSplineWorldRotationToWorldLocation(ActorLocation));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComp = UHazeSplineComponent::Get(SplineActor);
		SplinePos = FSplinePosition(SplineComp, SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation), true);

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");

		UHazeMovementComponent MioMoveComp = UHazeMovementComponent::Get(Game::Mio);
		MioMoveComp.AddMovementIgnoresComponent(this, MioBlocker);
		MioMoveComp.AddMovementIgnoresComponent(this, ZoeBlocker);

		UHazeMovementComponent ZoeMoveComp = UHazeMovementComponent::Get(Game::Zoe);
		ZoeMoveComp.AddMovementIgnoresComponent(this, ZoeBlocker);
		ZoeMoveComp.AddMovementIgnoresComponent(this, MioBlocker);
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		UVillageChaseMovingPlatformEffectEventHandler::Trigger_PlayerLanded(this);

		if (PlayersOnPlatform.Contains(Player))
			return;

		OnPlayerLanded.Broadcast(Player);

		PlayersOnPlatform.Add(Player);
		if (PlayersOnPlatform.Num() >= 2)
		{
			StartMoving();
		}

		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		if (Player.IsMio())
			MoveComp.RemoveMovementIgnoresComponents(this);
		else if (Player.IsZoe())
			MoveComp.RemoveMovementIgnoresComponents(this);

		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
	}

	UFUNCTION(DevFunction)
	void StartMoving()
	{
		bMoving = true;
		OnStartedMoving.Broadcast(Game::Mio);

		UVillageChaseMovingPlatformEffectEventHandler::Trigger_StartMoving(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bMoving)
			return;

		AccMoveSpeed.AccelerateTo(MaxMoveSpeed, 4.0, DeltaTime);
		SplinePos.Move(AccMoveSpeed.Value * DeltaTime);

		SetActorLocationAndRotation(SplinePos.WorldLocation, SplinePos.WorldRotation);
	}

	UFUNCTION()
	void BreakPlatform()
	{
		UVillageChaseMovingPlatformEffectEventHandler::Trigger_Destroyed(this);

		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			FPlayerLaunchToParameters LaunchToParams;
			LaunchToParams.Type = EPlayerLaunchToType::LaunchWithImpulse;
			LaunchToParams.LaunchImpulse = (LaunchDirectionActor.ActorForwardVector * 1600.0) + (FVector::UpVector * 300.0);
			LaunchToParams.Duration = 1.5;

			Player.LaunchPlayerTo(this, LaunchToParams);

			Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
			Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		}

		BP_BreakPlatform();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BreakPlatform() {}
}

class UVillageChaseMovingPlatformEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartMoving() {}
	UFUNCTION(BlueprintEvent)
	void Destroyed() {}
	UFUNCTION(BlueprintEvent)
	void PlayerLanded() {}
}