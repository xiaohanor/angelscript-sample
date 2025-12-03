event void IslandWalkerNeckTargetOnBreakSignature(AIslandWalkerNeckTarget Target);
event void IslandWalkerNeckTargetOnRecoverSignature(AIslandWalkerNeckTarget Target);

class AIslandWalkerNeckTarget : AHazeActor
{
	default AddActorTag(n"TreatAsAIForImpacts");

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ForceFieldRoot;

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UIslandWalkerForceFieldComponent ForceFieldComp;
	default ForceFieldComp.WorldScale3D = FVector(2.0, 1.4, 0.2);
	default ForceFieldComp.Type = EIslandForceFieldType::Red;

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	default GrenadeResponseComp.Shape.Type = EHazeShapeType::Box;
	default GrenadeResponseComp.Shape.BoxExtents = FVector(90.0, 60.0, 20.0);
	default GrenadeResponseComp.bTriggerRequiresGrenadeContact = false; // This only handles direct attachment

	UPROPERTY(DefaultComponent, Attach = "GrenadeResponseComp")
	UIslandRedBlueTargetableComponent GrenadeTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerForceFieldCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY()
	TSubclassOf<AIslandOverloadShootablePanel> PanelClass;

	AIslandOverloadShootablePanel ShootablePanel;

	IslandWalkerNeckTargetOnBreakSignature OnBreak;
	IslandWalkerNeckTargetOnRecoverSignature OnRecover;

	AHazeCharacter OwnerWalker;
	UIslandWalkerSettings Settings;

	bool bIsPoweredUp = true;
	bool bForceFieldBreached = false;
	bool bNeckBroken = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandWalkerSettings::GetSettings(OwnerWalker);
		ForceFieldComp.OnDepleted.AddUFunction(this, n"OnForceFieldDepleted");
		if (ForceFieldComp.Type == EIslandForceFieldType::Blue)
			GrenadeTargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Zoe);
		else 	
			GrenadeTargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Mio);

		ShootablePanel = SpawnActor(PanelClass, bDeferredSpawn = true, Level = OwnerWalker.Level); 
		ShootablePanel.AttachRootComponentTo(RootComp);
		ShootablePanel.MakeNetworked(this, n"ShootablePanel");
		ShootablePanel.OverchargeComp.bUseDataAssetSettings = false;
		ShootablePanel.OverchargeComp.Settings_Property = Settings.HeadPanelOverchargeSettings;
		if (ForceFieldComp.Type == EIslandForceFieldType::Blue)
		{
			// Blue forcefield, red panel
			ShootablePanel.OverchargeComp.Settings_Property.OverchargeColor = EIslandRedBlueOverchargeColor::Red;
			ShootablePanel.UsableByPlayer = EHazePlayer::Mio;
		}
		else
		{
			// Red forcefield, blue panel
			ShootablePanel.OverchargeComp.Settings_Property.OverchargeColor = EIslandRedBlueOverchargeColor::Blue;
			ShootablePanel.UsableByPlayer = EHazePlayer::Zoe;
		}
		FinishSpawningActor(ShootablePanel);
		ShootablePanel.OnImpact.AddUFunction(this, n"OnPanelImpact");
		ShootablePanel.OnOvercharged.AddUFunction(this, n"OnPanelOvercharged");
		ShootablePanel.TargetComp.Disable(this);

		// We need to adjust transform after finish spawning for some reason
		ShootablePanel.ActorScale3D = FVector(0.62);	
		ShootablePanel.ActorRelativeLocation = FVector(52.0, 0.0, -4.0);
		ShootablePanel.ActorRelativeRotation = FRotator(90.0, 0.0, 0.0);

		GrenadeResponseComp.OnAttached.AddUFunction(this, n"OnGrenadeAttached");
		GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnGrenadeDetonated");
		GrenadeResponseComp.IgnoreCollisionActors.Add(OwnerWalker);
		GrenadeResponseComp.IgnoreCollisionActors.Add(ShootablePanel);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPanelImpact()
	{
		// Suppress force field
		ForceFieldComp.TakeDamage(Settings.ForceFieldPanelImpactSuppression, ForceFieldComp.WorldLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGrenadeAttached(FIslandRedBlueStickGrenadeOnAttachedData Data)
	{
		if (IslandForceField::GetPlayerForceFieldType(Data.GrenadeOwner) != ForceFieldComp.Type)
		{
			UIslandWalkerNeckEffectHandler::Trigger_OnGrenadeAttachedWrongColour(this);	
			return;
		}
		UIslandWalkerNeckEffectHandler::Trigger_OnGrenadeAttachedCorrect(this);	
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGrenadeDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		if (IslandForceField::GetPlayerForceFieldType(Data.GrenadeOwner) != ForceFieldComp.Type)
		{
			UIslandWalkerNeckEffectHandler::Trigger_OnGrenadeDetonatedWrongColour(this);	
			return;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bForceFieldBreached && HasControl())
		{
			if (ForceFieldComp.Integrity > 0.85)
				CrumbForceFieldRecover();
		}
	}

	UFUNCTION()
	private void OnForceFieldDepleted(UIslandWalkerForceFieldComponent ForceFiedlComponent)
	{
		if(!ForceFieldComp.IsDepleted())
			return;

		UIslandWalkerNeckEffectHandler::Trigger_OnForcefieldDepleted(this);	

		bForceFieldBreached = true;
		ForceFieldComp.ApplyCollision(n"NoCollision", this, EInstigatePriority::Normal);
		GrenadeTargetableComp.Disable(this);
		ShootablePanel.TargetComp.Enable(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbForceFieldRecover()
	{
		bForceFieldBreached = false;
		ForceFieldComp.ClearCollision(this);
		GrenadeTargetableComp.Enable(this);
		ShootablePanel.TargetComp.Disable(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPanelOvercharged()
	{
		if (bNeckBroken)
			return;

		bNeckBroken = true;	
		UIslandWalkerNeckEffectHandler::Trigger_OnDestroyed(this, FIslandWalkerNeckDestroyedData(RootComp.WorldLocation));
		AddActorDisable(this);
		ShootablePanel.AddActorDisable(this);
		OnBreak.Broadcast(this);
	}

	UFUNCTION()
	private void OnWalkerReset()
	{
		RemoveActorDisable(this);
		ShootablePanel.RemoveActorDisable(this);
		PowerUp();
	}

	void PowerUp()
	{
		bIsPoweredUp = true;
		ForceFieldComp.PowerUp();
		ShootablePanel.RemoveActorDisable(this);
		ShootablePanel.RemoveActorVisualsBlock(this);
		GrenadeResponseComp.bTriggerForRedPlayer = true;
		GrenadeResponseComp.bTriggerForBluePlayer = true;
		GrenadeTargetableComp.Enable(this);
		UIslandWalkerEffectHandler::Trigger_OnNeckTargetPowerUp(OwnerWalker, FIslandWalkerNeckTargetEventData(this));
		UIslandWalkerNeckEffectHandler::Trigger_OnPowerUp(this);
	}

	void PowerDown()
	{
		bIsPoweredUp = false;
		ForceFieldComp.PowerDown();
		ShootablePanel.AddActorDisable(this);
		ShootablePanel.AddActorVisualsBlock(this);
		GrenadeResponseComp.bTriggerForRedPlayer = false;
		GrenadeResponseComp.bTriggerForBluePlayer = false;
		GrenadeTargetableComp.Disable(this);
		UIslandWalkerEffectHandler::Trigger_OnNeckTargetPowerDown(OwnerWalker, FIslandWalkerNeckTargetEventData(this));
		UIslandWalkerNeckEffectHandler::Trigger_OnPowerDown(this);
	}
}