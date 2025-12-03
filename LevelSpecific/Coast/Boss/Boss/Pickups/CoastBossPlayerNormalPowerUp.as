enum ECoastBossPlayerPowerUpType
{
	Barrage,
	Laser,
	Homing
}

UCLASS(Abstract)
class ACoastBossPlayerNormalPowerUp : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UWidgetComponent Icon;

	UPROPERTY(DefaultComponent)
	UNetworkLockComponent NetworkLock;

	// Making an array of these in CoastBossActorReferences instead so you can determine spawn order since there is now multiple types of PowerUps
	// UPROPERTY(DefaultComponent)
	// UHazeListedActorComponent ListedComp;

	ACoastBossActorReferences Refs;
	bool bPendingActive = false;
	bool bActive = false;
	bool bPlayerPicked = false;
	AHazePlayerCharacter ClaimedPlayer;

	float AliveDuration = 0.0;
	float PickedUpTimestamp = 0.0;
	float RandomSinusOffset = 0.0;
	float RandomXOffset = 0.0;

	FVector2D ManualRelativeLocation;
	FVector OGScale;

	ECoastBossPlayerPowerUpType PowerUpType = ECoastBossPlayerPowerUpType::Barrage;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<ACoastBossActorReferences> References;
		Refs = References.Single;
		OGScale = Icon.GetWorldScale();
		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Update the network lock so it tries to be owned by the closest player
		for (auto Player : Game::Players)
			NetworkLock.ApplyOwnerHint(Player, this, -Player.ActorLocation.DistSquared(ActorLocation), false);
		NetworkLock.UpdateHintValues();
	}

	void Activate(float SinusOffset, float XOffset)
	{
		bPendingActive = true;
		CrumbActivate(SinusOffset, XOffset);
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivate(float SinusOffset, float XOffset)
	{
		if(ClaimedPlayer != nullptr)
			NetworkLock.Release(ClaimedPlayer, this);

		ClaimedPlayer = nullptr;
		bPendingActive = false;
		bActive = true;
		bPlayerPicked = false;
		Icon.SetWorldScale3D(OGScale);
		AliveDuration = 0.0;
		SetActorHiddenInGame(false);
		SetActorTickEnabled(true);
		RandomSinusOffset = SinusOffset;
		RandomXOffset = XOffset;

		FCoastBossPowerUpPickupEffectParams Params;
		Params.PowerUp = this;
		UCoastBossPowerUpEffectHandler::Trigger_OnSpawn(this, Params);
	}

	void TryPickup(AHazePlayerCharacter Player)
	{
		if (Network::IsGameNetworked())
		{
			NetworkLock.Acquire(Player, this, FNetworkLockDelegate(this, n"CrumbPickedUp"));
		}
		else
			PickedUp(Player, this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbPickedUp(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		PickedUp(Player, Instigator);
	}

	UFUNCTION()
	private void PickedUp(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		PickedUpTimestamp = Time::GameTimeSeconds;
		bPlayerPicked = true;
		ClaimedPlayer = Player;
		BP_OnPickedUp();
		SetActorHiddenInGame(true);
		SetActorTickEnabled(true);
		UCoastBossAeronauticComponent AeroComp = UCoastBossAeronauticComponent::Get(Player);
		AeroComp.LastPowerUpTimestamp = Time::GameTimeSeconds;
		AeroComp.LastPowerUpType = PowerUpType;

		Player.PlayForceFeedback(AeroComp.FFPickup, false, true, this);

		FCoastBossPowerUpPickupEffectParams Params;
		Params.Player = Player;
		Params.PowerUp = this;
		UCoastBossPowerUpEffectHandler::Trigger_OnPickup(this, Params);

		FCoastBossAeronauticPowerupEffectData PlayerParams;
		PlayerParams.PowerupType = PowerUpType;
		UCoastBossAeuronauticPlayerEventHandler::Trigger_OnPickupPowerup(Player, PlayerParams);
	}

	void Unspawn()
	{
		bActive = false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnUnspawned()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPickedUp()
	{
	}
};