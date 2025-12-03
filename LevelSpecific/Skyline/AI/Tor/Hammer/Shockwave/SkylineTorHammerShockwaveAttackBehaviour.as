class USkylineTorHammerShockwaveAttackBehaviour : UBasicBehaviour
{	
	USkylineTorHammerVolleyComponent VolleyComp;
	USkylineTorHammerStealComponent StealComp;
	USkylineTorHammerComponent HammerComp;
	USkylineTorSettings Settings;
	UAnimInstanceSkylineTor AnimInstance;
	AHazeCharacter Character;

	private AHazeActor Target;
	bool bBladeHit;

	float ShockwaveInterval = 1.5;
	int ShockwaveNum;
	int FirstPhaseShockwaveMax = 0;
	int DefaultShockwaveMax = 1;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		VolleyComp = USkylineTorHammerVolleyComponent::GetOrCreate(Owner);
		StealComp = USkylineTorHammerStealComponent::GetOrCreate(Owner);
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);
		Character = Cast<AHazeCharacter>(Owner);
		AnimInstance = Cast<UAnimInstanceSkylineTor>(Character.Mesh.AnimInstance);

		UGravityBladeCombatResponseComponent BladeResponse = UGravityBladeCombatResponseComponent::Get(Owner);
		BladeResponse.OnHit.AddUFunction(this, n"OnBladeHit");
	}

	UFUNCTION()
	private void OnBladeHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		Cooldown.Set(1);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!VolleyComp.bEnableShockwaves)
			return false;
		if(Time::GetGameTimeSince(VolleyComp.ShockwaveTime) < ShockwaveInterval)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!VolleyComp.bEnableShockwaves)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		USkylineTorHammerEventHandler::Trigger_OnShockwaveTelegraphStart(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();	
		USkylineTorHammerEventHandler::Trigger_OnShockwaveTelegraphStop(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < ShockwaveInterval / 2)
			return;

		if(HammerComp.HoldHammerComp.Tor.PhaseComp.Phase == ESkylineTorPhase::Hovering && Settings.ShieldBreakModeEnabled)
			VolleyComp.SpawnShockwave(ESkylineTorSmashShockwaveType::Wave);
		else
			VolleyComp.SpawnShockwave(ESkylineTorSmashShockwaveType::Default);

		USkylineTorHammerEventHandler::Trigger_OnShockwaveAttack(Cast<AHazeActor>(Owner), FOnShockwaveAttackData(VolleyComp.ImpactLocation));
		DeactivateBehaviour();
	}
}