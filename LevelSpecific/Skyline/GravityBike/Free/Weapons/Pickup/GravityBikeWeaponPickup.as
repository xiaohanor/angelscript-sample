struct FGravityBikeWeaponPickupPlayerData
{
	float ResetTime = -1;
	UNiagaraComponent NiagaraComp;
	UDecalComponent DecalComp;
	UMaterialInstanceDynamic MID;
	float DecalOpacity = 0.5;

	bool IsEnabled() const
	{
		return ResetTime < 0;
	}
};

UCLASS(Abstract)
class AGravityBikeWeaponPickup : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent TriggerComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent MioNiagaraComp;

	UPROPERTY(DefaultComponent, Attach = MioNiagaraComp)
	UDecalComponent MioDecalComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ZoeNiagaraComp;

	UPROPERTY(DefaultComponent, Attach = ZoeNiagaraComp)
	UDecalComponent ZoeDecalComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000;

	UPROPERTY(EditAnywhere)
	float Radius = 500;

	UPROPERTY(EditAnywhere)
	float ChargePerPickup = 1.0;

	UPROPERTY(EditAnywhere)
	float ResetDuration = 3.0;

	UPROPERTY(EditDefaultsOnly)
	float ExpireDuration = -1.0;
	float ExpireTime = -1;

	UPROPERTY(EditAnywhere)
	bool bPerPlayer = true;

	TPerPlayer<FGravityBikeWeaponPickupPlayerData> PlayerDatas;
	float DecalMaxOpacity = 1;

	const float BobAmplitude = 40;
	const float BobFrequency = 3;
	const float SpinSpeed = 1.5;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TriggerComp.Shape = FHazeShapeSettings::MakeSphere(Radius);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		if (ExpireDuration > 0.0)
			ExpireTime = Time::GameTimeSeconds + ExpireDuration;

		SetupPlayerData(Game::Mio, MioNiagaraComp, MioDecalComp);
		SetupPlayerData(Game::Zoe, ZoeNiagaraComp, ZoeDecalComp);

		// Store the original opacity
		DecalMaxOpacity = PlayerDatas[0].DecalOpacity;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreen(f"{this} Weapon Pickup Ticking");

		if(ExpireDuration > 0.0 && Time::GameTimeSeconds > ExpireTime)
		{
			Expire();
			return;
		}

		for(auto Player : Game::Players)
		{
			FGravityBikeWeaponPickupPlayerData& PlayerData = PlayerDatas[Player];

			if(!PlayerData.IsEnabled())
			{
				// Reset weapon pickup for player after a duration
				if(Time::GameTimeSeconds > PlayerData.ResetTime)
				{
					Reset(Player);
				}
			}

			if(PlayerData.IsEnabled() && TriggerComp.IsPlayerInTrigger(Player))
			{
				// We are inside the trigger when it is enabled for us, so pick it up!
				OnPickedUp(Player);
			}

			// Fade decal in/out based on if it is enabled
			const float TargetOpacity = PlayerData.IsEnabled() ? DecalMaxOpacity : 0;
			PlayerData.DecalOpacity = Math::FInterpConstantTo(
				PlayerData.DecalOpacity,
				TargetOpacity,
				DeltaSeconds,
				1
			);

			PlayerData.MID.SetScalarParameterValue(n"Opacity", PlayerData.DecalOpacity);
		}

		if(!ShouldTick())
		{
			// Finished, stop ticking
			SetActorTickEnabled(false);
		}
	}

	void SetupPlayerData(AHazePlayerCharacter Player, UNiagaraComponent NiagaraComp, UDecalComponent DecalComp)
	{
		FGravityBikeWeaponPickupPlayerData& PlayerData = PlayerDatas[Player];

		PlayerData.NiagaraComp = NiagaraComp;
		NiagaraComp.SetRenderedForPlayer(Player, true);
		NiagaraComp.SetRenderedForPlayer(Player.OtherPlayer, false);

		PlayerData.DecalComp = DecalComp;

		PlayerData.MID = Material::CreateDynamicMaterialInstance(DecalComp, DecalComp.GetDecalMaterial());
		PlayerData.MID.SetScalarParameterValue(n"MioZoe", Player.IsMio() ? 0 : 1);
		DecalComp.SetDecalMaterial(PlayerData.MID);

		PlayerData.DecalOpacity = PlayerData.MID.GetScalarParameterValue(n"Opacity");
	}

	private bool ShouldTick()
	{
		if(TriggerComp.AreAnyPlayersInTrigger())
			return true;

		if(!PlayerDatas[0].IsEnabled())
			return true;
		else if(PlayerDatas[0].DecalOpacity < DecalMaxOpacity)
			return true;

		if(!PlayerDatas[1].IsEnabled())
			return true;
		else if(PlayerDatas[1].DecalOpacity < DecalMaxOpacity)
			return true;

		return false;
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(!PlayerDatas[Player].IsEnabled())
			return;

		OnPickedUp(Player);
	}

	void OnPickedUp(AHazePlayerCharacter Player)
	{
		auto WeaponComp = UGravityBikeWeaponUserComponent::Get(Player);
		if(WeaponComp == nullptr)
			return;

		WeaponComp.AddCharge(ChargePerPickup);
		WeaponComp.OnWeaponPickupPickedUp.Broadcast();

		AGravityBikeFree GravityBike = GravityBikeFree::GetGravityBike(Player);
		if(GravityBike != nullptr)
			UGravityBikeFreeEventHandler::Trigger_OnWeaponPickupPickedUp(GravityBikeFree::GetGravityBike(Player));

		FGravityBikeWeaponPickupPlayerData& PlayerData = PlayerDatas[Player];
		PlayerData.NiagaraComp.Deactivate();

		FGravityBikeWeaponPickupOnPickedUpEventData EventData;
		EventData.Player = Player;
		UGravityBikeWeaponPickupEventHandler::Trigger_OnPickedUp(this, EventData);

		PlayerData.ResetTime = Time::GameTimeSeconds + ResetDuration;
		SetActorTickEnabled(true);

		if (!bPerPlayer)
			Expire();
	}

	void Reset(AHazePlayerCharacter Player)
	{
		FGravityBikeWeaponPickupPlayerData& PlayerData = PlayerDatas[Player];
		PlayerData.NiagaraComp.Activate();
		PlayerData.ResetTime = -1;

		FGravityBikeWeaponPickupOnRespawnedEventData EventData;
		EventData.Player = Player;
		UGravityBikeWeaponPickupEventHandler::Trigger_OnRespawned(this, EventData);
	}

	void Expire()
	{
		UGravityBikeWeaponPickupEventHandler::Trigger_OnExpire(this);
		DestroyActor();
	}
};