
class UIslandOverseerDeployRollerBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	AHazeCharacter Character;
	UIslandOverseerPhaseComponent PhaseComp;
	UIslandOverseerDeployRollerManagerComponent RollerManagerComp;
	UAnimInstanceIslandOverseer AnimInstance;

	bool bDetached;
	float DetachDuration = 3;
	bool bAnimated;
	bool bReset;
	FBasicAIAnimationActionDurations Durations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Character = Cast<AHazeCharacter>(Owner);
		RollerManagerComp = UIslandOverseerDeployRollerManagerComponent::Get(Owner);
		RollerManagerComp.SetupRollers();
		PhaseComp = UIslandOverseerPhaseComponent::GetOrCreate(Owner);	
		RollerManagerComp.OnDeploy.AddUFunction(this, n"Deploy");
		AnimInstance = Cast<UAnimInstanceIslandOverseer>(Character.Mesh.AnimInstance);
	}

	UFUNCTION()
	private void Deploy()
	{
		bDetached = true;
		RollerManagerComp.CurrentRoller.Detach();
		RollerManagerComp.CurrentRoller.RollerComp.Detach(PhaseComp.Phase);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(Owner.IsCapabilityTagBlocked(n"Roller"))
			return true;
		if(!bDetached)
			return false;
		if(RollerManagerComp.CurrentRoller.RollerComp.bDestroyed)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		RollerManagerComp.ShieldActivations++;
		bDetached = false;
		bAnimated = false;
		bReset = false;

		if(RollerManagerComp.bRight)
		{
			RollerManagerComp.CurrentRoller = RollerManagerComp.RightRoller;
			AnimInstance.FinalizeDurations(FeatureTagIslandOverseer::DeployRoller, SubTagIslandOverseerDeployRoller::DeployRight, Durations);
			AnimComp.RequestAction(FeatureTagIslandOverseer::DeployRoller, SubTagIslandOverseerDeployRoller::DeployRight, EBasicBehaviourPriority::Medium, this, Durations);
		}
		else
		{
			RollerManagerComp.CurrentRoller = RollerManagerComp.LeftRoller;
			AnimInstance.FinalizeDurations(FeatureTagIslandOverseer::DeployRoller, SubTagIslandOverseerDeployRoller::DeployLeft, Durations);
			AnimComp.RequestAction(FeatureTagIslandOverseer::DeployRoller, SubTagIslandOverseerDeployRoller::DeployLeft, EBasicBehaviourPriority::Medium, this, Durations);
		}
		
		RollerManagerComp.bRight = !RollerManagerComp.bRight;

		UIslandOverseerRollerSweepComponent SweepComp = UIslandOverseerRollerSweepComponent::GetOrCreate(RollerManagerComp.CurrentRoller.Roller);
		SweepComp.SetSpline();
		FIslandOverseerRollerEventHandlerOnSweepTelegraphStartData Data;
		Data.TelegraphLocation = SweepComp.StartLocation;
		UIslandOverseerRollerEventHandler::Trigger_OnSweepTelegraphStart(RollerManagerComp.CurrentRoller.Roller, Data);

		if(RollerManagerComp.ShieldActivations <= 1)
		{
			SweepComp.ShieldActivationsLimit = 1;
		}
		else
		{
			SweepComp.ShieldActivationsLimit = 0;
		}
		RollerManagerComp.CurrentRoller.Roller.SetColor(EIslandForceFieldType::Both);

		for(AHazePlayerCharacter Player : Game::Players)
			UPlayerHealthSettings::SetInvulnerabilityDurationAfterRespawning(Player, 1, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		RollerManagerComp.CurrentRoller.Roller.HealthComp.TakeDamage(1.0, EDamageType::Default, Owner);
		RollerManagerComp.CurrentRoller.RollerComp.DestroyRoller();
		RollerManagerComp.CurrentRoller.Attach();
		UIslandOverseerRollerEventHandler::Trigger_OnSweepTelegraphEnd(RollerManagerComp.CurrentRoller.Roller);
		RollerManagerComp.CurrentRoller = nullptr;
		Cooldown.Set(1);

		for(AHazePlayerCharacter Player : Game::Players)
			Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bReset && ActiveDuration > 0.2)
		{
			bReset = true;
			RollerManagerComp.CurrentRoller.RollerComp.ResetRoller();
		}

		if(!bAnimated && ActiveDuration > Durations.GetTotal())
		{
			bAnimated = true;
			AnimComp.Reset();
		}
	}
}