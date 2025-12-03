// Don't do anything aggressive when forcefield is up
class USummitCrystalSkullBossForceFieldBehaviour :UBasicBehaviour
{
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	USummitCrystalSkullBossForceFieldComponent ForceField;
	UHackForceFieldCollision HackCollision;
	UHazeActorRespawnableComponent RespawnComp;
	USummitCrystalSkullArmourComponent ArmourComp;
	USummitCrystalSkullBossSettings BossSettings;
	USummitCrystalSkullsTeam SkullsTeam;
	float ForceFieldDownDuration = 0.0;
	bool bFlickerOff = false;
	float FlickerTime = 0.0;
	bool bStartedCollapseEffect = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		ForceField = USummitCrystalSkullBossForceFieldComponent::Get(Owner);
		HackCollision = UHackForceFieldCollision::Get(Owner);
		SkullsTeam = CrystalSkullsTeam::Join(Owner);
		SkullsTeam.Boss = Owner;
		ForceField.Initialize(SkullsTeam);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		ArmourComp = USummitCrystalSkullArmourComponent::Get(Owner);
		BossSettings = USummitCrystalSkullBossSettings::GetSettings(Owner); 
		ForceField.AddComponentVisualsBlocker(this);
		ForceField.AddComponentCollisionBlocker(this);
		if (HackCollision != nullptr)
			HackCollision.AddComponentCollisionBlocker(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (ForceField == nullptr)
			return false;
		if (!ForceField.IsOperational() && (RespawnComp.SpawnedDuration > 1.0))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ForceFieldDownDuration > BossSettings.ForceFieldBringDownDuration)
			return true;	
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ForceField.RemoveComponentVisualsBlocker(this);
		ForceField.RemoveComponentCollisionBlocker(this);
		if (HackCollision != nullptr)
			HackCollision.RemoveComponentCollisionBlocker(this);
		ArmourComp.Armour.bIgnoreAcid = true;
		bFlickerOff = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (!bFlickerOff)
			ForceField.AddComponentVisualsBlocker(this);
		ForceField.AddComponentCollisionBlocker(this);
		if (HackCollision != nullptr)
			HackCollision.AddComponentCollisionBlocker(this);
		ArmourComp.Armour.bIgnoreAcid = false;
		USummitMagicBarrierEventHandler::Trigger_OnCollapsed(Owner, FMagicBarrierCollapseParams(ForceField));				
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!ForceField.IsOperational())
			ForceFieldDownDuration += DeltaTime;
		else
			ForceFieldDownDuration = 0.0;

		if (ForceFieldDownDuration > 0)
		{
			//Flicker on and off until it finally goes down.
			if (Time::GameTimeSeconds > FlickerTime)
			{
				if (bFlickerOff)			
					ForceField.RemoveComponentVisualsBlocker(this);
				else
					ForceField.AddComponentVisualsBlocker(this);

				bFlickerOff = !bFlickerOff;
				FlickerTime = Time::GameTimeSeconds + Math::RandRange(0.05, 0.2);			
			}

			if (!bStartedCollapseEffect && ForceFieldDownDuration > 0.1)
				USummitMagicBarrierEventHandler::Trigger_OnStartCollapsing(Owner, FMagicBarrierCollapseParams(ForceField));				
		}		
	}
}

class UHackForceFieldCollision : UHazeCapsuleCollisionComponent
{
}
