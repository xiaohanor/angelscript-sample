event void FWalkerHeadStumpTakeDamageSignature(AHazePlayerCharacter Shooter, float RemainingHealth);
event void FWalkerHeadStumpForceFieldDepletedSignature(AHazePlayerCharacter Grenadier);

class AIslandWalkerHeadStumpTarget : AHazeActor
{
	default AddActorTag(n"TreatAsAIForImpacts");

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent ForceFieldRoot;
	default ForceFieldRoot.RelativeLocation = FVector(0.0, 0.0, 0.0);
	default ForceFieldRoot.RelativeRotation = FRotator(90.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UWalkerHeadStumpTargetHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UIslandWalkerHeadForceFieldComponent ForceFieldComp;
	default ForceFieldComp.Type = EIslandForceFieldType::Red;

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	default GrenadeResponseComp.Shape.Type = EHazeShapeType::Sphere;
	default GrenadeResponseComp.Shape.SphereRadius = 200.0;

	UPROPERTY(DefaultComponent, Attach = "ForceFieldRoot")
	UIslandRedBlueTargetableComponent TargetableComp;
	default TargetableComp.TargetShape.Type = EHazeShapeType::Sphere;
	default TargetableComp.TargetShape.SphereRadius = 180.0;
	default TargetableComp.bTargetWithGrenade = true;
	default TargetableComp.MaximumDistance = 12000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerHeadForceFieldCapability");

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY()
	UMaterialInterface AllowDamageMaterial_Red = nullptr;
	UPROPERTY()
	UMaterialInterface AllowDamageMaterial_Blue = nullptr;

	FWalkerHeadStumpForceFieldDepletedSignature OnForceFieldBreached;
	FWalkerHeadStumpTakeDamageSignature OnTakeDamage;

	AHazeCharacter OwnerHead;
	UIslandRedBlueReflectComponent BulletReflectComp;
	UIslandWalkerSettings Settings;
	AHazePlayerCharacter ShieldBreaker;
	UIslandWalkerThrusterAssembly ThrusterAssembly;

	float Health = 1.0;
	float NextThrusterHealthThreshold = 0.0;
	float ThrusterDestroyInterval = 1.0;

	bool bIsPoweredUp = true;
	bool bForceFieldBreached = false;
	bool bStumpDestroyed = false;
	bool bIgnoreDamage = false;
	float InitialAllowDamageTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandWalkerSettings::GetSettings(OwnerHead);

		BulletReflectComp = UIslandRedBlueReflectComponent::Get(OwnerHead);

		ForceFieldComp.OnDepleted.AddUFunction(this, n"OnForceFieldDepleted");
		if (ForceFieldComp.Type == IslandForceField::GetPlayerForceFieldType(Game::Zoe))
		{
			TargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Zoe);
			ShieldBreaker = Game::Zoe;
		}
		else
		{
			TargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Mio);
			ShieldBreaker = Game::Mio;
		} 	

		// This allows grenade detonation from anywhere on head
		GrenadeResponseComp.IgnoreCollisionActors.Add(OwnerHead);
		
		// Start without health bar, this will be shown when first powering up
		HealthBarComp.Initialize(OwnerHead);
		HealthBarComp.RemoveHealthBar();
		IgnoreDamage();

		// Detect impacts on thrusters or main body
		ThrusterAssembly = UIslandWalkerThrusterAssembly::Get(OwnerHead);
		ThrusterAssembly.OnBulletImpact.AddUFunction(this, n"OnBulletImpact");
		auto BodyImpactResponse = UIslandRedBlueImpactResponseComponent::Get(OwnerHead);		
		BodyImpactResponse.OnImpactEvent.AddUFunction(this, n"OnBulletImpact");

		// Separate settings for head force field 
		UIslandWalkerSettings::SetForceFieldReplenishCooldown(OwnerHead, Settings.HeadForceFieldReplenishCooldown, this, EHazeSettingsPriority::Gameplay);
		UIslandWalkerSettings::SetHeadForceFieldReplenishAmountPerSecond(OwnerHead, Settings.HeadForceFieldReplenishAmountPerSecond, this, EHazeSettingsPriority::Gameplay);

		DevTogglesWalker::FragileHead.MakeVisible();
	}

	UFUNCTION()
	private void OnBulletImpact(FIslandRedBlueImpactResponseParams Data)
	{
		if (!bForceFieldBreached)
			return;

		if (bIgnoreDamage)
			return;		

		float Damage = Settings.HeadDamagePerImpact;
		if (Time::GetGameTimeSince(InitialAllowDamageTime) < Settings.HeadDamageInitialDuration) 
			Damage = Settings.HeadDamagePerImpactInitial; // TODO: Move this to intro, should only affect detached phase for duration after intro
		Damage *= Data.ImpactDamageMultiplier;

		if (DevTogglesWalker::FragileHead.IsEnabled())
			Damage *= 10.0;		

		Health = Math::Max(0.0, Health - Damage);
		HealthBarComp.ModifyHealth(Health);

		// Optionally suppress force field
		if (Settings.HeadForceFieldIsSupressedByShooting)
			ForceFieldComp.TakeDamage(Settings.ForceFieldPanelImpactSuppression, ForceFieldComp.WorldLocation);

		if (Health < NextThrusterHealthThreshold)
		{
			NextThrusterHealthThreshold -= ThrusterDestroyInterval;
			ThrusterAssembly.ExtinguishThrusterAt(Data.ImpactLocation);	
		}

		DamageFlash::DamageFlashActor(OwnerHead, 0.1, FLinearColor::White * 0.05);		

		OnTakeDamage.Broadcast(Data.Player, Health);			
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bForceFieldBreached && HasControl() && (ForceFieldComp.Integrity > 0.85))
			CrumbForceFieldRecover();

		HealthBarComp.UpdateHealthBar();
	}

	UFUNCTION()
	private void OnForceFieldDepleted()
	{
		if(!ForceFieldComp.IsDepleted())
			return;

		bForceFieldBreached = true;
		ForceFieldComp.ApplyCollision(n"NoCollision", this, EInstigatePriority::Normal);

		BulletReflectComp.AddReflectBlockerForBothPlayers(this);

		// We only use targetable comp for grenades against shield
		TargetableComp.Disable(this);

		ThrusterAssembly.SetVulnerable();
		OnForceFieldBreached.Broadcast(ShieldBreaker);

		UIslandWalkerHeadEffectHandler::Trigger_OnForceFieldDepleted(OwnerHead);	
	}

	UFUNCTION(CrumbFunction)
	void CrumbForceFieldRecover()
	{
		bForceFieldBreached = false;
		ForceFieldComp.ClearCollision(this);
		BulletReflectComp.RemoveReflectBlockerForBothPlayers(this);
		TargetableComp.Enable(this);
		ThrusterAssembly.SetInvulnerable();
		UIslandWalkerHeadEffectHandler::Trigger_OnForceFieldRecover(OwnerHead);	
	}

	void SwapShieldBreaker()
	{
		if (HasControl())
			CrumbSwapShieldBreaker();
	}

	UFUNCTION(CrumbFunction)
	void CrumbSwapShieldBreaker()
	{
		ShieldBreaker = ShieldBreaker.OtherPlayer;

		ForceFieldComp.Type = IslandForceField::GetPlayerForceFieldType(ShieldBreaker);
		ForceFieldComp.SetForceFieldColours();
		ForceFieldComp.Replenish(1.0);

		if (!bForceFieldBreached)
			TargetableComp.SetUsableByPlayers(ShieldBreaker.IsZoe() ? EHazeSelectPlayer::Zoe : EHazeSelectPlayer::Mio);

		UIslandWalkerHeadEffectHandler::Trigger_OnForceFieldSwapColor(OwnerHead);		
	}

	void Destroy()
	{
		if (bStumpDestroyed)
			return;

		bStumpDestroyed = true;	
		AddActorDisable(this);
		TargetableComp.Disable(this);

		
		//HealthBarComp.OnDestroyed();
	}

	UFUNCTION()
	private void OnWalkerReset()
	{
		RemoveActorDisable(this);
		PowerUp();
		InitialAllowDamageTime = 0.0;
		bStumpDestroyed = false;
	}

	void PowerUp()
	{
		if (bIsPoweredUp)
			return;
		bIsPoweredUp = true;
		Health = 1.0;
		HealthBarComp.ShowHealthBar();
		ForceFieldComp.PowerUp();
		GrenadeResponseComp.bTriggerForRedPlayer = true;
		GrenadeResponseComp.bTriggerForBluePlayer = true;
		TargetableComp.Enable(this);
		ReigniteThrusters();
		UIslandWalkerHeadEffectHandler::Trigger_OnForceFieldPowerUp(OwnerHead);
	}

	void PowerDown()
	{
		if (!bIsPoweredUp)
			return;
		bIsPoweredUp = false;
		ForceFieldComp.PowerDown();
		GrenadeResponseComp.bTriggerForRedPlayer = false;
		GrenadeResponseComp.bTriggerForBluePlayer = false;
		TargetableComp.Disable(this);
		UIslandWalkerHeadEffectHandler::Trigger_OnForceFieldPowerDown(OwnerHead);
	}

	void IgnoreDamage()
	{
		if (bIgnoreDamage)
			return;

		bIgnoreDamage = true;
		GrenadeResponseComp.bTriggerForRedPlayer = false;
		GrenadeResponseComp.bTriggerForBluePlayer = false;
		TargetableComp.Disable(n"IgnoreDamage");
		ShowIgnoreDamage();
	}

	void ShowIgnoreDamage()
	{
		// When ignoring damage we use base material (from slot 0 of head mesh) on all slots
		UMaterialInterface IgnoreDamageMaterial = OwnerHead.Mesh.GetMaterial(0);
		if (IgnoreDamageMaterial != nullptr)
		{
			OwnerHead.Mesh.SetMaterial(1, IgnoreDamageMaterial);
			OwnerHead.Mesh.SetMaterial(2, IgnoreDamageMaterial);
		}
	}

	void AllowDamage()
	{
		if (!bIgnoreDamage)
			return;

		bIgnoreDamage = false;
		if (InitialAllowDamageTime == 0.0)
			InitialAllowDamageTime = Time::GameTimeSeconds;
		GrenadeResponseComp.bTriggerForRedPlayer = true;
		GrenadeResponseComp.bTriggerForBluePlayer = true;
		TargetableComp.Enable(n"IgnoreDamage");
		ShowAllowDamage();
	}

	void ShowAllowDamage()
	{
		if (AllowDamageMaterial_Red != nullptr)
			OwnerHead.Mesh.SetMaterial(1, AllowDamageMaterial_Red);
		if (AllowDamageMaterial_Blue != nullptr)
			OwnerHead.Mesh.SetMaterial(2, AllowDamageMaterial_Blue);
	}

	void ReigniteThrusters()
	{
		ThrusterAssembly.IgniteThrusters();

		// We can now extinguish some thrusters again. First one will go out at first damage, last thruster
		// one interval before we crash so players get some nice intermediate feedback that we're taking damage
		// Note that we should be at full health or expect to recover some health soon.
		NextThrusterHealthThreshold = Math::Min(1.0, Health + Settings.HeadCrashRecoverHealth);
		if (Settings.HeadCrashNumThrustersToExtinguish > 0)
			ThrusterDestroyInterval = Settings.HeadCrashRecoverHealth / float(Settings.HeadCrashNumThrustersToExtinguish);
	}
}

class UWalkerHeadStumpTargetHealthBarComponent : USceneComponent
{
 	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
 	private TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;

 	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private FText BossHealthBarDesc;

	UIslandWalkerSettings Settings;

 	private UBossHealthBarWidget BossHealthBar;
	private TPerPlayer<UHealthBarWidget> HealthBars;

	const float FinalSmashFullHealth = 0.1;

 	float Health = 1.0;
	float FinalSmashHealth = FinalSmashFullHealth;
	bool bIsDestroyed = false;

 	void Initialize(AHazeActor WalkerHead)
 	{
		Health = 1.0;
		Settings = UIslandWalkerSettings::GetSettings(WalkerHead);
		FinalSmashHealth = FinalSmashFullHealth;
	}
	
	void ModifyHealth(float RemainingHealth)
	{
		Health = Math::Max(0.0, RemainingHealth);
		if ((Health == 0.0) && (FinalSmashHealth == 0.0))
		{
			RemoveHealthBar();
			return;
		}
		ShowHealthBar();
		UpdateHealthBar();
	}

	void OnDestroyed()
	{
		bIsDestroyed = true;
		// We do not remove health bar when disabled anymore, since it's used for smashing the fake head flat as well
	}

	void ShowHealthBar()
	{
		if (bIsDestroyed)
			return;
		if (!Settings.bHeadStumpUseHealthBar)
			return;
		if (!HealthBarWidgetClass.IsValid())
			return;
		if (HealthBarWidgetClass.Get().IsChildOf(UBossHealthBarWidget))
		{
			if (BossHealthBar != nullptr)
				return;
			BossHealthBar = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(HealthBarWidgetClass));
			BossHealthBar.InitBossHealthBar(BossHealthBarDesc, 1.0 + FinalSmashFullHealth, 4);
		}
		else // Regular health bar
		{
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (HealthBars[Player] != nullptr)
					continue;
				HealthBars[Player] = Player.AddWidget(HealthBarWidgetClass);
				HealthBars[Player].InitHealthBar(1.0 + FinalSmashFullHealth);
				HealthBars[Player].AttachWidgetToComponent(this, NAME_None);
				HealthBars[Player].SetWidgetRelativeAttachOffset(Settings.HeadStumpHealthBarOffset);
				HealthBars[Player].SetRenderScale(Settings.HeadStumpHealthBarScale);
			}
		}
	}

	void UpdateHealthBar()
	{
		if (!Settings.bHeadStumpUseHealthBar)
			RemoveHealthBar();

		if (BossHealthBar != nullptr)
			BossHealthBar.SetHealthAsDamage(Health + FinalSmashHealth);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (HealthBars[Player] != nullptr)
				HealthBars[Player].SetHealthAsDamage(Health + FinalSmashHealth);
		}
	}

	void RemoveHealthBar()
	{
		if (BossHealthBar != nullptr)
		{
			Widget::RemoveFullscreenWidget(BossHealthBar);
			BossHealthBar = nullptr;
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (HealthBars[Player] != nullptr)
			{
				Player.RemoveWidget(HealthBars[Player]);
				HealthBars[Player] = nullptr;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		// We do not remove health bar when disabled anymore, since it's used for smashing the fake head flat as well
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveHealthBar();
	}

	void ModifySmashHealth(float RemainingFraction)
	{
		Health = 0.0;
		FinalSmashHealth = Math::Max(0.0, FinalSmashFullHealth * RemainingFraction);
		if (FinalSmashHealth < SMALL_NUMBER)
		{
			RemoveHealthBar();
			return;
		}
		ShowHealthBar();
		UpdateHealthBar();
	}
}

class UWalkerHeadDummyShootablePanelComponent : UStaticMeshComponent
{
	default GenerateOverlapEvents = false;
	default CollisionProfileName = n"NoCollision";

	bool bAllowShooting = true;

	void AllowShooting()
	{
		if (bAllowShooting)
			return;
		bAllowShooting = true;
		RemoveComponentVisualsBlocker(this);
	}

	void DisallowShooting()
	{
		if (!bAllowShooting)
			return;
		bAllowShooting = false;
		AddComponentVisualsBlocker(this);
	}
}
