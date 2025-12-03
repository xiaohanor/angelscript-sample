event void FIslandWalkerLegEventSignature();
event void FIslandWalkerLegCoverOpenedEventSignature(AIslandWalkerLegTarget OpenedTargetCover);

class AIslandWalkerLegTarget : AHazeActor
{
	default AddActorTag(n"TreatAsAIForImpacts");

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComponent;

	UPROPERTY(DefaultComponent)
	USceneComponent CenterComponent;
	default CenterComponent.RelativeRotation = FRotator(0.0, 0.0, 0.0);
	default CenterComponent.RelativeLocation = FVector(0.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = "CenterComponent")
	UIslandWalkerForceFieldComponent ForceFieldComp;

	UPROPERTY(DefaultComponent, Attach = "CenterComponent")
	UIslandRedBlueStickyGrenadeResponseComponent GrenadeResponseComp;
	default GrenadeResponseComp.Shape.Type = EHazeShapeType::Box;
	default GrenadeResponseComp.Shape.BoxExtents = FVector(25.0, 100.0, 150.0);
	default GrenadeResponseComp.bTriggerRequiresGrenadeContact = false; // This only handles direct attachment

	UPROPERTY(DefaultComponent, Attach = "CenterComponent")
	UIslandRedBlueTargetableComponent GrenadeTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandWalkerForceFieldCapability");

	UPROPERTY(DefaultComponent)
	UIslandRedBlueReflectComponent BulletReflectorComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;

	UPROPERTY()
	FIslandWalkerLegEventSignature OnLegDestroyed;

	UPROPERTY()
	FIslandWalkerLegEventSignature OnLegRespawned;

	UPROPERTY()
	FIslandWalkerLegCoverOpenedEventSignature OnCoverOpened;

	UPROPERTY()
	TSubclassOf<AIslandOverloadShootablePanel> PanelClass;

	AIslandOverloadShootablePanel RedPanel;
	AIslandOverloadShootablePanel BluePanel;
	AIslandOverloadShootablePanel CoverPanel;

	AHazeActor OwnerWalker;
	UIslandWalkerComponent WalkerComp;
	UHazeSkeletalMeshComponentBase Mesh;
	UIslandWalkerSettings Settings;
	FName LegBone;

	EWalkerHatch HatchAnimType;
	FName BluePanelSocket = NAME_None;
	FName RedPanelSocket = NAME_None;
	bool bCoverOpen = false;
	bool bForceFieldBreached = false;
	bool bRedPanelOvercharged = false;
	bool bBluePanelOvercharged = false;
	bool bIsDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandWalkerSettings::GetSettings(OwnerWalker);
		WalkerComp = UIslandWalkerComponent::Get(OwnerWalker);
		Mesh = Cast<AHazeCharacter>(OwnerWalker).Mesh;
		ForceFieldComp.OnDepleted.AddUFunction(this, n"OnForceFieldDepleted");

		if (ForceFieldComp.Type == EIslandForceFieldType::Blue)
			GrenadeTargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Zoe);
		else 	
			GrenadeTargetableComp.SetUsableByPlayers(EHazeSelectPlayer::Mio);

		RedPanel = SpawnActor(PanelClass, bDeferredSpawn = true, Level = OwnerWalker.Level); 
		RedPanel.AttachRootComponentTo(Mesh, RedPanelSocket);
		RedPanel.UsableByPlayer = EHazePlayer::Mio;
		RedPanel.MakeNetworked(this, n"RedPanel");
		FinishSpawningActor(RedPanel);
		RedPanel.OnImpact.AddUFunction(this, n"OnPanelImpact");
		RedPanel.OnOvercharged.AddUFunction(this, n"OnRedOvercharged");
		RedPanel.OnReset.AddUFunction(this, n"OnRedRecover");
		RedPanel.TargetComp.Disable(this);
		RedPanel.AddActorCollisionBlock(this);
		RedPanel.OverchargeComp.bUseDataAssetSettings = false;
		RedPanel.OverchargeComp.Settings_Property = Settings.LegPanelOverchargeSettings;
		RedPanel.OverchargeComp.Settings_Property.OverchargeColor = EIslandRedBlueOverchargeColor::Red;

		BluePanel = SpawnActor(PanelClass, bDeferredSpawn = true, Level = OwnerWalker.Level); 
		BluePanel.AttachRootComponentTo(Mesh, BluePanelSocket);
		BluePanel.UsableByPlayer = EHazePlayer::Zoe;
		BluePanel.MakeNetworked(this, n"BluePanel");
		FinishSpawningActor(BluePanel);
		BluePanel.OnImpact.AddUFunction(this, n"OnPanelImpact");
		BluePanel.OnOvercharged.AddUFunction(this, n"OnBlueOvercharged");
		BluePanel.OnReset.AddUFunction(this, n"OnBlueRecover");
		BluePanel.TargetComp.Disable(this);
		BluePanel.AddActorCollisionBlock(this);
		BluePanel.OverchargeComp.bUseDataAssetSettings = false;
		BluePanel.OverchargeComp.Settings_Property = Settings.LegPanelOverchargeSettings;
		BluePanel.OverchargeComp.Settings_Property.OverchargeColor = EIslandRedBlueOverchargeColor::Blue;

		// Panel transform tweaking
		RedPanel.ActorRelativeScale3D = FVector(0.25, 0.50, 0.50);	
		RedPanel.ActorRelativeLocation = FVector(0.0, 0.0, 50.0);
		RedPanel.ActorRelativeRotation = FRotator(180.0, 0.0, 0.0);
		BluePanel.ActorRelativeScale3D = FVector(0.25, 0.50, 0.50);		
		BluePanel.ActorRelativeLocation = FVector(0.0, 0.0, -40.0);
		BluePanel.ActorRelativeRotation = FRotator(0.0, 180.0, 0.0);

		GrenadeResponseComp.OnAttached.AddUFunction(this, n"OnGrenadeAttached");
		GrenadeResponseComp.OnDetonated.AddUFunction(this, n"OnGrenadeDetonated");
		GrenadeResponseComp.IgnoreCollisionActors.Add(OwnerWalker);
		GrenadeResponseComp.IgnoreCollisionActors.Add(RedPanel);
		GrenadeResponseComp.IgnoreCollisionActors.Add(BluePanel);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPanelImpact()
	{
		if (!bCoverOpen)
			return;

		// Suppress force field
		ForceFieldComp.TakeDamage(Settings.ForceFieldPanelImpactSuppression, CenterComponent.WorldLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGrenadeAttached(FIslandRedBlueStickGrenadeOnAttachedData Data)
	{
		if (!bCoverOpen)
			return;
		
		if (IslandForceField::GetPlayerForceFieldType(Data.GrenadeOwner) != ForceFieldComp.Type)
		{
			UIslandWalkerLegEffectHandler::Trigger_OnGrenadeAttachedWrongColour(this);	
			return;
		}
		UIslandWalkerLegEffectHandler::Trigger_OnGrenadeAttachedCorrect(this);	
		ForceFieldComp.Impact();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnGrenadeDetonated(FIslandRedBlueStickGrenadeOnDetonatedData Data)
	{
		if (!bCoverOpen)
			return;

		if (IslandForceField::GetPlayerForceFieldType(Data.GrenadeOwner) != ForceFieldComp.Type)
		{
			UIslandWalkerLegEffectHandler::Trigger_OnGrenadeDetonatedWrongColour(this);	
			return;
		}

		if (IslandForceField::GetPlayerForceFieldType(Data.GrenadeOwner) == ForceFieldComp.Type)
		{
			if (ForceFieldComp.OverrideBreachLocation.IsZero() && !ForceFieldComp.bPoweredDown)
			{
				if (Data.ExplosionOrigin.Distance(CenterComponent.WorldLocation)
					< ForceFieldComp.WorldTransform.TransformPositionNoScale(ForceFieldComp.LocalBreachLocation).Distance(CenterComponent.WorldLocation))
				{
					ForceFieldComp.LocalBreachLocation = ForceFieldComp.WorldTransform.InverseTransformPositionNoScale(Data.ExplosionOrigin).GetClampedToSize(ForceFieldComp.BoundsRadius, ForceFieldComp.BoundsRadius);
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBlueOvercharged()
	{
		bBluePanelOvercharged = true;
		if (bRedPanelOvercharged && HasControl())
			CrumbDestroyLeg();

		UIslandWalkerLegEffectHandler::Trigger_OnBluePanelOverload(this, FIslandWalkerPanelOverloadData(BluePanel.Root));
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnRedOvercharged()
	{
		bRedPanelOvercharged = true;
		if (bBluePanelOvercharged && HasControl())
			CrumbDestroyLeg();

		UIslandWalkerLegEffectHandler::Trigger_OnRedPanelOverload(this, FIslandWalkerPanelOverloadData(RedPanel.Root));
	}

	UFUNCTION()
	private void OnBlueRecover()
	{
		bBluePanelOvercharged = false;
	}

	UFUNCTION()
	private void OnRedRecover()
	{
		bRedPanelOvercharged = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bForceFieldBreached && HasControl())
		{
			if (ForceFieldComp.Integrity > 0.85)
				CrumbForceFieldRecover();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnForceFieldDepleted(UIslandWalkerForceFieldComponent ForceFieldComponent)
	{
		if (!bCoverOpen)
			return;
		if (!ForceFieldComp.IsDepleted())
			return;

		UIslandWalkerLegEffectHandler::Trigger_OnForcefieldDepleted(this);	

		bForceFieldBreached = true;
		ForceFieldComp.ApplyCollision(n"NoCollision", this, EInstigatePriority::Normal);
		GrenadeTargetableComp.Disable(this);
		BluePanel.TargetComp.Enable(this);
		BluePanel.RemoveActorCollisionBlock(this);
		RedPanel.TargetComp.Enable(this);
		RedPanel.RemoveActorCollisionBlock(this);
		CoverPanel.TargetComp.Disable(this);
	}
	
	UFUNCTION(CrumbFunction)
	void CrumbForceFieldRecover()
	{
		bForceFieldBreached = false;
		ForceFieldComp.ClearCollision(this);
		if (bCoverOpen)
			GrenadeTargetableComp.Enable(this);
		BluePanel.TargetComp.Disable(this);
		BluePanel.AddActorCollisionBlock(this);
		RedPanel.TargetComp.Disable(this);
		RedPanel.AddActorCollisionBlock(this);
		CoverPanel.TargetComp.Enable(this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbDestroyLeg()
	{
		UIslandWalkerLegsComponent LegsComp = UIslandWalkerLegsComponent::Get(AttachParentActor);
		bIsDestroyed = true;
		LegsComp.DestroyLeg(this);
		UIslandWalkerLegEffectHandler::Trigger_OnDestroyed(this, FIslandWalkerLegDestroyedData(CenterComponent.WorldLocation));
		RemoveLeg();

		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(!Player.ActorLocation.IsWithinDist(ActorLocation, Settings.LegExplosionRadius))
				continue;
			
			FKnockdown Knockdown;
			FVector Dir = (Player.ActorLocation - ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
			float ForceFactor = 1.0 - (ActorLocation.Distance(Player.ActorLocation) / Settings.LegExplosionRadius);
			float Force = 2000 * ForceFactor;
			Knockdown.Move = Dir * Force;
			Knockdown.Duration = 1;
			Player.ApplyKnockdown(Knockdown);
			UPlayerDamageEventHandler::Trigger_TakeBigDamage(Player);
		}

		OnLegDestroyed.Broadcast();
	}

	void RemoveLeg()
	{
		bIsDestroyed = true;

		WalkerComp.DestroyedLegs.AddUnique(LegBone);
		Mesh.HideBoneByName(LegBone, EPhysBodyOp::PBO_None);
		Mesh.SetAnimTrigger(n"LegDestroyed");

		AddActorDisable(this);
		RedPanel.AddActorDisable(this);
		BluePanel.AddActorDisable(this);
		CoverPanel.AddActorDisable(this);

		// The panels are set to not be hidden when disabled :P
		RedPanel.AddActorVisualsBlock(this);
		BluePanel.AddActorVisualsBlock(this);
		CoverPanel.AddActorVisualsBlock(this);
	}

	void PowerDown()
	{
		ForceFieldComp.PowerDown();
		RedPanel.DisablePanel();
		BluePanel.DisablePanel();
		CoverPanel.DisablePanel();
		GrenadeResponseComp.bTriggerForRedPlayer = false;
		GrenadeResponseComp.bTriggerForBluePlayer = false;
		GrenadeTargetableComp.Disable(this);
		WalkerComp.CurrentOpenHatch = EWalkerHatch::None;
	}

	void PowerUp()
	{
		ForceFieldComp.PowerUp();
		RedPanel.EnablePanel();
		BluePanel.EnablePanel();
		CoverPanel.EnablePanel();
		GrenadeResponseComp.bTriggerForRedPlayer = true;
		GrenadeResponseComp.bTriggerForBluePlayer = true;
		if (bCoverOpen)
			GrenadeTargetableComp.Enable(this);
	}

	void OpenCover()
	{
		if (bIsDestroyed)
			return;
		if (bCoverOpen)
			return;
		
		bCoverOpen = true;
		WalkerComp.CurrentOpenHatch = HatchAnimType;

		if (bForceFieldBreached)
		{
			BluePanel.TargetComp.Enable(this);
			BluePanel.RemoveActorCollisionBlock(this);
			RedPanel.TargetComp.Enable(this);
			RedPanel.RemoveActorCollisionBlock(this);
		}
		else
		{
			// Forcefield is up
			GrenadeTargetableComp.Enable(this);
		}
		// Note that we do not disable cover panel targetable until forcefield goes down

		// All other leg covers will be closed 
		OnCoverOpened.Broadcast(this);

		UIslandWalkerLegEffectHandler::Trigger_OpenLegCover(this);
	}

	void CloseCover()
	{
		if (bIsDestroyed)
			return;
		if (!bCoverOpen)
			return;
		bCoverOpen = false;		
		if (WalkerComp.CurrentOpenHatch == HatchAnimType)
			WalkerComp.CurrentOpenHatch = EWalkerHatch::None;
		GrenadeTargetableComp.Disable(this);
		BluePanel.TargetComp.Disable(this);
		BluePanel.AddActorCollisionBlock(this);
		RedPanel.TargetComp.Disable(this);
		RedPanel.AddActorCollisionBlock(this);
		CoverPanel.TargetComp.Enable(this);
		CoverPanel.OverchargeComp.ResetChargeAlpha();
		UIslandWalkerLegEffectHandler::Trigger_CloseLegCover(this);
	}
}