
class UIslandOverseerEyeExitBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	AAIIslandOverseerEye Eye;
	UIslandOverseerEyeSettings Settings;
	bool bArrived;
	UIslandForceFieldBubbleComponent ForceFieldBubbleComp;
	UBasicAIHealthComponent HealthComp;
	float InactiveDamage;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Eye = Cast<AAIIslandOverseerEye>(Owner);
		Eye.OnActivated.AddUFunction(this, n"Activated");
		Settings = UIslandOverseerEyeSettings::GetSettings(Owner);
		ForceFieldBubbleComp = UIslandForceFieldBubbleComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		HealthComp.OnTakeDamage.AddUFunction(this, n"TakeDamage");
	}

	UFUNCTION()
	private void TakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                        EDamageType DamageType)
	{
		if(IsActive())
			return;
		InactiveDamage += Damage;
	}

	UFUNCTION()
	private void Activated(AAIIslandOverseerEye ActivatedEye)
	{
		bArrived = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bArrived)
			return false;
		if(!Eye.bReturn)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(bArrived)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Eye.AccLocation.SnapTo(Eye.ActorLocation);
		Eye.AccScale.SnapTo(Eye.ActorScale3D);
		Eye.AccRotation.SnapTo(Eye.ActorRotation);
		ForceFieldBubbleComp.TakeDamage(100, FVector::ZeroVector);
		Eye.bInAttackSpace = false;
		Eye.Targetable.Disable(Eye);
		UIslandOverseerEyeEventHandler::Trigger_OnExitStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandOverseerEyeEventHandler::Trigger_OnExitEnd(Owner);
		Eye.Deactivate();
		
		UIslandOverseerTakeDamageComponent OwnerTakeDamageComp = UIslandOverseerTakeDamageComponent::GetOrCreate(Eye.Boss);
		FIslandRedBlueImpactResponseParams Data;
		Data.Player = Eye.KillingPlayer;
		Data.ImpactLocation = Eye.ActorLocation;	

		// Change damage from eye return based on how much damage players do during other phases
		float Damage = 0.05;
		Damage -= (Damage / 2) * Math::Clamp(InactiveDamage / Damage, 0, 1);

		// We don't want to kill the boss with the first eye return
		UBasicAIHealthComponent BossHealthComp = UBasicAIHealthComponent::GetOrCreate(Eye.Boss);
		int Segments = UBasicAIHealthBarSettings::GetSettings(Eye.Boss).HealthBarSegments;
		float SegmentHealth = BossHealthComp.CurrentHealth - (Segments - 1);
		if(SegmentHealth <= Damage)
		{
			UIslandOverseerDeployEyeManagerComponent EyesManagerComp = UIslandOverseerDeployEyeManagerComponent::GetOrCreate(Eye.Boss);
			for(auto ManagerEye : EyesManagerComp.Eyes)
			{
				if(ManagerEye == Eye)
					continue;
				if(ManagerEye.Active)
					Damage = SegmentHealth / 2;
			}
		}
		OwnerTakeDamageComp.TakeGeneralDamage(Damage, Data);
		InactiveDamage = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Eye.AccLocation.AccelerateTo(Eye.EyesComp.WorldLocation, Eye.ReturnDuration, DeltaTime);
		Owner.ActorLocation = Eye.AccLocation.Value;

		Eye.AccScale.AccelerateTo(Eye.OriginalScale, Eye.ReturnDuration, DeltaTime);
		Eye.ActorScale3D = Eye.AccScale.Value;
		DestinationComp.RotateInDirection(Eye.EyesComp.WorldRotation.ForwardVector);

		if(Owner.ActorLocation.PointsAreNear(Eye.EyesComp.WorldLocation, 25))
			bArrived = true;
	}
}