
class UIslandOverseerRollerSweepDropBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSettings Settings;
	UIslandOverseerRollerComponent RollerComp;
	UBasicAIRuntimeSplineComponent SplineComp;
	UIslandOverseerRollerSweepComponent SweepComp;
	UIslandOverseerForceFieldComponent ForceFieldComp;
	UIslandRedBlueStickyGrenadeTargetable Targetable;

	AIslandOverseerRoller Roller;
	FVector StartLocation;
	FVector TargetLocation;
	float Telegraph = 0.5;
	float DamageTelegraph = 0.0;
	float ShieldTelegraph = 0.5;
	float DropDuration = 0.75;
	bool bStarted;
	bool bShieldInitialized;
	bool bLanded;
	int Activations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Roller = Cast<AIslandOverseerRoller>(Owner);
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		RollerComp = UIslandOverseerRollerComponent::GetOrCreate(Owner);
		SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);
		SweepComp = UIslandOverseerRollerSweepComponent::GetOrCreate(Owner);
		ForceFieldComp = UIslandOverseerForceFieldComponent::Get(Owner);;
		Targetable = UIslandRedBlueStickyGrenadeTargetable::GetOrCreate(Owner);
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
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		StartLocation = Owner.ActorLocation;
		TargetLocation = SweepComp.StartLocation;
		Roller.DropTimeLike.Duration = DropDuration;
		bStarted = false;
		bShieldInitialized = false;
		Roller.DropTimeLike.BindFinished(this, n"Finished");
		Roller.RollerMesh.bPauseAnims = false;
		RollerComp.ResetDamage();
	}

	UFUNCTION()
	private void Finished()
	{
		DeactivateBehaviour();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.SetActorLocation(TargetLocation);
		Activations++;
		Roller.DropTimeLike.Stop();
		UIslandOverseerRollerEventHandler::Trigger_OnSweepDropLand(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < Telegraph)
			return;

		if(ActiveDuration < Telegraph + DamageTelegraph)
		{
			Roller.ShowDamageMesh();
			return;
		}

		if(Activations >= SweepComp.ShieldActivationsLimit && ActiveDuration < Telegraph + DamageTelegraph + ShieldTelegraph)
		{
			if(!bShieldInitialized)
			{
				Roller.InitializeForceField();
				Targetable.Enable(Owner);
				bShieldInitialized = true;
			}
			return;
		}

		if(!bStarted)
		{
			bStarted = true;
			Roller.DropTimeLike.PlayFromStart();
			UIslandOverseerRollerEventHandler::Trigger_OnSweepDrop(Owner);
		}
		
		float Alpha = Roller.DropTimeLike.GetValue();
		Owner.ActorLocation = Math::Lerp(TargetLocation, StartLocation, Alpha);

		if(Math::IsNearlyZero(Alpha, 0.2))
		{
			if(!bLanded)
			{
				bLanded = true;
				UIslandOverseerRollerEventHandler::Trigger_OnSweepDropLand(Owner);
			}
		}
		else
		{
			bLanded = false;
		}

		RollerComp.DealDamage();
	}
}