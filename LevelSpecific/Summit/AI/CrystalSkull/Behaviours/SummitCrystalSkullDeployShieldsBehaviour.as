class USummitCrystalSkullDeployShieldsBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitCrystalSkullSettings SkullSettings;

	UBasicAIHealthComponent HealthComp;
	USummitCrystalSkullComponent FlyerComp;
	UHazeCapsuleCollisionComponent Capsule;
	USummitCrystalSkullArmourComponent ArmourComp;
	TArray<USummitCrystalSkullShieldComponent> Shields;

	float DeployShieldTime;
	int NumDeployedShields;
	bool bSmashed = false;
	float SmashedTime = -BIG_NUMBER;
	USceneComponent ShieldsRoot;

	UAdultDragonTailSmashModeResponseComponent TailResponseComponent;
	UAdultDragonTailSmashModeResponseComponent ArmourTailResponseComponent;

	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SkullSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner); 
		FlyerComp = USummitCrystalSkullComponent::GetOrCreate(Owner);
		Capsule = Cast<AHazeCharacter>(Owner).CapsuleComponent;
		ArmourComp = USummitCrystalSkullArmourComponent::Get(Owner);
		Shields.Add(USummitCrystalSkullShieldComponent::Get(Owner));
		ShieldsRoot = Shields[0].AttachParent;
		Shields[0].WorldLocation = ShieldsRoot.WorldLocation + Math::GetRandomPointOnSphere() * SkullSettings.DeployShieldsDistance;

		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnSmashed(FTailSmashModeHitParams Params)
	{
		if (Params.PlayerInstigator == nullptr)
			return;
		if (!Params.PlayerInstigator.HasControl())
			return;
		if (NumDeployedShields == 0)
			return;
		// Currently this is only triggered on player instogator control side, so let's crumb it.
		CrumbSmashed();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSmashed()
	{
		if (NumDeployedShields == 0)
			return;
		NumDeployedShields = 0;
		bSmashed = true;
		Cooldown.Set(SkullSettings.DeployShieldsSmashCooldown);
		ArmourComp.Armour.bIgnoreAcid = false;
		for (USummitCrystalSkullShieldComponent Shield : Shields)
		{
			USummitCrystalSkullArmourEventHandler::Trigger_OnSmashShield(ArmourComp.Armour, FSummitCrystalSkullSmashShieldParams(Shield));
			Shield.Destroy();
		}
	}

	UFUNCTION()
	private void OnRespawn()
	{
		NumDeployedShields = 0;
		bSmashed = false;
		if ((ArmourComp != nullptr) && (ArmourComp.Armour != nullptr))
		{
			ArmourComp.Armour.bIgnoreAcid = false;
			ArmourComp.Armour.DestroyedCount = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;

		if (!TargetComp.HasValidTarget())
			return false;

		if (NumDeployedShields > 0)
			return false;

		if ((ArmourComp == nullptr) || !ArmourComp.HasArmour())
			return false;

		// Never deploy shields once armour has been destroyed and regrown
		if (ArmourComp.Armour.DestroyedCount > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;

		if (!TargetComp.HasValidTarget())
			return true;

		if (ArmourComp.Armour == nullptr)
			return false;

		if (NumDeployedShields >= SkullSettings.DeployShieldsNumber)
			return true;
		
		if (bSmashed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		ArmourComp.Armour.bIgnoreAcid = true;

		bSmashed = false;
		NumDeployedShields = 0;
		DeployShieldTime = Time::GameTimeSeconds;

		if (TailResponseComponent == nullptr)
		{
			TailResponseComponent = UAdultDragonTailSmashModeResponseComponent::GetOrCreate(Owner);
			TailResponseComponent.OnHitBySmashMode.AddUFunction(this, n"OnSmashed");
		}
		if (ArmourTailResponseComponent == nullptr)
		{
			ArmourTailResponseComponent = UAdultDragonTailSmashModeResponseComponent::GetOrCreate(ArmourComp.Armour);
			ArmourTailResponseComponent.OnHitBySmashMode.AddUFunction(this, n"OnSmashed");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(SkullSettings.DeployShieldsSmashCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((NumDeployedShields < SkullSettings.DeployShieldsNumber) && (Time::GameTimeSeconds > DeployShieldTime))
		{
			if (!Shields.IsValidIndex(NumDeployedShields))
			{
				// Create a new shield, spread evenly over a sphere around the skull
				auto Shield = USummitCrystalSkullShieldComponent::Create(Owner);
				Shield.MakeNetworked(Owner, Shields.Num() + 1);
				Shield.SetupFromTemplate(Shields[0]);
				Shield.AttachTo(ShieldsRoot);
				Shield.WorldLocation = ShieldsRoot.WorldLocation + Math::GetRandomPointOnSphere() * SkullSettings.DeployShieldsDistance;
				Shields.Add(Shield);
			}
			Shields[NumDeployedShields].Deploy();

			DeployShieldTime += (SkullSettings.DeployShieldsDuration / float(SkullSettings.DeployShieldsNumber));
			NumDeployedShields++;
		}

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Purple, 10);
		}
#endif
	}
}

