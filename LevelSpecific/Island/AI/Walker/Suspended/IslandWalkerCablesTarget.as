event void IslandWalkerCablesTargetOnBreakSignature(AIslandWalkerCablesTarget Target);
event void IslandWalkerCablesTargetOnRecoverSignature(AIslandWalkerCablesTarget Target);
event void IslandWalkerCablesTargetOnTakeDamageSignature(AIslandWalkerCablesTarget Target);

class AIslandWalkerCablesTarget : AHazeActor
{
	default AddActorTag(n"TreatAsAIForImpacts");

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ForceFieldRoot;

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UWalkerCablesTargetPanel Panel;

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UWalkerCablesTargetHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
    UHazeCrumbSyncedFloatComponent NetSyncedHealth;
	default NetSyncedHealth.DefaultValue = 1.0;
	default NetSyncedHealth.SyncRate = EHazeCrumbSyncRate::High; // Value will only change when player is shooting at target

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UIslandWalkerForceFieldComponent ForceFieldComp;
	default ForceFieldComp.WorldScale3D = FVector(4.2, 4.2, 4.2);
	default ForceFieldComp.Type = EIslandForceFieldType::Red;
	default ForceFieldComp.OverrideBreachLocation = FVector(0.0, 0.0, 50.0);

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	default GrenadeResponseComp.Shape.Type = EHazeShapeType::Sphere;
	default GrenadeResponseComp.Shape.SphereRadius = 250.0;

	UPROPERTY(DefaultComponent, Attach = "GrenadeResponseComp")
	UIslandRedBlueTargetableComponent TargetableComp;
	default TargetableComp.TargetShape.Type = EHazeShapeType::None;
	default TargetableComp.bTargetWithGrenade = true;
	default TargetableComp.bOnlyValidIfAimOriginIsWithinAngle = true;
	default TargetableComp.MaxAimAngle = 100.0;

	UPROPERTY(DefaultComponent, Attach="Panel", AttachSocket="")
	UIslandWalkerSuspendCouplingComponent CableCouplingRight;
	default CableCouplingRight.CableRailOffset = FVector(1500.0, 2000.0, 0.0);

	UPROPERTY(DefaultComponent, Attach="Panel", AttachSocket="")
	UIslandWalkerSuspendCouplingComponent CableCouplingLeft;
	default CableCouplingLeft.CableRailOffset = FVector(1500.0, -2000.0, 0.0);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerForceFieldCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerCablesTargetGrenadeDetectionCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactOverchargeResponseComponent ShootingResponseComp;

	float InitialDamageTime = BIG_NUMBER;

	UPROPERTY()
	TSubclassOf<AIslandOverloadShootablePanel> PanelClass;

	IslandWalkerCablesTargetOnBreakSignature OnBreak;
	IslandWalkerCablesTargetOnRecoverSignature OnRecover;
	IslandWalkerCablesTargetOnTakeDamageSignature OnTakeDamage;

	AHazeCharacter OwnerWalker;
	UIslandWalkerSettings Settings;
	AHazePlayerCharacter DestroyingPlayer;

	float Health = 1.0;

	bool bIsPoweredUp = true;
	bool bForceFieldBreached = false;
	bool bCablesTargetDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandWalkerSettings::GetSettings(OwnerWalker);
		ForceFieldComp.OnDepleted.AddUFunction(this, n"OnForceFieldDepleted");
		if (ForceFieldComp.Type == EIslandForceFieldType::Blue)
			TargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Zoe);
		else 	
			TargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Mio);
		TargetableComp.Disable(this);

		DestroyingPlayer = Game::Mio;

		if (ForceFieldComp.Type == EIslandForceFieldType::Blue)
		{
			DestroyingPlayer = Game::Zoe;
			NetSyncedHealth.OverrideControlSide(Game::Zoe);
		}
		else
		{
			NetSyncedHealth.OverrideControlSide(Game::Mio);
		}

		ShootingResponseComp.bUseDataAssetSettings = false;
		ShootingResponseComp.Settings_Property = Settings.HeadPanelOverchargeSettings;

		// Same color for forcefield and panel
		if (ForceFieldComp.Type == EIslandForceFieldType::Red)
			ShootingResponseComp.Settings_Property.OverchargeColor = EIslandRedBlueOverchargeColor::Red;
		else
			ShootingResponseComp.Settings_Property.OverchargeColor = EIslandRedBlueOverchargeColor::Blue;

		ShootingResponseComp.OnImpactEvent.AddUFunction(this, n"OnPanelImpact");

		Panel.SetColor(DestroyingPlayer.Player);

		GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnGrenadeDetonated");
		GrenadeResponseComp.IgnoreCollisionActors.Add(OwnerWalker);

	 	CableCouplingRight.DestroyedByPlayer = DestroyingPlayer.Player;
	 	CableCouplingLeft.DestroyedByPlayer = DestroyingPlayer.Player;

		if (ForceFieldComp.Type == EIslandForceFieldType::Blue)
		{
			CableCouplingRight.CableRailOffset.X = -1500.0;
			CableCouplingLeft.CableRailOffset.X = -1500.0;
		}

		HealthBarComp.Initialize(DestroyingPlayer);

		UIslandWalkerPhaseComponent::Get(OwnerWalker).OnPhaseChange.AddUFunction(this, n"OnWalkerPhaseChange");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPanelImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (!bForceFieldBreached)
			return;

		if (bCablesTargetDestroyed)
			return;	

		if (Data.Player != DestroyingPlayer)
			return;

		if (DestroyingPlayer.ActorLocation.Z < ActorLocation.Z - 500.0)
			return;	// Can only hit from aboveish

		float CurTime = Time::GameTimeSeconds;
		if (CurTime < InitialDamageTime)
			InitialDamageTime = CurTime;
		float Damage = (CurTime < InitialDamageTime + 7.0) ? Settings.CablePanelDamagePerImpactFirstJump : Settings.CablePanelDamagePerImpactLaterJumps;

		if (DestroyingPlayer.HasControl())			
			Health -= Damage;

		HealthBarComp.OnTakeDamage(Health);

		if (Health < SMALL_NUMBER)
		{
			if (DestroyingPlayer.HasControl())
				CrumbDestroy();
		}
		else
		{
			OnTakeDamage.Broadcast(this);
		}

		// Suppress force field
		ForceFieldComp.TakeDamage(Settings.ForceFieldPanelImpactSuppression, ForceFieldComp.WorldLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGrenadeDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		if (bCablesTargetDestroyed)
			return;	
		
		if (IslandForceField::GetPlayerForceFieldType(Data.GrenadeOwner) != ForceFieldComp.Type)
		{
			UIslandWalkerCablesTargetEffectHandler::Trigger_OnGrenadeDetonatedWrongColour(this);	
			return;
		}
	}

	UFUNCTION()
	private void OnWalkerPhaseChange(EIslandWalkerPhase NewPhase)
	{
		if ((NewPhase >= EIslandWalkerPhase::Decapitated) && !IsActorDisabled())
			AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bForceFieldBreached && DestroyingPlayer.HasControl())
		{
			if (ForceFieldComp.Integrity > 0.85)
				CrumbForceFieldRecover();
		}

		if (DestroyingPlayer.HasControl())			
			NetSyncedHealth.Value = Health;
		else
			Health = NetSyncedHealth.Value;

		HealthBarComp.UpdateHealthBar();
	}

	UFUNCTION()
	private void OnForceFieldDepleted(UIslandWalkerForceFieldComponent ForceFieldComponent)
	{
		if(!ForceFieldComp.IsDepleted())
			return;

		UIslandWalkerCablesTargetEffectHandler::Trigger_OnForcefieldDepleted(this);	

		bForceFieldBreached = true;
		ForceFieldComp.ApplyCollision(n"NoCollision", this, EInstigatePriority::Normal);
		TargetableComp.bTargetWithGrenade = false;
	}

	UFUNCTION(CrumbFunction)
	void CrumbForceFieldRecover()
	{
		bForceFieldBreached = false;
		ForceFieldComp.ClearCollision(this);
		TargetableComp.bTargetWithGrenade = true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbDestroy()
	{
		if (bCablesTargetDestroyed)
			return;

		bCablesTargetDestroyed = true;	
		Panel.Break(DestroyingPlayer.Player);
		UIslandWalkerCablesTargetEffectHandler::Trigger_OnDestroyed(this, FIslandWalkerCablesTargetDestroyedData(RootComp.WorldLocation));
		ForceFieldComp.AddComponentVisualsAndCollisionAndTickBlockers(this);
		AddActorTickBlock(this);
		HealthBarComp.OnDestroyed();
		OnBreak.Broadcast(this);
	}

	UFUNCTION()
	private void OnWalkerReset()
	{
		RemoveActorDisable(this);
		PowerUp();
	}

	void PowerUp()
	{
		if (bIsPoweredUp)
			return;
		bIsPoweredUp = true;
		Health = 1.0;
		HealthBarComp.Initialize(DestroyingPlayer);
		ForceFieldComp.PowerUp();
		GrenadeResponseComp.bTriggerForRedPlayer = true;
		GrenadeResponseComp.bTriggerForBluePlayer = true;
		TargetableComp.Enable(this);
		Panel.RemoveComponentVisualsBlocker(this);
		UIslandWalkerEffectHandler::Trigger_OnCablesTargetPowerUp(OwnerWalker, FIslandWalkerCablesTargetEventData(this));
		UIslandWalkerCablesTargetEffectHandler::Trigger_OnPowerUp(this);
	}

	void PowerDown()
	{
		if (!bIsPoweredUp)
			return;
		bIsPoweredUp = false;
		ForceFieldComp.PowerDown();
		HealthBarComp.RemoveHealthBar();
		GrenadeResponseComp.bTriggerForRedPlayer = false;
		GrenadeResponseComp.bTriggerForBluePlayer = false;
		TargetableComp.Disable(this);
		Panel.AddComponentVisualsBlocker(this);
		UIslandWalkerEffectHandler::Trigger_OnCablesTargetPowerDown(OwnerWalker, FIslandWalkerCablesTargetEventData(this));
		UIslandWalkerCablesTargetEffectHandler::Trigger_OnPowerUp(this);
	}
}

class UWalkerCablesTargetPanel : UPoseableMeshComponent
{
	default CollisionProfileName = n"NoCollision";

	UPROPERTY(EditDefaultsOnly)
	TArray<UMaterialInterface> ZoeMaterials;

	UPROPERTY(EditDefaultsOnly)
	TArray<UMaterialInterface> MioMaterials;

	UPROPERTY(EditDefaultsOnly)
	TArray<UMaterialInterface> ZoeBrokenMaterials;

	UPROPERTY(EditDefaultsOnly)
	TArray<UMaterialInterface> MioBrokenMaterials;

	TArray<UMaterialInstanceDynamic> MaterialInstances;

	void SetColor(EHazePlayer Player)
	{
		TArray<UMaterialInterface> PlayerMaterials;
		if (Player == EHazePlayer::Mio)
			PlayerMaterials = MioMaterials;
		else
			PlayerMaterials = ZoeMaterials;

		for (int iMat = 0; iMat < PlayerMaterials.Num(); iMat++)
		{
			if (PlayerMaterials[iMat] == nullptr)
				continue;
			UMaterialInstanceDynamic MaterialInstance = Material::CreateDynamicMaterialInstance(this, PlayerMaterials[iMat]);
			SetMaterial(iMat, MaterialInstance);
		}
	}

	void Break(EHazePlayer Player)
	{
		TArray<UMaterialInterface> BrokenMaterials;
		if (Player == EHazePlayer::Mio)
			BrokenMaterials = MioBrokenMaterials;
		else
			BrokenMaterials = ZoeBrokenMaterials;
		for (int iMat = 0; iMat < BrokenMaterials.Num(); iMat++)
		{
			if (BrokenMaterials[iMat] == nullptr)
				continue;
			UMaterialInstanceDynamic MaterialInstance = Material::CreateDynamicMaterialInstance(this, BrokenMaterials[iMat]);
			SetMaterial(iMat, MaterialInstance);
		}
	}
}

class UWalkerCablesTargetHealthBarComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;

	private AHazePlayerCharacter Player;
	private UHealthBarWidget HealthBar;

	float Health = 1.0;

	void Initialize(AHazePlayerCharacter DestroyingPlayer)
	{
		Health = 1.0;
		Player = DestroyingPlayer;
	}
	
	void OnTakeDamage(float RemainingHealth)
	{
		Health = RemainingHealth;
		ShowHealthBar();
		UpdateHealthBar();
	}

	void OnDestroyed()
	{
		RemoveHealthBar();
	}

	void ShowHealthBar()
	{
		if (!HealthBarWidgetClass.IsValid())
			return;
		if (HealthBar != nullptr)
			return;
		HealthBar = Player.AddWidget(HealthBarWidgetClass);
		HealthBar.InitHealthBar(1.0);
		HealthBar.AttachWidgetToComponent(this, NAME_None);
	}

	void UpdateHealthBar()
	{
		if (HealthBar == nullptr)
			return;
		HealthBar.SetWidgetRelativeAttachOffset(WorldTransform.InverseTransformVector(Player.ViewRotation.UpVector * 250.0));
		HealthBar.SetHealthAsDamage(Health);
	}

	void RemoveHealthBar()
	{
		if (HealthBar == nullptr)
			return;
		Player.RemoveWidget(HealthBar);
		HealthBar = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		RemoveHealthBar();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveHealthBar();
	}
}

