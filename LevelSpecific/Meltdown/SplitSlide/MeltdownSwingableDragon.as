event void FMeltdownSwingDragonPlayerRespawnedSignature(AHazePlayerCharacter Player);
event void FMeltdownSwingDragonLiftOffSignature();

class AMeltdownSwingableDragon : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent, Attach = ScifiRoot)
	USceneComponent ShipRoot;

	UPROPERTY(DefaultComponent, Attach = FantasyRoot)
	USceneComponent DragonRoot;

	UPROPERTY(DefaultComponent, Attach = DragonRoot)
	UHazeSkeletalMeshComponentBase DragonMesh;

	UPROPERTY(DefaultComponent, Attach = DragonMesh, AttachSocket = "LeftHandMiddle3")
	USceneComponent MioSwingFantasyAttachComp;

	UPROPERTY(DefaultComponent, Attach = DragonMesh, AttachSocket = "RightHandMiddle3")
	USceneComponent ZoeSwingFantasyAttachComp;

	UPROPERTY(DefaultComponent, Attach = ShipRoot)
	USwingPointComponent SwingCompMio;
	default SwingCompMio.UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent, Attach = ShipRoot)
	USwingPointComponent SwingCompZoe;
	default SwingCompZoe.UsableByPlayers = EHazeSelectPlayer::Zoe;

	UPROPERTY(EditInstanceOnly)
	AActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor CameraActor;

	UPROPERTY(EditAnywhere)
	float SplineForwardOffset = 1000.0;

	UPROPERTY(EditAnywhere)
	float FreeFlyingSpeed = 3000.0;

	UPROPERTY(EditAnywhere)
	float AccelerationDuration = 2.0;

	UPROPERTY()
	FTimeDilationEffect TimeDilationEffect;

	UPROPERTY()
	FMeltdownSwingDragonPlayerRespawnedSignature OnPlayerRespawned;

	UPROPERTY()
	FMeltdownSwingDragonLiftOffSignature OnLiftOff;

	TPerPlayer<bool> bAttached;

	bool bFollowingPlayer = false;
	bool bFlyingFreely = false;

	FHazeAcceleratedFloat AcceleratedSplineLocation;
	float FreeFlyingTargetSplineLocation;

	bool bPlayersReleased = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		SwingCompMio.OnPlayerAttachedEvent.AddUFunction(this, n"HandleSwingAttached");
		SwingCompZoe.OnPlayerAttachedEvent.AddUFunction(this, n"HandleSwingAttached");

		FVector MioSwingLocation = DragonRoot.WorldTransform.InverseTransformPositionNoScale(MioSwingFantasyAttachComp.WorldLocation);
		FVector ZoeSwingLocation = DragonRoot.WorldTransform.InverseTransformPositionNoScale(ZoeSwingFantasyAttachComp.WorldLocation);

		SwingCompMio.SetRelativeLocation(MioSwingLocation);
		SwingCompZoe.SetRelativeLocation(ZoeSwingLocation);

		SplineComp = Spline::GetGameplaySpline(SplineActor, this);

		if (SplineComp == nullptr)
			PrintToScreen("Swing dragon is missing spline reference", 3.0, FLinearColor::Red);

		for (auto Player : Game::GetPlayers())
		{
			auto HealthComp = UPlayerHealthComponent::GetOrCreate(Player);
			HealthComp.OnStartDying.AddUFunction(this, n"HandlePlayerDeath");

			if (Player == Game::Zoe)
				HealthComp.OnFinishDying.AddUFunction(this, n"HandleZoeRespawn");
			else
				HealthComp.OnFinishDying.AddUFunction(this, n"HandleMioRespawn");
		}

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bFollowingPlayer)
		{
			float TargetSplineDistance = (GetPlayerSplineDistance(Game::Mio) + GetPlayerSplineDistance(Game::Zoe)) * 0.5 + SplineForwardOffset;
										
			AcceleratedSplineLocation.AccelerateTo(TargetSplineDistance, AccelerationDuration, DeltaSeconds);
		}

		if (bFlyingFreely)
		{
			FreeFlyingTargetSplineLocation += FreeFlyingSpeed * DeltaSeconds;
			AcceleratedSplineLocation.AccelerateTo(FreeFlyingTargetSplineLocation, AccelerationDuration, DeltaSeconds);
		}

		if (!bPlayersReleased)
		{
			for (auto Player : Game::Players)
			{
				if (bAttached[Player])
				{
					FHazeFrameForceFeedback FF;
					FF.LeftMotor = 0.1 + Math::Sin(Time::GameTimeSeconds * 1.0) * 0.2;
					FF.RightMotor = 0.1 + Math::Sin(-Time::GameTimeSeconds * 1.0) * 0.2;

					Player.SetFrameForceFeedback(FF);
				}
			}
		}

		FVector Location = SplineComp.GetWorldLocationAtSplineDistance(AcceleratedSplineLocation.Value);
		FQuat Rotation = SplineComp.GetWorldRotationAtSplineDistance(AcceleratedSplineLocation.Value);
		ShipRoot.SetWorldLocationAndRotation(Location, Rotation);
		DragonRoot.SetRelativeLocationAndRotation(ShipRoot.RelativeLocation, ShipRoot.RelativeRotation);
	}

	private float GetPlayerSplineDistance(AHazePlayerCharacter InPlayer)
	{
		AHazePlayerCharacter Player = InPlayer;
		if (Player.IsPlayerDead() || bAttached[Player])
			Player = Player.OtherPlayer;

		float Distance = SplineComp.GetClosestSplineDistanceToWorldLocation(Player.ActorLocation);
		return Distance;
	}

	UFUNCTION()
	void Activate()
	{
		RemoveActorDisable(this);
		bFollowingPlayer = true;
	}

	UFUNCTION()
	private void HandlePlayerDeath()
	{
		for (auto Player : Game::GetPlayers())
		{
			if (bAttached[Player] && Player.OtherPlayer.IsPlayerDead())
				LiftOff();
		}

		if (bAttached[Game::Zoe] && bAttached[Game::Mio])
		{
			TimeDilation::StopWorldTimeDilationEffect(this);
		}
	}

	UFUNCTION()
	private void HandleMioRespawn()
	{
		if (bFlyingFreely)
			SwingCompMio.ForceActivateSwingPoint(Game::Mio);

		if (bAttached[Game::Zoe] && bAttached[Game::Mio])
		{
			OnPlayerRespawned.Broadcast(Game::Mio);
			Deactivate();
		}
	}

	UFUNCTION()
	private void HandleZoeRespawn()
	{
		if (bFlyingFreely)
			SwingCompZoe.ForceActivateSwingPoint(Game::Zoe);
		
		if (bAttached[Game::Zoe] && bAttached[Game::Mio])
		{
			OnPlayerRespawned.Broadcast(Game::Zoe);
			Deactivate();
		}
	}

	UFUNCTION()
	void StartInSwingSetup()
	{
		RemoveActorDisable(this);
		RepositionRoots();

		float TargetSplineDistance = (GetPlayerSplineDistance(Game::Mio) + GetPlayerSplineDistance(Game::Zoe)) * 0.5 + SplineForwardOffset;
		FreeFlyingTargetSplineLocation = TargetSplineDistance;
		AcceleratedSplineLocation.SnapTo(FreeFlyingTargetSplineLocation);

		PrintToScreen("Spline distance = " + TargetSplineDistance, 3.0);

		SwingCompMio.ForceActivateSwingPoint(Game::Mio);
		SwingCompZoe.ForceActivateSwingPoint(Game::Zoe);
	}

	UFUNCTION()
	private void HandleSwingAttached(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		bAttached[Player] = true;

		Player.BlockCapabilities(PlayerMovementTags::Swimming, this);
		Player.BlockCapabilities(PlayerSwingTags::SwingCancel, this);
		Player.BlockCapabilities(PlayerSwingTags::SwingJump, this);
		Player.BlockCapabilities(n"Death", this);

		PrintToScreenScaled("Attached" + Player, 3.0);

		if (bAttached[Player.OtherPlayer])
			LiftOff();

		if (Player.OtherPlayer.IsPlayerDead())
			LiftOff();

	}

	private void LiftOff()
	{
		if (bFlyingFreely)
			return;

		bFollowingPlayer = false;
		bFlyingFreely = true;

		FreeFlyingTargetSplineLocation = AcceleratedSplineLocation.Value;

		for (auto Player : Game::GetPlayers())
			Player.ActivateCamera(CameraActor, 3.0, this, EHazeCameraPriority::VeryHigh);

		Timer::SetTimer(this, n"EnableFantasy", 4.5);
		OnLiftOff.Broadcast();
	}

	UFUNCTION()
	private void EnableFantasy()
	{
		SetFantasyEnabled(true);
	}

	UFUNCTION()
	void ReleasePlayers()
	{
		for (auto Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(PlayerSwingTags::SwingCancel, this);
			Player.UnblockCapabilities(PlayerSwingTags::SwingJump, this);
			Player.UnblockCapabilities(PlayerMovementTags::Swimming, this);
			Player.UnblockCapabilities(n"Death", this);

			Player.DeactivateCameraByInstigator(this, 2.0);

			Player.SetActorVelocity(FVector::ZeroVector);
			Player.AddMovementImpulse(ActorForwardVector * 1000.0 + FVector::UpVector * 500.0);

			TimeDilation::StartWorldTimeDilationEffect(TimeDilationEffect, this);
		}

		bPlayersReleased = true;

		SwingCompMio.Disable(this);
		SwingCompZoe.Disable(this);

		//Timer::SetTimer(this, n"Deactivate", 3.0);
	}

	UFUNCTION()
	void Deactivate()
	{
		for (auto Player : Game::GetPlayers())
		{
			auto HealthComp = UPlayerHealthComponent::GetOrCreate(Player);
			HealthComp.OnStartDying.UnbindObject(this);
			HealthComp.OnFinishDying.UnbindObject(this);
		}

		AddActorDisable(this);
	}

	UFUNCTION()
	void HandlePlayerGrappled(AHazePlayerCharacter Player)
	{
	}
};