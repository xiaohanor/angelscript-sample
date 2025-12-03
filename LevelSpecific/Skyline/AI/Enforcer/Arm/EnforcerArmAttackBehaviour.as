class UEnforcerArmAttackBehaviour : UBasicBehaviour
{
	UEnforcerArmComponent ArmComp;
	UEnforcerArmSettings ArmSettings;

	private float AttackTime;
	AHazeActor ProximityTarget;
	FVector AttackLocation;
	FHazeAcceleratedVector AccVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ArmComp = UEnforcerArmComponent::Get(Owner);
		ArmComp.Initialize();
		ArmSettings = UEnforcerArmSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(ArmComp.bStruggling)
			return false;
		if(ProximityTarget == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;		
		if(ActiveDuration > ArmSettings.AttackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AttackLocation = ProximityTarget.FocusLocation;
		ArmComp.StartAttack();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		

		FVector Direction = (ProximityTarget.FocusLocation - Owner.FocusLocation).GetSafeNormal2D();
		Direction.Z = 0.5;
		ProximityTarget.AddMovementImpulse(Direction * ArmSettings.AttackPushbackPower);

		UPlayerHealthComponent PlayerHealthComp = UPlayerHealthComponent::Get(ProximityTarget);
		if(PlayerHealthComp != nullptr)
			PlayerHealthComp.DamagePlayer(ArmSettings.PlayerAttackDamage, nullptr, nullptr);

		UEnforcerArmResponseComponent ResponseComp = UEnforcerArmResponseComponent::Get(ProximityTarget);
		if(ResponseComp != nullptr)
		{
			ResponseComp.OnHit.Broadcast(ArmComp);
			ArmComp.AttackedActors.Add(ProximityTarget);
		}		

		ArmComp.EndAttack();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		FVector Direction = (AttackLocation - Owner.FocusLocation).GetSafeNormal();
		ArmComp.Arm.SetActorRotation(Direction.Rotation());

		AccVector.Value = ArmComp.Arm.Claw.GetWorldLocation();
		AccVector.AccelerateTo(AttackLocation, ArmSettings.AttackDuration, DeltaTime);
		ArmComp.SetArmWorldLocation(AccVector.Value);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())
			return;

		TArray<AHazeActor> Targets;
		TargetComp.FindAllTargets(ArmSettings.TargetDetectionRange, Targets);

		if(Targets.Num() == 0)
		{
			ProximityTarget = nullptr;
			return;
		}

		for(AHazeActor Target: Targets)
		{			
			if(!ArmComp.AttackedActors.Contains(Target))
			{
				ProximityTarget = Target;
				break;
			}
			else
			{
				ProximityTarget = nullptr;
			}
		}	
	}
}